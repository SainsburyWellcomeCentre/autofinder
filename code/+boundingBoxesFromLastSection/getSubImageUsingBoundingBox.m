function subIm = getSubImageUsingBoundingBox(im,BoundingBox,maintainSize)
    % Pull out a sub-region of the image based on a bounding box.
    %
    % Inputs
    % im - 2d image from which we will extract a sub-region
    % BoundingBox - in the form: [left corner pos, bottom corner pos, width, height]
    % maintainSize - false by default. If true, the output (subIM), is the same size as im
    %                but all pixels outside BoundingBox are zero.

    if nargin<3
        maintainSize=false;
    end


    BoundingBox = boundingBoxesFromLastSection.validateBoundingBox(BoundingBox,size(im));
    subIm = im(BoundingBox(2):BoundingBox(2)+BoundingBox(4), ...
               BoundingBox(1):BoundingBox(1)+BoundingBox(3));

    if maintainSize
        tmp=zeros(size(im));
        tmp(BoundingBox(2):BoundingBox(2)+BoundingBox(4), ...
            BoundingBox(1):BoundingBox(1)+BoundingBox(3)) = subIm;
        subIm =tmp;
    end

