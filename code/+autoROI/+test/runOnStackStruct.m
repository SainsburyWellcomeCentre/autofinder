function varargout=runOnStackStruct(pStack,noPlot,settings)
    % Run the ROI-finding algorithm on a stack processed by genGroundTruthBorders
    %
    % function autoROI.test.runOnStackStruct(pStack,noPlot,settings)
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
    % settings - if empty or missing we get from the file
    %
    % Outputs
    % stats structure
    %
    %
    %
    % Rob Campbell - 2020 SWC




    if nargin<2 || isempty(noPlot)
        % Show result progress images as we go? (slower)
        noPlot=false;
    end

    if nargin<3 || isempty(settings)
        settings = autoROI.readSettings;
    end


    pauseBetweenSections=false;

    % Ensure we start at section 1
    pStack.sectionNumber = 1;

    % Step one: process the initial image (first section) and find the bounding boxes
    % for tissue within it. This is the only point where we don't use the ROIs from the
    % previous section to constrain ROI choice on then next section. Hence we are not
    % in the main for loop yet.


    % These are in the input arguments for autoROI
    boundingBoxArgIn = {'doPlot', ~noPlot, ...
                    'settings', settings};



    fprintf('\n ** GETTING A THRESHOLD\n')
    fprintf('%s is running auto-thresh\n', mfilename)
    [tThreshSD,at_stats]=autoROI.autothresh.run(pStack, false, settings);
    fprintf('\nTHRESHOLD OBTAINED!\n')
    fprintf('%s\n\n',repmat('-',1,100))


    % In the first section the user should have acquired a preview that captures the whole sample
    % and has a generous border area. We therefore extract the ROIs from the whole of the first section.
    fprintf('\nDoing section %d/%d\n', 1, size(pStack.imStack,3))
    fprintf('Finding bounding box in first section\n')
    stats = autoROI(pStack, boundingBoxArgIn{:},'tThreshSD',tThreshSD);
    stats.roiStats.tThreshSD_recalc=false; %Flag to signal if we had to re-calc the threshold due to increase in laser power
    drawnow

    if pauseBetweenSections
        set(gcf,'Name',sprintf('%d/%d',1,size(pStack.imStack,3)))
        fprintf(' -> Press return\n')
        pause
    end

   
    rollingThreshold=settings.stackStr.rollingThreshold; %If true we base the threshold on the last few slices

    % Enter main for loop in which we process each section one at a time using the ROIs from the previous section
    for ii=2:size(pStack.imStack,3)
        fprintf('\nDoing section %d/%d\n', ii, size(pStack.imStack,3))
        pStack.sectionNumber=ii;

        % Use a rolling threshold based on the last nImages to drive sample/background
        % segmentation in the next image. If set to zero it uses the preceeding section.
        nImages=5;
        if rollingThreshold==false
            % Do not update the threshold at all
            thresh = stats.roiStats(1).medianBackground + stats.roiStats(1).stdBackground*tThreshSD;
        elseif nImages==0
            % Use the threshold from the last section
            thresh = stats.roiStats(ii-1).medianBackground + stats.roiStats(ii-1).stdBackground*tThreshSD;
        elseif ii<=nImages
            % Attempt to take the median value from the last nImages: take as many as possible 
            % until we have nImages worth of sections 
            thresh = median( [stats.roiStats.medianBackground] + [stats.roiStats.stdBackground]*tThreshSD);
        else
            % Take the median value from the last nImages 
            thresh = median( [stats.roiStats(end-nImages+1:end).medianBackground] + [stats.roiStats(end-nImages+1:end).stdBackground]*tThreshSD);
        end


        % autoROI is fed the ROI structure from the **previous section**
        % It runs the sample-detection code within these ROIs only and returns the results.
        tmp = autoROI(pStack, ...
            boundingBoxArgIn{:}, ...
            'tThreshSD',tThreshSD, ...
            'tThresh',thresh,...
            'lastSectionStats',stats);

        % A large and sudden decrease in the background pixels (or haiving none at all)
        % indicates that something like a change in laser power or wavelength has happened.
        % If this happens we need to re-run the finder. For now we place the code for this here
        % but in future it should be in autoROI -- TODO!!
        if ~isempty(tmp)
            FG_ratio_this_section = tmp.roiStats(end).foregroundSqMM/tmp.roiStats(end).backgroundSqMM;
            FG_ratio_previous_section = stats.roiStats(end).foregroundSqMM/stats.roiStats(end).backgroundSqMM;

            % Responds to laser being turned up. In general to higher SNR. 
            if (FG_ratio_this_section / FG_ratio_previous_section)>10
                fprintf('\nTRIGGERING RE-CALC OF tThreshSD due to high F/B ratio.\n')

                [tThreshSD,~,thresh]=autoROI.autothresh.run(pStack,[],[],tmp);
                tmp = autoROI(pStack, boundingBoxArgIn{:}, ...
                    'tThreshSD',tThreshSD, ...
                    'tThresh',thresh,...
                    'lastSectionStats',stats(ii-1));
                tmp.roiStats(end).tThreshSD_recalc=true;
            else
                tmp.roiStats(end).tThreshSD_recalc=false;
            end
        end

        if ~isempty(tmp)
            stats=tmp;
            if ~noPlot
                set(gcf,'Name',sprintf('%d/%d',ii,size(pStack.imStack,3)))
                drawnow
            end
            if pauseBetweenSections
                fprintf(' -> Press return\n')
                pause
            end
        else
            break
        end

    end



    % Log aspects of the run in the output structure
    stats.rollingThreshold=rollingThreshold;
    stats.runOnStackStructArgs = boundingBoxArgIn;
    stats.settings = settings;
    stats.nSamples = pStack.nSamples;
    stats.numUnprocessedSections = size(pStack.imStack,3)-length(stats);

    % Add a text report to the first element
    stats.report = autoROI.test.evaluateBoundingBoxes(stats,pStack);


    stats.autothreshStats = at_stats;
    stats.autothresh=true;

    % Tidy
    if noPlot, fprintf('\n'), end

    % Reset the figure name
    set(gcf,'Name','')


    % Return optional outputs
    if nargout>0
        varargout{1}=stats;
    end
