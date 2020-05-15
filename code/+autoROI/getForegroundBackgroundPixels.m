function imStats = getForegroundBackgroundPixels(im,pixelSize,borderPixSize,tThresh,BW)
    % Get forground and background pixels from image 
    %
    % function imStats = getForeGroundBackGroundPixels(im,pixelSize,borderPix,tThresh)
    %
    % Purpose
    % Called by autoROI in order to help calculate 
    % the image SNR based on foreground and background pixels.
    %
    %
    % Inputs
    % im - image to analyse
    % thresh - threshold between sample and no sample. can be missing
    % borderpPix - number of pixels from border to user for background calc.
    % tThresh - Threshold for tissue/no tissue. By default this is auto-calculated
    %
    % Inputs (optional)
    % BW - A binary mask where 1s are foreground (sample) pixels. If missing, this is 
    %      calculated from im using binarizeImage.
    %
    %
    % Outputs
    % pixels - A structure containing fields foregroundPix and backgroundPix, which are
    %          vectors of pixel values.
    %
    %
    % Rob Campbell - SWC 2020

    if nargin<5 || isempty(BW)
        %Get the binary image again so it includes all tissue above the threshold
        BW = autoROI.binarizeImage(im,pixelSize,tThresh); 
    end

    % Get foreground pixels and their stats
    foregroundPix = im(find(BW));
    imStats.foregroundPix = foregroundPix';


    % Get background pixels. We treat as the background only pixels around the border 
    % of the ROI which don't have tissue in them. The presence of tissue is determined 
    % by the BW mask and the threshold. 

    inverseBW = ~BW; %Pixels outside of the sample
    % Set all pixels further in than borderPix to zero (assume they contain sample anyway)
    b = borderPixSize;
    inverseBW(b+1:end-b,b+1:end-b)=0;
    backgroundPix = im(find(inverseBW));

    imStats.backgroundPix = backgroundPix';


    % BakingTray marks pixels that have not been imaged by assigning them the value pi. 
    % We remove any pi here. 

    fB=find(imStats.backgroundPix);
    fF=find(imStats.foregroundPix);
    if isempty(fB) || isempty(fF)
        fprintf('autoROI.getForeGroundBackGroundPixels finds non-imaged BakingTray pixels. Removing them\n')

        if length(fB) == length(imStats.backgroundPix)
            fprintf('All background pixels are being removed. BAD!\n')
        end
        if length(fF) == length(imStats.foregroundPix)
            fprintf('All background pixels are being removed. BAD!\n')
        end
        imStats.backgroundPix(fB) = [];
        imStats.backgroundPix(fF) = [];
    end

