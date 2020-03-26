function [stats,nRoiChange] = mergeOverlapping(stats,imSize,DD,im)
    % boundingBoxesFromLastSection.mergeOverlapping merges bounding boxes that overlap 
    %
    % function [stats,nRoiChange] = mergeOverlapping(stats,imSize,DD,im)
    %
    % Purpose
    % Consolidate bounding boxes that overlap a reasonable amount so long as doing so
    % Is not going to result in a large increase in the area being imaged. This avoids
    % imaging the same area twice and also helps to ensure that all of the tissue is 
    % imaged. 
    % 
    % Inputs [REQIURED]
    % stats - the output of getBoundingBoxes, a local function in boundingBoxesFromLastSection
    % imSize - the size of the image 
    %
    % Inputs  [OPTIONAL]
    % DD - False by default. If true, this is a hacky solution to avoid issues with imaging
    % a single brain twice (see https://github.com/raacampbell/autofinder/issues/14). It works
    % by expanding the ROI to the minimal bounding box using the local function 
    % expandROItoBoundingBox. In other words, "L-shaped" ROIs will become rectangles.
    % Alternatively, if DD is numeric and non-negative then it over-rides the mergeThresh value.
    %
    % im - Empty by default. If the original image data is optionally supplied, then diagnostic 
    % plots are made. 
    %
    %
    % Outputs
    % stats - the updated stats struct
    % nRoiChangee - the difference in ROI number after running
    %
    % 
    % 
    % Rob Campbell - SWC 2019/2020


    if nargin<3 || isempty(DD)
        DD=false;
    end

    settings = boundingBoxesFromLastSection.readSettings;

    if isnumeric(DD) && DD>=0
        % This over-rides the default behavior
        mergeThresh=DD;
    else
        %only merge if doing so doesn't increase imaged area by more than this. 
        mergeThresh=settings.mergeO.mergeThresh;
    end

    % Handle optional third argument
    if nargin<4
        im=[];
    end

    verbose=true; %Report more detailed info to command line

    if isempty(im)
        diagnositicPlots=false;
    else
        fprintf('mergeOverlaping is making diagnostic plots\n')
        diagnositicPlots=true;
    end

    if length(stats)==1 
        if verbose
            fprintf('Only one ROI, no merge possible by mergeOverlapping\n')
        end
        nRoiChange=0;
        return
    end

    % Generate an empty image that will accomodate all the boxes
    initialRoiNum=length(stats); %Used below
    tmpIm = boundingBoxesFromLastSection.genOverlapStack({stats.BoundingBox},imSize);

    % If areas do not overlap the sum of tmpIm along dim 3 will contain only 1 and 0.
    % Therefore the following anonymous function will return true when there are overlaps.
    containsOverlaps = @(x) ~isequal(unique(sum(x,3)),[0;1]);
    if ~containsOverlaps(tmpIm)
        if verbose
            fprintf('No overlapping ROIs\n')
        end
        nRoiChange=0;
        return
    end

    if size(tmpIm,3)>1
        if verbose
            fprintf('Attempting to merge %d ROIs\n',size(tmpIm,3));
        end
    end

    % Keep looping until all are merged
    while containsOverlaps(tmpIm)
        combosToTest = nchoosek(1:size(tmpIm,3),2);  %The unique combinations to test
        overlapProp = zeros(1,length(combosToTest)); %Pre-allocate a variable in which to store results

        if DD==true
            tmpIm = expandROItoBoundingBox(tmpIm,1.08); 
        end

        if diagnositicPlots
            clf
            montage(tmpIm,'bordersize',1,'BackgroundColor','r')
            title(sprintf('Current available planes: %d',size(tmpIm,3)))
            drawnow
            pause
        end

        % Determine how much each ROI overlaps with every other
        for ii=1:size(combosToTest,1)

            % Make a new plane that is the sum of two we are testing
            tCombo = sum( tmpIm(:,:,[combosToTest(ii,1),combosToTest(ii,2)]), 3); 
            overlapProp(ii) = length(find(tCombo(:)==2)) / length(find(tCombo(:)>=1));

            if diagnositicPlots
                clf
                subplot(1,2,1)
                imagesc(im.*tmpIm(:,:,combosToTest(ii,1)))
                title(sprintf('Plane %d', combosToTest(ii,1)))

                subplot(1,2,2)
                imagesc(im.*tmpIm(:,:,combosToTest(ii,2)))
                title(sprintf('Plane %d Prop overlap: %0.3f', combosToTest(ii,2), overlapProp(ii)))
                axis equal tight

                drawnow
                pause
            end

            if verbose
                fprintf('ROI %d / ROI %d - %0.3f%% overlap\n', ...
                    combosToTest(ii,1), ...
                    combosToTest(ii,2), ...
                    overlapProp(ii)*100)
            end
        end

        %Make a new area composed of only 1s and 0s which merges the two bounding boxes which 
        %overlap the most and ignore the rest (maybe this a bad idea, but let's go with it for now)
        [~,ind] = max(overlapProp);
        tCombo  = sum( tmpIm(:,:,[combosToTest(ind,1),combosToTest(ind,2)]), 3); 
        tCombo(tCombo>0) = 1; %We now have a new ROI that incorporates the two


        % Determine by how much we will increase the total imaged area if we merge these ROIs
        areaOfROI1 = sum( tmpIm(:,:,combosToTest(ind,1)), 'all' );
        areaOfROI2 = sum( tmpIm(:,:,combosToTest(ind,2)), 'all' );
        areaOfMergedROI = boundingBoxesFromLastSection.boundingBoxAreaFromImage(tCombo);

        % The following is the proportion increase in imaged pixels. It also reflects
        % whether a much larger bounding box will be needed to accomodate an usual ROI shape. 
        proportionIncrease = areaOfMergedROI/(areaOfROI1+areaOfROI2);

        if diagnositicPlots
            clf
            imagesc(im.*tCombo)
            if proportionIncrease<mergeThresh
                mergeStr='MERGING';
            else
                mergeStr='NOT MERGING';
            end
            title(sprintf('AreaA %d. AreaB %d. Imaging area increase prop:%0.3f %s',...
                areaOfROI1, ...
                areaOfROI2, ...
                proportionIncrease, ...
                mergeStr))
            pause
        end

        % Merge if the increase in area is less than mergeThresh
        if proportionIncrease<mergeThresh
            if verbose
                fprintf('Merging into plane %d and then deleting plane %d. Area change: %0.2f\n', ...
                    combosToTest(ind,1), combosToTest(ind,2), proportionIncrease)
            end
            tmpIm(:,:,combosToTest(ind,1)) = tCombo;

            if diagnositicPlots
                subplot(1,2,1)
                imagesc(im.*tmpIm(:,:,combosToTest(ind,1)) )
                title('MERGED PLANE')

                subplot(1,2,2)
                imagesc(im.*tmpIm(:,:,combosToTest(ind,2)) )
                title('PLANE BEING DELETED')
                drawnow
                pause
            end

            tmpIm(:,:,combosToTest(ind,2)) = []; %Delete plane

        else
            % Otherwise remove the overlap between these two areas
            if verbose
                fprintf('Not merging\n')
            end
            tmpIm(:,:,combosToTest(ind,1)) =  tmpIm(:,:,combosToTest(ind,1)) - tmpIm(:,:,combosToTest(ind,2));
            tmpIm(tmpIm<0)=0;
        end


        % Break out of the loop if there are no more overlaps
        if size(tmpIm,3)==1 || sum(overlapProp)==0
            fprintf('\n')
            break
        end

    end % while

    if size(tmpIm,3)==0
        % Something bad has happened
        return
    end

    % Round to nearest pixel
    if verbose
        fprintf('Finished merging with %d bounding boxes\n', length(stats))
    end

    %Loop through each plane and create a bounding box from it
    %Can not use the sum of all planes as we risk merging bounding boxes
    for ii=1:size(tmpIm,3)
        tmp(ii)=regionprops(tmpIm(:,:,ii),'BoundingBox','Image');
    end
    stats=tmp;

    if verbose
        fprintf('After re-running regionprops we have %d bounding boxes\n', length(stats))
    end

    for ii=1:length(stats)
        if verbose
            fprintf('Rounding pixels in bounding box %d\n',ii)
        end
        stats(ii).BoundingBox = round(stats(ii).BoundingBox);
        stats(ii).BoundingBox(stats(ii).BoundingBox==0)=1;
    end

    if size(tmpIm,3)>1
        fprintf('mergeOverlapping has found %d regions\n', size(tmpIm,3))
    elseif size(tmpIm,3)==1
        fprintf('mergeOverlapping has found 1 region\n')
    end

    if diagnositicPlots
        clf
        montage(tmpIm,'bordersize',1,'BackgroundColor','r')
        title(sprintf('Final regions: %d',size(tmpIm,3)))
        drawnow
        pause
    end

    nRoiChange = length(stats)-initialRoiNum;
    if verbose
        if nRoiChange==0
            fprintf('Number of ROIs unchanged by merge operation\n')
        elseif nRoiChange<0
            fprintf('Number of ROIs decreased from %d to %d\n', initialRoiNum,length(stats))
        end

    end


function [BW,propChange] = expandROItoBoundingBox(BW,expandThresh)
    % Takes as input a BW image that contains a ROI and finds the minimal bounding box. Then 
    % replaces the ROI with this bounding box. 
    %
    % i.e. it would convert this:
    %
    %   **
    %   ***
    %   ****
    %
    % To this:
    %
    %   ****
    %   ****
    %   ****
    %
    %
    % Inputs
    % BW - The binarized image used to find bounding boxes. If BW is a 3-D array, the function 
    %      processes each plan separately and returns an array of the same size. 
    % expandThresh - 0 by default. If positive number, the plane is only modified if 
    %                doing so satisfies (newArea/origArea) > expandThresh

    %TODO - likely can delete. I don't think we need this any more 26/03/2020

    verbose=false;
    if verbose
        initBW=BW;
    end


    if nargin<2 || expandThresh<0 
        fprintf('expandROItoBoundingBox is setting expandThresh to inf\n')
        expandThresh=inf;
    end
        

    for ii=1:size(BW,3)

        %Get the bounding box and trim it by a pixel to ensure it does
        %not extend beyond the original bounds if possible. 
        s = regionprops(BW(:,:,ii));
        eb = s.BoundingBox;
        eb(1:2) = eb(1:2)+1;
        eb(3:4) = eb(3:4)-1;
        eb = boundingBoxesFromLastSection.validateBoundingBox(eb,size(BW));


        % TODO the tmp is not needed since we have the initBW
        tmp = BW(:,:,ii);
        tmp(eb(2):eb(2)+eb(4), eb(1):eb(1)+eb(3)) = 1;
        initialPix=sum(BW(:,:,ii),'all');
        finalPix=sum(tmp,'all');

        propChange = finalPix/initialPix;
        if propChange>expandThresh

            BW(:,:,ii)=tmp;
            if verbose

                msg=sprintf('Initial pix: %d ; Final pix: %d ; prop: %0.2f\n', ...
                    initialPix, finalPix, propChange);
                fprintf(msg)
                clf
                subplot(1,2,1)
                imagesc(initBW(:,:,ii))
                title('Before BB expansion')
                
                subplot(1,2,2)
                imagesc(BW(:,:,ii))
                title('After BB expansion')
                drawnow
                pause

            end
        end

    end


