function evaluateDir(runDir)
% Evaluate all results in runDir
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
%




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

fid=fopen(evaltxtFname,'w');

for ii=1:length(resultFiles)
    tFile = resultFiles(ii).name;

    % Load the data
    msg = sprintf('Evaluating %s\n', tFile);
    fprintf(fid,'\n%s',msg);
    fprintf(msg)

    load(fullfile(runDir,tFile))

    %Evaluate and write to file
    msg=boundingBoxesFromLastSection.test.evaluateBoundingBoxes(testLog);
    fprintf(fid,msg);
end

fclose(fid);