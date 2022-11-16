close all; clear all;

rootdir = 'D:\84C10Gal4_GCaMP6s_RFP_180509\'
TSeriesFolder = 'TSeries-05092018-1612-230';
% flyTiffFolder = '12012017_044_flyTIFFs';
TImgRoot = 'TSeries-05092018-1612-230_Cycle00001_Ch1_'; %000001.ome
saveBlackAndWhite = 1; %If set to 0, save imagesc instead.
if(saveBlackAndWhite),
    upperStretchLim = 0.1;
    stretchThreshold = upperStretchLim*4095;
else,
    climvals = [0 100];
end;
medfiltSize = 7;
slicesPerStack = 6;
recordedFPS = 10;
fps2write = 20;

cd(rootdir);

if(saveBlackAndWhite),
    vidObj = VideoWriter([TImgRoot '_BW_upperStretchLim ' num2str(upperStretchLim) '_medfilt'  num2str(medfiltSize) '_medfiltLastMeanZ.avi']);
else,
    vidObj = VideoWriter([TImgRoot '_imagesc.avi']);
end;
open(vidObj);
cd(TSeriesFolder);
% Last frame: 'fc2_save_2017-12-01-173304-10412';
tiffList = dir([TImgRoot '*.tif']);
display(numel(tiffList));

maxFrame2read = 200; %numel(tiffList);
for(ti = 1:maxFrame2read),
    imgName = [TImgRoot num2str(ti,'%06.0f') '.ome.tif'];
    rawImg = imread(imgName);
    rawImg_doubleVec =double(rawImg(:));
    if(ti==1),
        display(maxFrame2read);
        pixelDat = NaN(numel(rawImg_doubleVec),maxFrame2read);
    end;
    
    pixelDat(:,ti) = double(rawImg(:));
%     useMedian = 0;
%     if(useMedian), %This if clause doesn't even really work...
%         medianPixValue = median(double(rawImg(:)));
%         perFrameStretchLim = stretchThreshold/2/medianPixValue;
%         display(['Frame ' num2str(ti) ', medval=' num2str(medianPixValue) ', Per Frame Stretch =' num2str(perFrameStretchLim)]);
%     else,
%         maxPixValue = max(double(rawImg(:)));
%         perFrameStretchLim = stretchThreshold/maxPixValue;
%         display(['Frame ' num2str(ti) ', maxval=' num2str(maxPixValue) ', Per Frame Stretch =' num2str(perFrameStretchLim)]);
%         if(perFrameStretchLim>1),
%             perFrameStretchLim = 1;
%         end;
%     end;
    if(mod(ti,slicesPerStack)==0),
        display(ti);
        maxZProj = mean(pixelDat(:,ti-slicesPerStack+1:ti),2);
%         maxZProj = max(pixelDat(:,ti-slicesPerStack+1:ti),[],2);
        maxZProjFrame = reshape(maxZProj,size(rawImg,1),size(rawImg,2));
        maxPixValue = max(double(rawImg(:)));
        perFrameStretchLim = stretchThreshold/maxPixValue;
        if(saveBlackAndWhite),
            %         thisFrame = uint8(imadjust(rawImg,[0 perFrameStretchLim]));
            % perFrameStretchLim
                medFiltFrame = medfilt2(uint16(maxZProjFrame),[medfiltSize medfiltSize]);
            adjustedFrame = imadjust(medFiltFrame,[0 perFrameStretchLim]);
            writeVideo(vidObj,uint8(adjustedFrame));
        else,
            h=figure(1);
            subplot(1,2,1);
            imagesc(imread(imgName),climvals); axis equal;
            colorbar('south');
            title(['CLim=[' num2str(climvals(1)) ' ' num2str(climvals(2)) ']']);
            
            subplot(1,2,2);
            [n,xout] = hist(rawImg_doubleVec,[0:100:4000]);
            bar(xout(2:end),n(2:end));
            xlim([0 max(xout)]);
            
            I = getframe(h);
            writeVideo(vidObj,I);
        end;
    end;    
end;
close(vidObj);
