function resStruct = resultsFileToStruct(fname)
% Convert a results file into a structure
%
%  function boundingBoxesFromLastSection.test.resultsFileToStruct(fname)
%
% Purpose
% Convert results file into a structure where the keys are file names
% and the values within them are obtained from the file.
%
% Inputs
% fname - path to the results file or directory which contains it
%
% Output
% resStruct - structure with results 
%
% Examples
% RS=boundingBoxesFromLastSection.test.resultsFileToStruct('test/200326_0823/results.txt');
% RS=boundingBoxesFromLastSection.test.resultsFileToStruct('test/200326_0823');


resStruct=struct;

if exist(fname,'dir')
    fname = fullfile(fname,'results.txt');
end
if ~exist(fname)
    fprintf('Can not find file %s\n', fnameB)
    return
end


fidR=fopen(fname,'r');

if fidR == -1
    fprintf('Failed to open %s for reading\n', fname)
    return
end


% Empty struct template for each acquisition
emptyStruct = struct(...
    'allAcquired',false, ...
    'propUnprocessedSections',0, ...
    'numStars',0, ...
    'sqmmMissed',0,...
    'sqmmExtra',0);

tline=fgets(fidR); %first line is empty

while ~isnumeric(tline)
    tline=fgets(fidR);

    if ~isempty(strfind(tline,'Evaluating'))
        tok = regexp(tline,'Evaluating log_(.*)_previewStack\.mat','tokens');
        tKey = tok{1}{1};
        resStruct.(tKey) = emptyStruct;
        starsCounter=0;
        sqmm_missed=0;
        sqmm_extra=0;
    end


    if ~isempty(strfind(tline,'GOOD '))
        resStruct.(tKey).allAcquired=true;
    end

    if ~isempty(strfind(tline,'Median area of ROIs filled'))
        tok = regexp(tline,'tissue: (.*) \(run at','tokens');
        tok = tok{1};
        resStruct.(tKey).medianROIareaWithTissue = str2num(tok{1});
    end

    if ~isempty(strfind(tline,'Total imaged sq mm in this acquisition:'))
        tok = regexp(tline,'acquisition: (.*)','tokens');
        tok = tok{1};
        resStruct.(tKey).totalImagedSqMM = str2num(tok{1});
    end

    if ~isempty(strfind(tline,'Proportion of original area'))
        tok = regexp(tline,'by ROIs: (.*)','tokens');
        tok = tok{1};
        resStruct.(tKey).propImagedArea = str2num(tok{1});
    end

    if ~isempty(strfind(tline,'WARNING -- There are ')) 
        tok = regexp(tline,'There are (\d+) sections .* only (\d+) were','tokens');
        tok = tok{1};
        resStruct.(tKey).propUnprocessedSections = str2num(tok{2})/str2num(tok{1});
    end

    if ~isempty(strfind(tline,' * S'))
        starsCounter = starsCounter+1;
    end

    if ~isempty(strfind(tline,'non-imaged'))
        tok=regexp(tline, ' tiles; (.*) sq mm', 'tokens');
        if ~isempty(tok)
            sqmm_missed(end+1) = str2num(tok{1}{1});
        end
    end

    if ~isempty(strfind(tline,'extra sq mm'))
        tok=regexp(tline, ' has (.*) extra sq mm', 'tokens');
        if ~isempty(tok)
            sqmm_extra(end+1) = str2num(tok{1}{1});
        end
    end


    % At end of each sample is an empty line. We write results now

    if length(tline)==1
        resStruct.(tKey).sqmmMissed = sqmm_missed;
        resStruct.(tKey).sqmmExtra = sqmm_extra;
        resStruct.(tKey).numStars = starsCounter;
    end

end

fclose(fidR);

%Sort keys alphabetically because we make the results file with a parfor loop
%meaning that the acquisitions are in a random order
tFields = sort(fields(resStruct));

tmp=struct;
for ii=1:length(tFields)
    tmp.(tFields{ii}) = resStruct.(tFields{ii});

end

resStruct = tmp;


