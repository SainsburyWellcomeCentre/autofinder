function addToPath
% Adds this current autofinder directory to the MATLAB path.
%
% Purpose
% Removes any existing autofinder paths and adds the current one to the path. 
% The code directory is added only. This function is used to temporarily
% add autofinder to the path for testing purposes:
% The we create a second (or third!) clone of autofinder. Start MATLAB. 
% Adds the clone to the path and run tests. This allows us to keep working
% as normal whilst tests run in the background on an independent copy


currentPath=fullfile(pwd,'code');

if exist('autoROI','file')
    % It's already somewhere in the path and needs to be removed
    pathToRepo = which('autoROI');
    tok=regexp(pathToRepo,'(.*code)','tokens');

    pathToRepo=tok{1}{1};

    if strcmp(pathToRepo,currentPath)
        fprintf('Current repo is already in the path.\n')
        return
    end

    if ~isempty(pathToRepo)
        fprintf('Removing %s from MATLAB path.\n', pathToRepo)
        rmpath(pathToRepo)
    end


    if exist('autoROI','file')
        fprintf('Failed to remove existing repo. Quitting\n')
        return
    end
end


currentPath=fullfile(pwd,'code');
fprintf('Adding %s to MATLAB path.\n', currentPath)
addpath(currentPath)