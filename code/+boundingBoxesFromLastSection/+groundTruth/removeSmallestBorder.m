function pStack = removeSmallestBorder(pStack,inds)
% Remove the smallest sample border from pStack.borders{inds}
%
% pStack = boundingBoxesFromLastSection.groundTruth.stackToGroundTruth(removeSmallestBorder(pStack,inds)
%
% Purpose
% Used to help curate data. Removes whichever is the smallest border in each cell defined by 
% the vector inds.
%
% 
% Inputs
% pStack - pStack data structure.
% inds - a vector to loop over. These are indecies of pStack.borders
%            have multiple samples. 
%
% Outputs
% pStack - pStack data structure.
%
%

if ~isstruct(pStack)
    fprintf('pStack should be a structure\n')
    return
end

if ~isfield(pStack,'borders')
    fprintf('No borders field in pStruct. First you need to run boundingBoxesFromLastSection.groundTruth.genGroundTruthBorders\n')
    return
end


for ii=1:length(inds)
    tInd = inds(ii);

    if tInd > length(pStack.borders{1})
        fprintf('index %d is out of range. length borders is %d. Skipping.\n', ...
            tInd, length(pStack.borders{1}))
        continue
    end

    %Find smallest border and remove it
    tB = pStack.borders{1}{tInd};
    fprintf('Removing one border from a list of %d borders\n', length(tB));
    L = cellfun(@length, tB);
    [~,minInd] = min(L);
    tB(minInd)=[];

    pStack.borders{1}{tInd} = tB;
end
