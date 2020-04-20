function tiledBox = boundingBoxToTiledBox(BoundingBox,pixelSizeInMicrons,tileSizeInMicrons,tileOverlapProportion)
% Rounds up the size of a bounding box to the nearest full tile 
%
% function tiledBox = autoROI.boundingBoxToTiledBox(BoundingBox,pixelSizeInMicrons,tileSizeInMicrons,tileOverlapProportion)
%
% Purpose
% BoundingBoxes are of arbitrary sizes. In practice we will image using tiles. This function
% rounds up the size of the bounding box so that it's to the nearest number of tiles. It
% takes into account tile overlap. The bounding box position is shifted so it remains
% centered in the same location despite the increase in size. This function is called by
% autoROI
%
% Inputs
% BoundingBox - 1 by 4 vector [x,y,xSize,ySize]
% pixelSizeInMicrons -
% tileSizeInMicrons - i.e. this is the FOV of microscope (length of tile on a side)
% tileOverlapProportion - 0.1 means tiles overlap by 10%
% 
%
% Outputs
% tiledBox - a bounding box vector with the updated coords and size
%
%
% Rob Campbell - SWC 2020

    verbose=false;

    if nargin<4
        tileOverlapProportion=0.1;
    end

    % Calculate the bounding box built from tiles of a size defined by the user.
    tileSizeInMicrons = tileSizeInMicrons * (1 - tileOverlapProportion);

    xP = [BoundingBox(1), BoundingBox(3)+BoundingBox(1)];
    yP = [BoundingBox(2), BoundingBox(4)+BoundingBox(2)];


    xSizeInMicrons = diff(xP) * pixelSizeInMicrons;
    ySizeInMicrons = diff(yP) * pixelSizeInMicrons;


    n_xTiles = ceil(xSizeInMicrons / tileSizeInMicrons);
    n_yTiles = ceil(ySizeInMicrons / tileSizeInMicrons);


    if verbose
        fprintf('Bounding box is %0.2f by %0.2f mm: %d by %d tiles\n', ...
         xSizeInMicrons/1E3, ySizeInMicrons/1E3, n_xTiles, n_yTiles)
    end


    %Size of tiled area to image 
    xTilesPix = (n_xTiles * tileSizeInMicrons)/pixelSizeInMicrons; 
    yTilesPix = (n_yTiles * tileSizeInMicrons)/pixelSizeInMicrons; 

    % Correctly position this area, over-writing previous xP and yP vectors
    xP = [mean(xP)-(xTilesPix/2), mean(xP)+(xTilesPix/2) ];
    yP = [mean(yP)-(yTilesPix/2), mean(yP)+(yTilesPix/2) ];

    tiledBox = round([xP(1), ...
                     yP(1), ...
                     xP(2)-xP(1), ...
                     yP(2)-yP(1)]);
