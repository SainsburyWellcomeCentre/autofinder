function pStack = stackToGroundTruth(imStack,voxelSize,tileSize,nSamples)
% Wrap an image stack into a "ground truth" structure for testing
%
% boundingBoxesFromLastSection.test.stackToGroundTruth(imStack,voxelSize,tileSize,nSamples)
%
% Purpose
% The "groundTruth" structure will be used for testing the behavior of the brain-finding
% algorithm. This function produces the structure. The structure should contain all the 
% parameters we need to obtain a ground truth brain border against which we can go on to 
% test whether or not the auto-brain-finder has managed to identify the whole brain. 
%
% 
% Inputs
% imStack - The preview image stack produced by previewFilesToTiffStack from BakingTray.
% voxelSize - size of an x/y voxel in imStack in microns.
% tileSize - the number of microns on a side for each tile
% nSamples - the number of samples (e.g. brains) contained in imStack. Some acquisitions 
%            have multiple samples. 
%
%
%


if nargin<2 || isempty(voxelSize)
    voxelSize=10;
end

if nargin<3 || isempty(tileSize)
    tileSize=1E3;
end

if nargin<4 || isempty(nSamples)
    nSamples=1;
end

pStack.imStack = imStack;
pStack.voxelSizeInMicrons = voxelSize;
pStack.tileSizeInMicrons = tileSize;
pStack.nSamples = nSamples;
pStack.binarized = [];
pStack.borders = {};
