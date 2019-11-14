function varargout=brainTrackerUsingLastImage(im,noPlot,resizeStackBy,micsPix)


    if nargin<2 || isempty(noPlot)
        noPlot=false;
    end
    if nargin<3 || isempty(resizeStackBy)
        resizeStackBy=1;
    end

    if nargin<4 || isempty(micsPix)
        micsPix = 10;
    end

    if resizeStackBy~=1
        im=imresize3(im, resizeStackBy);
    end


    tileSizeInMicrons=1000; 


    L={};
    minEnclosingBoxCoords=cell(1,size(im,3));
    tileBoxCoords=cell(1,size(im,3));
    tB=[];
    for ii=1:size(im,3)
        if ii==1
            stats = autof.autofindBrainsInSection(im(:,:,ii), 'pixelSize',micsPix, 'doPlot',~noPlot, ...
                'tileSize',tileSizeInMicrons);
        else
            % Use a threshold determined from the last nImages
            nImages=5;
            if ii<=nImages
                thresh = median( [stats.medianBackground] + [stats.stdBackground]*4);
            else
                thresh = median( [stats(end-nImages+1:end).medianBackground] + [stats(end-nImages+1:end).stdBackground]*4);
            end
            [stats(ii),H] = autof.autofindBrainsInSection(im(:,:,ii), 'pixelSize',micsPix, 'tThresh',thresh,...
                            'doPlot',~noPlot, 'ROIrestrict',tB, 'tileSize',tileSizeInMicrons);

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
            xEnd = tL(3)+tL(1);
            xP = [tL(1),xEnd];
            yEnd = tL(4)+tL(2);
            yP = [tL(2),yEnd];

            x=[xP(1), xP(2), xP(2), xP(1), xP(1)];
            y=[yP(1), yP(1), yP(2), yP(2), yP(1)];
            minEnclosingBoxCoords{ii}(kk) = {[y',x']}; %For volView

            %Plot in green the border of the previous section before extending 
            %to cope with tiling
            if ~noPlot
                plot(x, y, ':g', 'LineWidth',3, 'Parent', H.hAx_brainBorder);
            end

            %TODO: we need to merge enclosing boxes of final boxes based on tiles not the minimum boxes. 



            % Overlay the box corresponding to what we would image if we have tiles.
            % This should be larger than the preceeding box in most cases
            tileEncBox = autof.region2EnclosingBox(stats(ii-1).boundaries(kk),micsPix,tileSizeInMicrons);
            tB = tileEncBox{1};
            x=[tB(1), tB(1)+tB(3), tB(1)+tB(3), tB(1), tB(1)];
            y=[tB(2), tB(2), tB(2)+tB(4), tB(2)+tB(4), tB(2)];
            tileBoxCoords{ii}(kk)={[y',x']}; %For volView

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
