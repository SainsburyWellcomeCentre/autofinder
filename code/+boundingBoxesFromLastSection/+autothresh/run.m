function [tThreshSD,stats] = run(pStack, runSeries, settings)
    % Search a range of thresholds and find the best one. 
    %
    % function [tThreshSD,stats] = boundingBoxFromLastSection.autoThresh.run(pStack, runSeries)
    %
    % Purpose
    % Choose threshold based on the number of ROIs it produces. 
    %
    % Inputs
    % pStack - the pStack structure
    % runSeries - Just runs a series of thresholds and plots the result. False by default.
    %             This option runs a finer set of thresholds than the actual thresh finder.
    % settings - optional. The settings structure. If empty or missing, we read from the file itself.

    % For most samples, if the threshold is too low this usually causes the whole FOV to imaged.
    % With the SNR of most samples, as a high threshold is never a problem. With low SNR, the
    % sample vanishes at high threshold values but might go through a peak with many ROIs. At low
    % threshold a low SNR sample is fine. 

    if nargin<2 || isempty(runSeries)
        runSeries=false;
    end

    if nargin<3 || isempty(settings)
        settings = boundingBoxesFromLastSection.readSettings;
    end


    % This is the image we will use to obtain the threshold
    imTMP = pStack.imStack(:,:,1);



    tileSize = pStack.tileSizeInMicrons;
    voxSize = pStack.voxelSizeInMicrons;

    argIn = {'tileSize',tileSize,'pixelSize',voxSize,'doPlot',false,...
    'skipMergeNROIThresh',settings.autoThresh.skipMergeNROIThresh,...
    'doBinaryExpansion',settings.autoThresh.doBinaryExpansion};



    minThresh=settings.autoThresh.minThreshold;
    maxThresh=settings.autoThresh.maxThreshold;
    stats=calcStatsFromThreshold(minThresh);




    % Produce a curve
    if runSeries
        t=tic;
        x=minThresh*1.1;
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
    [tThreshSD,stats] = getThreshAlg(stats,maxThresh);


    boundingBoxesFromLastSection(imTMP, argIn{:},'tThreshSD',tThreshSD,'doPlot',true);

    % Nested functions follow
    function stats = calcStatsFromThreshold(tThreshSD)
        % Calculate a bunch of stats from a threshold
        [OUT,bwStats] = boundingBoxesFromLastSection(imTMP, argIn{:},'tThreshSD',tThreshSD);

        if isempty(OUT)
            stats.nRois=nan;
            stats.totalBoundingBoxSqMM=nan;
            stats.meanBoundingBoxSqMM=nan;
            stats.propImagedAreaUnderBoundingBox=nan;
            stats.notes='';
            stats.SNR_medAboveThresh=nan;
            stats.SNR_medBelowThresh=nan;
            stats.SNR_medThreshRatio=nan;
            stats.bwStats = struct;
        else
            stats.nRois = length(OUT.BoundingBoxes);
            stats.totalBoundingBoxSqMM = OUT.totalBoundingBoxSqMM;
            stats.meanBoundingBoxSqMM = OUT.meanBoundingBoxSqMM;
            stats.propImagedAreaUnderBoundingBox=OUT.propImagedAreaCoveredByBoundingBox;
            stats.notes='';

            % Extract values related to SNR
            aboveThresh = imTMP(imTMP>OUT.tThresh);
            belowThresh = imTMP(imTMP<OUT.tThresh);

            stats.SNR_medAboveThresh = single(median(aboveThresh));
            stats.SNR_medBelowThresh = single(median(belowThresh));
            stats.SNR_medThreshRatio = stats.SNR_medAboveThresh/stats.SNR_medBelowThresh;

            stats.bwStats = bwStats;
        end
        stats.tThreshSD=tThreshSD;

    end % calcStatsFromThreshold



    function [tThreshSD,stats] = getThreshAlg(stats,maxThresh)
        % Start with a high threshold and decrease
        % A sharp increase in ROI number means that we're too low
        % Filling the whole FOV means we're too low

        % The following just looks for when the FOV fills. 
        % The other point is that often number of ROIs stays constant for 
        % some time, as does the imaged area. Maybe this info can be used 
        % instead?

        x = maxThresh;
        tThreshSD=nan;
        decreaseBy = settings.autoThresh.decreaseThresholdBy;

        fprintf('\n\ngetThreshAlg working over tThreshSD range %0.1f to %0.1f and decreasing by %0.2f on each pass through loop\n', ...
            minThresh,maxThresh, decreaseBy)
        while x>minThresh %Very small thresholds tend to be bad news
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
            x(end+1)= x(end) * decreaseBy; % Unwise if this is too fine. 0.9 is slightly too fine and can bias us to having a low threshold.
        end

        %Now sort just to be sure
        [tThreshSD_vec,ind] = sort([stats.tThreshSD],'ascend');
        stats = stats(ind);



        [findsAgar,stats] = isThreshTreatingAgarAsSample(stats,tileSize,voxSize);
        if any(findsAgar)
            tF = find(findsAgar);
            fprintf(' ** DELETED FIRST %d entries up to tThreshSD = %0.2f because we see tiling artifacts there. **\n', ...
             tF(end), stats(tF(end)).tThreshSD )

            stats(1:tF(end))=[];

            % TODO: this sort of thing needs to be more formally logged. To a file or something like that. 
            if length(stats)==0
                fprintf(' ** VERY BAD: after removing thresholds due to tiling artifacts there are no more threshold values.\n')
            end

            % If we have very threshold values left, we a slightly larger range.
            if length(stats)<5 && settings.autoThresh.allowMaxExtensionIfFewThreshLeft
                newMaxThresh = maxThresh+5;
                if maxThresh < settings.autoThresh.maxThreshold*4 % to avoid infinite recursion
                    fprintf('TOO FEW THRESHOLDS: DOING ANOTHER RUN UP TO NEW MAXTHRESH OF %d\n',newMaxThresh)
                    stats=calcStatsFromThreshold(minThresh);
                    [~,stats]=getThreshAlg(stats,newMaxThresh);
                end
            end
            clippedDueToAgar=true;
        else
            clippedDueToAgar=false;
        end

        % If the median SNR is low, we get rid tThresh values above 8
        % This helps with certain low SNR samples

        medSNR = nanmedian([stats.SNR_medThreshRatio]);
        clipVal=8;


        if medSNR<=4
          ind = find([stats.tThreshSD]<=clipVal);
          if ~isempty(ind)
              fprintf(' ---> Median SNR is low: %0.1f -- Clipping tThreshSD to values below %d. <---\n', ...
                    medSNR, clipVal)
               stats = stats(ind);
           else
              fprintf(' ---> Median SNR is low: %0.1f -- but all thresholds are above the clipping value of %d. NOT CLIPPING. <---\n', ...
                    medSNR, clipVal)
           end

            % TODO: this sort of thing needs to be more formally logged. To a file or something like that. 
            if length(stats)==0
                fprintf(' ** VERY BAD: after clipping due to low SNR are no more threshold values.\n')
            end
        end


        % Before finally bailing out, see if we can improve the threshold. If many 
        % points have the same number of ROIs, choose the middle of this range instead. 
        nR = [stats.nRois];
        [theMode,numOccurances] = mode(nR);
        fM=find(nR==theMode); %The indecies of the mode


        % If there are more than three of them and all are in a row, then we use the mean of these as the threshold
        fprintf('\n\nFinishing up.\nNumber of ROIs have mode value of %d which occurs %d times\n', theMode, numOccurances)

        tThreshSD_vec = [stats.tThreshSD];
        if numOccurances>3 && all(diff(fM)==1)
            fprintf(' --->  Choosing based on uninterupted mode of %d.\n', theMode)
            ind = find(nR==theMode);
            tThreshSD = mean(tThreshSD_vec(ind));
            stats(1).notes=sprintf('Mean of values at nROI=%d', theMode);

        elseif numOccurances>8 && (length(fM)/length(fM(1):fM(end)))>0.8
            fprintf(' --->  Choosing based on mode with few interruptions: n=%d missing=%d\n', ...
                length(fM), length(fM(1):fM(end))-length(fM) )

            % Remove thresholds that are very low. Clip out low values, in other words.
            tThreshSD_vec = tThreshSD_vec(find(nR==theMode));
            tThreshSD_vec(tThreshSD_vec<=0.5)=[];
            tThreshSD = mean(tThreshSD_vec);

            stats(1).notes=sprintf('Mean of %d values at nROI=%d. %d missing.', ...
                numOccurances, theMode, length(fM(1):fM(end))-length(fM) );

        elseif ~isempty(findLowestThreshStretch(nR,4))
            ind = findLowestThreshStretch(nR,4);

            % Remove thresholds that are very low. Clip out low values, in other words.
            tThreshSD_vec = tThreshSD_vec(ind);
            tThreshSD_vec(tThreshSD_vec<=0.5)=[];
            tThreshSD = mean(tThreshSD_vec);

            msg=sprintf('Choosing using findLowestThreshStretch with thresh of 4: tThreshSD=%0.2f\n',tThreshSD);
            fprintf(msg)
            stats(1).notes=msg;

        else
            fprintf(' ---> Choosing based on exit point value where ROI got large. (THIS IS PROBABLY NOT AN IDEAL SITUATION)\n')
            stats(1).notes='Value near full size ROI';

        end

        if isnan(tThreshSD)
            fprintf('Bounding box always stays small. Setting based on SNR\n')
            vSNR = ([stats.SNR_medThreshRatio]);
            med_vSNR = median(vSNR);
            if med_vSNR<minThresh
                fprintf('Capping at min\n')
                tThreshSD=minThresh;
            elseif med_vSNR>maxThresh
                fprintf('Capping at max\n')
                tThreshSD=maxThresh;
            else
                fprintf('Setting to median\n')
                tThreshSD=med_vSNR;
            end
        end

        if isnan(tThreshSD)
            fprintf('\n ** autoThresh.run ends with a NaN threshold. VERY BAD! **\n\n')
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
                fprintf('Chopping first sequence of length %d\n\n',length(splt{1})+1)
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

end %findLowestThreshStretch


function [isFindingAgar,stats] = isThreshTreatingAgarAsSample(stats,tileSizeInMicrons,micsPix)
    % Examines each threshold in turns and determines whether the is evidence that it's
    % treating agar as a ROIs. This can happen when the user has a huge ROI that includes
    % regions outside of the agar.
    verbose=true;

    propTileSizeROIs = zeros(1,length(stats));
    nROIs = zeros(1,length(stats));
    seemsLikeGrid = zeros(1,length(stats));

    tileArea = (tileSizeInMicrons * 1E-3)^2;

    for ii = 1:length(stats)

        if isnan(stats(ii).nRois)
            if verbose
                fprintf('isThreshTreatingAgarAsSample loop %d/%d finds NaNs. skipping.\n', ii, length(stats))
            end
            continue
        end
        tmp=stats(ii).bwStats.step_three.Area_sqmm;
        % How many ROIs have a size that looks like it could be a single tile?
        propTileSizeROIs(ii) = mean(tmp>tileArea*0.125 & tmp<tileArea*0.5);
        nROIs(ii) = length(tmp);

        % Does there seem to be a grid pattern in the centroid locations?
        c=stats(ii).bwStats.step_two.Centroid;
        c=round(c/10)*10 ;
        dx=diff(sort(c(:,1)));
        dy=diff(sort(c(:,1)));
        d=[dx;dy];

        if (sum(d==0)/length(d))>0.4
            seemsLikeGrid(ii)=1;
        end

    end

    % TODO: nROIs threshold shoudld be smarter than this. 

    isFindingAgar = nROIs>30  &  propTileSizeROIs>0.45 &  seemsLikeGrid;
    % insert these values into the stats array
    for ii=1:length(stats)
        stats(ii).thinksAgarIsAROI = isFindingAgar(ii);
    end

    if verbose
        fprintf('\nIs thresh treating agar as sample?\n')
        disp([stats.tThreshSD])
        disp(propTileSizeROIs)
        disp(nROIs)
        disp(seemsLikeGrid)
        disp(isFindingAgar)
    end

end %isThreshTreatingAgarAsSample

