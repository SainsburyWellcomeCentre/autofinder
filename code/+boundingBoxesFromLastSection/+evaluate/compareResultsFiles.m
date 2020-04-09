function compareResultsFiles(fnameA,fnameB)
% Compare fnameB to fnameA using plots and stats printed to screen
%
%  function boundingBoxesFromLastSection.test.compareResultsFiles(fnameA,fnameB)
%
% 
% Inputs
% fnameA - path to first file, which will correspond to the "initial" data
% fnameB - path to second file, which will correspond to the "new" state. 
%
%
% Outputs
% none
%
%
% Rob Campbell - SWC 2020


resStructA = boundingBoxesFromLastSection.test.resultsFileToStruct(fnameA);
resStructB = boundingBoxesFromLastSection.test.resultsFileToStruct(fnameB);

if isempty(resStructA) || isempty(resStructB)
    return
end



f = fields(resStructA);

sqmmA_sum = zeros(length(f),1);
sqmmB_sum = zeros(length(f),1);

sqmmA_max = zeros(length(f),1);
sqmmB_max = zeros(length(f),1);

extraA_sum = zeros(length(f),1);
extraB_sum = zeros(length(f),1);

extraA_max = zeros(length(f),1);
extraB_max = zeros(length(f),1);

medROIareaFilledA = zeros(length(f),1);
medROIareaFilledB = zeros(length(f),1);

totalROIareA = zeros(length(f),1);
totalROIareB = zeros(length(f),1);

for ii=1:length(f)
    if ~isfield(resStructB,f{ii});
        continue
    end
    tA = resStructA.(f{ii});
    tB = resStructB.(f{ii});

    fprintf('%d. %s\n', ii, f{ii})

    % Reports to CLI
    if tB.propUnprocessedSections>0 && tA.propUnprocessedSections==0
        fprintf('BAD -- %s developed unprocessed sections when none previously existed.\n',f{ii})
    end

    if tB.propUnprocessedSections==0 && tA.propUnprocessedSections>0
        fprintf('GOOD -- %s had unprocessed sections but now has none.\n',f{ii})
    end

    % Log info for plotting
    sqmmA_sum(ii) = sum(tA.sqmmMissed);
    sqmmB_sum(ii) = sum(tB.sqmmMissed);

    sqmmA_max(ii) = max(tA.sqmmMissed);
    sqmmB_max(ii) = max(tB.sqmmMissed);

    extraA_sum(ii) = sum(tA.sqmmExtra);
    extraB_sum(ii) = sum(tB.sqmmExtra);

    extraA_max(ii) = max(tA.sqmmExtra);
    extraB_max(ii) = max(tB.sqmmExtra);

    medROIareaFilledA(ii) = tA.medianROIareaWithTissue;
    medROIareaFilledB(ii) = tB.medianROIareaWithTissue;

    totalROIareA(ii) = tA.totalImagedSqMM;
    totalROIareB(ii) = tB.totalImagedSqMM;
end



clf

subplot(3,2,1)
plot(sqmmB_sum - sqmmA_sum, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A square mm missed')
title('Total square mm missed (lower better)')

subplot(3,2,2)
plot(sqmmB_max - sqmmA_max, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A square mm missed')
title('Worst section square mm missed (lower better)')

subplot(3,2,3)
plot(extraB_sum - extraA_sum, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A square mm extra')
title('Total square mm extra (lower better)')

subplot(3,2,4)
plot(extraB_max - extraA_max, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A square mm extra')
title('Largest square mm increase (lower better)')

subplot(3,2,5)
plot(medROIareaFilledB - medROIareaFilledA, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A ROI pixels that contain tissue')
title('Median square mm increase (higher better)')



subplot(3,2,6)
plot(totalROIareB - totalROIareA, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('B minus A total ROI sq mm')
title('Total ROI sq mm')




