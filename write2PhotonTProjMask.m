%INPUTS: Cycle and channel of data to take a Z projection of.
%OUTPUTS:
%Saves a struct which contains "avgIntensity"
%%numFrames: total # of frames.
%%sumFrame: sum of intensities at each position.

function [sumFrame,numFrames] = write2PhotonTProjMask(varargin)
close all;
if(nargin==0),
rootdir = 'D:\23E10GCaMP7b'
% rootdir = 'D:\Hugin\emptyChrimson_HugS3_Arclight\';
TSeriesFolder = 'TSeries-11192020-1542-552';
    %Every image in the TSeries folder is in this format:
    %TSeries-10222019-1549-340_Cycle00001_Ch1_000013.ome;
    
    TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_'];
    %Cycle number indicates the time stamp.
    %
    
    %The last time I used this script when I remembered what I was doing:
    %     rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180607\'
    %     TSeriesFolder = 'TSeries-06072018-1333-279';
    %     TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_'];
else, %The variables we entered in above are being called by an external script.
    rootdir = varargin{1};
    TSeriesFolder = varargin{2};
    TImgRoot = [TSeriesFolder '_Cycle00001_Ch' varargin{3} '_'];
end;

if(strfind(TImgRoot,'_Ch2_')),
    %     img2mask = strrep(TImgRoot,'_Ch2_', '_Ch1_TprojMask.mat');
    %     outname = [TImgRoot '_maskedByCh1.mat'];
    outname = [TImgRoot '_mask.mat'];
else,
    img2mask = strrep(TImgRoot,'_Ch1_', '_Ch1_mask.mat');
    outname = img2mask;
end;

maxNumFrames = 120*4*20; %120 seconds, 4 Hz, 20 slices - this is super important for the 90 minute recordings because otherwise this script will take forever to run when it really shouldn't.

% upperStretchLim = 0.1;
% stretchThreshold = upperStretchLim*4095;
% else,
%     climvals = [0 100];
% end;
medfiltSize = 3;
%
% recordedFPS = 10;
% fps2write = 20;
% bwThresh = 0.1;

cd(rootdir);
cd(TSeriesFolder);
% Last frame: 'fc2_save_2017-12-01-173304-10412';
tiffList = dir([TImgRoot '*.tif']);
display(TImgRoot);
display(numel(tiffList));

% maxFrame2read = 8548; %numel(tiffList);
maxFrame2read = min(numel(tiffList),maxNumFrames);

% regionPropsArray = cell(maxFrame2read,1);
for(ti = 1:maxFrame2read),
    display(ti);
    imgName = [TImgRoot num2str(ti,'%06.0f') '.ome.tif'];
    try,
        rawImg = double(medfilt2(imread(imgName),[medfiltSize medfiltSize]));
        %     rawImg_doubleVec =double(rawImg(:));
        %     display(size(rawImg));
        % dbquit
        if(ti == 1),
            allImgSum =zeros(size(rawImg,1),size(rawImg,2));
        end;
        allImgSum = allImgSum+rawImg;
    catch,
    end;
end;

cd(rootdir);
if(nargin==0),
    avgImg = allImgSum/maxFrame2read;
    [n,xout] = hist(avgImg(:),1:128);
    figure; plot(xout,n);
    medianPxVal = median(avgImg(:));
    maxPxVal = max(avgImg(:));
    minPxVal = min(avgImg(:));
    % bwThresh = 2*medianPxVal/maxPxVal;
    % try,
    bwThresh = (medianPxVal+(medianPxVal-minPxVal))/maxPxVal;
    if(bwThresh>1),
        cumsum_n = cumsum(n/sum(n));
        highIndex = find(cumsum_n>0.98,1);
        bwThresh = xout(highIndex)/maxPxVal;
    end;
    
    figure; imagesc(avgImg/maxPxVal);
    
    bwFrame = im2bw(avgImg/maxPxVal,bwThresh);
    
    s = regionprops(bwFrame>0,'Area','Centroid');
    
    imshow(uint8(avgImg));
    figure; imshow(uint8(bwFrame*256));
    % for(si = 1:numel(s)),
    %     text(s(si).Centroid(1),s(si).Centroid(2),num2str(si),'r');
    % end;
    
    % img2mask = strrep(TImgRoot,'_Ch2_', '_Ch1_mask.mat']);
    save(outname,'avgImg','bwThresh','bwFrame','s');
    imwrite(uint8(bwFrame*256),strrep(outname,'.mat','.tif'));
else,
    sumFrame = allImgSum;
    numFrames = maxFrame2read;
end;
% catch,
%     save(outname,'avgImg');
% imwrite(strrep(outname,'.mat'),'.tif',uint8(bwFrame*256));
%
% end;