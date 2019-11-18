function pStack = stackToGroundTruth(imStack,voxelSize,tileSize,nSamples)
	% Generate a structure for testing ground truth from an image stack
	%
	% imStack is the preview stack produced by previewFilesToTiffStack from BakingTray
	% This function builds a structure and adds this to it. The structure
	% is supposed to contain all the parameter we need to obtain a ground truth
	% brain border against which we can go on to test whether or not the auto-brain-finder
	% has managed to identify the whole brain. 


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
