function out = batchDir(runDir)
    % function [tThresh,stats] = boundingBoxFromLastSection.autoThresh.batchDir(runDir)






    pStack_list = dir(fullfile(runDir, '/**/*_previewStack.mat'));

    if isempty(pStack_list)
        fprintf('Found no preview stacks in %s\n',runDir)
        return
    end

    out.thresh = zeros(1,length(pStack_list));
    out.nameWithoutExtension={};

    for ii=1:length(pStack_list)
        tFile = fullfile(pStack_list(ii).folder,pStack_list(ii).name);
        fprintf('Loading %s\n',tFile)
        pStack = pstack_loader(tFile);
        [~,nameWithoutExtension] = fileparts(pStack_list(ii).name);

        out.thresh(ii)=boundingBoxesFromLastSection.autothresh.run(pStack,false);
        out.nameWithoutExtension{ii}=nameWithoutExtension;
    end


function pStack=pstack_loader(fname)
    load(fname)