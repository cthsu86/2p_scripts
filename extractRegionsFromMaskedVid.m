% close all; clear all;
function extractRegionsFromMaskedVid()
%Inputs:
%1) rootdir (where we store the output data).
%2) TSeries folder (where we keep the raw data)
%3) TImgRoot - this refers to the frames we want to extract pixel intensity values from. Generally do
%not have to change this (except to specify Ch2 versus Ch1); should match
%TSeriesFolder.
%4) TMaskRoot - this refers to the name of the images we want to use for
%the mask. In cases where there is mCherry (Ch1) present, then use this to
%mask. Otherwise, use Ch2 for the mask.
%5) TProjMask: Helps restrict the field of view to the region where the
%cells are.

rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP6m_180410\'; %TSeries-04102018-1122-201\'
TSeriesFolder = 'TSeries-04102018-1122-202';

TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_']; %000001.ome
TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
TProjMask = [TSeriesFolder '_Cycle00001_Ch1_maskReg2 3.mat']
% TProjMask = [TSeriesFolder '_Cycle00001_Ch1_mask.mat']

outname = strrep(TProjMask, '.mat','Intensities.mat');
% 
% if(strfind(TImgRoot,'_Ch2_')),
%     maskmat = strrep(TImgRoot,'_Ch2_', '_Ch1_mask.mat');
%     outname = [TImgRoot '_maskedByCh1.mat'];
% else,
%     maskmat = strrep(TImgRoot,'_Ch1_', '_Ch1_mask.mat');
%     outname = maskmat;
% end;
writeVid = 0;
upperStretchLim = 0.1;
stretchThreshold = upperStretchLim*4095;
medfiltSize = 7;

recordedFPS = 25;
fps2write = 25;
bwThresh = 0;

cd(rootdir);

if(writeVid),
    vidObj = VideoWriter([TImgRoot '_BWthresh' num2str(bwThresh) '_upperStretchLim ' num2str(upperStretchLim) '_medfilt'  num2str(medfiltSize) '.avi']);
end;
A = load(TProjMask);
tProjMaskMat = A.bwFrame;

if(writeVid),
    open(vidObj);
end;
cd(TSeriesFolder);
% Last frame: 'fc2_save_2017-12-01-173304-10412';
tiffList = dir([TImgRoot '*.tif']);
display(numel(tiffList));

maxFrame2read = numel(tiffList);

regionPropsArray = cell(maxFrame2read,2);
for(ti = 1:maxFrame2read),
    display(ti);
    imgName = [TImgRoot num2str(ti,'%06.0f') '.ome.tif'];
    rawImg = imread(imgName); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
    medFiltFrame = medfilt2(rawImg,[medfiltSize medfiltSize]);
    
    maskName = [TMaskRoot num2str(ti,'%06.0f') '.ome.tif'];
    maskImg = imread(maskName);
%     tic;
    medFiltMask = double(medfilt2(maskImg,[medfiltSize medfiltSize]));
%     toc
    
    %First, take the maskImg, and convert it to a true binary mask.
    minMaskValue = min(medFiltMask(:));
    medianMaskValue = median(medFiltMask(:));
    mask_bwThresh4095 = 2*medianMaskValue-minMaskValue;
    maskImg = medFiltMask>mask_bwThresh4095;
    
    %Next, want to eliminate things outside the TProjectionMask.
    maskImg = maskImg.*tProjMaskMat;
    bwFrame = im2bw(maskImg,0);
    
    %Want to run regionProps on the bwFrame
    s = regionprops(bwFrame>0,'Area','BoundingBox','Centroid','PixelIdxList'); %,'PixelValues');
    if(writeVid),
        h = figure(1);
        subplot(1,2,1);
        imshow(medFiltFrame); hold on;
    end;
    %         display(s.Area);
    largeAreaIndices = find([s.Area]>0);
    realAreas = cell(numel(largeAreaIndices),1);
    pxIntensitiesForRegions = cell(numel(largeAreaIndices),1);
    for(ai = 1:numel(largeAreaIndices)),
        thisRegion = s(largeAreaIndices(ai));
        if(writeVid),
            plot(thisRegion.BoundingBox(1),thisRegion.BoundingBox(2),'ro');
        end;
        realAreas{ai} = thisRegion;
        pxIntensitiesForRegions{ai,2} = medFiltFrame(thisRegion.PixelIdxList);
        pxIntensitiesForRegions{ai,1} = medFiltMask(thisRegion.PixelIdxList);
        %             display(thisRegion.BoundingBox);
    end;
    
    regionPropsArray{ti,1} = realAreas;
    regionPropsArray{ti,2} = pxIntensitiesForRegions;
    if(writeVid),
        subplot(1,2,2);
        imshow(uint8(bwFrame*256));
        I = getframe(h);
        writeVideo(vidObj,I);
        close(figure(1));
        %
    end;
end;
if(writeVid),
    close(vidObj);
end;
cd(rootdir);
A.regionPropsArray = regionPropsArray;
A.TProjMask = TProjMask;
save(outname,'-struct','A');

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