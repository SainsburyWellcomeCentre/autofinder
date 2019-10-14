function pixArea=scrollStack(im)

    tileSizeInMicrons=1000; 
    micsPix = 7;

    L={};
    pixArea=0;
     for ii=1:size(im,3)
        L{ii} = autof.autofindBrains(im(:,:,ii),micsPix,1);

        ax = findobj('Tag','brainBorder');

        if ii==1;
            tL = L{1}{1};
        else 
            tL = L{ii-1}{1};
        end

        xEnd=tL(3)+tL(1);
        xP = [tL(1),xEnd];
        yEnd = tL(4)+tL(2);
        yP = [tL(2),yEnd];

        hold(ax,'on')
        %Plot in green the border of the previous section
        plot([xP(1), xP(2), xP(2), xP(1), xP(1)], ...
             [yP(1), yP(1), yP(2), yP(2), yP(1)], ...
             ':g', 'LineWidth',3, 'Parent', ax);

        
        ySizeInMicrons = tL(4) * micsPix;
        xSizeInMicrons = tL(3) * micsPix;
        xTiles = ceil(xSizeInMicrons / tileSizeInMicrons);
        yTiles = ceil(ySizeInMicrons / tileSizeInMicrons);

        %Size of tiled area to image 
        yTilesPix = (yTiles * tileSizeInMicrons)/micsPix; 
        xTilesPix = (xTiles * tileSizeInMicrons)/micsPix; 
        pixArea = pixArea + yTilesPix*xTilesPix;
       %fprintf('Last X extent: %d pixels; tiled X extent %d pixels\n', ...
       %     )
        %Top corner of this tiled area
        xpTile = [mean(xP)-(xTilesPix/2), mean(xP)+(xTilesPix/2) ];
        ypTile = [mean(yP)-(yTilesPix/2), mean(yP)+(yTilesPix/2) ];

        % Plot this
        plot([xpTile(1), xpTile(2), xpTile(2), xpTile(1), xpTile(1)], ...
             [ypTile(1), ypTile(1), ypTile(2), ypTile(2), ypTile(1)], ...
             '--g', 'LineWidth',5, 'Parent', ax);


        hold(ax,'off')

        set(gcf,'name',sprintf('%d/%d', ii, size(im,3)))
        drawnow; 

    end