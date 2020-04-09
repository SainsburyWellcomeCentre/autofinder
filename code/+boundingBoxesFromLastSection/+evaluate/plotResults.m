function plotResults(testDir)
% Make summary plots of all data in a test directory
%
%  function boundingBoxesFromLastSection.test.plotResults(testDir)
%
% Purpose
% This function helps to highlight which samples still need more work. If
% run with no input argument, it works in the current directory. 
%
% Inputs
% testDir - path test directory. Optional. 
%
%
% Outputs
% none
%
%
% Rob Campbell - SWC 2020


summaryTable = getSummaryTable(testDir);
if isempty(summaryTable)
    return 
end


%report to screen the file name and index of each recording
for ii=1:size(summaryTable,1)
    fprintf('%d/%d. %s\n', ii, size(summaryTable,1), ...
        summaryTable.fileName{ii});
end

% Report recordings with unprocessed sections
f=find(summaryTable.numUnprocessedSections>0);
if ~isempty(f)
    fprintf('\n\n ** The following recordings have unprocessed sections:\n')
    for ii=1:length(f)
            fprintf('%d/%d. %s -- %d unprocessed sections. tThresh SD=%0.2f\n', f(ii), size(summaryTable,1), ...
        summaryTable.fileName{f(ii)}, summaryTable.numUnprocessedSections(f(ii)), ...
        summaryTable.tThreshSD(f(ii))     );
    end
end

clf

subplot(4,2,1)
plot(summaryTable.totalNonImagedSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Square mm missed')
title('Total square mm missed (lower better)')

subplot(4,2,2)
plot(summaryTable.totalNonImagedSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Aquare mm missed')
title('Worst section square mm missed (lower better)')

subplot(4,2,3)
plot(summaryTable.totalImagedSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Square mm extra')
title('Total square mm extra (lower better)')

subplot(4,2,4)
plot(summaryTable.maxExtraSqMM, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Aquare mm extra')
title('Section with most extra square mm (lower better)')


subplot(4,2,5)
plot(summaryTable.totalImagedSqMM,summaryTable.totalNonImagedSqMM,'.r')
hold on
xoffset = diff(xlim)*0.0075;
yoffset = diff(ylim)*0.02;
for ii=1:length(summaryTable.totalImagedSqMM)
    text(summaryTable.totalImagedSqMM(ii)+xoffset, summaryTable.totalNonImagedSqMM(ii)+yoffset,num2str(ii))
end
hold off
xlabel('Extra sq mm')
ylabel('Missed sq mm')

subplot(4,2,6)
nBins=round(length(summaryTable.totalNonImagedSqMM)/5);
if nBins<5
    nBins=5;
end
hist(summaryTable.totalNonImagedSqMM,nBins)
x=xlim;
xlim([0,x(2)]);
xlabel('Missed sq mm')
ylabel('# acquisitions')



subplot(4,2,7)
plot(summaryTable.propImagedArea,'.r-')
mu=mean(summaryTable.propImagedArea);
hold on
plot([xlim],[mu,mu],'--b')
hold off
xlabel('Acquisition #')
ylabel('Total imaged sq mm')
title(sprintf('Prop orig area covered by ROIs (mean=%0.3f)', mu))
ylim([0,1])
grid on

subplot(4,2,8)
plot(summaryTable.medPropPixelsInRoiThatAreTissue,'.r-')
mu = mean(summaryTable.medPropPixelsInRoiThatAreTissue);
hold on
plot([xlim],[mu,mu],'--b')
hold off

ylim([0,1])
xlabel('Acquisition #')
ylabel('Prop ROI area filled')
title('Proportion of imaged ROI that is filled with tissue')
grid on
