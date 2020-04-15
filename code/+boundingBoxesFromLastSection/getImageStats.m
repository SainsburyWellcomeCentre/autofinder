function imStats = getImageStats(im,pixelSize,borderPixSize,tThresh)
    % Get key image stats, such as background/foreground pixel info
    %
    % function imStats = getImageStats(im,pixelSize,borderPix,tThresh)
    %
    % Purpose
    % Called by boundingBoxesFromLastSection
    %
    %
    % Inputs
    % im - image to analyse
    % thresh - threshold between sample and no sample. can be missing
    % borderpPix - number of pixels from border to user for background calc.
    % tThresh - Threshold for tissue/no tissue. By default this is auto-calculated
    %
    % Outputs
    % imStats - important statistics associated with the sub-image, such as the background pixel stats


    calcFullStats=false; %In case we ever need more detailed stats. For now we don't

    %Get the binary image again so it includes all tissue above the threshold
    BW = boundingBoxesFromLastSection.binarizeImage(im,pixelSize,tThresh); 

    % Get foreground pixels and their stats
    foregroundPix = im(find(BW));
    if calcFullStats
        imStats.meanForeground = mean(foregroundPix(:));
        imStats.medianForeground = median(foregroundPix(:));
        imStats.stdForeground = std(foregroundPix(:));
    end
    imStats.foregroundPix = foregroundPix;


    % Get background pixels and their stats. We treat as the background
    % only pixels around the border of the ROI which don't have tissue in them. 
    % The presence of tissue is determined by the BW mask and the threshold. 

    inverseBW = ~BW; %Pixels outside of the sample
    % Set all pixels further in than borderPix to zero (assume they contain sample anyway)
    b = borderPixSize;
    inverseBW(b+1:end-b,b+1:end-b)=0;
    backgroundPix = im(find(inverseBW));

    if calcFullStats
        imStats.meanBackground = mean(backgroundPix(:));
        imStats.medianBackground = median(backgroundPix(:));
        imStats.stdBackground = std(backgroundPix(:));
    end
    imStats.backgroundPix = backgroundPix;

