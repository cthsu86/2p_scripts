%% brukerMultiFlyZSummedTiffs_to_regionVals.m
%
% Assumes that the following has been run previously:
% 1) brukerMultiFlyZSeriesToTiffSeries.m
% 2) uiDrawMasks.m
% 
% Outputs data as a space delineated text file containing ZSeries number,
% timeInterval_hrs since start, and average regions for channels 1 and 2.

close all;
clear all;
rootdir = 'D:\23E10GCaMP7b_slowTimescale\210610\last few';
prefix = 'ZSeries-06102021-1028-';
zInterval = 2;
ZSeries_numList = 981:zInterval:992;
channelList = [1 2];
maskName = 'ZSeries-06102021-1028-871_Cycle00001_Ch2__userDrawnMask.mat';
timeInterval_hrs = 5/60; 
%When 'timeInterval_hrs' is set to 5/60, assumes each element in the ZSeries above was taken at 5 minute intervals.

%%
cd(rootdir);

%first, want to load mask.
A = load(maskName);
bwFrame = A.bwFrame;
s = regionprops(bwFrame>0,'Area','Centroid','PixelIdxList');
allRegions_pixelIdx = s(1).PixelIdxList;
% In case there is more than one region, want to go through and put all of
% the PixelIdxLists into a single vector?
if(size(s,1)>1),
    for(si = 2:size(size(2,1))),
        thisRegion_pixelIdx = s(si).PixelIdxList;
        allRegions_pixelIdx = [allRegions_pixelIdx(:) thisRegion_pixelIdx];
    end;
end;

mat2write = NaN(numel(ZSeries_numList),2+numel(channelList));
for(cNum = channelList),
    for(zi = 1:numel(ZSeries_numList)),
        if(cNum==1),
            mat2write(zi,1) = ZSeries_numList(zi);
            mat2write(zi,2) = zi*timeInterval_hrs;
        end;
        subfolder = [prefix num2str(ZSeries_numList(zi))]
        imgName = [subfolder '_Ch' num2str(cNum) '.tif'];
        I = double(imread(imgName));
        pixelVals = I(allRegions_pixelIdx);
        mat2write(zi,2+cNum) = mean(pixelVals);
    end;
    %
    %     % img2mask = strrep(TImgRoot,'_Ch2_', '_Ch1_mask.mat']);
    % prefix = 'ZSeries-01242021-1317-';
    % zInterval = 2;
    % ZSeries_numList = 304:zInterval:433;
    % channelList = [1 2];
%     avgImg = uint8(zStack_sumProj_allTimepoints_normalized*256);

end;
outname = [prefix '_' num2str(ZSeries_numList(1)) '_' num2str(zInterval) '_' num2str(ZSeries_numList(end)) '.txt'];
dlmwrite(outname, mat2write); %mat2write,outname);
%     save(outname,'avgImg','bwThresh','bwFrame','s');