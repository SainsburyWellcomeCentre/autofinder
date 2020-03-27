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
    return
end


tline=fgets(fidR); %first line is empty

starsCounter=0;
sqMM_missed=[];
sqMM_extra=[];

while ~isnumeric(tline)
    tline=fgets(fidR);

    if ~isempty(strfind(tline,'Evaluating'))
        fprintf(fidD,tline);
        starsCounter=0;
        sqMM_missed=0;
        sqMM_extra=0;
    end

    if ~isempty(strfind(tline,'GOOD ')) || ~isempty(strfind(tline,'WARNING ')) 
        fprintf(fidD,tline);
    end

    if ~isempty(strfind(tline,' * S'))
        starsCounter = starsCounter+1;
    end

    if ~isempty(strfind(tline,' non-imaged '))
        tok=regexp(tline, ' tiles; (.*) sq mm', 'tokens');
        if ~isempty(tok)
            sqMM_missed(end+1) = str2num(tok{1}{1});
        end
    end

    if ~isempty(strfind(tline,' extra sq mm due to '))
        tok=regexp(tline, ' has (.*) extra sq mm', 'tokens');
        if ~isempty(tok)
            sqMM_extra(end+1) = str2num(tok{1}{1});
        end
    end

    % At end of each sample is an empty line. We write results now

    if length(tline)==1
        fprintf(fidD,'Total square mm missed = %0.1f\n', sum(sqMM_missed));
        fprintf(fidD,'Worst section sq mm missed = %0.1f\n', max(sqMM_missed));
        fprintf(fidD,'Num sq mm stars = %d\n\n',starsCounter);
        fprintf(fidD,'Total extra square mm added = %0.1f\n', sum(sqMM_extra));
        fprintf(fidD,'Worst section extra sq mm added = %0.1f\n', max(sqMM_extra));
    end

end

fclose(fidD);
fclose(fidR);
