function stats = getBoundingBoxes(BW,im,pixelSize)
    % Get bounding boxes in binarized image, BW. 
    verbose=true;
    settings = boundingBoxesFromLastSection.readSettings;

    % Find bounding boxes, removing very small ones and 
    stats = regionprops(BW,'boundingbox', 'area', 'extrema');

    if isempty(stats)
        fprintf('autofindBrainsInSection.image2boundingBoxes found no sample in ROI! BAD!\n')
        return
    end

    % Delete very small objects and ensure we have no non-integers
    sizeThresh = settings.mainGetBB.minSizeInSqMicrons / pixelSize;

    for ii=length(stats):-1:1
        stats(ii).BoundingBox(1:2) = round(stats(ii).BoundingBox(1:2));
        stats(ii).BoundingBox(stats(ii).BoundingBox==0)=1;
        if stats(ii).Area < sizeThresh;
            fprintf('Removing small ROI of size %d\n', stats(ii).Area)
            stats(ii)=[];
        end
    end
    if length(stats)==0
        fprintf('%s > getBoundingBoxes after removing small ROIs there are none left.\n',mfilename)
    end

    % -------------------
    % TEMP UNTIL WE FIX BAKINGTRAY WE MUST REMOVE THE NON-IMAGED CORNER PIXELS
    %Look for ROIs smaller than 2 by 2 mm and ask whether they are the un-imaged corner tile.
    %(BakingTray currently (Dec 2019) produces these tiles and this needs sorting.)
    %If so delete. TODO: longer term we want to get rid of the problem at acquisition. 

    for ii=length(stats):-1:1
        boxArea = prod(stats(ii).BoundingBox(3:4)*pixelSize*1E-3);
        if boxArea>2
            % TODO: could use the actual tile size
            continue
        end


        % Ask if most pixels the median value.
        tmp=boundingBoxesFromLastSection.getSubImageUsingBoundingBox(im,stats(ii).BoundingBox);
        tMed=median(tmp(:));
        propMedPix=length(find(tmp==tMed)) / length(tmp(:));
        if propMedPix>0.5
            %Then delete the ROI
            fprintf('Removing corner ROI\n')
            stats(ii)=[];
        end
    end
    % -------------------

    %Sort in ascending size order
    [~,ind]=sort([stats.Area]);
    stats = stats(ind);

    if verbose==false
        return
    end

    if length(stats)==1
        fprintf('%s > getBoundingBoxes Found 1 Bounding Box\n',mfilename)
    elseif length(stats)>1
        fprintf('%s > getBoundingBoxes Found %d Bounding Boxes\n',mfilename,length(stats))
    elseif length(stats)==0
        fprintf('%s > getBoundingBoxes Found no Bounding Boxes\n',mfilename)
    end


    %Report clipping of ROI edges
    for ii=1:length(stats)
       % boundingBoxesFromLastSection.findROIEdgeClipping(BW,stats(ii).BoundingBox)
    end


