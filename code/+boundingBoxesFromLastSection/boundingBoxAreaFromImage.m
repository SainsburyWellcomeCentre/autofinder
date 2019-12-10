function [tArea,boundingBoxSize] = boundingBoxAreaFromImage(im)
    % Determine the area of a bounding box required to fit all non-zero pixels in a binary image.
    tmp = im>0;

    %Rows and columns that have at least one non-zero pixel
    a = find(sum(tmp,1)>1);
    b = find(sum(tmp,2)>1);
    tArea = length(min(a):max(a)) * length(min(b):max(b));

    boundingBoxSize=[length(b),length(a)];



