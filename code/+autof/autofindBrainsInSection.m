function varargout=autofindBrainsInSection(im, varargin)
    % autofindBrains
    %
    % function varargout=autofindBrainsInSection(im,pixelSize,doPlot,threshold)
    % 
    % Purpose
    % Automatically detect brain and calculate minimum enclosing box.
    % Return results in a structure.
    %
    % 
    % Inputs (Required)
    % im - downsampled 2D image
    %
    % Inputs (Optional param/val pairs)
    % pixelSize - 25 (microns/pixel) by default
    % tThresh - Threshold for brain/no brain. By defaul this is auto-calculated
    % doPlot - if true, display image and overlay boxes. false by default
    % ROIrestrict - by default the whole image is used. If this argument is 
    %               present it should be a vector of length 4 in the same format
    %               as the enclosing boxes returned by region2EnclosingBox.
    %
    % Outputs
    % stats - borders and so forth
    % H - plot handles
    % im - the image that was analysed 
    %
    %
    % Rob Campbell - SWC, 2019


    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('pixelSize', 5, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('ROIrestrict',[], @(x) isnumeric(x) && isscalar(x))


    params.parse(varargin{:})
    pixelSize = params.Results.pixelSize;
    doPlot = params.Results.doPlot;
    tThresh = params.Results.tThresh;
    ROIrestrict = params.Results.ROIrestrict;


    if ~isnumeric(im)
        fprintf('%s - First input argument must be an image\n',mfilename)
        return
    end

    if size(im,3)> 1
        im = stitchit.sampleSplitter.filterAndProjectStack(im);
    end

    im = single(im);
    im = medfilt2(im,[5,5]);


    if isempty(tThresh)
        %Find pixels within 10 of a border
        b=5;
        borderPix = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        borderPix = borderPix(:);
        tThresh = mean(borderPix) + std(borderPix)*4;
    end


    BW = im>tThresh;
    BW = medfilt2(BW,[2,2]);


    % Remove crap

    % TODO: try disk1
    SE = strel('disk',round(50/pixelSize));
    BW = imerode(BW,SE);
    BW = imdilate(BW,SE);

    % Add a border around the brain
    SE = strel('square',round(275/pixelSize));
    BW = imdilate(BW,SE);

    %Look for objects at that occupy least a certain proportion of the image area
    minSize=0.015;
    nBrains=1;
    sizeThresh = prod(size(im)) * (minSize / nBrains);
    [L,indexedBW]=bwboundaries(BW,'noholes');
    for ii=length(L):-1:1
        thisN = length(find(indexedBW == ii));
        if thisN < sizeThresh
            L(ii)=[]; % Delete small stuff
        end
    end

    H=[]; % Empty plot handle variable in case no brains were found
    if isempty(L)
        fprintf('No brains found!\n')
        stats=[];
    else
        % Generate all relevant stats and so forth
        stats.boundaries = L;
        stats.enclosingBoxes = autof.region2EnclosingBox(L);

        backgroundPix = im(find(~BW));
        stats.meanBackground = mean(backgroundPix(:));
        stats.stdBackground = std(backgroundPix(:));
        stats.nBackgroundPix = sum(~BW(:));

        foregroundPix = im(find(BW));
        stats.meanForeground = mean(foregroundPix(:));
        stats.stdForeground = std(foregroundPix(:));
        stats.nForegroundPix = sum(BW(:));

        stats.tThresh = tThresh;

        % Optionally display image with overlayed borders 
        if doPlot
            H=autof.plotSectionAndBorders(im,stats);
        end

    end


    % Optionally return coords of each box
    if nargout>0
        varargout{1}=stats;
    end

    if nargout>1
        varargout{2}=H;
    end

    if nargout>2
        varargout{3}=im;
    end