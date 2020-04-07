function report_auto_thresh_notes
% Exploratory. Report to CLI the smaple name and notes from the auto thresh
%
%  function boundingBoxesFromLastSection.test.report_auto_thresh_notes
%
% Purpose
% To see which samples were handled how. cd to dir with log files and run
% Make a plot too.
%
% Inputs
% none
%
%
% Outputs
% none
%
%
% Rob Campbell - SWC 2020



logFiles = dir('log_*.mat');

SNRall=zeros(1,length(logFiles));
isLow=zeros(1,length(logFiles));
tThreshSDAll=zeros(1,length(logFiles));

for ii=1:length(logFiles)
    load(logFiles(ii).name)
    notes = testLog(1).autothreshStats(1).notes;
    notes = strtrim(notes);

    tThreshSDAll(ii)=testLog(1).tThreshSD;
    % Find the SNR of the closest tThresh we have
    tTvec = [testLog(1).autothreshStats.tThreshSD];
    d = abs(tTvec - testLog(1).tThreshSD);
    [~,ind] = min(d);
    SNR = testLog(1).autothreshStats(ind).SNR.medThreshRatio;
    fprintf('%d/%d %s -- SNR: %0.2f -- %s\n', ...
        ii, length(logFiles), logFiles(ii).name, SNR, notes)

    SNRall(ii) = SNR;
    if ~isempty(strfind(notes,'Low '))
        isLow(ii)=1;
    end
end

% Make a plot
clf
ind=1:length(logFiles);

subplot(2,2,1)
plot(ind,SNRall,'.-k')
hold on
plot(ind(find(isLow)),SNRall(find(isLow)),'or')
hold off
title('Highlighted points went through low SNR alg')


subplot(2,2,2)
hist(SNRall,round(length(logFiles)/2))
[y,x]=hist(SNRall,round(length(logFiles)/2));

cy=cumsum(y);
cy=cy/max(cy);
yyaxis right
plot(x,cy,'-ro','linewidth',2,'markerfacecolor',[1,0.5,0.4])



subplot(2,2,3)
plot(tThreshSDAll,SNRall,'ok','markerfacecolor',[1,1,1]*0.5)
plot(tThreshSDAll,SNRall,'.')
hold on 
for ii=1:length(logFiles)
    t=text(tThreshSDAll(ii), SNRall(ii), num2str(ii));
    if isLow(ii)
        t.Color='r';
    end
end
hold off
xlabel('tThreshSD')
ylabel('SNR')
grid