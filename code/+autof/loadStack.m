function imStack=loadStack(fname)
% function imStack=loadStack(fname)
%
%
% Load and filter a stack and return as a 3d matrix



if ~exist(fname)
    fprintf('File %s does not exist\n', fname);
    return
end

[~,~,ext] = fileparts(fname);
if strcmp(ext,'.mat')
    fprintf('Loading %s\n', fname)
    L = load(fname);
    f=fields(L);
    imStack = L.(f{1});
    fprintf('Median filtering each plane\n')
    imStack = medfilt3(imStack,[3,3,1]);
elseif strcmp(ext,'.tif') || strcmp(ext,'.tiff')
    fprintf('Loading %s\n', fname)
    imStack =  autof.filterStack(load3Dtiff(fname));
else
    fprintf('Unknown image format: %s\n', fname)
    return
end

