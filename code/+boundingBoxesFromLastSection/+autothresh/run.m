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
            stats.boundingBoxSqMM = OUT.totalBoundingBoxPixels * (voxSize * 1E-3)^2;
            stats.propImagedAreaUnderBoundingBox=OUT.propImagedAreaCoveredByBoundingBox;
            stats.notes='';
        end
        stats.tThreshSD=tThreshSD;

    end % runThreshCheck



    function [tThreshSD,stats] = lowSNRalg(stats)
        initial_nROIs = stats.nRois;
        x=0.015;

        fprintf('\n\n\n ** SEARCHING LOW SNR with %d INITIAL ROIS\n', initial_nROIs)

        % We loop through and break off if the number of ROIs drops
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


        % If it's still a NaN then the number of ROIs never dropped. 
        % Instead, lets's look for a drop in coverage
        tT=[stats.tThreshSD];
        [tT,ind] = sort(tT,'ascend');
        stats = stats(ind);

        if isnan(finalX)
            sqm = round([stats.boundingBoxSqMM],1);
            f=find(diff(sqm)<0);
            if ~isempty(f) && f(1)>2
                finalX = tT(f(1)-1);
                stats(1).notes=sprintf('Low SNR: Chose finalX based on drop in bounding box area');
            end
        else
            stats(1).notes=sprintf('Low SNR: Chose finalX based on break from full coverage');

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
        while x>0.75 %Very small thresholds tend to be bad news
            fprintf(' ---> thresh = %0.3f\n', x(end))
            stats(end+1)=runThreshCheck(x(end));

            % If we reach over 95% coverage then back up a notch and assign the threshold as this value
            if stats(end).propImagedAreaUnderBoundingBox>0.95
                if length(x)>1
                    tThreshSD = x(end-1)*1.75;
                else
                    fprintf('\nODD -- High SNR -- breaking with length(x)==1\n');
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


        % Before finally bailing out, see if we can improve the threshold. If many 
        % points have the same number of ROIs, choose the middle of this range instead. 
        nR = [stats.nRois];
        [theMode,numOccurances] = mode(nR);
        fM=find(nR==theMode); %The indecies of the mode


        % If there are more than three of them and all are in a row, then we use the mean of these as the threshold
        fprintf('\n\nFinishing up high SNR.\nNumber of ROIs have mode value of %d which occurs %d times\n', theMode, numOccurances)

        if numOccurances>3 && all(diff(fM)==1)
            fprintf(' --->  High SNR: Choosing based on uninterupted mode.\n')
            tThreshSD = mean(tT(find(nR==theMode)));
            stats(1).notes=sprintf('High SNR: mean of values at nROI=%d', theMode);

        elseif numOccurances>8 && (length(fM)/length(fM(1):fM(end)))>0.8
            fprintf(' --->  High SNR: Choosing based on mode with few interruptions: n=%d missing=%d\n', ...
                length(fM), length(fM(1):fM(end))-length(fM) )

            % Remove thresholds that are very low. Clip out low values, in other words.
            tT = tT(find(nR==theMode));
            tT(tT<=0.5)=[];
            tThreshSD = mean(tT);

            stats(1).notes=sprintf('High SNR: mean of %d values at nROI=%d. %d missing.', ...
                numOccurances, theMode, length(fM(1):fM(end))-length(fM) );

        elseif ~isempty(findLowestThreshStretch(nR,4))
            ind = findLowestThreshStretch(nR,4);

            % Remove thresholds that are very low. Clip out low values, in other words.
            tT = tT(ind);
            tT(tT<=0.5)=[];
            tThreshSD = mean(tT);

            msg=sprintf('High SNR: Choosing using findLowestThreshStretch with thresh of 4: tThreshSD=%0.2f\n',tThreshSD);
            fprintf(msg)
            stats(1).notes=msg;

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


function ind = findLowestThreshStretch(nR,thresh)

    % Find the stretch of mode(nR) that is lowest. 
    % i.e. If we have a bunch of nR=4 values at lower thersholds, then a gap of a different value,
    % then a bunch more pf nR=4 at high values, we want to choose the lower threshold values. So
    % long as these number more than thresh. 

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


