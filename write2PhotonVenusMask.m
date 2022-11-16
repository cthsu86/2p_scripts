% close all; clear all;

rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Raw Data\23E10lexACsChRimson_84C10Gal4GCaMP6m\'
TSeriesFolder = 'TSeries-03132018-1305-177';
% flyTiffFolder = '12012017_044_flyTIFFs';
TImgRoot = 'TSeries-03132018-1305-177_Cycle00001_Ch1_'; %000001.ome
% saveBlackAndWhite = 1; %If set to 0, save imagesc instead.
% if(saveBlackAndWhite),
    upperStretchLim = 0.1; 
    stretchThreshold = upperStretchLim*4095;
% else,
%     climvals = [0 100];
% end;
medfiltSize = 15;

recordedFPS = 10;
fps2write = 20;
bwThresh = 0.1;

cd(rootdir);

% if(saveBlackAndWhite),
    vidObj = VideoWriter([TImgRoot '_BWthresh' num2str(bwThresh) '_upperStretchLim ' num2str(upperStretchLim) '_medfilt'  num2str(medfiltSize) '.avi']);
% else,
%     vidObj = VideoWriter([TImgRoot '_imagesc.avi']);
% end;
open(vidObj);
cd(TSeriesFolder);
% Last frame: 'fc2_save_2017-12-01-173304-10412';
tiffList = dir([TImgRoot '*.tif']);
display(numel(tiffList));

maxFrame2read = numel(tiffList);

regionPropsArray = cell(maxFrame2read,1);
for(ti = 1:maxFrame2read),
    imgName = [TImgRoot num2str(ti,'%06.0f') '.ome.tif'];
    rawImg = imread(imgName);
    rawImg_doubleVec =double(rawImg(:));
    if(ti==1),
        pixelDat = NaN(numel(rawImg_doubleVec),maxFrame2read);
    end;
    pixelDat(:,ti) = rawImg_doubleVec;
    useMedian = 0;
    if(useMedian), %This if clause doesn't even really work...
        medianPixValue = median(double(rawImg(:)));
        perFrameStretchLim = stretchThreshold/2/medianPixValue;
        display(['Frame ' num2str(ti) ', medval=' num2str(medianPixValue) ', Per Frame Stretch =' num2str(perFrameStretchLim)]);
    else,
    maxPixValue = max(double(rawImg(:)));
    perFrameStretchLim = stretchThreshold/maxPixValue;
        display(['Frame ' num2str(ti) ', maxval=' num2str(maxPixValue) ', Per Frame Stretch =' num2str(perFrameStretchLim)]);
        if(perFrameStretchLim>1),
            perFrameStretchLim = 1;
        end;
    end;
    
%     if(saveBlackAndWhite),
        %         thisFrame = uint8(imadjust(rawImg,[0 perFrameStretchLim]));
        medFiltFrame = medfilt2(rawImg,[medfiltSize medfiltSize]);
        % perFrameStretchLim
        adjustedFrame = double(imadjust(medFiltFrame,[0 perFrameStretchLim]))/256;
        bwFrame = im2bw(adjustedFrame,bwThresh);
        
        %Want to run regionProps on the bwFrame
        s = regionprops(bwFrame,'Area','BoundingBox','Centroid','PixelIdxList');        
        h = figure(1);
        subplot(1,2,1);
        imshow(adjustedFrame); hold on;
        
%         display(s.Area);
        largeAreaIndices = find([s.Area]>5);
        realAreas = cell(numel(largeAreaIndices),1);
        for(ai = 1:numel(largeAreaIndices)),
            thisRegion = s(largeAreaIndices(ai));
            plot(thisRegion.BoundingBox(1),thisRegion.BoundingBox(2),'ro');
            realAreas{ai} = thisRegion;
%             display(thisRegion.BoundingBox);
        end;
        
        regionPropsArray{ti} = realAreas;

        subplot(1,2,2);
        imshow(uint8(bwFrame*256));
        %         writeVideo(vidObj,uint8(bwFrame*256));
        %     else,
        %         h=figure(1);
        %         subplot(1,2,1);
        %         imagesc(imread(imgName),climvals); axis equal;
        %         colorbar('south');
        %         title(['CLim=[' num2str(climvals(1)) ' ' num2str(climvals(2)) ']']);
        %
        %         subplot(1,2,2);
        %         [n,xout] = hist(rawImg_doubleVec,[0:100:4000]);
        %         bar(xout(2:end),n(2:end));
        %         xlim([0 max(xout)]);
        %
        I = getframe(h);
        writeVideo(vidObj,I);
        close(figure(1));
%         
%     end;
end;
close(vidObj);

% figure(2);
% imagesc(pixelDat,[1 1500]);
% colorbar('southoutside');
% saveas(['
% 
% figure(3);
% imagesc(diff(pixelDat,1,2),[1 500]);
% colorbar('southoutside');
%Two photon started at 176.
%9927
% cd ..
% save([flyTiffFolder '_vid.mat'],allFrames);