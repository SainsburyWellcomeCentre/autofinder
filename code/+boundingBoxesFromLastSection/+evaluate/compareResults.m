function compareResults(dirReference,dirTest,varargin)
% Compare fnameB to fnameA using plots and stats printed to screen
%
%  function boundingBoxesFromLastSection.test.compareResults(dirReference,dirTest)
%
% 
% Inputs
% dirReference - path to first file, which will correspond to the "initial" data
% dirTest - path to second file, which will correspond to the "new" state. 
%
% Optional Inputs (param/val pairs)
% excludeIndex - vector of acquisition idexes to exclude from plotting.
%
%
% Outputs
% none
%
%
% Rob Campbell - SWC 2020


refTable = getSummaryTable(dirReference);
testTable = getSummaryTable(dirTest);

if isempty(refTable) || isempty(testTable)
    return
end


params = inputParser;
params.CaseSensitive=false;
params.addParameter('excludeIndex',[],@isnumeric)

params.parse(varargin{:})
excludeIndex = params.Results.excludeIndex;


% Remove any samples in the test table that don't exist in the reference table
% and then sort them both alphabetically .
missingFileInds = cellfun(@(x) isempty(strmatch(x,refTable.fileName)), ...
    testTable.fileName,'uniformoutput',false);
missingFileInds = cell2mat(missingFileInds);

if any(missingFileInds)
    fprintf('Removing %d test acquisitions not present in reference table\n', sum(missingFileInds));
    testTable(find(missingFileInds),:)=[];
end

% Now remove any samples in the reference table that aren't in the test table
missingFileInds = cellfun(@(x) isempty(strmatch(x,testTable.fileName)), ...
    refTable.fileName,'uniformoutput',false);
missingFileInds = cell2mat(missingFileInds);

if any(missingFileInds)
    fprintf('Removing %d reference acquisitions not present in test table\n', sum(missingFileInds));
    refTable(find(missingFileInds),:)=[];
end



%Sort both tables alphabetically so we have data from the same sample on each row
%Then sort by sqmm missed in ref table
[~,ind] = sort(refTable.fileName);
refTable = refTable(ind,:);
testTable = testTable(ind,:);

[~,ind] = sort(refTable.totalNonImagedSqMM);
refTable = refTable(ind,:);
testTable = testTable(ind,:);


% Optionally exclude indexes
if ~isempty(excludeIndex)
    refTable(excludeIndex,:)=[];
    testTable(excludeIndex,:)=[];
end


%report to screen the file name and index of each recording
for ii=1:size(refTable,1)
    fprintf('%d/%d. %s\n', ii, size(refTable,1), ...
        refTable.fileName{ii});
end


% Issue some reports to screen
d=refTable.numUnprocessedSections - testTable.numUnprocessedSections;
f=find(d>0);
if isempty(f)
    for ii=1:length(f)
        fprintf('GOOD -- %d/%d. %s now has fewer unprocessed sections: %d -> %d\n', ...
            f(ii), size(refTable,1), refTable.fileName{f(ii)}, ...
            refTable.numUnprocessedSections(f(ii)), testTable.numUnprocessedSections(f(ii)) )
    end
end

f=find(d<0);
if isempty(f)
    for ii=1:length(f)
        fprintf('BAD -- %d/%d. %s now has more unprocessed sections: %d -> %d\n', ...
            f(ii), size(refTable,1), refTable.fileName{f(ii)}, ...
            refTable.numUnprocessedSections(f(ii)), testTable.numUnprocessedSections(f(ii)) )
    end
end


% Get the plot settings
pS = plotSettings;


clf

subplot(3,2,1)
plot(refTable.totalNonImagedSqMM - testTable.totalNonImagedSqMM, pS.basePlotStyle{:})
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm missed')
title('Total square mm missed (lower better)')
xlim([1,size(refTable,1)])

subplot(3,2,2)
%plot(sqmmB_max - sqmmA_max, '.r-')
%hold on 
%%plot(xlim,[0,0],'k:')
%grid on
%hold off
%xlabel('Acquisition #')
%ylabel('B minus A square mm missed')
%title('Worst section square mm missed (lower better)')

subplot(3,2,3)
plot(refTable.totalExtraSqMM - testTable.totalExtraSqMM, pS.basePlotStyle{:})
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm extra')
title('Total square mm extra (lower better)')
xlim([1,size(refTable,1)])

subplot(3,2,4)
plot(refTable.maxExtraSqMM - testTable.maxExtraSqMM, pS.basePlotStyle{:})
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm extra')
title('Largest square mm increase (lower better)')
xlim([1,size(refTable,1)])


subplot(3,2,5)
plot(refTable.medPropPixelsInRoiThatAreTissue - testTable.medPropPixelsInRoiThatAreTissue, pS.basePlotStyle{:})
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test ROI pixels that contain tissue')
title('Median square mm increase (higher better)')
xlim([1,size(refTable,1)])


subplot(3,2,6)
plot(refTable.totalImagedSqMM - testTable.totalImagedSqMM, pS.basePlotStyle{:})
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test total ROI sq mm')
title('Total ROI sq mm')
xlim([1,size(refTable,1)])



