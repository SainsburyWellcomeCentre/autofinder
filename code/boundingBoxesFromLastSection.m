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
    % pixelSize - 7 (microns/pixel) by default
    % tileSize - 1000 (microns) by default. Size of tile FOV in microns.
    % tThresh - Threshold for brain/no brain. By default this is auto-calculated
    % tThreshSD - Used to do the auto-calculation of tThresh.
    % doPlot - if true, display image and overlay boxes. false by default
    % doTiledRoi - if true (default) return the ROI we would have if tile scanning. 
    % lastSectionStats - By default the whole image is used. If this argument is 
    %               present it should be the output of image2boundingBoxes from a
    %               previous sectionl
    % borderPixSize - number of pixels from border to user for background calc. 5 by default
    % skipMergeNROIThresh - If more than this number of ROIs is found, do not attempt
    %                         to merge. Just return them. Used to speed up auto-finding.
    %                         By default this is infinity, so we always try to merge.
    % rescaleTo - number of microns per pixel to which we will re-scale. By default 
    %             uses value from settings file.
    %
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

    settings = boundingBoxesFromLastSection.readSettings;
    % Parse input arguments
    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('pixelSize', 7, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('tileSize', 1000, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('doTiledRoi', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('tThreshSD',settings.main.defaultThreshSD, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('lastSectionStats',[], @(x) isstruct(x) || isempty(x))
    params.addParameter('borderPixSize',4, @(x) isnumeric(x) )
    params.addParameter('skipMergeNROIThresh',inf, @(x) isnumeric(x) )
    params.addParameter('rescaleTo',settings.stackStr.rescaleTo, @(x) isnumeric(x) )    

    params.parse(varargin{:})
    pixelSize = params.Results.pixelSize;
    tileSize = params.Results.tileSize;
    doPlot = params.Results.doPlot;
    doTiledRoi=params.Results.doTiledRoi;
    tThresh = params.Results.tThresh;
    tThreshSD = params.Results.tThreshSD;
    borderPixSize = params.Results.borderPixSize;
    lastSectionStats = params.Results.lastSectionStats;
    skipMergeNROIThresh = params.Results.skipMergeNROIThresh;
    rescaleTo = params.Results.rescaleTo;

    if size(im,3)>1
        fprintf('%s requires a single image not a stack\n',mfilename)
        return
    end

    if rescaleTo>1
        fprintf('%s is rescaling image to %d mic/pix from %0.2f mic/pix\n', ...
            mfilename, rescaleTo, pixelSize);
        sizeIm=size(im);
        sizeIm = round( sizeIm / (rescaleTo/pixelSize) );
        im = imresize(im, sizeIm);
        origPixelSize = pixelSize;
        pixelSize = rescaleTo;
    else
        origPixelSize = pixelSize;
    end


    fprintf('boundingBoxesFromLastSection running with: ')
    fprintf('pixelSize: %0.2f, tileSize: %d microns, tThreshSD: %0.3f\n', ...
        pixelSize, round(tileSize), tThreshSD)



    % Median filter the image first. This is necessary, otherwise downstream steps may not work.
    im = medfilt2(im,[settings.main.medFiltRawImage,settings.main.medFiltRawImage]);
    im = single(im);

    % If no threshold for segregating sample from background was supplied then calculate one
    % based on the pixels around the image border.
    if isempty(tThresh)
        %Find pixels within b pixels of the border
        b = borderPixSize;
        borderPix = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        borderPix = borderPix(:);
        tThresh = median(borderPix) + std(borderPix)*tThreshSD;
        fprintf('No threshold provided to %s - Choosing a threshold of %0.1f based on threshSD of %0.2f\n', ...
         mfilename, tThresh, tThreshSD)

    else
        fprintf('Running %s with a threshold of %0.2f\n', mfilename, tThresh)
    end



    if isempty(lastSectionStats)

        % We run on the whole image
        BW    = binarizeImage(im,pixelSize,tThresh); % Binarize, clean, add a border.
        stats = getBoundingBoxes(BW,im,pixelSize);  % Find bounding boxes
        %stats = boundingBoxesFromLastSection.growBoundingBoxIfSampleClipped(im,stats,pixelSize,tileSize);

        if length(stats) < skipMergeNROIThresh
            stats = boundingBoxesFromLastSection.mergeOverlapping(stats,size(im)); % Merge partially overlapping ROIs
        end

    else

        if rescaleTo>1
            lastSectionStats.BoundingBoxes = ...
                cellfun(@(x) round(x/(rescaleTo/origPixelSize)), lastSectionStats.BoundingBoxes,'UniformOutput',false);
        end

        % Run within each ROI then afterwards consolidate results
        nT=1;
        for ii = 1:length(lastSectionStats.BoundingBoxes)
            % Scale daown the bounding boxes

            fprintf('* Analysing ROI %d/%d for sub-ROIs\n', ii, length(lastSectionStats.BoundingBoxes))
            tIm        = getSubImageUsingBoundingBox(im,lastSectionStats.BoundingBoxes{ii},true); % Pull out just this sub-region
            BW         = binarizeImage(tIm,pixelSize,tThresh);
            tStats{ii} = getBoundingBoxes(BW,im,pixelSize);
            %tStats{ii}}= boundingBoxesFromLastSection.growBoundingBoxIfSampleClipped(im,tStats{ii},pixelSize,tileSize);

            if ~isempty(tStats{ii})
                tStats{nT} = boundingBoxesFromLastSection.mergeOverlapping(tStats{ii},size(tIm));
                nT=nT+1;
            end

        end

        if ~isempty(tStats{1})

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

            if length(stats) < skipMergeNROIThresh
                fprintf('* Doing final merge\n')
                stats = boundingBoxesFromLastSection.mergeOverlapping(stats,size(im));
            end
        else
            % No bounding boxes found
            fprintf('boundingBoxesFromLastSection found no bounding boxes\n')
            stats=[];
        end

    end

    % Deal with scenario where nothing was found
    if isempty(stats)
        fprintf(' ** Stats array is empty. %s is bailing out. **\n',mfilename)
        if nargout>0
            varargout{1}=[];
        end
        if nargout>1
            varargout{2}=[];
        end
        if nargout>2
            varargout{3}=im;
        end
        return

    end


    % We now expand the tight bounding boxes to larger ones that correspond to a tiled acquisition
    if doTiledRoi

        fprintf('\n -> Creating tiled bounding boxes\n');
        %Convert to a tiled ROI size 
        for ii=1:length(stats)
            stats(ii).BoundingBox = ...
            boundingBoxesFromLastSection.boundingBoxToTiledBox(stats(ii).BoundingBox, ...
                pixelSize, tileSize);
        end

        if settings.main.doTiledMerge && length(stats) < skipMergeNROIThresh
            fprintf('* Doing merge of tiled bounding boxes\n')
            [stats,delta_n_ROI] = ...
                boundingBoxesFromLastSection.mergeOverlapping(stats, size(im), ...
                    settings.main.tiledMergeThresh);
        else
            delta_n_ROI=0;
        end

        % If the number of ROIs decreased then we must re-run the tiled box algorithm
        if delta_n_ROI<0 && settings.main.secondExpansion && settings.main.doTiledMerge && length(stats) < skipMergeNROIThresh
            fprintf('Bounding box number decreased by %d. Recalculating them.\n',delta_n_ROI)
            for ii=1:length(stats)
                stats(ii).BoundingBox = ...
                boundingBoxesFromLastSection.boundingBoxToTiledBox(stats(ii).BoundingBox, ...
                    pixelSize, tileSize);
            end % for ii=1:length(stats)
        end %if delta_n_ROI<0

    end % if doTiledRoi


    if doPlot
        clf
        H=boundingBoxesFromLastSection.plotting.overlayBoundingBoxes(im,stats);
        title('Final boxes')
    else
        H=[];
    end



    % Finish up: generate all relevant stats to return as an output argument
    out.BoundingBoxes = {stats.BoundingBox};
    out.globalBoundingBox={}; % Filled in later 


    % Store statistics in output structure
    BW = binarizeImage(im,pixelSize,tThresh); %Get the binary image again so it includes all tissue above the threshold
    inverseBW = ~BW; %Pixels outside of brain

    % Set all pixels further in than borderPix to zero (assume they contain sample anyway)
    b = borderPixSize;
    inverseBW(b+1:end-b,b+1:end-b)=0;
    backgroundPix = im(find(inverseBW));
    out.origPixelSize = origPixelSize;
    out.rescaledPixelSize = rescaleTo;
    out.rescaledRatio = origPixelSize/rescaleTo;

    out.meanBackground = mean(backgroundPix(:));
    out.medianBackground = median(backgroundPix(:));
    out.stdBackground = std(backgroundPix(:));

    out.nBackgroundPix = sum(~BW(:));
    out.nBackgroundSqMM = out.nBackgroundPix * (pixelSize*1E-3)^2;

    foregroundPix = im(find(BW));
    out.meanForeground = mean(foregroundPix(:));
    out.medianForeground = median(foregroundPix(:));
    out.stdForeground = std(foregroundPix(:));
    out.nForegroundPix = sum(BW(:));
    out.nForegroundSqMM = out.nForegroundPix * (pixelSize*1E-3)^2;
    out.BoundingBox=[]; % Main function fills in if the analysis was performed on a smaller ROI
    out.notes=''; %Anything odd can go in here
    out.tThresh = tThresh;
    out.imSize = size(im);

    % Calculate the number of pixels in the bounding boxes

    for ii=1:length(out.BoundingBoxes)
        out.BoundingBoxPixels(ii) = prod(out.BoundingBoxes{ii}(3:4));
    end
    out.totalBoundingBoxPixels = sum(out.BoundingBoxPixels);
    out.propImagedAreaCoveredByBoundingBox = out.totalBoundingBoxPixels / prod(size(im));


    % Finally: return bounding boxes to original size
    % If we re-scaled then we need to put the bounding box coords back into the original size
    if rescaleTo>1
        out.BoundingBoxes = ...
            cellfun(@(x) round(x*(rescaleTo/origPixelSize)), out.BoundingBoxes,'UniformOutput',false);
    end

    % Determine the size of the overall box that would include all boxes
    if length(out.BoundingBoxes)==1
        out.globalBoundingBox = out.BoundingBoxes{1};
    elseif length(out.BoundingBoxes)>1
        tmp = cell2mat(out.BoundingBoxes');
        out.globalBoundingBox = [min(tmp(:,1:2)), max(tmp(:,1)+tmp(:,3)), max(tmp(:,2)+tmp(:,4))];
    end

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
    showImages = false; %Set to true to display binarized images and force step-through with return key

    settings = boundingBoxesFromLastSection.readSettings;

    BW = im>tThresh;
    if showImages
        subplot(2,2,1)
        imagesc(BW)
        axis square
        title('Before medfilt2')
    end

    BW = medfilt2(BW,[settings.mainBin.medFiltBW,settings.mainBin.medFiltBW]);

    if showImages
        subplot(2,2,2)
        imagesc(BW)
        axis square
        title('After medfilt2')
    end
    if verbose
        fprintf('Binarized size before dilation: %d by %d\n',size(BW));
    end

    % Remove crap using spatial filtering
    SE = strel(settings.mainBin.primaryShape, ...
        round(settings.mainBin.primaryFiltSize/pixelSize));
    BW = imerode(BW,SE);    
    BW = imdilate(BW,SE);
    if showImages
        subplot(2,2,3)
        imagesc(BW)
        title('After morph filter')
    end


    % EXPAND IMAGED AREA: Add a small border around the brain
    SE = strel(settings.mainBin.expansionShape, ...
        round(settings.mainBin.expansionSize/pixelSize));
    BW = imdilate(BW,SE);

    if showImages
        subplot(2,2,4)
        imagesc(BW)
        drawnow
        title('After expansion')
        pause
    end

    if verbose
        fprintf('Binarized size after dilation: %d by %d\n',size(BW));
            [~,tmp] = boundingBoxesFromLastSection.boundingBoxAreaFromImage(BW);
        fprintf('ROI size within binarized image: %d by %d\n',tmp);
    end



function stats = getBoundingBoxes(BW,im,pixelSize)
    % Get bounding boxes in binarized image, BW. 
    verbose=true;
    settings = boundingBoxesFromLastSection.readSettings;

    % Find bounding boxes, removing very small ones and 
    stats = regionprops(BW,'boundingbox', 'area', 'extrema');

    if isempty(stats)
        fprintf('autofindBrainsInSection.image2boundingBoxes found no sample in ROI! BAD!\n')
        return
    end

    % Delete very small objects and ensure we have no non-integers
    sizeThresh = settings.mainGetBB.minSizeInSqMicrons / pixelSize;

    for ii=length(stats):-1:1
        stats(ii).BoundingBox(1:2) = round(stats(ii).BoundingBox(1:2));
        stats(ii).BoundingBox(stats(ii).BoundingBox==0)=1;
        if stats(ii).Area < sizeThresh;
            fprintf('Removing small ROI of size %d\n', stats(ii).Area)
            stats(ii)=[];
        end
    end
    if length(stats)==0
        fprintf('%s > getBoundingBoxes after removing small ROIs there are none left.\n',mfilename)
    end

    % -------------------
    % TEMP UNTIL WE FIX BAKINGTRAY WE MUST REMOVE THE NON-IMAGED CORNER PIXELS
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

    if verbose==false
        return
    end

    if length(stats)==1
        fprintf('%s > getBoundingBoxes Found 1 Bounding Box\n',mfilename)
    elseif length(stats)>1
        fprintf('%s > getBoundingBoxes Found %d Bounding Boxes\n',mfilename,length(stats))
    elseif length(stats)==0
        fprintf('%s > getBoundingBoxes Found no Bounding Boxes\n',mfilename)
    end


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

