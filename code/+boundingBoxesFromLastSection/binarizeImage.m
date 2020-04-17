function varargout = binarizeImage(im,pixelSize,tThresh,varargin)
    % Binarize, morph filter, and clean a single image using a fixed threshold.
    %
    % function BW = boundingBoxesFromLastSection.binarizeImage(im,pixelSize,tThresh,...)
    %
    % Purpose
    % This function is called by boundingBoxFromLastSection and is a critical point in
    % the auto-ROI finder. It binarizes and tidies images.
    %
    %
    % Inputs (required)
    % im - a single image from an image stack
    % pixelSize - the number of microns per pixel
    % tThresh - the threshold between sample tissue and background
    %
    % Inputs (optional param/val pairs)
    % showImages - false by default. If true, images are shown.
    % verbose - false by default
    %
    % The following optional parameters take default values from boundingBoxesFromLastSection.readSettings
    % removeNoise - If true, uses morphological filtering to remove electrical noise from the binarized image. 
    % doExpansion - If true, we expand the image area by a value listed in the settings file.
    % settings - Settings structure from .readSettings. If missing, the settings file is read.
    %
    %
    % Output
    % BW - The binarised imaged.
    % stats - An optional structure containing stats describing the number of ROIs, their sizes, etc
    %         this is only calculated if requested. 
    %
    %
    % Rob Campbell - SWC 2020




    % Parse optional input arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('showImages', false, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('verbose', false, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('settings', boundingBoxesFromLastSection.readSettings, @(x) isstruct(x))
    params.addParameter('removeNoise', [], @(x) islogical(x) || x==1 || x==0 || isempty(x))
    params.addParameter('doExpansion', [], @(x) islogical(x) || x==1 || x==0 || isempty(x))

    params.parse(varargin{:})
    showImages = params.Results.showImages;
    verbose = params.Results.verbose;
    settings = params.Results.settings;
    removeNoise = params.Results.removeNoise;
    doExpansion = params.Results.doExpansion;

    if isempty(removeNoise)
        removeNoise = settings.mainBin.removeNoise;
    end
    if isempty(doExpansion)
        doExpansion = settings.mainBin.doExpansion;
    end




    % STEP ONE: threshold the image to produce a binary image
    BW = im>tThresh;
    if showImages
        subplot(2,2,1)
        imagesc(BW)
        title('Before medfilt2')
    end



    % STEP TWO: first morphological filtering stage
    if removeNoise
        % Get rid of line-like things of any orientation. Long thin lines are a hallmark 
        % of the electrical noise in the binary image, so this does a good job of getting
        % rig of most of it. 
        BW=bwpropfilt(BW,'Eccentricity',[0,0.99]); 
    end

    BW = medfilt2(BW,[settings.mainBin.medFiltBW,settings.mainBin.medFiltBW]);

    if showImages
        subplot(2,2,2)
        imagesc(BW)
        title('After medfilt2')
    end

    if verbose
        fprintf('Binarized size before dilation: %d by %d\n',size(BW));
    end
    if nargout>1
        stats.step_two = getStatsFromBW(BW);
    end



    % STEP THREE: second morphological filtering stage using and erode/expand cycle
    SE = strel(settings.mainBin.primaryShape, ...
        round(settings.mainBin.primaryFiltSize/pixelSize));
    BW = imerode(BW,SE);
    if removeNoise
        % Again get rid of line-like things of any orientation; but now do it in the 
        % eroded image then follow it up by getting rid of things with a minor axis length
        % that is short. This catches a few more small noise-like things that might have 
        % been missed by the eccentricity filter. 
        % rig of most of it.
        BW=bwpropfilt(BW,'Eccentricity',[0,0.99]); %Get rid of line-like things
        BW=bwpropfilt(BW,'MinorAxisLength',[2,inf]); %Get rid of things that are thin
    end
    BW = imdilate(BW,SE);

    if showImages
        subplot(2,2,3)
        imagesc(BW)
        title('After morph filter')
        %subplot(2,2,4)
       %hist([r.MinorAxisLength],100)
    end
    if nargout>1
        stats.step_three = getStatsFromBW(BW);
    end


    % STEP FOUR: expansion of the binarized area by adding a border around it
    if doExpansion
        SE = strel(settings.mainBin.expansionShape, ...
            round(settings.mainBin.expansionSize/pixelSize));
        BW = imdilate(BW,SE);
        if nargout>1
            stats.step_four = getStatsFromBW(BW);
        end
    elseif doExpansion==false && nargout>1
        % Just copy data from three as step four never happened
        stats.step_four = stats.step_three;
    end

    if showImages
        subplot(2,2,4)
        imagesc(BW)
        drawnow
        if doExpansion
            title('After expansion')
        else
            title('No expansion performed')
        end
    end



    if nargout>0
        varargout{1}=BW;
    end

    if nargout>1
        varargout{2}=stats;
    end



    %Nested functions follow
    function out_stats = getStatsFromBW(BW)
        bw_stats_tmp = regionprops(BW,'Area','Circularity','Centroid');
        out_stats.Area = [bw_stats_tmp.Area];
        out_stats.Centroid = reshape([bw_stats_tmp.Centroid],2,length(bw_stats_tmp))';
        out_stats.Circularity = [bw_stats_tmp.Circularity];
        out_stats.Area_sqmm = out_stats.Area * (pixelSize*1E-3)^2;
    end

end % enclosing function
