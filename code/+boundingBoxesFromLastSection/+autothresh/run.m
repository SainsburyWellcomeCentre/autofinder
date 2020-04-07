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

    % This is the image we will use to obtain the threshold
    imTMP = pStack.imStack(:,:,1);

    settings = boundingBoxesFromLastSection.readSettings;
    defaultThresh = settings.main.defaultThreshSD;

    tileSize = pStack.tileSizeInMicrons;
    voxSize = pStack.voxelSizeInMicrons;
    argIn = {'tileSize',tileSize,'pixelSize',voxSize,'doPlot',false,'skipMergeNROIThresh',10};


    stats=calcStatsFromThreshold(0);
    maxThresh=40;



    % Produce a curve
    if runSeries
        t=tic;
        x=0.015;
        while x<maxThresh
            fprintf('Running for tThreshSD * %0.2f\n',x);
            stats(end+1)=calcStatsFromThreshold(x);
            x=x*1.1;
        end
        boundingBoxesFromLastSection.autothresh.plot(stats)
        tThreshSD = nan;
        fprintf('Finished!\n')
        toc(t)
        return
    end



    % Find the threshold
    [tThreshSD,stats] = getThreshAlg(stats);


    boundingBoxesFromLastSection(imTMP, argIn{:},'tThreshSD',tThreshSD,'doPlot',true);

    % Nested functions follow
    function stats = calcStatsFromThreshold(tThreshSD)
        % Calculate a bunch of stats from a threshold
        OUT = boundingBoxesFromLastSection(imTMP, argIn{:},'tThreshSD',tThreshSD);

        if isempty(OUT)
            stats.nRois=nan;
            stats.boundingBoxPixels=nan;
            stats.meanBoundingBoxPixels=nan;
            stats.boundingBoxSqMM=nan;
            stats.propImagedAreaUnderBoundingBox=nan;
            stats.notes='';
            stats.SNR_medAboveThresh=nan;
            stats.SNR_medBelowThresh=nan;
            stats.SNR_medThreshRatio=nan;
        else
            stats.nRois = length(OUT.BoundingBoxes);
            stats.boundingBoxPixels=OUT.totalBoundingBoxPixels;
            stats.meanBoundingBoxPixels=mean(OUT.BoundingBoxPixels);
            stats.boundingBoxSqMM = OUT.totalBoundingBoxPixels * (voxSize * 1E-3)^2;
            stats.propImagedAreaUnderBoundingBox=OUT.propImagedAreaCoveredByBoundingBox;
            stats.notes='';

            % Extract values related to SNR
            aboveThresh = imTMP(imTMP>OUT.tThresh);
            belowThresh = imTMP(imTMP<OUT.tThresh);

            stats.SNR_medAboveThresh = single(median(aboveThresh));
            stats.SNR_medBelowThresh = single(median(belowThresh));
            stats.SNR_medThreshRatio = stats.SNR_medAboveThresh/stats.SNR_medBelowThresh;
        end
        stats.tThreshSD=tThreshSD;

    end % calcStatsFromThreshold



    function [tThreshSD,stats] = getThreshAlg(stats)
        % Start with a high threshold and decrease
        % A sharp increase in ROI number means that we're too low
        % Filling the whole FOV means we're too low

        % The following just looks for when the FOV fills. 
        % The other point is that often number of ROIs stays constant for 
        % some time, as does the imaged area. Maybe this info can be used 
        % instead?

        x = maxThresh;
        tThreshSD=nan;
        while x>0.75 %Very small thresholds tend to be bad news
            fprintf(' ---> thresh = %0.3f\n', x(end))
            stats(end+1)=calcStatsFromThreshold(x(end));

            % If we reach over 95% coverage then back up a notch and assign the threshold as this value
            if stats(end).propImagedAreaUnderBoundingBox>0.95
                if length(x)>1
                    tThreshSD = x(end-1)*1.75;
                else
                    fprintf('\nODD -- breaking with length(x)==1\n');
                    tThreshSD = x(end)*1.75;
                end
                break
            end
            x(end+1)= x(end) * 0.8; % Unwise if this is too fine. 0.9 is slightly too fine and can bias us to having a low threshold.
        end

        %Now sort because 0 is at the start
        tT=[stats.tThreshSD];
        [tT,ind] = sort(tT,'ascend');
        stats = stats(ind);

        % If the median SNR is low, we get rid tThresh values above 8
        % This helps with certain low SNR samples
        if nanmedian([stats.SNR_medThreshRatio])<=4
            fprintf(' ---> Median SNR is low! Clipping tThreshSD to low values. <---\n')
            ind = find([stats.tThreshSD]<=8);
            stats = stats(ind);
        end

        % Before finally bailing out, see if we can improve the threshold. If many 
        % points have the same number of ROIs, choose the middle of this range instead. 
        nR = [stats.nRois];
        [theMode,numOccurances] = mode(nR);
        fM=find(nR==theMode); %The indecies of the mode


        % If there are more than three of them and all are in a row, then we use the mean of these as the threshold
        fprintf('\n\nFinishing up.\nNumber of ROIs have mode value of %d which occurs %d times\n', theMode, numOccurances)


        if numOccurances>3 && all(diff(fM)==1)
            fprintf(' --->  Choosing based on uninterupted mode of %d.\n', theMode)
            ind = find(nR==theMode);
            tThreshSD = mean(tT(ind));
            stats(1).notes=sprintf('Mean of values at nROI=%d', theMode);

        elseif numOccurances>8 && (length(fM)/length(fM(1):fM(end)))>0.8
            fprintf(' --->  Choosing based on mode with few interruptions: n=%d missing=%d\n', ...
                length(fM), length(fM(1):fM(end))-length(fM) )

            % Remove thresholds that are very low. Clip out low values, in other words.
            tT = tT(find(nR==theMode));
            tT(tT<=0.5)=[];
            tThreshSD = mean(tT);

            stats(1).notes=sprintf('Mean of %d values at nROI=%d. %d missing.', ...
                numOccurances, theMode, length(fM(1):fM(end))-length(fM) );

        elseif ~isempty(findLowestThreshStretch(nR,4))
            ind = findLowestThreshStretch(nR,4);

            % Remove thresholds that are very low. Clip out low values, in other words.
            tT = tT(ind);
            tT(tT<=0.5)=[];
            tThreshSD = mean(tT);

            msg=sprintf('Choosing using findLowestThreshStretch with thresh of 4: tThreshSD=%0.2f\n',tThreshSD);
            fprintf(msg)
            stats(1).notes=msg;

        else
            fprintf(' ---> Choosing based on exit point value where ROI got large.\n')
            stats(1).notes='Value near full size ROI';

        end

        if isnan(tThreshSD)
            fprintf('Bounding box always stays small. Sticking with default threshold of %0.2f\n', defaultThresh)
            tThreshSD=defaultThresh;
        end
    end %getThreshAlg

end % main function


function ind = findLowestThreshStretch(nR,thresh)
    % This function finds a a stretch of values in a vector which are the same. 
    %
    % nR - A vector defining the number of ROIs for each of a range of threshold 
    %     values (which we don't need to know here)
    % thresh - Defines the length of shortest stretch of identical values in nR.
    %
    % e.g. 
    % nR = [1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    % thresh = 4
    %
    % It will choose the grouping of 2s at the left side of the vector. This is 
    % so as bias ourselves to lower thresholds. 


    verbose=false;

    ind=[];
    if length(nR) < thresh
        return
    end
    modeR = mode(nR);

    F=find(nR==modeR);

    dF=diff(F);

    passNum=1;

    if verbose
        fprintf('Running findLowestThreshStretch with a thresh of %d\n\n', thresh)
    end
    while length(dF)>thresh

        % Turn into a word and split it with strsplit
        tStr = num2str( dF ~=1 );
        tStr = strrep(tStr,' ','');
        if verbose
            fprintf('findLowestThreshStretch pass number # %d\n',passNum)
            fprintf('Word before splitting: %s\n',tStr)
        end

        splt = strsplit(tStr,'1');


        if length(splt{1})+1 < thresh
            % If the the first sequence was too short we chop it out and go back
            f=find(dF ~= 1);

            %Delete this short stretch
            if verbose
                fprintf('Chopping first sequene of length %d\n\n',length(splt{1})+1)
            end
            dF(1:f(1)) = [];
            F(1:f(1)) = [];
            passNum = passNum + 1;
            continue

        elseif length(splt{1})+1 >= thresh
            % Otherwise this was the correct length
            f=find(dF ~= 1);
            if isempty(f)
                ind=F(1:end);
            else
                ind=F(1:f(1));
            end
                
            return
        end
        if verbose
            fprintf('\n\n')
        end
        passNum = passNum + 1;
    end %while

end


