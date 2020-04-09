function compareResults(dirReference,dirTest)
% Compare fnameB to fnameA using plots and stats printed to screen
%
%  function boundingBoxesFromLastSection.test.compareResults(dirReference,dirTest)
%
% 
% Inputs
% dirReference - path to first file, which will correspond to the "initial" data
% dirTest - path to second file, which will correspond to the "new" state. 
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


% Remove any samples in the test table that don't exist in the reference table
% and then sort them both alphabetically .
missingFileInds = cellfun(@(x) isempty(strmatch(x,refTable.fileName)), ...
    testTable.fileName,'uniformoutput',false);
missingFileInds = cell2mat(missingFileInds);

if any(missingFileInds)
    fprintf('Removing %d test acquisitions not present in reference\n', sum(missingFileInds));
    testTable(find(missingFileInds),:)=[];
end

%Sort both tables alphabetically so we have data from the same sample on each row
[~,ind] = sort(refTable.fileName);
refTable = refTable(ind,:);
testTable = testTable(ind,:);



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



clf

subplot(3,2,1)
plot(refTable.totalNonImagedSqMM - testTable.totalNonImagedSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm missed')
title('Total square mm missed (lower better)')

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
plot(refTable.totalExtraSqMM - testTable.totalExtraSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm extra')
title('Total square mm extra (lower better)')

subplot(3,2,4)
plot(refTable.maxExtraSqMM - testTable.maxExtraSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test square mm extra')
title('Largest square mm increase (lower better)')

subplot(3,2,5)
plot(refTable.medPropPixelsInRoiThatAreTissue - testTable.medPropPixelsInRoiThatAreTissue, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test ROI pixels that contain tissue')
title('Median square mm increase (higher better)')



subplot(3,2,6)
plot(refTable.totalImagedSqMM - testTable.totalImagedSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('ref minus test total ROI sq mm')
title('Total ROI sq mm')




