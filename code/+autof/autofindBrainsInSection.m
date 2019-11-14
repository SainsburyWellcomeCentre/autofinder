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
    % pixelSize - 5 (microns/pixel) by default
    % tileSize - 1000 (microns/pixel) by default. Size of tile FOV in microns.
    % tThresh - Threshold for brain/no brain. By defaul this is auto-calculated
    % doPlot - if true, display image and overlay boxes. false by default
    % ROIrestrict - By default the whole image is used. If this argument is 
    %               present it should be a vector of length 4 in the same format
    %               as the enclosing boxes returned by region2EnclosingBox:
    %               This is in the format: [x_corner, y_corner, x_width, y_width] 
    %               The function will use only the supplied ROI (sub region of the 
    %               while image) then attempt to grow the image if needed to 
    %               capture the whole brain. 
    %
    %
    % Outputs
    % stats - borders and so forth
    % H - plot handles
    % im - the image that was analysed 
    %
    %
    % Rob Campbell - SWC, 2019



    % Parse input arguments
    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('pixelSize', 5, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('tileSize', 1000, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', true, @(x) islogical(x) || x==1 || x==0)
    params.addParameter('tThresh',[], @(x) isnumeric(x) && isscalar(x))
    params.addParameter('ROIrestrict',[], @(x) isnumeric(x) )


    params.parse(varargin{:})
    pixelSize = params.Results.pixelSize;
    tileSize = params.Results.tileSize;
    doPlot = params.Results.doPlot;
    tThresh = params.Results.tThresh;
    ROIrestrict = params.Results.ROIrestrict;

    if isempty(ROIrestrict)
        ROIrestrict=[0,0,size(im)];
    end

    if ~isnumeric(im)
        fprintf('%s - First input argument must be an image\n',mfilename)
        return
    end

    if size(im,3)> 1
        im = stitchit.sampleSplitter.filterAndProjectStack(im);
    end

    % Median filter the image first. This is necessary, otherwise downstream steps may not work.

    im = medfilt2(im,[5,5]);

    im = single(im);


    if isempty(tThresh)
        %Find pixels within 10 of a border
        b=5;
        borderPix = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        borderPix = borderPix(:);
        tThresh = mean(borderPix) + std(borderPix)*4;
    end


    % Optionally set data points outside of the restricted ROI to zero
    if isempty(ROIrestrict)
        stats = getBrainInImage(im,pixelSize,tThresh);
    else
        imOrig = im; % Keep a backup
        tROI = validateROIrestrict(ROIrestrict,imOrig);
        im = imOrig(tROI(2):tROI(2)+tROI(4),tROI(1):tROI(1)+tROI(3));
        stats = getBrainInImage(im,pixelSize,tThresh);
        clippedEdges = findROIEdgeClipping(im,stats);
        tileSizeInPixels = round(tileSize/pixelSize);

        % Keep looping until we have a full image
        n=1;
        while ~isempty(clippedEdges)
            fprintf('FOV expansion pass %d\n', n)
            n=n+1;

            if any(clippedEdges=='N')
                tROI(2) = tROI(2)-tileSizeInPixels;
            end
            if any(clippedEdges=='S')
                tROI(4) = tROI(4)+tileSizeInPixels;
            end
            if any(clippedEdges=='E')
                tROI(3) = tROI(3)+tileSizeInPixels;
            end
            if any(clippedEdges=='W')
                tROI(1) = tROI(1)-tileSizeInPixels;
            end

            tROI = validateROIrestrict(tROI,imOrig);
            im = imOrig(tROI(2):tROI(2)+tROI(4),tROI(1):tROI(1)+tROI(3));
            %cla,imagesc(im),drawnow,pause

            stats = getBrainInImage(im,pixelSize,tThresh);
            clippedEdges = findROIEdgeClipping(im,stats);

            % Choose some arbitrary largish number and break if we still haven't expanded to the full field by this point
            if n>20
                fprintf('HARD-BREAK FROM FOV EXPANSION LOOP\n')
                break
            end
        end

        % Log the current FOV ROI and and ensure that all ROI boxes we have drawn in the 
        % units of the original image. 
        stats.ROIrestrict=tROI;
    end


    %Return coordinates in full image space
    for ii=1:length(stats.enclosingBoxes)
        stats.enclosingBoxes{ii}(1:2) = stats.enclosingBoxes{ii}(1:2) + stats.ROIrestrict(1:2);
    end
    for ii=1:length(stats.boundaries)
        stats.boundaries{ii}(:,1) = stats.boundaries{ii}(:,1) + stats.ROIrestrict(2);
        stats.boundaries{ii}(:,2) = stats.boundaries{ii}(:,2) + stats.ROIrestrict(1);
    end
    stats.globalBox(1:2) = stats.globalBox(1:2) + stats.ROIrestrict(1:2);



    % Optionally display image with overlayed borders 
    if doPlot
        H=autof.plotSectionAndBorders(im,stats);
    else
        H=[];        
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




    % Internal functions follow
    function ROIrestrict = validateROIrestrict(ROIrestrict,im)
        % Ensure coordinates of ROIrestrict will not produce invalid values that are outside of the imaged area
        verbose=false;
        if ROIrestrict(1)<1
            if verbose
                fprintf('Capping RR1 from %d to 1\n',ROIrestrict(1))
            end
            ROIrestrict(1)=1;
        end
        if ROIrestrict(2)<1
            if verbose
                fprintf('Capping RR2 from %d to 1\n',ROIrestrict(2))
            end
            ROIrestrict(2)=1;
        end

        if (ROIrestrict(3)+ROIrestrict(1)) > size(im,2)
            if verbose
                disp('Capping RR3')
            end
            ROIrestrict(3) = size(im,2)-ROIrestrict(1);
        end

        if (ROIrestrict(4)+ROIrestrict(2)) > size(im,1)
            if verbose
                fprintf('Capping RR4 from %d to %d\n', ROIrestrict(4),size(im,1)-ROIrestrict(2))
            end
            ROIrestrict(4) = size(im,1)-ROIrestrict(2);
        end


    function clippedEdges = findROIEdgeClipping(im,stats)
        % Return IDs of images edges at which the ROI is clipped. This would indicate
        % that the brain lies outside of the current FOV. 
        % The output variable, clippedEdges, codes data as 'N'orth, 'S'outh, 'E'ast, and 'W'est
        clippedEdges=[];
        for ii=1:size(stats.enclosingBoxes)
            eb=stats.enclosingBoxes{ii};
            if eb(1)==1
                clippedEdges(end+1)='W';
            end
            if eb(2)==1
                clippedEdges(end+1)='N';
            end
            if eb(1)+eb(3) >= size(im,2)
                clippedEdges(end+1)='E';
            end
            if eb(2)+eb(4) >= size(im,1)
                clippedEdges(end+1)='S';
            end
        end

        clippedEdges = char(unique(clippedEdges));


    function stats = getBrainInImage(im,pixelSize,tThresh)
        % Main workhorse function. This one uses a defined threshold
        % to draw a box with a boundary around the brain. 


        % Binarize and clean
        BW = im>tThresh;
        BW = medfilt2(BW,[2,2]);


        % Remove crap using spatial filtering
        SE = strel('disk',round(50/pixelSize));
        BW = imerode(BW,SE);
        BW = imdilate(BW,SE);


        % Add a border around the brain
        SE = strel('square',round(200/pixelSize));
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

            % Determine the size of the overall box that would include all boxes
            if length(stats.enclosingBoxes)==1
                stats.globalBox = stats.enclosingBoxes{1};
            elseif length(stats.enclosingBoxes)>1
                tmp = cell2mat(stats.enclosingBoxes');
                stats.globalBox = [min(tmp(:,1:2)), max(tmp(:,1)+tmp(:,3)), max(tmp(:,2)+tmp(:,4))];                
            end

            backgroundPix = im(find(~BW));
            stats.meanBackground = mean(backgroundPix(:));
            stats.stdBackground = std(backgroundPix(:));
            stats.nBackgroundPix = sum(~BW(:));

            foregroundPix = im(find(BW));
            stats.meanForeground = mean(foregroundPix(:));
            stats.stdForeground = std(foregroundPix(:));
            stats.nForegroundPix = sum(BW(:));
            stats.ROIrestrict=[]; % Main function fills in if the analysis was performed on a smaller ROI

            stats.tThresh = tThresh;

        end
