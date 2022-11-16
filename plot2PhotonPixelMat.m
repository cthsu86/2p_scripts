close all; clear all;

rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP\'
TSeriesFolder = 'TSeries-03132018-1305-177';
% flyTiffFolder = '12012017_044_flyTIFFs';
TImgRoot = 'TSeries-03132018-1305-177_Cycle00001_Ch2_'; %000001.ome
saveBlackAndWhite = 1; %If set to 0, save imagesc instead.
if(saveBlackAndWhite),
    upperStretchLim = 0.4;
    stretchThreshold = upperStretchLim*4095;
else,
    climvals = [0 100];
end;

recordedFPS = 10;
fps2write = 20;

cd(rootdir);

if(saveBlackAndWhite),
    vidObj = VideoWriter([TSeriesFolder '_BW_upperStretchLim ' num2str(upperStretchLim) '.avi']);
else,
    vidObj = VideoWriter([TSeriesFolder '_imagesc.avi']);
end;
open(vidObj);
cd(TSeriesFolder);
% Last frame: 'fc2_save_2017-12-01-173304-10412';
tiffList = dir([TImgRoot '*.tif']);
display(numel(tiffList));

maxFrame2read = 100; %numel(tiffList);
for(ti = 1:maxFrame2read),
    imgName = [TImgRoot num2str(ti,'%06.0f') '.ome.tif'];
    rawImg = imread(imgName);
    rawImg_doubleVec =double(rawImg(:));
    if(ti==1),
        pixelDat = NaN(numel(rawImg_doubleVec),maxFrame2read);
    end;
    pixelDat(:,ti) = rawImg_doubleVec;
    maxPixValue = max(double(rawImg(:)));
    perFrameStretchLim = stretchThreshold/maxPixValue;
    %      perFrameStretchLim = pixStretchLim/4095*maxPixValue
    if(saveBlackAndWhite),
        thisFrame = uint8(imadjust(rawImg,[0 perFrameStretchLim]));
        writeVideo(vidObj,thisFrame);
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
        %          close(figure(1));
        
    end;
    display(['Frame ' num2str(ti) ', maxval=' num2str(maxPixValue) ', Per Frame Stretch =' num2str(perFrameStretchLim)]);
end;
close(vidObj);

figure(2);
imagesc(pixelDat,[1 1500]);
colorbar('southoutside');
% saveas(['

figure(3);
imagesc(diff(pixelDat,1,2),[1 500]);
colorbar('southoutside');
%Two photon started at 176.
%9927
% cd ..
% save([flyTiffFolder '_vid.mat'],allFrames);