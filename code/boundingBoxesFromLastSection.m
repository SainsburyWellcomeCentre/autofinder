function varargout=boundingBoxesFromLastSection(im, varargin)
    % boundingBoxesFromLastSection
    %
    % function varargout=boundingBoxesFromLastSection(im, 'param',val, ... )
    % 
    % Purpose
    % Automatically detect regions in the current section where there is
    % sample and find a tile-based bounding box that surrounds it. This function
    % can also be fed a bounding box list in order to use these ROIs as a guide
    % for finding the next set of boxes in the next xection. This mimics the 
    % behavior under the microscope. 
    % See: boundingBoxesFromLastSection.text.runOnStackStruct
    %
    % Return results in a structure.
    %
    % 
    % Inputs (Required)
    % im - downsampled 2D image.
    %
    % Inputs (Optional param/val pairs)
    % pixelSize - 5 (microns/pixel) by default
    % tileSize - 1000 (microns/pixel) by default. Size of tile FOV in microns.
    % tThresh - Threshold for brain/no brain. By default this is auto-calculated
    % doPlot - if true, display image and overlay boxes. false by default
    % lastSectionStats - By default the whole image is used. If this argument is 
    %               present it should be the output of image2boundingBoxes from a
    %               previous sectionl
    % borderPixSize - number of pixels from border to user for background calc. 5 by default
    %
    % Outputs
    % stats - borders and so forth
    % H - plot handles
    % im - the image that was analysed 
    %
    %
    % Rob Campbell - SWC, 2019


    if ~isnumeric(im)
        fprintf('%s - First input argument must be an image.\n',mfilename)
        return
    end


    % Parse input arguments
    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('pixelSize', 7, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('tileSize', 1000, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('lastSectionStats',[], @(x) isstruct(x) || isempty(x))
    params.addParameter('borderPixSize',5, @(x) isnumeric(x) ) %TODO -- DOES NOTHING RIGHT NO


    params.parse(varargin{:})
    pixelSize = params.Results.pixelSize;
    tileSize = params.Results.tileSize;
    doPlot = params.Results.doPlot;
    tThresh = params.Results.tThresh;
    borderPixSize = params.Results.borderPixSize;
    lastSectionStats = params.Results.lastSectionStats;






    % Median filter the image first. This is necessary, otherwise downstream steps may not work.
    im = medfilt2(im,[5,5]);
    im = single(im);


    % If no threshold for segregating sample from background was supplied then calculate one
    % based on the pixels around the image border.
    if isempty(tThresh)
        %Find pixels within b pixels of the border
        b = borderPixSize;
        borderPixSize = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        borderPixSize = borderPixSize(:);
        tThresh = median(borderPixSize) + std(borderPixSize)*4;
    end

    if isempty(lastSectionStats)
        % We run on the whole image
        BW    = binarizeImage(im,pixelSize,tThresh); % Binarize, clean, add a border.
        stats = getBoundingBoxes(BW,im,pixelSize);  % Find bounding boxes
        %stats = boundingBoxesFromLastSection.growBoundingBoxIfSampleClipped(im,stats,pixelSize,tileSize);
        stats = boundingBoxesFromLastSection.mergeOverlapping(stats,size(im)); % Merge partially overlapping ROIs
    else
        % Run within each ROI then afterwards consolidate results
        for ii = 1:length(lastSectionStats.BoundingBoxes)
            %fprintf('Analysing ROI %d for sub-ROIs\n', ii)
            tIm        = getSubImageUsingBoundingBox(im,lastSectionStats.BoundingBoxes{ii},true); % Pull out just this sub-region
            BW         = binarizeImage(tIm,pixelSize,tThresh);
            tStats{ii} = getBoundingBoxes(BW,im,pixelSize);
            %tStats{ii}}= boundingBoxesFromLastSection.growBoundingBoxIfSampleClipped(im,tStats{ii},pixelSize,tileSize);
            tStats{ii} = boundingBoxesFromLastSection.mergeOverlapping(tStats{ii},size(tIm));
        end

        % Collate bounding boxes across sub-regions into one "stats" structure. 
        n=1;
        for ii = 1:length(tStats)
            for jj = 1:length(tStats{ii})
                stats(n).BoundingBox = tStats{ii}(jj).BoundingBox; %collate into one structure
                n=n+1;
            end
        end


        % Final merge. This is in case some sample ROIs are now so close together that
        % they ought to be merged. This would not have been possible to do until this point. 
        % TODO -- possibly we can do only the final merge?
        stats = boundingBoxesFromLastSection.mergeOverlapping(stats,size(im));

    end
    

    doTiledRoi=true;
    if doTiledRoi
        fprintf('Building tiled ROIs\n')
        %Convert to a tiled ROI size 
        for ii=1:length(stats)
            stats(ii).BoundingBox = ...
            boundingBoxesFromLastSection.boundingBoxToTiledBox(stats(ii).BoundingBox, ...
                pixelSize, tileSize, 0.1);

        end

        [stats,dRoi] = boundingBoxesFromLastSection.mergeOverlapping(stats,size(im));

        if dRoi<0
            for ii=1:length(stats)
                stats(ii).BoundingBox = ...
                boundingBoxesFromLastSection.boundingBoxToTiledBox(stats(ii).BoundingBox, ...
                    pixelSize, tileSize, 0.1);
            end % for 
        end %if dRoi
    end % if doTiledRoi


    if doPlot
        imagesc(im)
        colormap gray
        axis equal tight
        for ii=1:length(stats)
            H(ii)=boundingBoxesFromLastSection.plotting.overlayBoundingBox(stats(ii).BoundingBox);
        end
    else
        H=[];
    end



    % Finish up: generate all relevant stats to return as an output argument
    out.BoundingBoxes = {stats.BoundingBox};

    % Determine the size of the overall box that would include all boxes
    if length(out.BoundingBoxes)==1
        out.globalBoundingBox = out.BoundingBoxes{1};
    elseif length(out.BoundingBoxes)>1
        tmp = cell2mat(out.BoundingBoxes');
        out.globalBoundingBox = [min(tmp(:,1:2)), max(tmp(:,1)+tmp(:,3)), max(tmp(:,2)+tmp(:,4))];
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
    out.BoundingBox=[]; % Main function fills in if the analysis was performed on a smaller ROI
    out.notes=''; %Anything odd can go in here
    out.tThresh = tThresh;


    % Optionally return coords of each box
    if nargout>0
        varargout{1}=out;
    end

    if nargout>1
        varargout{2}=H;
    end

    if nargout>2
        varargout{3}=im;
    end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%% Internal functions follow
function BW = binarizeImage(im,pixelSize,tThresh)
    % Binarise and clean image. Adding a border before returning
    verbose = false;
    BW = im>tThresh;
    BW = medfilt2(BW,[5,5]);

    if verbose
        fprintf('Binarized size before dilation: %d by %d\n',size(BW));
    end

    % Remove crap using spatial filtering
    SE = strel('disk',round(50/pixelSize));
    BW = imerode(BW,SE);    
    BW = imdilate(BW,SE);


    % Add a border around the brain
    SE = strel('square',round(200/pixelSize));
    BW = imdilate(BW,SE);

    if verbose
        fprintf('Binarized size after dilation: %d by %d\n',size(BW));
            [~,tmp] = boundingBoxesFromLastSection.boundingBoxAreaFromImage(BW);
        fprintf('ROI size within binarized image: %d by %d\n',tmp);
    end



function stats = getBoundingBoxes(BW,im,pixelSize)
    % Get bounding boxes in binarized image, BW. 

    % Find bounding boxes, removing very small ones and 
    stats = regionprops(BW,'boundingbox', 'area', 'extrema');

    if isempty(stats)
        fprintf('autofindBrainsInSection.image2boundingBoxes found no sample in ROI! BAD!\n')
        return
    end

    % Delete very small objects and ensure we have no non-integers
    minSizeInSqMicrons=50;
    sizeThresh = minSizeInSqMicrons * pixelSize;


    for ii=length(stats):-1:1
        stats(ii).BoundingBox(1:2) = round(stats(ii).BoundingBox(1:2));
        stats(ii).BoundingBox(stats(ii).BoundingBox==0)=1;
        if stats(ii).Area < sizeThresh;
            fprintf('Removing small ROI of size %d\n', stats(ii).Area)
            stats(ii)=[];
        end

    end

    % -------------------
    % TEMP UNTIL WE FIX BAKINGTRAY
    %Look for ROIs smaller than 2 by 2 mm and ask whether they are the un-imaged corner tile.
    %(BakingTray currently (Dec 2019) produces these tiles and this needs sorting.)
    %If so delete. TODO: longer term we want to get rid of the problem at acquisition. 
    for ii=length(stats):-1:1
        boxArea = prod(stats(ii).BoundingBox(3:4)*pixelSize*1E-3);
        if boxArea>2
            % TODO: could use the actual tile size
            continue
        end


        % Ask if most pixels the median value.
        tmp=getSubImageUsingBoundingBox(im,stats(ii).BoundingBox);
        tMed=median(tmp(:));
        propMedPix=length(find(tmp==tMed)) / length(tmp(:));
        if propMedPix>0.5
            %Then delete the ROI
            fprintf('Removing corner ROI\n')
            stats(ii)=[];
        end
    end
    % -------------------


    %Sort in ascending size order
    [~,ind]=sort([stats.Area]);
    stats = stats(ind);

    %Report clipping of ROI edges
    for ii=1:length(stats)
       % boundingBoxesFromLastSection.findROIEdgeClipping(BW,stats(ii).BoundingBox)
    end



function subIm = getSubImageUsingBoundingBox(im,BoundingBox,maintainSize)
    % Pull out a sub-region of the image based on a bounding box.
    %
    % Inputs
    % im - 2d image from which we will extract a sub-region
    % BoundingBox - in the form: [left corner pos, bottom corner pos, width, height]
    % maintainSize - false by default. If true, the output (subIM), is the same size as im
    %                but all pixels outside BoundingBox are zero.

    if nargin<3
        maintainSize=false;
    end


    BoundingBox = boundingBoxesFromLastSection.validateBoundingBox(BoundingBox,size(im));
    subIm = im(BoundingBox(2):BoundingBox(2)+BoundingBox(4), ...
               BoundingBox(1):BoundingBox(1)+BoundingBox(3));

    if maintainSize
        tmp=zeros(size(im));
        tmp(BoundingBox(2):BoundingBox(2)+BoundingBox(4), ...
            BoundingBox(1):BoundingBox(1)+BoundingBox(3)) = subIm;
        subIm =tmp;
    end


 
