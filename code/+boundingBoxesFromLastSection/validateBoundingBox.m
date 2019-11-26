function BoundingBox = validateROIrestrict(BoundingBox,imSize)
    % Ensure bounding box is valid before proceeding. 
    %
    % imSize can be the image in question or the size of the the image

    if ~isequal(size(imSize),[1,2])
        imSize = size(imSize);
    end

    verbose=false;

    BoundingBox = [floor(BoundingBox(1:2)),ceil(BoundingBox(3:4))];

    if BoundingBox(1)<1
        if verbose
            fprintf('Capping RR1 from %d to 1\n',BoundingBox(1))
        end
        BoundingBox(1)=1;
    end
    if BoundingBox(2)<1
        if verbose
            fprintf('Capping RR2 from %d to 1\n',BoundingBox(2))
        end
        BoundingBox(2)=1;
    end

    if (BoundingBox(3)+BoundingBox(1)) > imSize(2)
        if verbose
            disp('Capping RR3')
        end
        BoundingBox(3) = imSize(2)-BoundingBox(1);
    end

    if (BoundingBox(4)+BoundingBox(2)) > imSize(1)
        if verbose
            fprintf('Capping RR4 from %d to %d\n', BoundingBox(4),imSize(1)-BoundingBox(2))
        end
        BoundingBox(4) = imSize(1)-BoundingBox(2);
    end