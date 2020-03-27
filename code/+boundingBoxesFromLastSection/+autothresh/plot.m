function plot(stats)
    % plot output of run command
    %
    % function boundingBoxFromLastSection.autoThresh.plot(stats)
    %
    % Purpose
    % Choose threshold based on the number of ROIs it produces. 
    %
    %


    clf
    subplot(2,2,1)
    plot([stats.tThreshSD],[stats.nRois],'-ok')
    xlabel('threshold')
    ylabel('num ROIs')
    grid on

    subplot(2,2,2)
    plot([stats.tThreshSD],[stats.propImagedAreaUnderBoundingBox],'-ok')
    xlabel('threshold')
    ylabel('prop area covered by ROIs')
    grid on


    subplot(2,2,3)
    plot([stats.tThreshSD],[stats.meanBoundingBoxPixels],'-ok')
    xlabel('threshold')
    ylabel('Mean pixels per bounding box')
    grid on

    subplot(2,2,4)
    plot([stats.tThreshSD],[stats.meanBoundingBoxPixels]./[stats.nRois],'-ok')
    xlabel('threshold')
    ylabel('Mean pixels per bounding box')
    grid on
end % main function
