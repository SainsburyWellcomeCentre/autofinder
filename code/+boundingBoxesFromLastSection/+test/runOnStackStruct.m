function varargout=runOnStackStruct(pStack,noPlot,doAutoThreshold)
    % Run the brain-finding algorithm on a stack processed by genGroundTruthBorders
    %
    % function boundingBoxesFromLastSection.test.runOnStackStruct(pStack,noPlot,doAutoThreshold)
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
    %
    % Inputs
    % pStack - preview stack structure
    % noPlot - false by default
    % doAutoThreshold - false by default. If true, figure out the tThreshSD
    %                   threshold automatically for the first section.
    %
    % Outputs
    % stats structure
    %
    % Extras:
    % To over-ride the defaul threshold:
    % pStack.tThreshSD=3;
    % boundingBoxesFromLastSection.test.runOnStackStruct(pStack)
    %
    %
    % Rob Campbell - 2020 SWC




    if nargin<2 || isempty(noPlot)
        % Show result progress images as we go? (slower)
        noPlot=false;
    end


    if nargin<3 || isempty(noPlot)
        % Auto find the threshold?
        doAutoThreshold = true;
    end




    settings = boundingBoxesFromLastSection.readSettings;
    pauseBetweenSections=false;

    % Step one: process the initial image (first section) and find the bounding boxes
    % for tissue within it. This is the only point where we don't use the ROIs from the
    % previous section to constrain ROI choice on then next section. Hence we are not
    % in the main for loop yet.


    argIn = {'pixelSize', pStack.voxelSizeInMicrons, ...
             'tileSize', pStack.tileSizeInMicrons, ...
             'doPlot', ~noPlot};

    if isfield(pStack,'tThreshSD')
        % Start with a threshold hard-coded into the pStack file
        tThreshSD = pStack.tThreshSD;
        argIn = [argIn,{'tThreshSD',pStack.tThreshSD}];
        fprintf('%s is starting with a custom SD threshold of %0.1f\n', ...
            mfilename, tThreshSD)
        if doAutoThreshold
            fprintf('**** YOU ASKED FOR AUTO-THRESH BUT pStack has a tThreshSD field. USING THAT INSTEAD!\n\n')
            doAutoThreshold=false;
            pause(0.75)
        end

    elseif doAutoThreshold
        % Determine the threshold automatically
        fprintf('%s is running auto-thresh\n', mfilename)
        [tThreshSD,at_stats]=boundingBoxesFromLastSection.autothresh.run(pStack,false);
        argIn = [argIn,{'tThreshSD',tThreshSD}];

    else
        % Use the default value in the settings file
        tThreshSD=settings.main.defaultThreshSD;
        fprintf('%s is starting with a default SD threshold of %0.1f\n', ...
            mfilename, tThreshSD)

    end




    % In the first section the user should have acquired a preview that captures the whole sample
    % and has a generous border area. We therefore extract the ROIs from the whole of the first section.
    fprintf('\nDoing section %d/%d\n', 1, size(pStack.imStack,3))
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

    rollingThreshold=true; %If true we base the threshold on the last few slices


    % Enter main for loop in which we process each section one at a time using the ROIs from the previous section
    for ii=2:size(pStack.imStack,3)
        fprintf('\nDoing section %d/%d\n', ii, size(pStack.imStack,3))
        % Use a rolling threshold based on the last nImages to drive brain/background
        % segmentation in the next image. 
        nImages=5;
        if rollingThreshold==false
           thresh = median( [stats(1).medianBackground] + [stats(1).stdBackground]*tThreshSD);
        elseif ii<=nImages
            thresh = median( [stats.medianBackground] + [stats.stdBackground]*tThreshSD);
        else
            thresh = median( [stats(end-nImages+1:end).medianBackground] + [stats(end-nImages+1:end).stdBackground]*tThreshSD);
        end

        % boundingBoxesFromLastSection is fed the ROI structure from the **previous section**
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
    stats(1).rescaleTo = settings.stackStr.rescaleTo; % Log by how much we re-scaled in boundingBoxesFromLastSection
    stats(1).rollingThreshold=rollingThreshold;

    % Log settings to the first element of the structure
    stats(1).runOnStackStructArgs = argIn;
    stats(1).settings = settings;

    % Add a text report
    stats(1).report = boundingBoxesFromLastSection.test.evaluateBoundingBoxes(stats,pStack);

    %Add the tThreshSD setting to everything
    for ii=1:length(stats)
        stats(ii).tThreshSD=tThreshSD;
        if doAutoThreshold
            stats(ii).autothresh=true;
        else
            stats(ii).autothresh=false;
        end
    end

    % Log the auto-thresh stuff in the first element if present
    if doAutoThreshold
        stats(1).autothreshStats = at_stats;
    else
        stats(1).autothreshStats = [];
    end

    if noPlot, fprintf('\n'), end

    % Reset the figure name
    set(gcf,'Name','')

    if nargout>0
        varargout{1}=stats;
    end
