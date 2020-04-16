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
    % tThresh - Threshold for tissue/no tissue. By default this is auto-calculated
    % tThreshSD - Used to do the auto-calculation of tThresh.
    % doPlot - if true, display image and overlay boxes. false by default
    % doTiledRoi - if true (default) return the ROI we would have if tile scanning. 
    % lastSectionStats - By default the whole image is used. If this argument is 
    %               present it should be the output of image2boundingBoxes from a
    %               previous sectionl
    % borderPixSize - number of pixels from border to user for background calc. 4 by default
    % skipMergeNROIThresh - If more than this number of ROIs is found, do not attempt
    %                         to merge. Just return them. Used to speed up auto-finding.
    %                         By default this is infinity, so we always try to merge.
    % rescaleTo - number of microns per pixel to which we will re-scale. By default 
    %             uses value from settings file.
    % showBinaryImages - shows results from the binarization step
    % doBinaryExpansion - default from setings file. If true, run the expansion of 
    %                     binarized image routine. 
    % settings - the settings structure. If empty or missing, we read from the file itself
    %
    % Outputs
    % stats - borders and so forth
    % binaryImageStats - detailed stats on the binary image step (see binarizeImage)
    % H - plot handles
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

    params.addParameter('pixelSize', 20, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('tileSize', 1000, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('doTiledRoi', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('showBinaryImages', false, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('lastSectionStats',[], @(x) isstruct(x) || isempty(x))
    params.addParameter('borderPixSize',4, @(x) isnumeric(x) )
    params.addParameter('skipMergeNROIThresh',inf, @(x) isnumeric(x) )

    params.addParameter('settings',boundingBoxesFromLastSection.readSettings, @(x) isstruct(x) )

    params.addParameter('tThreshSD',[], @(x) isnumeric(x) && isscalar(x) || isempty(x))
    params.addParameter('doBinaryExpansion', [], @(x) islogical(x) || x==1 || x==0 || isempty(x))
    params.addParameter('rescaleTo',[], @(x) isnumeric(x) || isempty(x))


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
    settings = params.Results.settings;
    rescaleTo = params.Results.rescaleTo;
    showBinaryImages = params.Results.showBinaryImages;
    doBinaryExpansion = params.Results.doBinaryExpansion;

    % Get defaults from settings file if needed
    if isempty(tThreshSD)
        fprintf('%s is using a default threshold of %0.2f\n',mfilename,tThreshSD)
        tThreshSD = settings.main.defaultThreshSD;
    end
    if isempty(doBinaryExpansion)
        doBinaryExpansion = settings.mainBin.doExpansion;
    end
    if isempty(rescaleTo)
        rescaleTo = settings.stackStr.rescaleTo;
    end


    % These are the arguments we feed into the binarization function
    binArgs = {'showImages',showBinaryImages,'doExpansion',doBinaryExpansion,'settings',settings};

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
        fprintf('\n\nNo threshold provided to %s - USING IMAGE BORDER PIXELS to extract a threshold of %0.1f based on threshSD of %0.2f\n', ...
         mfilename, tThresh, tThreshSD)

    else
        fprintf('Running %s with provided threshold of %0.2f\n', mfilename, tThresh)
    end



    % Binarize, clean, add a border around the sample
    if nargout>1
       [BW,binStats] = boundingBoxesFromLastSection.binarizeImage(im,pixelSize,tThresh,binArgs{:});
    else
        BW = boundingBoxesFromLastSection.binarizeImage(im,pixelSize,tThresh,binArgs{:});
    end
    % We run on the whole image
    if showBinaryImages
        disp('Press return')
        pause
    end

    if isempty(lastSectionStats)
        stats = boundingBoxesFromLastSection.getBoundingBoxes(BW,im,pixelSize);  % Find bounding boxes
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
            % Scale down the bounding boxes

            fprintf('* Analysing ROI %d/%d for sub-ROIs\n', ii, length(lastSectionStats.BoundingBoxes))
            % TODO -- we run binarization each time. Otherwise boundingboxes tha merge don't unmerge for some reason.
            %         see Issue 58. 
            tIm = boundingBoxesFromLastSection.getSubImageUsingBoundingBox(im,lastSectionStats.BoundingBoxes{ii},true); % Pull out just this sub-region
            %tBW = boundingBoxesFromLastSection.getSubImageUsingBoundingBox(BW,lastSectionStats.BoundingBoxes{ii},true); % Pull out just this sub-region
            tBW = boundingBoxesFromLastSection.binarizeImage(tIm,pixelSize,tThresh,binArgs{:});
            tStats{ii} = boundingBoxesFromLastSection.getBoundingBoxes(tBW,tIm,pixelSize);
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
    out.BoundingBox=[]; % TODO -- runOnStackStruct writes to this but I'm not sure why
    out.notes=''; % Observations and so on can go here
    out.tThresh = tThresh;

    % Variables associated with pixel size and the original image
    out.origPixelSize = origPixelSize;
    out.rescaledPixelSize = rescaleTo;
    out.rescaledRatio = origPixelSize/rescaleTo;
    out.imSize = sizeIm;


    % GET STATS OF EACH ROI
    for ii=1:length(out.BoundingBoxes)
        tIm = boundingBoxesFromLastSection.getSubImageUsingBoundingBox(im,out.BoundingBoxes{ii});
        tBW = boundingBoxesFromLastSection.getSubImageUsingBoundingBox(BW,out.BoundingBoxes{ii});
        imStats(ii) = boundingBoxesFromLastSection.getImageStats(tIm,pixelSize,borderPixSize,tThresh,tBW);
    end

    % Get the foreground and background pixel stats from the ROIs (not the whole image)
    out.meanBackground = mean([imStats.backgroundPix]);
    out.medianBackground = median([imStats.backgroundPix]);
    out.stdBackground = std([imStats.backgroundPix]);

    out.meanForeground = mean([imStats.foregroundPix]);
    out.medianForeground = median([imStats.foregroundPix]);
    out.stdForeground = std([imStats.foregroundPix]);


    % Calculate area of background and foreground in sq mm from the above ROIs
    out.backgroundSqMM = length([imStats.backgroundPix]) * (pixelSize*1E-3)^2;
    out.foregroundSqMM = length([imStats.foregroundPix]) * (pixelSize*1E-3)^2;


    % Calculate the number of pixels in the bounding boxes
    for ii=1:length(out.BoundingBoxes)
        nBoundingBoxPixels(ii) = prod(out.BoundingBoxes{ii}(3:4)); % Do not return total pixels: they are downsampled
    end
    % Convert bounding box sizes to meaningful units and return those.
    out.BoundingBoxSqMM = nBoundingBoxPixels * (pixelSize*1E-3)^2;
    out.meanBoundingBoxSqMM = mean(out.BoundingBoxSqMM);
    out.totalBoundingBoxSqMM = sum(out.BoundingBoxSqMM);

    % What proportion of the whole FOV is covered by the bounding boxes?
    % This number is only available in test datasets. In real acquisitions with the 
    % auto-finder we won't have this number. 
    out.propImagedAreaCoveredByBoundingBox = sum(nBoundingBoxPixels) / prod(sizeIm);


    % Finally: return bounding boxes to original size
    % If we re-scaled then we need to put the bounding box coords back into the original size
    if rescaleTo>1
        out.BoundingBoxes = ...
            cellfun(@(x) round(x*(rescaleTo/origPixelSize)), out.BoundingBoxes,'UniformOutput',false);
    end



    % Optionally return coords of each box
    if nargout>0
        varargout{1}=out;
    end

    if nargout>1
        varargout{2}=binStats;
    end

    if nargout>2
        varargout{3}=H;
    end
