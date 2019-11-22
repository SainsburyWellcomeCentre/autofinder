function ROIrestrict = validateROIrestrict(ROIrestrict,im)
    % Ensure coordinates of ROIrestrict will not produce invalid values that are outside of the imaged area
    verbose=false;
    if ROIrestrict(1)<1
        if verbose
            fprintf('Capping RR1 from %d to 1\n',ROIrestrict(1))
        end
        ROIrestrict(1)=1;
    end
    if ROIrestrict(2)<1
        if verbose
            fprintf('Capping RR2 from %d to 1\n',ROIrestrict(2))
        end
        ROIrestrict(2)=1;
    end

    if (ROIrestrict(3)+ROIrestrict(1)) > size(im,2)
        if verbose
            disp('Capping RR3')
        end
        ROIrestrict(3) = size(im,2)-ROIrestrict(1);
    end

    if (ROIrestrict(4)+ROIrestrict(2)) > size(im,1)
        if verbose
            fprintf('Capping RR4 from %d to %d\n', ROIrestrict(4),size(im,1)-ROIrestrict(2))
        end
        ROIrestrict(4) = size(im,1)-ROIrestrict(2);
    end


 