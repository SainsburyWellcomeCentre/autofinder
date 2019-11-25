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

    eb = boundingBox{ii};
    xP = [eb(1), eb(3)+eb(1)];
    yP = [eb(2), eb(4)+eb(2)];

    xSizeInMicrons = diff(xP) * pixelSize;
    ySizeInMicrons = diff(yP) * pixelSize;

    n_xTiles = ceil(xSizeInMicrons / tileSizeInMicrons);
    n_yTiles = ceil(ySizeInMicrons / tileSizeInMicrons);

    %Size of tiled area to image 
    xTilesPix = (n_xTiles * tileSizeInMicrons)/pixelSize; 
    yTilesPix = (n_yTiles * tileSizeInMicrons)/pixelSize; 

    % Correctly position this area, over-writing previous xP and yP vectors
    xP = [mean(xP)-(xTilesPix/2), mean(xP)+(xTilesPix/2) ];
    yP = [mean(yP)-(yTilesPix/2), mean(yP)+(yTilesPix/2) ];

    tiledBox = round([xP(1), ...
                     yP(1), ...
                     xP(2)-xP(1), ...
                     yP(2)-yP(1)]);
