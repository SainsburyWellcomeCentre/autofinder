function varargout=runOnStackStruct(pStack,noPlot)
    % Run the brain-finding algorithm on a stack processed by genGroundTruthBorders
    %
    % function boundingBoxesFromLastSection.test.runOnStackStruct(pStack,noPlot)
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
    %
    % Inputs
    % pStack - preview stack structure
    % noPlot - flase by default
    %
    % Outputs
    % stats structure
    %
    % Extras:
    % To over-ride the defaul threshold:
    % pStack.tThreshSD=3;
    % boundingBoxesFromLastSection.test.runOnStackStruct(pStack)
    %




    if nargin<2 || isempty(noPlot)
        noPlot=false;
    end

    settings = boundingBoxesFromLastSection.readSettings;
    pauseBetweenSections=false;

    % Step one: process the initial image (first section) and find the bounding boxes
    % for tissue within it. This is the only point where we don't use the ROIs from the
    % previous section to constrain ROI choice on then next section. Hence we are not
    % in the main for loop yet.

    rescaleTo=settings.stackStr.rescaleTo;
    if rescaleTo>1
        %pStack.imStack = pStack.imStack(:,:,1:2:end);
        s=size(pStack.imStack);
        s(1:2) = round( s(1:2) / (rescaleTo/pStack.voxelSizeInMicrons) );
        pStack.imStack = imresize3(pStack.imStack, s);
        pStack.origVoxelSize = pStack.voxelSizeInMicrons;
        pStack.voxelSizeInMicrons = rescaleTo;
    end


    argIn = {'pixelSize', pStack.voxelSizeInMicrons, ...
             'tileSize', pStack.tileSizeInMicrons, ...
             'doPlot', ~noPlot};

    if isfield(pStack,'tThreshSD')
        threshSD = pStack.tThreshSD;
        argIn = [argIn,{'tThreshSD',pStack.tThreshSD}];
        fprintf('%s is starting with a custom SD threshold of %0.1f\n', ...
            mfilename, threshSD)
    else
        threshSD=settings.main.defaultThreshSD;
        fprintf('%s is starting with a default SD threshold of %0.1f\n', ...
            mfilename, threshSD)

    end

    fprintf('Finding bounding box in first section\n')
    stats = boundingBoxesFromLastSection(pStack.imStack(:,:,1), argIn{:});
    drawnow

    if pauseBetweenSections
        set(gcf,'Name',sprintf('%d/%d',1,size(pStack.imStack,3)))
        fprintf(' -> Press return\n')
        pause
    end

    % Pre-allocate various variables
    L={};
    minBoundingBoxCoords=cell(1,size(pStack.imStack,3));
    tileBoxCoords=cell(1,size(pStack.imStack,3));
    tB=[];

    rollingThreshold=false; %If true we base the threshold on the last few slices

    % Enter main for loop in which we process each section one at a time.
    for ii=2:size(pStack.imStack,3)
        fprintf('\nDoing section %d/%d\n', ii, size(pStack.imStack,3))
        % Use a rolling threshold based on the last nImages to drive brain/background
        % segmentation in the next image. 
        nImages=5;
        if rollingThreshold==false
           thresh = median( [stats(1).medianBackground] + [stats(1).stdBackground]*threshSD);
        elseif ii<=nImages
            thresh = median( [stats.medianBackground] + [stats.stdBackground]*threshSD);
        else
            thresh = median( [stats(end-nImages+1:end).medianBackground] + [stats(end-nImages+1:end).stdBackground]*threshSD);
        end

        % boundingBoxesFromLastSection is fed the ROI structure from the previous section. 
        % It runs the sample-detection code within these ROIs only and returns the results.
        [tmp,H] = boundingBoxesFromLastSection(pStack.imStack(:,:,ii), ...
            'pixelSize', pStack.voxelSizeInMicrons,...
            'tileSize',pStack.tileSizeInMicrons, ...
            'tThresh',thresh,...
            'doPlot',~noPlot, ...
            'lastSectionStats',stats(ii-1));

        if ~isempty(tmp)
            stats(ii)=tmp;
            set(gcf,'Name',sprintf('%d/%d',ii,size(pStack.imStack,3)))
            drawnow
            if pauseBetweenSections
                fprintf(' -> Press return\n')
                pause
            end
        else
            break
        end

    end

    %Log aspects of the run in the first element
    stats(1).rescaleTo = rescaleTo; % Log by how much we re-scaled. 
    stats(1).rollingThreshold=rollingThreshold;

    % If we re-scaled then we need to put the bounding box coords back into the original size
    if rescaleTo>1
        for ii=1:length(stats)
            stats(ii).BoundingBoxes = ...
                cellfun(@(x) round(x*(rescaleTo/pStack.origVoxelSize)), stats(ii).BoundingBoxes,'UniformOutput',false);

            stats(ii).globalBoundingBox = round((rescaleTo/pStack.origVoxelSize) * stats(ii).globalBoundingBox);
        end
    end

    %Add the threshSD setting to everything
    for ii=1:length(stats)
        stats(ii).threshSD=threshSD;
    end

    % Log settings to the first element of the structure
    stats(1).runOnStackStructArgs = argIn;
    stats(1).settings = settings;

    if noPlot, fprintf('\n'), end

    % Reset the figure name
    set(gcf,'Name','')

    if nargout>0
        varargout{1}=stats;
    end
