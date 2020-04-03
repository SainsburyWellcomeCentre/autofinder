function evaluateDir(runDir)
% Evaluate all results in runDir
%
% function boundingBoxesFromLastSection.test.evaluateDir(runDir)
%
%
% Purpose
% Makes a text file describing performance of the brain finder for each
% sample. Call from directory contining the pStack files
%
% Inputs
% runDir - the test directory in which to run
% Example
% boundingBoxesFromLastSection.test.runOnStackStruct
% boundingBoxesFromLastSection.test.evaluateDir('tests/191210_1426')
%
% Then do:
% boundingBoxesFromLastSection.test.digestResultsFile('results.txt')




if ~exist(runDir)
    fprintf('Can not find directory %s\n', runDir)
    return
end


% Find the result files
resultFiles = dir( fullfile(runDir,'log_*_previewStack.mat') );
if isempty(resultFiles)
    fprintf('Found no result files in directory %s\n', runDir)
    return
end

% Loop through each result file 
evaltxtFname = fullfile(runDir,'results.txt');

%We will open only transiently to write
fid=fopen(evaltxtFname,'w');
fclose(fid);

lockFname = fullfile(runDir,'LOCK'); %So we can parallelise

parfor ii=1:length(resultFiles)
    tFile = resultFiles(ii).name;

    % Load the data
    msg = sprintf('\nEvaluating %s\n', tFile);
    fprintf(msg);

    testLog = testLog_loader(fullfile(runDir,tFile));

    %Evaluate and write to file
    tmp=boundingBoxesFromLastSection.test.evaluateBoundingBoxes(testLog);
    msg = [msg,tmp];

    writeData(evaltxtFname,msg,lockFname)

end




% internal functions 
function testLog=testLog_loader(fname)
    load(fname)

function writeData(evaltxtFname,msg,lockFname)
    while exist(lockFname,'file')
        fprintf('  *** WAITING TO WRITE DATA TO LOG FILE ***\n') 
        pause(0.1)
    end

    fprintf('STARTING WRITE TO LOG FILE...')
    fid=fopen(lockFname,'w+');
    fclose(fid);

    fid=fopen(evaltxtFname,'a+');
    fprintf(fid,msg);
    fclose(fid);

    delete(lockFname);
    fprintf('DONE\n')
