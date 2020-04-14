function plot(stats)
    % plot output of run command
    %
    % function boundingBoxFromLastSection.autoThresh.plot(stats)
    %
    % Purpose
    % Choose threshold based on the number of ROIs it produces. 
    %
    %

    nRows = 4;

    clf
    subplot(nRows,2,1)
    plot([stats.tThreshSD],[stats.nRois],'-ok')
    xlabel('threshold')
    ylabel('num ROIs')
    grid on

    subplot(nRows,2,2)
    plot([stats.tThreshSD],[stats.propImagedAreaUnderBoundingBox],'-ok')
    xlabel('threshold')
    ylabel('prop area covered by ROIs')
    grid on


    subplot(nRows,2,3)
    plot([stats.tThreshSD],[stats.meanBoundingBoxPixels],'-ok')
    xlabel('threshold')
    ylabel('Mean pixels per bounding box')
    grid on

    subplot(nRows,2,4)
    plot([stats.tThreshSD],[stats.meanBoundingBoxPixels]./[stats.nRois],'-ok')
    xlabel('threshold')
    ylabel('Mean pixels per bounding box')
    grid on

    subplot(nRows,2,5)
    f=~isnan([stats.nRois]);
    stats = stats(f);
    plot([stats.tThreshSD],[stats.SNR_medThreshRatio],'-ok')
    xlabel('tThreshSD')
    ylabel('SNR')


    subplot(nRows,2,6)
    f=~isnan([stats.nRois]);
    stats = stats(f);
    % Loop through and find the number of regions
    n=zeros(1,length(stats));
    rArea=zeros(1,length(stats));
    for ii=1:length(stats)
        tmp = stats(ii).bwStats.step_two;
        n(ii)=length(tmp.Area);
        rArea(ii) = median(tmp.Area_sqmm);
    end
    plot([stats.tThreshSD],rArea,'-ok')
    xlabel('tThreshSD')
    ylabel('Num ROIs')


    if isfield(stats,'thinksAgarIsAROI')
        subplot(nRows,2,7)
        plot([stats.tThreshSD],[stats.thinksAgarIsAROI],'-ok')
        xlabel('threshold')
        ylabel('thinksAgarIsAROI')
        grid on
    end

end % main function
