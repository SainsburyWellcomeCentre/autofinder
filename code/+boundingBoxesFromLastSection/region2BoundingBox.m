function boundingBox = region2boundingBox(region,pixelSize,tileSizeInMicrons)
%    function boundingBox = region2boundingBox(region,pixelSize,tileSizeInMicrons)
%
% Purpose
% Calculate the smallest enclosing rectangle for one or more
% regions returned by bwboundaries.
%
% If pixelSize and tileSizeInMicrons are provided, then enclosing box is
% rounded up the to the best fit box made up of tiles of the defined
% size
% 
%
% Inputs
% region - a cell array of regions
%
% Optional inputs
% pixelSize - number of microns per pixel
% tileSizeInMicrons - the length of a side of a (square) tile in microns.
% 
% Outputs
% boundingBox - a cell array of minimum enclosing rectangles
%             This is in the format: [x_corner, y_corner, x_width, y_width]
%
%
% Rob Campbell , SWC, August 2019

if nargin<2
    pixelSize=[];
end

if nargin<3
    tileSizeInMicrons=[];
end

if ~isempty(pixelSize) && ~isempty(tileSizeInMicrons)
    calcTileBox=true;
else
    calcTileBox=false;
end

validateattributes(region,{'cell'},{'2d'})

% Keep track of the maximum x and y positions of the boxes so we can test later 
% for overlap
maxY=zeros(1,length(region));
maxX=zeros(1,length(region));

for ii=1:length(region)
    [boundingBox{ii}, maxX(ii),maxY(ii)] = boundary2encBox(region{ii});
end


% ------
% Consolidate bounding boxes that overlap a reasonable amount so long as doing so
% Is not going to result in a large increase in the area being imaged.
tmpIm = zeros([max(maxY)+5,max(maxX)+5,length(region)]);

% Fill in the "image" with the areas that are ROIs
for ii=1:length(region)
    eb = boundingBox{ii};
    tmpIm(eb(2):eb(2)+eb(4), eb(1):eb(1)+eb(3),ii) = 1;
end

%If areas do not overlap the following is false
containsOverlaps = @(x) ~isequal(unique(sum(x,3)),[0;1]);
if size(tmpIm,3)>1
    fprintf('Attempting to merge %d ROIs\n',size(tmpIm,3));
end

while containsOverlaps(tmpIm)
    combosToTest = nchoosek(1:size(tmpIm,3),2);
    overlapProp = zeros(1,length(combosToTest));
    for ii=1:size(combosToTest,1)
        tCombo = tmpIm(:,:,[combosToTest(ii,1),combosToTest(ii,2)]);
        tCombo = sum(tCombo,3);
        overlapProp = length(find(tCombo(:)==2)) / length(find(tCombo(:)>=1));
    end

    %Make a new area comprising that with the maximum overlap
    [~,ind] = max(overlapProp);
    tCombo = tmpIm(:,:,[combosToTest(ind,1),combosToTest(ind,2)]);
    tCombo = sum(tCombo,3);
    tCombo(tCombo>0) = 1; %We now have a new ROI that incorporates the two
    tmpIm(:,:,combosToTest(combosToTest(ind,1))) = tCombo;
    tmpIm(:,:,combosToTest(combosToTest(ind,2))) = [];
    fprintf('.')
    if size(tmpIm,3) == 1, fprintf('\n'), break, end
end



% Convert to vectors
boundingBox = cell(1,size(tmpIm,3));
for ii=1:size(tmpIm,3)
    b = bwboundaries(tmpIm(:,:,ii));
    boundingBox{ii} = boundary2encBox(b{1});
end


% Algorithm:
% - Sum in 3rd dim. If everything is a 1 we quit.
% - perform some crap and recalculate
% - Sum in 3rd dim. If everything is a 1 we quit

% So what crap should we calculate?
% Choose areas with most overlap and least extra added area and merge those
% - Find the area it overlaps with most


% ------
% Convert to tiled version if the user supplied the pixel size and tile size
if ~calcTileBox
    return
end

for ii=1:length(boundingBox)
    % Calculate the bounding box built from tiles of a size defined by the user.

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

    boundingBox{ii} = round([xP(1), ...
                        yP(1), ...
                        xP(2)-xP(1), ...
                        yP(2)-yP(1)]);
end



function [eb,maxX,maxY] = boundary2encBox(b)
    % Get the bounding box for a single bwboundaries area also return the maximum 
    % positions of the box in x and y.
    xP = [min(b(:,2)), max(b(:,2))];
    yP = [min(b(:,1)), max(b(:,1))];

    maxX=xP(2);
    maxY=yP(2);

    eb= [xP(1), ...
         yP(1), ...
         xP(2)-xP(1), ...
         yP(2)-yP(1)];
