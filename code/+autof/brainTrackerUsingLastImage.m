function varargout=brainTrackerUsingLastImage(im,noPlot)


    if nargin<2
        noPlot=false;
    end
    tileSizeInMicrons=1000; 
    micsPix = 7;

    L={};
    minEnclosingBoxCoords=cell(1,size(im,3));
    tileBoxCoords=cell(1,size(im,3));
    for ii=1:size(im,3)
        if ii==1
            stats = autof.autofindBrainsInSection(im(:,:,ii),'pixelSize',micsPix,'doPlot',~noPlot);
        else
            % Use a threshold determined from the last image
            thresh = stats(end).meanBackground + stats(end).stdBackground*4; 
            % TODO: add an input argument to restrict the autofind to a particular region <-- WE AREN'T USING THE LAST IMAGE!!!!
            [stats(ii),H] = autof.autofindBrainsInSection(im(:,:,ii),'pixelSize',micsPix,'tThresh',thresh,'doPlot',~noPlot);
        end

        if ii==1
            continue
        end


        lastEncBoxes = stats(ii-1).enclosingBoxes;

        if noPlot
            if mod(ii,5)==0, fprintf('.'), end
        else
            hold(H.hAx_brainBorder,'on')
        end

        for kk = 1:length(lastEncBoxes)
            tL = lastEncBoxes{kk};
            xEnd=tL(3)+tL(1);
            xP = [tL(1),xEnd];
            yEnd = tL(4)+tL(2);
            yP = [tL(2),yEnd];

            x=[xP(1), xP(2), xP(2), xP(1), xP(1)];
            y=[yP(1), yP(1), yP(2), yP(2), yP(1)];
            minEnclosingBoxCoords{ii}(kk)={[y',x']}; %For volView

            %Plot in green the border of the previous section before extending 
            %to cope with tiling
            if ~noPlot
                plot(x, y, ':g', 'LineWidth',3, 'Parent', H.hAx_brainBorder);
            end

            %TODO: we need to merge enclosing boxes of final boxes based on tiles not the minimum boxes. 



            % Overlay the box corresponding to what we would image if we have tiles.
            % This should be larger than the preceeding box in most cases
            tileEncBox=autof.region2EnclosingBox(stats(ii-1).boundaries(kk),micsPix,tileSizeInMicrons);
            tB = tileEncBox{1};
            x=[tB(1), tB(1)+tB(3), tB(1)+tB(3), tB(1), tB(1)];
            y=[tB(2), tB(2), tB(2)+tB(4), tB(2)+tB(4), tB(2)];
            tileBoxCoords{ii}(kk)={[y',x']};%For volView
            % Plot this
            if ~noPlot
                plot(x, y, '--g', 'LineWidth',5, 'Parent', H.hAx_brainBorder);
            end


            % TODO: 
            % Assume that we imaged this area and then check if there is tissue extending
            % up to the border. If so, we add tiles to areas where this is happening. 
            % This means we will add quite small increaases. 

            % TODO: generate warning if this will still miss brain

        end

        if ~noPlot
            hold(H.hAx_brainBorder,'off')

            set(H.hFig,'name',sprintf('%d/%d', ii, size(im,3)))
            drawnow
        end

    end

    if noPlot, fprintf('\n'), end

    if nargout>0
        %For volView
        boundariesForPlotting.border{1} = {stats(:).boundaries};
        boundariesForPlotting.minEnclosingBoxCoords{1} = minEnclosingBoxCoords;
        boundariesForPlotting.tileBoxCoords{1} = tileBoxCoords;
        varargout{1}=boundariesForPlotting;
    end
    if nargout>1
        varargout{2} = stats;
    end
