function [tThreshSD,stats] = run(pStack, runSeries)
    % Search a range of thresholds and find the best one. 
    %
    % function [tThreshSD,stats] = boundingBoxFromLastSection.autoThresh.run(pStack)
    %
    % Purpose
    % Choose threshold based on the number of ROIs it produces. 
    %
    %


    % For most samples, if the threshold is too low this usually causes the whole FOV to imaged.
    % With the SNR of most samples, as a high threshold is never a problem. With low SNR, the
    % sample vanishes at high threshold values but might go through a peak with many ROIs. At low
    % threshold a low SNR sample is fine. 

    if nargin<2
        runSeries=true;
    end


    settings = boundingBoxesFromLastSection.readSettings;
    defaultThresh = settings.main.defaultThreshSD;

    tileSize = pStack.tileSizeInMicrons;
    voxSize = pStack.voxelSizeInMicrons;
    argIn = {'tileSize',tileSize,'pixelSize',voxSize,'doPlot',false,'skipMergeNROIThresh',10};


    stats=runThreshCheck(0);
    maxThresh=40;

    % Produce a curve
    if runSeries
        t=tic;
        x=0.015;
        while x<maxThresh
            fprintf('Running for tThreshSD * %0.2f\n',x);
            stats(end+1)=runThreshCheck(x);
            x=x*1.1;
        end
        boundingBoxesFromLastSection.autothresh.plot(stats)
        tThreshSD = nan;
        fprintf('Finished!\n')
        toc(t)
        return
    end



    % Otherwise we try to find a threshold
    if stats.propImagedAreaUnderBoundingBox>0.95
        disp('HIGH SNR')
        [tThreshSD,stats] = highSNRalg(stats);
    else
        fprintf('Looks like a low SNR sample')
        [tThreshSD,stats] = lowSNRalg(stats);
    end

    boundingBoxesFromLastSection(pStack.imStack(:,:,1),argIn{:}, ...
        'tThreshSD',tThreshSD,'doPlot',true);

    % Nested functions follow
    function stats = runThreshCheck(tThreshSD)
        OUT = boundingBoxesFromLastSection(pStack.imStack(:,:,1),argIn{:},'tThreshSD',tThreshSD);

        if isempty(OUT)
            stats.nRois=0;
            stats.boundingBoxPixels=0;
            stats.meanBoundingBoxPixels=0;
            stats.boundingBoxSqMM=0;
            stats.propImagedAreaUnderBoundingBox=0;
            stats.notes='';
        else
            stats.nRois = length(OUT.BoundingBoxes);
            stats.boundingBoxPixels=OUT.totalBoundingBoxPixels;
            stats.meanBoundingBoxPixels=mean(OUT.BoundingBoxPixels);
            stats.boundingBoxSqMM = sqrt(OUT.totalBoundingBoxPixels * voxSize * 1E-3);
            stats.propImagedAreaUnderBoundingBox=OUT.propImagedAreaCoveredByBoundingBox;
            stats.notes='';
        end
        stats.tThreshSD=tThreshSD;

    end % runThreshCheck

    function [tThreshSD,stats] = lowSNRalg(stats)
        initial_nROIs = stats.nRois;
        x=0.015;

        fprintf('\n\n\n ** SEARCHING LOW SNR with %d INITIAL ROIS\n', initial_nROIs)

        finalX=nan;
        while x(end)<maxThresh

            fprintf(' ---> thresh = %0.3f\n', x(end))

            stats(end+1)=runThreshCheck(x(end));

            if stats(end).nRois > initial_nROIs
                if length(x)>1
                    finalX = x(end-1)*0.5;
                    fprintf('BREAKING\n')
                    break
                else
                    % LIKELY A BAD SITUATION
                    finalX=0;
                end
            end

            x(end+1)=x(end)*1.8;
        end

        if ~isnan(finalX)
            tThreshSD = finalX;
        else
            tThreshSD = defaultThresh;
        end

        fprintf(' ---> Low SNR Choosing a final thresh of %0.3f\n', finalX);

    end %lowSNRalg


    function [tThreshSD,stats] = highSNRalg(stats)
        % Start with a high threshold and decrease
        % A sharp increase in ROI number means that we're too low
        % Filling the whole FOV means we're too low

        % The following just looks for when the FOV fills. 
        % The other point is that often number of ROIs stays constant for 
        % some time, as does the imaged area. Maybe this info can be used 
        % instead?

        x = maxThresh;
        tThreshSD=nan;
        while x>0.01
            fprintf(' ---> thresh = %0.3f\n', x(end))
            stats(end+1)=runThreshCheck(x(end));

            % If we reach over 95% coverage then back up a notch and assign the threshold as this value
            if stats(end).propImagedAreaUnderBoundingBox>0.95
                tThreshSD = x(end-1)*1.75;
                break
            end
            x(end+1)= x(end) * 0.9;
        end

        %Now sort because 0 is at the start
        tT=[stats.tThreshSD];
        [~,ind] = sort(tT);
        stats = stats(ind);

        % Before finally bailing out, see if we can improve the threshold. If many 
        % points have the same number of ROIs, choose the middle of this range instead. 
        nR = [stats.nRois];
        [theMode,numOccurances] = mode(nR);


        % If there are more than three of them and all are in a row, then we use the mean of these as the threshold
        fprintf('mode nROIs: %d and occurs %d times\n', theMode, numOccurances)
        
        if numOccurances>3 && all(diff(find(nR==theMode))==1)
            fprintf(' --->  High SNR: Choosing based on mode.\n')
            tThreshSD = mean(tT(find(nR==theMode)));
            stats(1).notes=sprintf('High SNR: mean of values at nROI=%d', theMode);
        else
            fprintf(' ---> High SNR: Choosing based on exit point value where ROI gets large.\n')
            stats(1).notes='High SNR: Value near full size ROI';
        end

        if isnan(tThreshSD)
            fprintf('Bounding box always stays small. Sticking with default threshold of %0.2f\n', defaultThresh)
            tThreshSD=defaultThresh;
        end
    end %highSNRalg

end % main function
