function plotResultsFile(fname)
% Plot data from a single results file
%
%  function boundingBoxesFromLastSection.test.plotResultsFile(fname)
%
% Purpose
% This function helps to highlight which samples still need more work
%
% Inputs
% fname - path to results file, which will correspond to the "initial" data
%
%
% Outputs
% none
%
%
% Rob Campbell - SWC 2020


resStruct = boundingBoxesFromLastSection.test.resultsFileToStruct(fname);

if isempty(resStruct)
    return
end



f = fields(resStruct);

sqmm_sum = zeros(length(f),1);
sqmm_max = zeros(length(f),1);
extra_sum = zeros(length(f),1);
extra_max = zeros(length(f),1);
medROIareaFilled = zeros(length(f),1);

for ii=1:length(f)

    tF = resStruct.(f{ii});

    fprintf('%d. %s\n', ii, f{ii})

    % Log info for plotting
    sqmm_sum(ii) = sum(tF.sqmmMissed);
    sqmm_max(ii) = max(tF.sqmmMissed);
    extra_sum(ii) = sum(tF.sqmmExtra);
    extra_max(ii) = max(tF.sqmmExtra);
    medROIareaFilled(ii) = tF.medianROIareaWithTissue;
end



clf

subplot(4,2,1)
plot(sqmm_sum, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Square mm missed')
title('Total square mm missed (lower better)')

subplot(4,2,2)
plot(sqmm_max, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Aquare mm missed')
title('Worst section square mm missed (lower better)')

subplot(4,2,3)
plot(extra_sum, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Square mm extra')
title('Total square mm extra (lower better)')

subplot(4,2,4)
plot(extra_max, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('Aquare mm extra')
title('Section with most extra square mm (lower better)')


subplot(4,2,5)
plot(extra_sum,sqmm_sum,'.r')
hold on
xoffset = diff(xlim)*0.0075;
yoffset = diff(ylim)*0.02;
for ii=1:length(extra_sum)
    text(extra_sum(ii)+xoffset, sqmm_sum(ii)+yoffset,num2str(ii))
end
hold off
xlabel('Extra sq mm')
ylabel('Missed sq mm')

subplot(4,2,6)
hist(sqmm_sum,25)
xlabel('Missed sq mm')
ylabel('# acquisitions')


subplot(4,2,7)
plot(medROIareaFilled,'.r-')
ylim([0,1])
xlabel('Acquisition #')
ylabel('Prop ROI area filled')
grid on
