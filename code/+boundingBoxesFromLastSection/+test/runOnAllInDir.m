function runOnAllInDir(runDir,doAutoThreshold)
    % Run auto-find test on all structures in runDir
    %
    % function boundingBoxesFromLastSection.tests.runOnAllInDir(runDir,doAutoThreshold)
    %
    % Purpose
    % Batch run of boundingBoxesFromLastSection.test.runOnStackStruc
    % Looks for pStack structures in the current directory and all 
    % directories within it. Saves results to a directory called "tests"
    % in the current directory.
    %
    %
    % Inputs (optional)
    % runDir - directory in which to look for files and run. If missing, 
    %          the current directory is used.
    % doAutoThreshold - false by default
    %
    %
    % Example
    % >> ls
    %   readme.txt stacks     tests 
    % >> boundingBoxesFromLastSection.tests.runOnAllInDir('stacks/twoBrains')
    %
    % Or run on all sub-directories:
    % >> boundingBoxesFromLastSection.tests.runOnAllInDir('stacks')



if nargin<1
    runDir='stacks';
end


if nargin<2 || isempty(doAutoThreshold)
    % Auto find the threshold?
    doAutoThreshold = false;
end




testDir = fullfile('tests');
if ~exist(testDir,'dir')
    success=mkdir(testDir);
    if ~success
        fprintf('Failed to make %s\n',testDir);
        return
    end
end



pStack_list = dir(fullfile(runDir, '/**/*_previewStack.mat'));

if isempty(pStack_list)
    fprintf('Found no preview stacks in %s\n',runDir)
    return
end


testDirThisSession = fullfile(testDir,datestr(now,'yymmdd_HHMM'));
success=mkdir(testDirThisSession);
if ~success
    fprintf('Failed to make %s\n',testDir);
    return
else
    fprintf('Writing test data in directory %s\n', testDirThisSession)

end


parfor ii=1:length(pStack_list)
    tFile = fullfile(pStack_list(ii).folder,pStack_list(ii).name);
    fprintf('Loading %s\n',tFile)
    pStack = pstack_loader(tFile);
    [~,nameWithoutExtension] = fileparts(pStack_list(ii).name);

    % Do not process if the loaded .mat file does not contain a struct
    if ~isstruct(pStack)
        fid = fopen(fullfile(testDirThisSession,['NOT_A_STRUCT_',nameWithoutExtension]),'w');
        fclose(fid)
        continue
    end

    try
        % Run
        testLog = boundingBoxesFromLastSection.test.runOnStackStruct(pStack,true,doAutoThreshold);

        % Log useful info in first element
        testLog(1).stackFname = tFile; %Into the first element add the file name

        saveFname = fullfile(testDirThisSession,['log_',pStack_list(ii).name]);
        fprintf('Saving data to %s\n', saveFname)
        testlog_saver(saveFname,testLog)% (fullfile(testDirThisSession,['log_',pStack_list(ii).name]),'testLog')
    catch ME
        fid = fopen(fullfile(testDirThisSession,['FAIL_',nameWithoutExtension]),'w');
        fprintf(fid,ME.message);
        fclose(fid)
        fprintf('%s FAILED WITH MESSAGE :\n%s\n',nameWithoutExtension, ME.message)
    end


end


% internal functions 
function pStack=pstack_loader(fname)
    load(fname)

function testlog_saver(fname,testLog)
    save(fname,'testLog')
