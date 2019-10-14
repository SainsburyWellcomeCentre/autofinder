function filteredStack = filterStack(im)
%
% function filteredStack = filterStack(im)
%
% Purpose
% Reduce noise and 2D median filter downsampled stack. 
%
% Inputs
% im - 3D image stack
%
% Outputs
% filteredStack
%
%
% Rob Campbell - August 2019

fprintf('Filtering projection\n')

M = readMetaData2Stitchit;
nP = M.mosaic.numOpticalPlanes;

fprintf('%d total optical planes (%d per section)\n', size(im,3), nP)

filteredStack = zeros([size(im,1), size(im,2), floor(size(im,3)/nP)]);

n=1;

for ii=1:nP:size(im,3)
    fprintf('.')
    tSlices = ii:(ii+nP-1);
    if size(filteredStack,3)<n
        break
    end
    filteredStack(:,:,n) = mean(medfilt3(im(:,:,tSlices), [3,3,3]),3);
    n=n+1;
end
fprintf('\n')
