function runOnAllInDir(runDir)
    % Run auto-find test on all structures in runDir
    %
    % function runOnAllInDir(runDir)
    %
    % Purpose
    % Batch run of boundingBoxesFromLastSection.test.runOnStackStruct
    %
    % Inputs (optional)
    % runDir - directory in which to look for files and run. If missing, 
    %          the current directory is used. 
    %
    % 



if nargin<1
    runDir=pwd;
end



testDir = fullfile(runDir,'tests');
if ~exist(testDir,'dir')
    success=mkdir(testDir);
    if ~success
        fprintf('Failed to make %s\n',testDir);
        return
    end
end


pStacks = dir(fullfile(runDir,'*_previewStack.mat'));

if isempty(pStacks)
    fprintf('Found no preview stacks in %s\n',runDir)
    return
end



testDirThisSession = fullfile(testDir,datestr(now,'yymmdd_HHMM'));
success=mkdir(testDirThisSession);
if ~success
    fprintf('Failed to make %s\n',testDir);
    return
end


for ii=1:length(pStacks)
    tFile = fullfile(runDir,pStacks(ii).name);
    fprintf('Loading %s\n',tFile)
    load(tFile)

    [~,nameWithoutExtension] = fileparts(pStacks(ii).name);

    % Do not process if the loaded .mat file does not contain a struct
    if ~istruct(pStack)
        fid = fopen(fullfile(testDirThisSession,['NOT_A_STRUCT_',nameWithoutExtension]),'w');
        fclose(fid)
        continue
    end

    try
        testLog = boundingBoxesFromLastSection.test.runOnStackStruct(pStack,true);
        save(fullfile(testDirThisSession,['log_',pStacks(ii).name]),'testLog')
    catch ME
        fid = fopen(fullfile(testDirThisSession,['FAIL_',nameWithoutExtension]),'w');
        fprintf(fid,ME.message);
        fclose(fid)
    end


end