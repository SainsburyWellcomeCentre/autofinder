function scratch(pStack,stats)

%  load stacks/threeBrains/AF_C2_2FPPVs_previewStack.mat
%  load tests/191228_1433/log_AF_C2_2FPPVs_previewStack.mat
%  scratch(pStack,testLog)

vs=pStack.voxelSizeInMicrons;
ts=pStack.tileSizeInMicrons;
tThresh=8;

ii=11;

res=0.55;
boundingBoxesFromLastSection(imresize(pStack.imStack(:,:,ii),res),...
            'pixelSize', vs/res, ...
            'tileSize',ts, ...
            'tThresh',tThresh,...
            'doPlot',1, ...
            'lastSectionStats',stats(ii-1));