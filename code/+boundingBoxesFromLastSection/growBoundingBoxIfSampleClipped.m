function BoundingBox = growBoundingBoxIfSampleClipped(im,stats,pixelSize,tileSize)
% Enlarge bounding box by full tile increments if the sample is clipped
% This function will be run *after* the new sample images are acquired
% so growth by full tiles is the only option
%
% Inputs-
% im - must be a filtered 2D image
% stats - output of getBoundingBoxes from boundingBoxFromLastSection.m
%         stats is a structure which can have a length>1 for cases with multiple ROIs
% pixelSize - in microns per pixel (for im)
% tileSize - imaging system tile size in microns

disp('NOT FINISHED')
clippedEdges = boundingBoxesFromLastSection.findROIEdgeClipping(im,stats);
tileSizeInPixels = round(tileSize/pixelSize);


% At this point we should have in our ROI structure the tile-based 
% bounding boxes of the current. 

% Keep looping until we have a full image
n=1;
while ~isempty(clippedEdges)
    fprintf('FOV expansion pass %d\n', n)
    n=n+1;

    if any(clippedEdges=='N')
        tROI(2) = tROI(2)-tileSizeInPixels;
    end
    if any(clippedEdges=='S')
        tROI(4) = tROI(4)+tileSizeInPixels;
    end
    if any(clippedEdges=='E')
        tROI(3) = tROI(3)+tileSizeInPixels;
    end
    if any(clippedEdges=='W')
        tROI(1) = tROI(1)-tileSizeInPixels;
    end

    tROI = boundingBoxesFromLastSection.validateROIrestrict(tROI,imOrig);
    im = imOrig(tROI(2):tROI(2)+tROI(4),tROI(1):tROI(1)+tROI(3));

    %cla,imagesc(im),drawnow
    stats = boundingBoxesFromLastSection.getBrainInImage(im,pixelSize,tThresh); %TODO - this is not going to work right now
    clippedEdges = boundingBoxesFromLastSection.findROIEdgeClipping(im,stats);

    % Choose some arbitrary largish number and break if we still haven't expanded to the full field by this point
    if n>20
        msg = 'HARD-BREAK FROM FOV EXPANSION LOOP ';
        fprintf('%s\n',msg)
        stats.notes=[stats.notes,msg];
        break
    end

    %HACK to avoid looping in cases where the brain is up against the edge of the FOV
    if (size(imOrig,1)-tROI(4)-tROI(2))<=1 && any(clippedEdges=='S')
        %fprintf('Removing south ROI clip\n')
        %clippedEdges
        clippedEdges(clippedEdges=='S')=[];
        %clippedEdges
    end

end

% Log the current FOV ROI and and ensure that all ROI boxes we have drawn in the 
% units of the original image. 
stats.ROIrestrict=tROI;