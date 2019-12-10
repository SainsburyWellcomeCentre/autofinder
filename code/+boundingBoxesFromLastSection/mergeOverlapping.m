function [stats,nRoiChange] = mergeOverlapping(stats,imSize)
    % Consolidate bounding boxes that overlap a reasonable amount so long as doing so
    % Is not going to result in a large increase in the area being imaged.
    %
    % Returns the updated stats struct and the difference in ROI number after running.

    diagnositicPlots=false;

    if length(stats)==1 
        if diagnositicPlots
            fprintf('Only one ROI, no merge possible by mergeOverlapping\n')
        end
        nRoiChange=0;
        return
    end

    % Generate an empty image that will accomodate all the boxes
    tmpIm = zeros([imSize,length(stats)]);
    initialRoiNum=length(stats);
    % Fill in the blank "image" with the areas that are ROIs
    for ii=1:length(stats)
        eb = boundingBoxesFromLastSection.validateBoundingBox(stats(ii).BoundingBox, imSize);
        tmpIm(eb(2):eb(2)+eb(4), eb(1):eb(1)+eb(3),ii) = 1;
    end



    % If areas do not overlap the sum of tmpIm along dim 3 will contain only 1 and 0.
    % Therefore the following anonymous function will return true when there are overlaps.
    containsOverlaps = @(x) ~isequal(unique(sum(x,3)),[0;1]);
    if ~containsOverlaps(tmpIm)
        if diagnositicPlots
            fprintf('No overlapping ROIs\n')
        end
        nRoiChange=0;
        return
    end

    if size(tmpIm,3)>1
        if diagnositicPlots
            fprintf('Attempting to merge %d ROIs\n',size(tmpIm,3));
        end
    end

    % Keep looping until all are merged

    while containsOverlaps(tmpIm)
        combosToTest = nchoosek(1:size(tmpIm,3),2);  %The unique combinations to test
        overlapProp = zeros(1,length(combosToTest)); %Pre-allocate a variable in which to store results

        % Determine how much each ROI overlaps with every other
        for ii=1:size(combosToTest,1)
            % Make a new plane that is the sum of two we are testing
            tCombo = sum( tmpIm(:,:,[combosToTest(ii,1),combosToTest(ii,2)]), 3); 
            overlapProp(ii) = length(find(tCombo(:)==2)) / length(find(tCombo(:)>=1));
            if diagnositicPlots
                clf
                subplot(1,2,1)
                imagesc(tmpIm(:,:,combosToTest(ii,1)))
                title(sprintf('Plane %d', combosToTest(ii,1)))
                subplot(1,2,2)
                imagesc(tmpIm(:,:,combosToTest(ii,2)))
                title(sprintf('Plane %d Prop overlap: %0.3f', combosToTest(ii,2), overlapProp(ii)))
                pause
            end
        end

        %Make a new area composed of only 1s and 0s which merges the two bounding boxes which 
        %overlap the most and ignore the rest (maybe this a bad idea, but let's go with it for now)
        [~,ind] = max(overlapProp);
        tCombo = sum( tmpIm(:,:,[combosToTest(ind,1),combosToTest(ind,2)]), 3); 
        tCombo(tCombo>0) = 1; %We now have a new ROI that incorporates the two


        % Determine by how much we will increase the total imaged area if we merge these ROIs
        areaOfROI1 = sum( tmpIm(:,:,combosToTest(ind,1)), 'all');
        areaOfROI2 = sum( tmpIm(:,:,combosToTest(ind,2)), 'all');
        areaOfMergedROI = boundingBoxesFromLastSection.boundingBoxAreaFromImage(tCombo);
        proportionIncrease = areaOfMergedROI/(areaOfROI1+areaOfROI2);

        if diagnositicPlots
            clf
            imagesc(tCombo)
            title(sprintf('AreaA %d. AreaB %d. Imaging area increase prop:%0.3f',...
                areaOfROI1, ...
                areaOfROI2, ...
                proportionIncrease))
            pause
        end

        % Merge if less than 10%
        if proportionIncrease<1.3
            if diagnositicPlots
                fprintf('Merging into plane %d and then deleting plane %d\n', ...
                    combosToTest(ind,1), combosToTest(ind,2))
            end
            tmpIm(:,:,combosToTest(ind,1)) = tCombo;
            tmpIm(:,:,combosToTest(ind,2)) = [];
        else
            % Otherwise remove the overlap between these two areas
            if diagnositicPlots
                fprintf('Not merging\n')
            end
            tmpIm(:,:,combosToTest(ii,1)) =  tmpIm(:,:,combosToTest(ind,1)) - tmpIm(:,:,combosToTest(ind,2));
            tmpIm(tmpIm<0)=0;
        end


        % Break out of the loop if there are no more overlaps
        if size(tmpIm,3)==1 || sum(overlapProp)==0
            fprintf('\n')
            break
        end

    end


    % Round to nearest pixel
    stats = regionprops(sum(tmpIm,3)>0,'BoundingBox','Image');
    for ii=1:length(stats)
        stats(ii).BoundingBox = round(stats(ii).BoundingBox);
        stats(ii).BoundingBox(stats(ii).BoundingBox==0)=1;
    end
    fprintf('mergeOverlapping Found %d regions\n', size(tmpIm,3))

    nRoiChange = length(stats)-initialRoiNum;

