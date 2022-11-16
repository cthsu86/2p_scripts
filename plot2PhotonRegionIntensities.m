function plot2PhotonRegionIntensities()

close all; 
%clear all;
%
% fps = 1/0.33858; %18.59081614; %2.7263*9; %1/0.13287*3;'
slicesPerStack = 10;
% fps = 1/0.23342*5;
    rootdir = 'E:\MB122B_UASdnClk_23E10LexA_GCaMP7b'
%     TSeriesFolder = 'TSeries-08262020-1442-455';
% TSeries-05092018-1612-230_Cycle00001_Ch2__maskReg11 19 21 25 30 40Intensities
% TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_']; %000001.ome
% TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
% Only purpose of TProjMask here is to provide the matname.
% D:\Hugin\HugLexA_csChrimson_hugArclight\TSeries-10062020-1717-489
% TProjMask = 'TSeries-10072020-1456-494_Cycle00002_Ch2__maskReg1 2 3 4 5.mat'; %[TSeriesFolder '_Cycle00001_Ch2__maskReg3.mat'];
signalMatname = 'TSeries-05102022-1434-745_Cycle00001_Ch2__userDrawnMask_Cycle00001_Intensities.mat'; %strrep(TProjMask, '.mat','Intensities.mat');
cycleRankNum = 0;
xmlName = 'TSeries-05102022-1434-745.xml';

% rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP'
% venus_matname = 'TSeries-03132018-1305-179_Cycle00001_Ch1_mask.mat';
% gcamp_matname = strrep(venus_matname,'_Ch1_mask.mat','_Ch2__maskedByCh1.mat');

cd(rootdir)

output = strrep(signalMatname,'.mat','');
if(exist([output '.ps'],'file')),
    delete([output '.ps']);
end;

A = load(signalMatname);
regions = A.regionPropsArray;

[stackTimes, shutterTimes] = readTimeFromXML(xmlName,cycleRankNum);
midStackTimes = mean(stackTimes,2);
fps = 1/mean(diff(midStackTimes));
%For reference: the commented out code fragment below is copied from
%extractRegionsFromMaskedVid.m
% pxIntensitiesForRegions{ai,2} = medFiltFrame(thisRegion.PixelIdxList);
% pxIntensitiesForRegions{ai,1} = medFiltMask(thisRegion.PixelIdxList);
% regionPropsArray{ti,1} = realAreas;
% regionPropsArray{ti,2} = pxIntensitiesForRegions;

meanPixelIntensityPerFrame = NaN(size(regions,1),2);
for(ti = 1:size(regions,1)),
    thisFrameRegions = regions{ti,2};
    %thisFrameRegions is a two cell array of pixel intensities. The first cell contains pixel intensity data
    %from the MASK (probably the mCherry signal). The second cell contains
    %the pixel intensity data from the frames being masked (probably the
    %GCamP6m signal).
    
    sumPixelIntensity = 0;
    numPixels = 0;
    sumGCaMPIntensity = 0;
    numPixels_GCaMP = 0;
    for(si = 1:size(thisFrameRegions,1)),
        
        %First block of code: run the average mean pixel intensity for the
        %first channel (mCherry).
        sumPixelIntensity = sumPixelIntensity+sum(thisFrameRegions{si,1});
        numPixels = numPixels+numel(thisFrameRegions{si,1});
        
        sumGCaMPIntensity = sumGCaMPIntensity+sum(thisFrameRegions{si,2});
        numPixels_GCaMP = numPixels_GCaMP+numel(thisFrameRegions{si,2});
    end;
    display(sumPixelIntensity);
    display(numPixels);
    meanPixelIntensityPerFrame(ti,1) = 1; %sumPixelIntensity/numPixels;
    
%     thisFrameRegions = gcamp_regions{ti,2};
%     sumPixelIntensity = 0;
%     numPixels = 0;
%     for(si = 1:numel(thisFrameRegions)),
%         sumPixelIntensity = sumPixelIntensity+sum(thisFrameRegions{si});
%         numPixels = numPixels+numel(thisFrameRegions{si});
%     end;
    meanPixelIntensityPerFrame(ti,2) = sumGCaMPIntensity/numPixels_GCaMP;

end;

if(size(stackTimes,1)>size(meanPixelIntensityPerFrame,1)),
    display('pause.');
end;

maxYlim = max(meanPixelIntensityPerFrame(:));

% figure(1);
% secondsPerSubplot = 120;
% numberZoomedInSubplots = size(meanPixelIntensityPerFrame,1)/secondsPerSubplot/fps;
% if(numberZoomedInSubplots<=1),
% % numSubplots = 
% else,
%     numSubplots = ceil(numberZoomedInSubplots)+1;
%     subplot(numSubplots,1,1);
% end;

redSignal = meanPixelIntensityPerFrame(:,1);
numIndices = find(~isnan(redSignal));
try,
redInterp = interp1(numIndices,redSignal(numIndices),1:numel(redSignal));
catch,
    redInterp = ones(size(redSignal));
end;
greenSignal = meanPixelIntensityPerFrame(:,2);
numIndices = find(~isnan(greenSignal));
greenInterp = interp1(numIndices,greenSignal(numIndices),1:numel(greenSignal));

seconds_xval = (1:size(meanPixelIntensityPerFrame,1))/fps/slicesPerStack;
plot(seconds_xval,redInterp,'r'); hold on;
plot(seconds_xval,greenInterp,'g');
ylim([0 500]);
% xlabel('Time (seconds)');
ylabel('Raw Photon Counts');
% 
% Fpass = 15;
% Fstop = 150;
% Apass = 1;
% Astop = 65;
% Fs = 1e3;
% 
% d = designfilt('lowpassfir', ...
%   'PassbandFrequency',Fpass,'StopbandFrequency',Fstop, ...
%   'PassbandRipple',Apass,'StopbandAttenuation',Astop, ...
%   'DesignMethod','equiripple','SampleRate',Fs);
% 
% y = filter(d,diffArray); %[diffArray; zeros(D,1)]);
% plot(y(round(Fpass/2):end),'r');


% 
% if(numberZoomedInSubplots>1)
%     framesPerPlot = round(secondsPerSubplot*fps);
%     subpcount = 2;
%     for(ti = 1:framesPerPlot:size(meanPixelIntensityPerFrame,1)),
%         subplot(numSubplots,1,subpcount);
%         frameStart = ti;
%         frameEnd = ti+framesPerPlot-1;
%         if(frameEnd>size(meanPixelIntensityPerFrame,1)),
%             frameEnd = size(meanPixelIntensityPerFrame,1);
%         end;
%         plot(seconds_xval(frameStart:frameEnd),redInterp(frameStart:frameEnd),'r'); hold on;
%         plot(seconds_xval(frameStart:frameEnd),greenInterp(frameStart:frameEnd),'g'); hold on;
%         ylim([0 500]);
%         subpcount = subpcount+1;
%     end;
% end;

figure(2);
normalizedIntensity = meanPixelIntensityPerFrame(:,2)./meanPixelIntensityPerFrame(:,1);
xval = (1:size(meanPixelIntensityPerFrame,1))/fps/slicesPerStack;
isNumIndices = ~isnan(normalizedIntensity);
interpY = interp1(xval(isNumIndices),normalizedIntensity(isNumIndices),xval);
deltaFoverF = diff(interpY)./interpY(1:(end-1));
% shutterDeltaIndices = find(abs(deltaFoverF)>0.05);
% interpY(shutterDeltaIndices) = NaN;

plot(xval,interpY,'k');
xlabel('Time (seconds)');
ylabel('GCamp6m/tdTomato');
title(strrep(signalMatname,'_','..'));

figure(3);
rawIntensity = meanPixelIntensityPerFrame(:,2); %./meanPixelIntensityPerFrame(:,1);
xval = (1:size(meanPixelIntensityPerFrame,1))/fps/slicesPerStack;
isNumIndices = ~isnan(rawIntensity);
interpY = interp1(xval(isNumIndices),rawIntensity(isNumIndices),xval);
% deltaFoverF = diff(interpY$)./interpY(1:(end-1));
% shutterDeltaIndices = find(abs(deltaFoverF)>0.05);
% interpY(shutterDeltaIndices) = NaN;

plot(xval,interpY,'k'); hold on;

baselineVal = mean(interpY(round([1:30]*fps*slicesPerStack)));
plot([xval(1) xval(end)], [baselineVal baselineVal],'Color',[0.5 0.5 0.5],'LineWidth',3);
xlabel('Time (seconds)');
ylabel('Ch2');
title(strrep(signalMatname,'_','..'));
figure(4);

plot((1:numel(deltaFoverF))/fps,deltaFoverF,'k');
xlabel('Time (seconds)');
ylabel('deltaF/prevF');

for(fignum = 2:4),

    orient(figure(fignum),'landscape');
    print(figure(fignum),'-dpsc2',[output '.ps'],'-append');
    figure(fignum);
%     xlim([10 30]);
%     orient(figure(fignum),'landscape');
%     print(figure(fignum),'-dpsc2',[output '.ps'],'-append');
%     
%     close(figure(fignum));
end;

% A.seconds_xval = seconds_xval;
% A.meanPixelIntensityPerFrame = meanPixelIntensityPerFrame;
% A.normalizedIntensity = interpY;
% A.fps = fps;
% 
% save(signalMatname,'-struct','A');


ps2pdf('psfile', [output '.ps'], 'pdffile', [output '.pdf'], ...
    'gspapersize', 'letter',...
    'verbose', 1, ...
    'gscommand', 'C:\Program Files\gs\gs9.21\bin\gswin64.exe');
%=======================================================
