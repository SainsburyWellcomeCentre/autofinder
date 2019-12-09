function tiledBox = boundingBoxToTiledBox(BoundingBox,pixelSizeInMicrons,tileSizeInMicrons,tileOverlapProportion)
% function tiledBox = boundingBoxesFromLastSection.boundingBoxToTiledBox(BoundingBox,pixelSizeInMicrons,tileSizeInMicrons,tileOverlapProportion)
%%
% Takes a BoundingBox of a certain size and converts to the smallest bounding box
% that would be possible on a tiled acquisition system. 
%
% Inputs
% BoundingBox - 1 by 4 vector
% pixelSizeInMicrons
% tileSizeInMicrons - FOV of microscope (length of tile on a side)
% tileOverlapProportion - 0.1 means tiles overlap by 10%



    % Calculate the bounding box built from tiles of a size defined by the user.
    tileSizeInMicrons = tileSizeInMicrons * (1 - tileOverlapProportion);

    xP = [BoundingBox(1), BoundingBox(3)+BoundingBox(1)];
    yP = [BoundingBox(2), BoundingBox(4)+BoundingBox(2)];

    xSizeInMicrons = diff(xP) * pixelSizeInMicrons;
    ySizeInMicrons = diff(yP) * pixelSizeInMicrons;

    n_xTiles = ceil(xSizeInMicrons / tileSizeInMicrons);
    n_yTiles = ceil(ySizeInMicrons / tileSizeInMicrons);

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
