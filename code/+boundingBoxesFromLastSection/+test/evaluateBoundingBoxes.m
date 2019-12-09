function out=evaluateBoundingBoxes(pStack,stats)
% Evaluate how well the bounding boxes capture the brain
% 
%   function out=evaluateBoundingBoxes(pStack,stats)



BW=pStack.binarized;
for ii=1:size(pStack.binarized,3)
    for jj=1:length(stats(ii).BoundingBoxes)
        bb=stats(ii).BoundingBoxes{jj};


        BW(bb(2):bb(2)+bb(4), bb(1):bb(1)+bb(3),ii)=0;

        if sum(BW(:,:,ii),[1,2])>0
            imagesc(BW(:,:,ii))
            disp(ii)
            drawnow
            pause
        end

    end
end