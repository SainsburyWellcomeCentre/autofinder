function out=evaluateBoundingBoxes(stats)
% Evaluate how well the bounding boxes capture the brain
%
%   function out=evaluateBoundingBoxes(stats)
%
% Purpose
% Report accuracy of brain finding. Shows images of failed sections
% if no outputs were requested. 
%
% Inputs
% The pStackLog file in test directory
%
% Example
% testLog  = boundingBoxesFromLastSection.test.runOnStackStruct(testLog)
% boundingBoxesFromLastSection.test.evaluateBoundingBoxes(testLog)
%
% Outputs
% out - A string describing how well this sample registered. This
%       is so we can write text files for multiple sumples to summarize
%       the performance of the algorithm. 


% Look for pStack file to load

pStackFname = stats(1).stackFname;
if ~exist(pStackFname,'file')
    out = sprintf('No pStack file found at %s\n', pStackFname);
    fprintf(out)
    return
else
    load(pStackFname)
end


BW=pStack.binarized;
nPlanesWithMissingBrain=0;

out = '';
for ii=1:size(pStack.binarized,3)

    for jj=1:length(stats(ii).BoundingBoxes)
        % All pixels that are within the bounding box should be zero
        bb=stats(ii).BoundingBoxes{jj};

        bb(bb<=0)=1; %In case boxes have origins outside of the image

        BW(bb(2):bb(2)+bb(4), bb(1):bb(1)+bb(3),ii)=0;
    end

    % Any non-zero pixels indicate non-imaged sample areas
    nonImagedPixels = sum(BW(:,:,ii),[1,2]);

    if nonImagedPixels>0
        nPlanesWithMissingBrain = nPlanesWithMissingBrain + 1;

        if nargout==0
            imagesc(pStack.imStack(:,:,ii));

            % Overlay the brain border
            hold on
            for jj=1:length(pStack.borders{1}{ii})
                tBorder = pStack.borders{1}{ii}{jj};
                plot(tBorder(:,2),tBorder(:,1), '--c')
                plot(tBorder(:,2),tBorder(:,1), ':g','LineWidth',1)
            end        
            hold off

            % Overlay bounding boxes
            for jj=1:length(stats(ii).BoundingBoxes)
                bb=stats(ii).BoundingBoxes{jj};
                boundingBoxesFromLastSection.plotting.overlayBoundingBox(bb);
            end


            set(gcf,'Name',sprintf('%d/%d',ii,size(pStack.binarized,3)))
            caxis([0,300])
            drawnow
            pause
        end
        % How many pixels fell outside of the area?
        pixelsInATile = round(pStack.tileSizeInMicrons/pStack.voxelSizeInMicrons)^2;
        nonImagedTiles = nonImagedPixels/pixelsInATile;
        if nonImagedTiles>1
            warnStr = ' * ';
        elseif nonImagedTiles>2
            warnStr = ' ** ';
        elseif nonImagedTiles>3
            warnStr = ' *** ';
        else
            warnStr = '';
        end

        msg = sprintf('%sSection %03d/%03d, %d ROIs, %d non-imaged pixels; %0.3f tiles; %0.3f sq mm \n', ...
            warnStr, ...
            ii, ...
            size(pStack.binarized,3), ...
            length(stats(ii).BoundingBoxes), ...
            nonImagedPixels, ...
            nonImagedTiles, ...
            sqrt(nonImagedPixels) * pStack.voxelSizeInMicrons * 1E-3);

        fprintf(msg)
        out = [out,msg];

    end

end

if nPlanesWithMissingBrain==0
    msg='GOOD -- None of the sample has been left unimaged.\n';
    fprintf(msg)
    out=msg;
end

