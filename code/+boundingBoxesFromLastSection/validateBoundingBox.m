function BoundingBox = validateROIrestrict(BoundingBox,im)
     % Ensure bounding box is valid before proceeding. 

     % Ensure bounding box is valid before proceeding. 
    verbose=false;
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

    if (BoundingBox(3)+BoundingBox(1)) > size(im,2)
        if verbose
            disp('Capping RR3')
        end
        BoundingBox(3) = size(im,2)-BoundingBox(1);
    end

    if (BoundingBox(4)+BoundingBox(2)) > size(im,1)
        if verbose
            fprintf('Capping RR4 from %d to %d\n', BoundingBox(4),size(im,1)-BoundingBox(2))
        end
        BoundingBox(4) = size(im,1)-BoundingBox(2);
    end