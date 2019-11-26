function varargout=runOnStackStruct(pStack,noPlot)
    % Run the brain-finding algorithm on a stack processed by genGrounTruthBorders
    % 
    % Purpose
    % Simulate the behavior of an imaging system seeking to image only
    % the tissue without benefit of a low res preview scan of the area.
    % This function will be used for tweaking algorithms, benchmarking,
    % and testing. It must simulate the steps the actual microscope will
    % take and so can't "cheat" and must only use "past" data to derive
    % future behavior.
    %
    % This function just loops through the sample-detection code. It
    % doesn't implement extra steps for finding the sample. 




    if nargin<2 || isempty(noPlot)
        noPlot=false;
    end




    % Step one: process the initial image (first section) and find the bounding boxes
    % for tissue within it. This is the only point where we don't use the ROIs from the
    % previous section to constrain ROI choice on then next section. Hence we are not
    % in the main for loop yet. 
    stats = boundingBoxesFromLastSection(pStack.imStack(:,:,1), ...
            'pixelSize', pStack.voxelSizeInMicrons, ...
            'tileSize', pStack.tileSizeInMicrons, ...
            'doPlot', ~noPlot)


    % Pre-allocate various variables
    L={};
    minBoundingBoxCoords=cell(1,size(im,3));
    tileBoxCoords=cell(1,size(im,3));
    tB=[];


    % Enter main for loop in which we process each section one at a time.
    for ii=2:size(pStack.imStack,3)

        % Use a rolling threshold based on the last nImages to drive brain/background
        % segmentation in the next image. 
        nImages=5;
        if ii<=nImages
            thresh = median( [stats.medianBackground] + [stats.stdBackground]*4);
        else
            thresh = median( [stats(end-nImages+1:end).medianBackground] + [stats(end-nImages+1:end).stdBackground]*4);
        end


        % boundingBoxesFromLastSection is fed the ROI structure from the previous section. 
        % It runs the sample-detection code within these ROIs only and returns the results.
        [stats(ii),H] = boundingBoxesFromLastSection(pStack,imStack(:,:,ii), ...
            'pixelSize', pStack.voxelSizeInMicrons,...
            'tileSize',pStack.tileSizeInMicrons, ...
            'tThresh',thresh,...
            'doPlot',~noPlot, ...
            'ROIrestrict',stats(ii-1)) 



        lastBoundBoxes = stats(ii-1).boundingBoxes;

        if noPlot
            if mod(ii,5)==0, fprintf('.'), end
        else
            hold(H.hAx_brainBorder,'on')
        end


        for kk = 1:length(lastBoundBoxes)
            tL = lastBoundBoxes{kk};
            xEnd = tL(3)+tL(1);
            xP = [tL(1),xEnd];
            yEnd = tL(4)+tL(2);
            yP = [tL(2),yEnd];

            x=[xP(1), xP(2), xP(2), xP(1), xP(1)];
            y=[yP(1), yP(1), yP(2), yP(2), yP(1)];
            minBoundingBoxCoords{ii}(kk) = {[y',x']}; %For volView

            %Plot in green the border of the previous section before extending 
            %to cope with tiling
            if ~noPlot
                plot(x, y, ':g', 'LineWidth',3, 'Parent', H.hAx_brainBorder);
            end

            %TODO: we need to merge bounding boxes of final boxes based on tiles not the minimum boxes. 



            % Overlay the box corresponding to what we would image if we have tiles.
            % This should be larger than the preceeding box in most cases
            %TODO: THIS FOLLOWING WILL GO INTO boundingBoxesFromLastSection
            tileBoundBox = boundingBoxesFromLastSection.region2BoundingBox(stats(ii-1).boundaries(kk),micsPix,tileSizeInMicrons);
            tB = tileBoundBox{1};
            x=[tB(1), tB(1)+tB(3), tB(1)+tB(3), tB(1), tB(1)];
            y=[tB(2), tB(2), tB(2)+tB(4), tB(2)+tB(4), tB(2)];
            tileBoxCoords{ii}(kk)={[y',x']}; %For volView

            % Plot this
            if ~noPlot
                plot(x, y, '--g', 'LineWidth',5, 'Parent', H.hAx_brainBorder);
            end


            % TODO: 
            % Assume that we imaged this area and then check if there is tissue extending
            % up to the border. If so, we add tiles to areas where this is happening. 
            % This means we will add quite small increases. 

            % TODO: generate warning if this will still miss brain
        end

        if ~noPlot
            hold(H.hAx_brainBorder,'off')

            set(H.hFig,'name',sprintf('%d/%d', ii, size(im,3)))
            drawnow
        end

    end

    if noPlot, fprintf('\n'), end

    if nargout>0
        %For volView
        boundariesForPlotting.border{1} = {stats(:).boundaries};
        boundariesForPlotting.minBoundingBoxCoords{1} = minBoundingBoxCoords;
        boundariesForPlotting.tileBoxCoords{1} = tileBoxCoords;
        varargout{1}=boundariesForPlotting;
    end
    if nargout>1
        varargout{2} = stats;
    end
