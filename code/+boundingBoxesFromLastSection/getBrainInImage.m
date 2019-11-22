function stats = getBrainInImage(im,pixelSize,tThresh)
    % Main workhorse function. This one uses a defined threshold
    % to draw a box with a boundary around the brain. 

    im=single(im);


    % Binarize and clean
    BW = im>tThresh;
    BW = medfilt2(BW,[3,3]);

    % Remove crap using spatial filtering
    SE = strel('disk',round(50/pixelSize));
    BW = imerode(BW,SE);
    BW = imdilate(BW,SE);


    % Add a border around the brain
    SE = strel('square',round(200/pixelSize));
    BW = imdilate(BW,SE);


    %Look for objects at that occupy least a certain proportion of the image area
    minSize=0.015;
    nBrains=1;
    sizeThresh = prod(size(im)) * (minSize / nBrains);

    [L,indexedBW]=bwboundaries(BW,'noholes');

    for ii=length(L):-1:1
        thisN = length(find(indexedBW == ii));
        if thisN < sizeThresh
            L(ii)=[]; % Delete small stuff
        end
    end

    H=[]; % Empty plot handle variable in case no brains were found
    if isempty(L)
        fprintf('autofindBrainsInSection.getBrainInImage found no sample! BAD!\n')
        stats=[];
    else
        % Generate all relevant stats and so forth
        stats.boundaries = L;
        stats.enclosingBoxes = autof.region2EnclosingBox(L);

        % Determine the size of the overall box that would include all boxes
        if length(stats.enclosingBoxes)==1
            stats.globalBox = stats.enclosingBoxes{1};
        elseif length(stats.enclosingBoxes)>1
            tmp = cell2mat(stats.enclosingBoxes');
            stats.globalBox = [min(tmp(:,1:2)), max(tmp(:,1)+tmp(:,3)), max(tmp(:,2)+tmp(:,4))];                
        end

        % Store statistics in output structure
        backgroundPix = im(find(~BW));
        stats.meanBackground = mean(backgroundPix(:));
        stats.medianBackground = median(backgroundPix(:));
        stats.stdBackground = std(backgroundPix(:));
        stats.nBackgroundPix = sum(~BW(:));

        foregroundPix = im(find(BW));
        stats.meanForeground = mean(foregroundPix(:));
        stats.medianForeground = median(foregroundPix(:));
        stats.stdForeground = std(foregroundPix(:));
        stats.nForegroundPix = sum(BW(:));
        stats.ROIrestrict=[]; % Main function fills in if the analysis was performed on a smaller ROI
        stats.notes=''; %Anything odd can go in here
        stats.tThresh = tThresh;

    end
