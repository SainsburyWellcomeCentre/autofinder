function out=batchAllBrains


d=dir(pwd);
d(~[d.isdir])=[];
d(1:2)=[];

out={};
for ii=1:length(d)
    out{ii}=handleBrainsInDir(d(ii).name);
end



function OUT=handleBrainsInDir(tDir)
    files = dir(fullfile(tDir,'*.mat'));
    for ii=1:length(files)
        fname=fullfile(tDir,files(ii).name);
        fprintf('Loading %s...',fname)
        load(fname)
        fprintf(' processing\n')

        try
            borders=autof.brainTrackerUsingLastImage(pStack,true);
        catch
            borders=nan;
        end

        OUT(ii).fname=fname;
        OUT(ii).borders=borders;
    end

