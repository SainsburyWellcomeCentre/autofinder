function BW = binarizeImage(im,pixelSize,tThresh,showImages)
    % Binarise and clean image. Adding a border before returning.
    %
    % function BW = binarizeImage(im,pixelSize,tThresh)
    %
    % Purpose
    % This function is called by boundingBoxFromLastSection
    %
    % Inputs (required)
    % im - a single image from an image stack
    % pixelSize - the number of microns per pixel
    % tThresh - the threshold between brain and no brain
    %
    % Inputs (optional)
    % showImages - false by default. If true, images are shown. User has to press return to continue.
    %
    % Output
    % BW - the binarised imaged. 
    %

    if nargin<4 || isempty(showImages)
        showImages = false; %Set to true to display binarized images and force step-through with return key
    end

    verbose = false;


    settings = boundingBoxesFromLastSection.readSettings;

    BW = im>tThresh;
    if showImages
        subplot(2,2,1)
        imagesc(BW)
        title('Before medfilt2')
    end




    BW=bwpropfilt(BW,'Eccentricity',[0,0.99]); %Get rid of line-like things

    BW = medfilt2(BW,[settings.mainBin.medFiltBW,settings.mainBin.medFiltBW]);

    if showImages
        subplot(2,2,2)
        imagesc(BW)
        title('After medfilt2')
    end
    if verbose
        fprintf('Binarized size before dilation: %d by %d\n',size(BW));
    end

    % Remove crap using spatial filtering
    SE = strel(settings.mainBin.primaryShape, ...
        round(settings.mainBin.primaryFiltSize/pixelSize));
    BW = imerode(BW,SE);
    BW=bwpropfilt(BW,'Eccentricity',[0,0.99]); %Get rid of line-like things
    BW=bwpropfilt(BW,'MinorAxisLength',[2,inf]); %Get rid of things that are thin
    BW = imdilate(BW,SE);


    if showImages
        subplot(2,2,3)
        imagesc(BW)
        title('After morph filter')
        %subplot(2,2,4)
       %hist([r.MinorAxisLength],100)
    end


    % EXPAND IMAGED AREA: Add a small border around the brain
    SE = strel(settings.mainBin.expansionShape, ...
        round(settings.mainBin.expansionSize/pixelSize));
    BW = imdilate(BW,SE);

    if showImages
        subplot(2,2,4)
        imagesc(BW)
        drawnow
        title('After expansion')
        %pause
    end

    if verbose
        fprintf('Binarized size after dilation: %d by %d\n',size(BW));
            [~,tmp] = boundingBoxesFromLastSection.boundingBoxAreaFromImage(BW);
        fprintf('ROI size within binarized image: %d by %d\n',tmp);
    end

