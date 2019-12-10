function out=evaluateBoundingBoxes(pStack,stats)
% Evaluate how well the bounding boxes capture the brain
% 
%   function out=evaluateBoundingBoxes(pStack,stats)



BW=pStack.binarized;
nPlanesWithMissingBrain=0;
for ii=1:size(pStack.binarized,3)
    for jj=1:length(stats(ii).BoundingBoxes)
        bb=stats(ii).BoundingBoxes{jj};

        bb(bb<=0)=1; %In case boxes have origins outside of the image

        BW(bb(2):bb(2)+bb(4), bb(1):bb(1)+bb(3),ii)=0;

        if sum(BW(:,:,ii),[1,2])>0
            nPlanesWithMissingBrain = nPlanesWithMissingBrain + 1;
            imagesc(BW(:,:,ii))
            disp(ii)
            drawnow
            pause
        end

    end
end

if nPlanesWithMissingBrain==0
    fprintf('None of the sample has been left unimaged.\n')
end