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

sqmmA = zeros(length(f),1);
sqmmB = zeros(length(f),1);



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
    sqmmA(ii) = tA.sqmmMissed;
    sqmmB(ii) = tB.sqmmMissed;


end



clf 

subplot(2,2,1)
plot(sqmmA - sqmmB, '.r-')
hold on 
plot(xlim,[0,0],'k:')
grid on
hold off
xlabel('Acquisition #')
ylabel('delta square mm missed')

subplot(2,2,2)
plot(sqmmA, sqmmB, 'o')
hold on
plot(xlim,xlim,'k:')
grid on
xlabel('Sq mm missed A')
ylabel('Sq mm missed B')