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


% These are the available pStack files
pStacks = dir(fullfile(pwd,'*_previewStack.mat'));

if isempty(pStacks)
    fprintf('Found no preview stacks in the current directory\n')
    return
end



% Loop through each result file 
evaltxtFname = fullfile(runDir,'results.txt');

fid=fopen(evaltxtFname,'w');

for ii=1:length(resultFiles)
	tFile = resultFiles(ii).name;

	% Can we find an original pStack file for this?
	ind=strmatch(strrep(tFile,'log_',''), {pStacks.name});
	if isempty(ind)
		fprintf('Found no pStack file called %s in the current directory. SKIPPING.\n', strrep(tFile,'log_',''))
		continue
	end

	% Load the data
	fprintf('Evaluating %s\n', pStacks(ind).name)
	load(pStacks(ind).name)
	load(fullfile(runDir,tFile))

	%Evaluate and write to file
	fprintf(fid,'\nSample %s\n', pStacks(ind).name);
	msg=boundingBoxesFromLastSection.test.evaluateBoundingBoxes(pStack,testLog);
	fprintf(fid,msg);
end

fclose(fid);