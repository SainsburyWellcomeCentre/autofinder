function plot(stats)
    % plot output of run command
    %
    % function boundingBoxFromLastSection.autoThresh.plot(stats)
    %
    % Purpose
    % Choose threshold based on the number of ROIs it produces. 
    %
    %

    nRows = 3;

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
    SNR=[stats.SNR];
    plot([stats.tThreshSD],[SNR.medThreshRatio],'-ok')
end % main function
