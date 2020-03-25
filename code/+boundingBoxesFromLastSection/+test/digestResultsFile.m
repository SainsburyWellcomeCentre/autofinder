function digestResultsFile(fname)
% Read in results file in test dir and produce a summary version
%
% function boundingBoxesFromLastSection.test.digestResultsFile(fname)
%
% Purpose
% With fixed number of summary lines per sample
%
% Inputs
% fname - path to results.txt file in test directory
%
%


if ~exist(fname)
    fprintf('Can not find file %s\n', fname)
    return
end

pathToFile = fileparts(fname);

digestFname = 'results_digest.txt';



% Open files for reading and writing
fidD=fopen(fullfile(pathToFile,digestFname),'w+');
fidR=fopen(fname,'r');

if fidR == -1
    fprintf('Failed to open %s for reading\n', fname)
end


tline='STARTSTART'; % Just a marker so the loop starts

starsCounter=0;
totalSqMM_missed=0;

while ~isnumeric(tline)
    tline=fgets(fidR);

    if ~isempty(strfind(tline,'Evaluating'))
        fprintf(fidD,tline);
        starsCounter=0;
        totalSqMM_missed=0;
    end

    if ~isempty(strfind(tline,'GOOD ')) || ~isempty(strfind(tline,'WARNING ')) 
        fprintf(fidD,tline);
    end

    if ~isempty(strfind(tline,' * S'))
        starsCounter = starsCounter+1;
    end

    if ~isempty(strfind(tline,' sq mm'))
        tok=regexp(tline, ' tiles; (.*) sq mm', 'tokens');
        if ~isempty(tok)
            totalSqMM_missed = totalSqMM_missed + str2num(tok{1}{1});
        end
    end

    % At end of each sample is an empty line. We write results now

    if length(tline)==1
        fprintf(fidD,'Total square mm missed = %0.1f\n', totalSqMM_missed);
        fprintf(fidD,'Num stars = %d\n\n',starsCounter);

    end

end

fclose(fidD);
fclose(fidR);
