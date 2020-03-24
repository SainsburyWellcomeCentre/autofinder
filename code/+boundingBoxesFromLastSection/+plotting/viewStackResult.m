function varargout = viewStackResult(fname,imRange)
% Overlay bounding box on current axes
%
% h=boundingBoxesFromLastSection.plotting.viewStackResult(fname,imRange)
%
% Purpose
% Load data into volView to see results of an anlysis. Optionally
% return handle to volView. 
%
% Inputs
% fname - path to file
% imRange - optional ([1,200] by default) if supplied, this is the 
%           displayed range in volView.
% 
% Rob Campbell - March 2020

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
