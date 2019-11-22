function clippedEdges = findROIEdgeClipping(im,stats)
    % Return IDs of images edges at which the ROI is clipped. This would indicate
    % that the brain lies outside of the current FOV. 
    % The output variable, clippedEdges, codes data as 'N'orth, 'S'outh, 'E'ast, and 'W'est
    clippedEdges=[];
    for ii=1:size(stats.enclosingBoxes)
        eb=stats.enclosingBoxes{ii};
        if eb(1)==1
            clippedEdges(end+1)='W';
        end
        if eb(2)==1
            clippedEdges(end+1)='N';
        end
        if eb(1)+eb(3) >= size(im,2)
            clippedEdges(end+1)='E';
        end
        if eb(2)+eb(4) >= size(im,1)
            clippedEdges(end+1)='S';
        end
    end

    clippedEdges = char(unique(clippedEdges));


