function varargout = findROIEdgeClipping(im,BoundingBox,verbose)
% Find clipped image edges based on a bounding box
% 
% function clippedEdges = findROIEdgeClipping(im,BoundingBox)
%
% Purpose
% Return IDs of images edges at which the ROI is clipped. This would indicate
% that the brain lies outside of the current FOV. 
% The output variable, clippedEdges, codes data as 'N'orth, 'S'outh, 'E'ast, and 'W'est
%
% Inputs
% im - image in which to look for clipped edges
% BoundingBox - the bounding box
% verbose - false by default unless no output arguments assigned, 
%           in which case it's true.



if nargin<3 && nargout==0
    verbose=true;
elseif nargin<3
    verbose=false;
end


clippedEdges=[];


if BoundingBox(1)<=1
    clippedEdges(end+1)='W';
end

if BoundingBox(2)<=1
    clippedEdges(end+1)='N';
end

if BoundingBox(1)+BoundingBox(3) >= size(im,2)
    clippedEdges(end+1)='E';
end

if BoundingBox(2)+BoundingBox(4) >= size(im,1)
    clippedEdges(end+1)='S';
end

clippedEdges = char(unique(clippedEdges));

if verbose && ~isempty(clippedEdges)
    fprintf('The following sides are clipped because the ROI extends all the way to image edge: %s\n', clippedEdges)
end

if nargout>0
    varargout{1}=clippedEdges;
end