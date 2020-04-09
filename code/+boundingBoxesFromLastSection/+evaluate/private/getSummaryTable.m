function summaryTable = getSummaryTable(testDir)
% Local helper function for getting the summary table.
% Avoids boilerplate. 


if nargin<1 || isempty(testDir)
    testDir=pwd;
end

fname = fullfile(testDir,'summary_table.mat');

if ~exist(fname,'file')
    fprintf('No summary_table.mat file found.\n');
    summaryTable = [];
    return
else
    load(fname)
end

