function checkBToutput
    % throwaway function that checks whether the tile positions and preview scans seem to match from a BT acquisition
    % run from sample directory

    d=dir('rawData/*-*');
    d=d([d.isdir]);


    for ii=length(d):-1:1
        posFname = fullfile(d(ii).folder,d(ii).name,'tilePositions.mat');
        previewFname = fullfile(d(ii).folder,d(ii).name,'sectionPreview.mat');

        if ~exist(posFname,'file') || ~exist(previewFname,'file')
            continue
        end

        load(posFname,'positionArray')
        load(previewFname,'sectionPreview')

        previewSize(ii) = prod(size(sectionPreview.imStack));
        posLength(ii) = size(positionArray,1);
    end

    clf
    colororder({'r','k'})
    x=1:length(d);
    yyaxis left
    h1=plot(x,posLength,'-o','markerfacecolor','r');
    ylabel('Number of tile positions')

    yyaxis right
    h1=plot(x,previewSize,'-s','markerfacecolor','k');
    ylabel('Number of pixels in preview image')

    xlabel('section number')

    % overlay lines wherever the number of positions changes
    yyaxis left
    if length(posLength)>20
        hold on
        f=find(diff(posLength)~=0);
        for ii=1:length(f)
            plot([f(ii),f(ii)],ylim,'r:')
        end
        hold off
    end
    grid
