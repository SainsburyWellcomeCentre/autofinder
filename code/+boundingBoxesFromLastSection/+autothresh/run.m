function [tThresh,stats] = run(pStack, runSeries)
    % Search a range of thresholds and find the best one. 
    %
    % function [tThresh,stats] = boundingBoxFromLastSection.autoThresh.run(pStack)
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
    maxThresh=30;

    % Produce a curve
    if runSeries
        x=0.015;
        while x<maxThresh
            fprintf('Running for tThresh * %0.2f\n',x);
            stats(end+1)=runThreshCheck(x);
            x=x*1.6;
        end
        boundingBoxesFromLastSection.autothresh.plot(stats)
        tThresh = nan;
        return
    end



    % Otherwise we try to find a threshold
    if stats.propImagedAreaUnderBoundingBox>0.95
        disp('HIGH SNR')
        [tThresh,stats] = highSNRalg(stats);
    else
        fprintf('Looks like a low SNR sample')
        [tThresh,stats] = lowSNRalg(stats);
    end

    boundingBoxesFromLastSection(pStack.imStack(:,:,1),argIn{:}, ...
        'tThreshSD',tThresh,'doPlot',true);

    % Nested functions follow
    function stats = runThreshCheck(tThreshSD)
        OUT = boundingBoxesFromLastSection(pStack.imStack(:,:,1),argIn{:},'tThreshSD',tThreshSD);

        if isempty(OUT)
            stats.nRois=0;
            stats.boundingBoxPixels=0;
            stats.meanBoundingBoxPixels=0;
            stats.boundingBoxSqMM=0;
            stats.propImagedAreaUnderBoundingBox=0;
        else
            stats.nRois = length(OUT.BoundingBoxes);
            stats.boundingBoxPixels=OUT.totalBoundingBoxPixels;
            stats.meanBoundingBoxPixels=mean(OUT.BoundingBoxPixels);
            stats.boundingBoxSqMM = sqrt(OUT.totalBoundingBoxPixels * voxSize * 1E-3);
            stats.propImagedAreaUnderBoundingBox=OUT.propImagedAreaCoveredByBoundingBox;
        end
        stats.tThreshSD=tThreshSD;

    end % runThreshCheck

    function [tThresh,stats] = lowSNRalg(stats)
        initial_nROIs = stats.nRois;
        x=0.015;

        fprintf('\n\n\n ** SEARCHING LOW SNR with %d INITIAL ROIS\n', initial_nROIs)

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

        tThresh = finalX;
        fprintf(' ---> Choosing a final thresh of %0.3f\n', ...
            finalX, tThresh);

    end %lowSNRalg


    function [tThresh,stats] = highSNRalg(stats)
        % Start with a high threshold and decrease
        % A sharp increase in ROI number means that we're too low
        % Filling the whole FOV means we're too low

        % The following just looks for when the FOV fills. 
        % The other point is that often number of ROIs stays constant for 
        % some time, as does the imaged area. Maybe this info can be used 
        % instead?

        x = maxThresh;
        tThresh=nan;
        while x>0.01
            x(end+1)= x(end) * 0.75;
            fprintf(' ---> thresh = %0.3f\n', x(end))
            stats(end+1)=runThreshCheck(x(end));

            if stats(end).propImagedAreaUnderBoundingBox>0.95
                tThresh = x(end-1)*1.75;
                break
            end

        end


        if isnan(tThresh)
            fprintf('Bounding box always stays small. Sticking with default threshold of %0.2f\n', defaultThresh)
            tThresh=defaultThresh
        end
    end %highSNRalg

end % main function
