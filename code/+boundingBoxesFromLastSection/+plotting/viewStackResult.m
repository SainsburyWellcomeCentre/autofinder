function varargout = viewStackResult(fname,imRange)
% Overlay bounding box on current axes
%
% h=boundingBoxesFromLastSection.plotting.viewStackResult(fname,imRange)
%
% Purpose
% Load data into volView based on a stack result file to see results of an anlysis. 
% Optionally return handle to volView. 
%
% Inputs
% fname - path to file. If empty or missing a GUI comes up.
% imRange - optional ([1,200] by default) if supplied, this is the 
%           displayed range in volView.
%
%
% Example
% >> boundingBoxesFromLastSection.plotting.viewStackResult('200330_1657/log_CC_125_1__125_2_previewStack.mat')
%
% Rob Campbell - March 2020

if nargin<1 || isempty(fname)
    [fname,tpath] = uigetfile(pwd);
    fname = fullfile(tpath,fname);
    fprintf('Opening %s\n',fname)
end

if ~exist(fname,'file')
    fprintf('Can not find %d\n', fname);
    return
end

if nargin<2
    imRange=[1,200];
end

load(fname)

fprintf('Loading %s\n',testLog(1).stackFname)
load(testLog(1).stackFname)

b={{testLog.BoundingBoxes},{},{}};;


H=volView(pStack.imStack,imRange,b);


% Optionally return handle to plot object
if nargout>0
    varargout{1}=H;
end
