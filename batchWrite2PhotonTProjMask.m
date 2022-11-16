rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180604\';
xlname = '84C10Gal4_UASGCaMP_RFP_180604';
TSeriesColNum = 5;
brightChannelString = '2';
outname = [xlname '_Ch' brightChannelString '_mask.mat']

cd(rootdir);
[num,txt,raw] = xlsread(xlname); 

TSeriesList = raw(:,TSeriesColNum);
% sumFrame_allTSeries = [];
numFrames_allTSeries = 0;
% sumIntensity_allFrames = 
for(ti = 1:numel(TSeriesList)),
    TSeriesName = TSeriesList{ti};
    if(strfind(TSeriesName,'eries-')),
        try,
    [sumFrame,numFrames] = write2PhotonTProjMask(rootdir,TSeriesName,brightChannelString);
        catch,
            display(TSeriesName);
        end;
    numFrames_allTSeries = numFrames+numFrames_allTSeries;
    if(~exist('sumIntensity_allFrames','var')),
        sumIntensity_allFrames = sumFrame;
    else,
        sumIntensity_allFrames = sumIntensity_allFrames+sumFrame;
    end;
    end;
end;

avgImg = sumIntensity_allFrames/numFrames_allTSeries;
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

