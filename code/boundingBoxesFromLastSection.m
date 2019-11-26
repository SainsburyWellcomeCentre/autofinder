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
    % im - downsampled 2D image
    %
    % Inputs (Optional param/val pairs)
    % pixelSize - 5 (microns/pixel) by default
    % tileSize - 1000 (microns/pixel) by default. Size of tile FOV in microns.
    % tThresh - Threshold for brain/no brain. By default this is auto-calculated
    % doPlot - if true, display image and overlay boxes. false by default
    % ROIrestrict - By default the whole image is used. If this argument is 
    %               present it should be a vector of length 4 in the same format
    %               as the enclosing boxes returned by region2EnclosingBox:
    %               This is in the format: [x_corner, y_corner, x_width, y_width] 
    %               The function will use only the supplied ROI (sub region of the 
    %               while image) then attempt to grow the image if needed to 
    %               capture the whole brain. 
    % borderPixSize - number of pixels from border to user for background calc. 5 by default
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
    params.addParameter('borderPix',5, @(x) isnumeric(x) ) %TODO -- DOES NOTHING RIGHT NO


    params.parse(varargin{:})
    pixelSize = params.Results.pixelSize;
    tileSize = params.Results.tileSize;
    doPlot = params.Results.doPlot;
    tThresh = params.Results.tThresh;
    ROIrestrict = params.Results.ROIrestrict;
    borderPix = params.Results.borderPix;


    if isempty(ROIrestrict)
        ROIrestrict=[0,0,size(im)];
    end

    if ~isnumeric(im)
        fprintf('%s - First input argument must be an image\n',mfilename)
        return
    end

    %TODO: make it possible to feed boundingBoxesFromLastSection.image2boundingBoxes ROIs from last image


    % Optionally set data points outside of the restricted ROI to zero
    if isempty(ROIrestrict)
        stats = boundingBoxesFromLastSection.image2boundingBoxes(im,pixelSize;
    else
        imOrig = im; % Keep a backup

        % TODO - we will get rid of these lines as they go into image2boundingBoxes 
        tROI = boundingBoxesFromLastSection.validateROIrestrict(ROIrestrict,imOrig);
        im = imOrig(tROI(2):tROI(2)+tROI(4),tROI(1):tROI(1)+tROI(3));

        stats = boundingBoxesFromLastSection.image2boundingBoxes(im,pixelSize);
        clippedEdges = boundingBoxesFromLastSection.findROIEdgeClipping(im,stats);
        tileSizeInPixels = round(tileSize/pixelSize);

        % TODO: the following should be optional and part of a separate function. 
        % At this point we should have in our ROI structure the tile-based 
        % bounding boxes of the current. 

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

            tROI = boundingBoxesFromLastSection.validateROIrestrict(tROI,imOrig);
            im = imOrig(tROI(2):tROI(2)+tROI(4),tROI(1):tROI(1)+tROI(3));

            %cla,imagesc(im),drawnow
            stats = boundingBoxesFromLastSection.getBrainInImage(im,pixelSize,tThresh);
            clippedEdges = boundingBoxesFromLastSection.findROIEdgeClipping(im,stats);

            % Choose some arbitrary largish number and break if we still haven't expanded to the full field by this point
            if n>20
                msg = 'HARD-BREAK FROM FOV EXPANSION LOOP ';
                fprintf('%s\n',msg)
                stats.notes=[stats.notes,msg];
                break
            end

            %HACK to avoid looping in cases where the brain is up against the edge of the FOV
            if (size(imOrig,1)-tROI(4)-tROI(2))<=1 && any(clippedEdges=='S')
                %fprintf('Removing south ROI clip\n')
                %clippedEdges
                clippedEdges(clippedEdges=='S')=[];
                %clippedEdges
            end

        end

        % Log the current FOV ROI and and ensure that all ROI boxes we have drawn in the 
        % units of the original image. 
        stats.ROIrestrict=tROI;
    end


    %Return coordinates in full image space
    for ii=1:length(stats.BoundingBox)
        stats.BoundingBox{ii}(1:2) = stats.BoundingBox{ii}(1:2) + stats.ROIrestrict(1:2);
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

