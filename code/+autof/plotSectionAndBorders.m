function varargout=plotSectionAndBorders(im,stats)
% function H=plotSectionAndBorders(im,stats)
%
% Plots brain and border from output of autofindBrains


%Make figure window if needed, re-cycling an old one of possible
hFig=findobj('Tag',mfilename);

if isempty(hFig)
    hFig=figure;
    fprintf('Making figure with tag %s\n',mfilename)
    set(hFig,'Tag',mfilename);
end

clf(hFig)


%Plot a histogram along the bottom of the figure window
hAx_intensityHistogram=axes('Position', [0.025, 0.035, 0.95, 0.10], ...
    'Parent',hFig);

hist(im(:),500,'Parent',hAx_intensityHistogram)
hold(hAx_intensityHistogram,'on')
Y=ylim;
plot([stats.tThresh,stats.tThresh],ylim,'r--','Parent',hAx_intensityHistogram)
hold(hAx_intensityHistogram,'off')



%Make a large axis to display the brain section and the borders


hAx_brainBorder=axes('Position', [0.025, 0.145, 0.95, 0.85], ...
    'Parent',hFig);

imagesc(im,'Parent',hAx_brainBorder)
hold(hAx_brainBorder,'on')

colormap gray


% Overlay boundaries and enclosing boxes
for ii=1:length(stats.boundaries)
    tB = stats.boundaries{ii};

    % Plot the boundary around the brain
    hBorders(ii) = plot(tB(:,2),tB(:,1), '--', 'color', [0.5, 0.5, 1]);
end

for ii=1:length(stats.enclosingBoxes)
    %Plot the enclosing box
    encB = stats.enclosingBoxes{ii};
    hEnclosingBox(ii) = ....
    plot([encB(1), encB(1)+encB(3), encB(1)+encB(3), encB(1), encB(1)], ...
         [encB(2), encB(2), encB(2)+encB(4), encB(2)+encB(4), encB(2)], ...
         '-r', 'Parent', hAx_brainBorder);
end

hold(hAx_brainBorder,'off')
axis equal off
caxis([0,stats.tThresh*5])


% Add tags to the axes
hAx_intensityHistogram.Tag='intensityHistogram';
hAx_brainBorder.Tag='brainBorder';


if nargout>0
    H.hFig = hFig;
    H.hAx_intensityHistogram = hAx_intensityHistogram;
    H.hAx_brainBorder = hAx_brainBorder;
    H.hEnclosingBox = hEnclosingBox;
    H.hBorders = hBorders;
    varargout{1} = H;
end