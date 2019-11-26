function out = image2boundingBoxes(im,pixelSize,varargin)
    % Main workhorse function. This one uses a defined threshold
    % to draw a box with a boundary around the brain. 
    %
    % Inputs
    % im - 2D image 
    % pixelSize
    %
    % Inputs (optioanal param/val pairs)
    % ROIstats - To allow image2boundingBoxes to run only within sub-regions of the image.
    %            This simulates the behavior of 


    % TODO - add determine bounding box based on a particular tile size. 
    % This is important as it will have implications on how bounding boxes merge.


    % Parse input arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('ROIstats',[], @(x) isstruct(x) || isempty(x))
    params.addParameter('borderPixSize',5, @(x) isnumeric(x) )
    params.addParameter('tileSize', 1000, @(x) isnumeric(x) && isscalar(x))


    params.parse(varargin{:})
    doPlot = params.Results.doPlot;
    tThresh = params.Results.tThresh;
    borderPixSize = params.Results.borderPixSize;
    tileSize = params.Results.tileSize;
    ROIstats = params.Results.ROIstats;




    % Median filter the image first. This is necessary, otherwise downstream steps may not work.
    im = medfilt2(im,[5,5]);
    im = single(im);


    if isempty(tThresh)
        %Find pixels within b pixels of the border
        b=borderPixSize;
        borderPix = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        borderPix = borderPix(:);
        tThresh = median(borderPix) + std(borderPix)*4;
    end


    % Binarize and clean image. Add a border before returning
    BW = binarizeImage(im,tThresh);

    % Find bounding boxes
    stats = getBoundingBoxes(BW);

    % Merge partially overlapping ROIs
    stats=mergeOverlapping(stats,size(BW));


    if doPlot
        imagesc(im)
        colormap gray
        axis equal tight
        for ii=1:length(stats)
            boundingBoxesFromLastSection.plotting.overlayBoundingBox(stats(ii).BoundingBox)
        end

    end





    % Finish up: generate all relevant stats to return as an output argument
    out.BoundingBoxes = {stats.BoundingBox};

    % Determine the size of the overall box that would include all boxes
    if length(out.BoundingBoxes)==1
        out.globalBoundingBox = out.BoundingBoxes{1};
    elseif length(out.BoundingBoxes)>1
        tmp = cell2mat(out.BoundingBoxes');
        out.globalBox = [min(tmp(:,1:2)), max(tmp(:,1)+tmp(:,3)), max(tmp(:,2)+tmp(:,4))];
    end

    % Store statistics in output structure
    backgroundPix = im(find(~BW));
    out.meanBackground = mean(backgroundPix(:));
    out.medianBackground = median(backgroundPix(:));
    out.stdBackground = std(backgroundPix(:));
    out.nBackgroundPix = sum(~BW(:));

    foregroundPix = im(find(BW));
    out.meanForeground = mean(foregroundPix(:));
    out.medianForeground = median(foregroundPix(:));
    out.stdForeground = std(foregroundPix(:));
    out.nForegroundPix = sum(BW(:));
    out.ROIrestrict=[]; % Main function fills in if the analysis was performed on a smaller ROI
    out.notes=''; %Anything odd can go in here
    out.tThresh = tThresh;




% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%% Internal functions follow

function stats = mergeOverlapping(stats,imSize)
    % Consolidate bounding boxes that overlap a reasonable amount so long as doing so
    % Is not going to result in a large increase in the area being imaged.


    % Generate an empty image that will accomodate all the boxes
    tmpIm = zeros([imSize,length(stats)]);

    % Fill in the blank "image" with the areas that are ROIs
    for ii=1:length(stats)
        eb = stats(ii).BoundingBox;
        eb = [floor(eb(1:2)), ceil(eb(3:4))];   
        tmpIm(eb(2):eb(2)+eb(4), eb(1):eb(1)+eb(3),ii) = 1;
        %tmpIm(:,:,ii) = boundingBox2Image(maxY,maxX, stats(ii).BoundingBox);
    end


    % If areas do not overlap the sum of tmpIm along dim 3 will contain only 1 and 0.
    % Therefore the following anonymous function will return true when there are overlaps.
    containsOverlaps = @(x) ~isequal(unique(sum(x,3)),[0;1]);
    if ~containsOverlaps(tmpIm)
        return
    end

    if size(tmpIm,3)>1
        fprintf('Attempting to merge %d ROIs\n',size(tmpIm,3));
    end

    % Keep looping until all are merged

    while containsOverlaps(tmpIm)
        combosToTest = nchoosek(1:size(tmpIm,3),2);  %The unique combinations to test
        overlapProp = zeros(1,length(combosToTest)); %Pre-allocate a variable in which to store results

        % Determine how much each ROI overlaps with every other
        for ii=1:size(combosToTest,1)
            % Make a new plane that is the sum of two we are testing
            tCombo = sum( tmpIm(:,:,[combosToTest(ii,1),combosToTest(ii,2)]), 3); 
            overlapProp = length(find(tCombo(:)==2)) / length(find(tCombo(:)>=1));
        end

        %Make a new area composed of only 1s and 0s which merges the two bounding boxes which 
        %overlap the most and ignore the rest (maybe this a bad idea, but let's go with it for now)
        [~,ind] = max(overlapProp);
        tCombo = sum( tmpIm(:,:,[combosToTest(ii,1),combosToTest(ii,2)]), 3); 
        tCombo(tCombo>0) = 1; %We now have a new ROI that incorporates the two


        % Determine by how much we will increase the total imaged area if we merge these ROIs
        areaOfROI1=sum( tmpIm(:,:,combosToTest(ii,1)), 'all');
        areaOfROI2=sum( tmpIm(:,:,combosToTest(ii,2)), 'all');
        areaOfMergedROI=boundingBoxAreaFromImage(tCombo);
        proportionIncrease = areaOfMergedROI/(areaOfROI1+areaOfROI2);

        % Merge if less than 10%
        if proportionIncrease<1.1
            tmpIm(:,:,combosToTest(combosToTest(ind,1))) = tCombo;
            tmpIm(:,:,combosToTest(combosToTest(ind,2))) = [];
        else
            % Otherwise remove the overlap between these two areas
            tmpIm(:,:,combosToTest(ii,1)) =  tmpIm(:,:,combosToTest(ii,1)) - tmpIm(:,:,combosToTest(ii,2));
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
    end
    fprintf('Found %d regions\n', size(tmpIm,3))




function im = boundingBox2Image(imSizeRows, imSizeCols, BoundingBox)
    % Create an image of zeros of size imSizeRows and imSizeCols which contains within it
    % a bounding box filled within 1s. The box is defined the way regionprops does it:
    % [x,y,sizex,sizey]

    im = zeros(imSizeRows,imSizeCols);
    BoundingBox = [floor(BoundingBox(1:2)), ceil(BoundingBox(3:4))];        
    im(BoundingBox(2):BoundingBox(2)+BoundingBox(4), BoundingBox(1):BoundingBox(1)+BoundingBox(3)) = 1;




function tArea = boundingBoxAreaFromImage(im)
    % Determine the area of a bounding  box required to fit all non-zero pixels in a binary image.
    tmp = im>0;

    %Rows and columns that have at least one non-zero pixel
    a = find(sum(tmp,1)>1);
    b = find(sum(tmp,2)>1);
    tArea = length(min(a):max(a)) * length(min(b):max(b));



function BW = binarizeImage(im,tThresh)
    % Binarise and clean image. Adding a border before returning
    BW = im>tThresh;
    BW = medfilt2(BW,[5,5]);

    % Remove crap using spatial filtering
    SE = strel('disk',round(50/pixelSize));
    BW = imerode(BW,SE);    BW = imdilate(BW,SE);

    % Add a border around the brain
    SE = strel('square',round(200/pixelSize));
    BW = imdilate(BW,SE);



function stats = getBoundingBoxes(BW)
    % Find bounding boxes, removing very small ones and 
    stats = regionprops(BW,'boundingbox', 'area', 'extrema');

    if isempty(stats)
        fprintf('autofindBrainsInSection.image2boundingBoxes found no sample in ROI! BAD!\n')
        return
    end

    % Delete very small objects
    minSizeInSqMicrons=50;
    sizeThresh = minSizeInSqMicrons * pixelSize;

    for ii=length(stats):-1:1
        round(stats(ii).BoundingBox)
        if stats(ii).Area < sizeThresh;
            stats(ii)=[];
        end
    end

    %Sort in ascending size order
    [~,ind]=sort([stats.Area]);
    stats = stats(ind);
