function varargout = genSummaryTable(dirToProcess)
% Generate a summary table for a test directory
%
% function summaryTable = boundingBoxFromLastSection.evaluate.genSummaryTable(dirToProcess)
%
%
% Purpose
% Load all testLog files in a test directory and condense the key infofmation into a single table.
% Works in current directory if no directory is provided as input. The summary table is written
% into the test directory and also optionally returned as an output argument. The table is saved
% as a file called summary_table.mat containing a variable called 'summaryTable'.
%
% Inputs
% dirToProcess - Path to test directory to process. If missing, it attempt to run on the current dir.
%
%
% Outputs
% summaryTable - summary table.
%
%
% Rob Campbell - SWC 2020


if nargin<1
    dirToProcess=pwd;
end

tLogs = dir(fullfile(dirToProcess,'log_*.mat'));

if isempty(tLogs)
    fprintf('No testLog .mat files found in directory %s\n', dirToProcess)
    return
end


% Pre-allocate the variables that we will later use to build the table
n=length(tLogs);
fileName = {tLogs.name}';
pStackFname = cell(n,1);
tThreshSD = zeros(n,1);
rollingThreshold = zeros(n,1);
autoThreshold = zeros(n,1);
numSectionsWithHighCoverage = zeros(n,1);
numUnprocessedSections = zeros(n,1);
medPropPixelsInRoiThatAreTissue = zeros(n,1);
totalImagedSqMM = zeros(n,1);
propImagedArea = zeros(n,1);
nSamples = zeros(n,1);
isProblemCase = zeros(n,1);

totalNonImagedTiles = zeros(n,1);
totalNonImagedSqMM = zeros(n,1);
totalExtraSqMM = zeros(n,1);
maxNonImagedTiles = zeros(n,1);
maxNonImagedSqMM = zeros(n,1);
maxExtraSqMM = zeros(n,1);
nPlanesWithMissingBrain = zeros(n,1);

autothresh_notes = cell(n,1);
autothresh_SNR = zeros(n,1);
autothresh_tThreshSD = zeros(n,1);


fprintf('\nGenerating summary table:\n')
for ii=1:n
    fname=fullfile(dirToProcess,fileName{ii});
    fprintf('Processing %s\n',fname)
    load(fname)

    % Populate variables
    pStackFname{ii} = testLog(1).stackFname;
    tThreshSD(ii) = testLog(1).tThreshSD;
    rollingThreshold(ii) = testLog(1).rollingThreshold;
    autoThreshold(ii) = testLog(1).autothresh;
    numSectionsWithHighCoverage(ii) = testLog(1).report.numSectionsWithHighCoverage;
    numUnprocessedSections(ii) = testLog(1).numUnprocessedSections;

    medPropPixelsInRoiThatAreTissue(ii) = testLog(1).report.medPropPixelsInRoiThatAreTissue;
    totalImagedSqMM(ii) = testLog(1).report.totalImagedSqMM;
    propImagedArea(ii) = testLog(1).report.propImagedArea;
    nSamples(ii) = testLog(1).nSamples;

    % Get auto-thresh info
    if ~isempty(strfind(pStackFname{ii},'problemCases'))
        isProblemCase(ii) = 1;
    end
    [autothresh_notes{ii}, autothresh_tThreshSD(ii), autothresh_SNR(ii)] = returnAutoThreshSummaryStats(testLog);

    % Get more info from report structure
    totalNonImagedTiles(ii) = sum(testLog(1).report.nonImagedTiles);
    totalNonImagedSqMM(ii) = sum(testLog(1).report.nonImagedSqMM);
    totalExtraSqMM(ii) = sum(testLog(1).report.extraSqMM);

    maxNonImagedTiles(ii) = max(testLog(1).report.nonImagedTiles);
    maxNonImagedSqMM(ii) = max(testLog(1).report.nonImagedSqMM);
    maxExtraSqMM(ii) = max(testLog(1).report.extraSqMM);

    nPlanesWithMissingBrain(ii) = max(testLog(1).report.nPlanesWithMissingBrain);
end


summaryTable = table(fileName, tThreshSD, rollingThreshold, autoThreshold, numSectionsWithHighCoverage, ...
    medPropPixelsInRoiThatAreTissue, totalImagedSqMM, propImagedArea,nSamples,isProblemCase, ...
    numUnprocessedSections, autothresh_notes, autothresh_tThreshSD, autothresh_SNR, ...
    totalNonImagedTiles, totalNonImagedSqMM, totalExtraSqMM, ...
    maxNonImagedTiles, maxNonImagedSqMM, maxExtraSqMM,nPlanesWithMissingBrain, ...
    pStackFname);


% Save the table to disk
save(fullfile(dirToProcess,'summary_table.mat'),'summaryTable')

if nargout>0
    varargout{1}=summaryTable;
end


function [notes, tThreshSD, SNR] = returnAutoThreshSummaryStats(testLog)
    % Get the autoThresh stats from the case that best matches the finally chosen
    % tThreshSD that was returned by the auto-thresholder

    notes = testLog(1).autothreshStats(1).notes;
    notes = strtrim(notes);

    tThreshSDactual=testLog(1).tThreshSD;

    % Find the SNR of the closest tThresh we have
    tTvec = [testLog(1).autothreshStats.tThreshSD];
    d = abs(tTvec - testLog(1).tThreshSD);
    [~,ind] = min(d);
    tThreshSD = tTvec(ind);
    SNR = testLog(1).autothreshStats(ind).SNR_medThreshRatio;