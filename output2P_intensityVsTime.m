%%function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime(varargin)
%
% October 7, 2022 - useful to use for the olfaction experiments.
%
% Best used in instances where it is necessary to compute when the shutter
% clsoes over the scanner (for instance, in the chrimson stimulation case).
%
% Bug note, 6/24/2021: 
% TSeries-05012021-1552-577_Cycle00001_Ch2__SMP_Cycle00001_Intensities
% C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\HugS3_ASAP2s\210501
% Yields one more stack (as read from the XML) than images processed from
% the extractRegionsFromMaskedVid script.

function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime(varargin)

if (nargin==0),
    rootdir = 'E:\Rebecca\'
    %     rootdir = 'D:\Rebecca and Joe\'
    signalMatname = 'TSeries-09222022-1624-952_Cycle00001_Ch2_AL_userDrawnMask_Cycle00001_Intensities.mat'; %strrep(TProjMask, '.mat','Intensities.mat');
    cycleRankNum = 0; %Set to 0 if there is no voltage being used, otherwise set to 1.
    % Voltage values are hardcoded into the readTimeFromXML script.
    xmlName = 'TSeries-09222022-1624-952.xml';
    %Will check for xmlName in root directory - if not found, will look for
    %a directory of the same name, and enter it and look for it in that
    %subfolder.
    plotSignal = 1;
    t0_inSeconds=5*60*60; %20*60; %Set to NaN if t0_inSeconds should be extracted from shutter information.
    color2plot = [0.5 0.5 0.5];
    close all;
else,
    rootdir = varargin{1};
    signalMatname = varargin{2};
    cycleRankNum = varargin{3};
    xmlName = varargin{4};
    plotSignal = varargin{5};
    if(nargin>5),
        t0_inSeconds = varargin{6};
        color2plot = varargin{7};
    else,
        t0_inSeconds = NaN; %Use first shutter value if not specified.
        color2plot = [0.5 0.5 0.5];
    end;
end;

cd(rootdir);

A = load(signalMatname);
regions = A.regionPropsArray;

display(cycleRankNum);
[stackTimes, shutterTimes, lastBaselineIndex] = readTimeFromXML(xmlName,cycleRankNum);
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
    %     meanPixelIntensityPerFrame(ti,1) = sumPixelIntensity/numPixels;
    
    meanPixelIntensityPerFrame(ti,1) = 1; %sumPixelIntensity/numPixels;
    %Set to 1 if no RFP
    
    meanPixelIntensityPerFrame(ti,2) = sumGCaMPIntensity/numPixels_GCaMP;
    
end;
%
if(size(stackTimes,1)<size(meanPixelIntensityPerFrame,1)),
    numSlices = round(size(meanPixelIntensityPerFrame,1)/size(stackTimes,1));
else,
    %One possible explanation for entering this clause is that the successive
    %stacks are numbered by Cycle, rather than saved to a single
    %*Intensities.mat
    %     display('what?');
    %     display(size(stackTimes))
    %     display(size(meanPixelIntensityPerFrame));
end;
% sliceSubIndices
pixelIntensityPerStack = meanPixelIntensityPerFrame(numSlices:numSlices:end,:);
% if(pixelIntensityPerStack<size(stackTimes,1)),
timeIntensityMat = [stackTimes(1:size(pixelIntensityPerStack,1),1) pixelIntensityPerStack];

%But, we also have to check the voltage:
%We want to set to NaN any stacks where either the start or the end time is
%in between the shutter's opening and closing times.
if(~isempty(shutterTimes)),
    for(si = 1:size(shutterTimes,1)),
        stackBeginsWhenShutterClosed = stackTimes(:,1)>shutterTimes(si,1) & stackTimes(:,1)<shutterTimes(si,2);
        timeIntensityMat(find(stackBeginsWhenShutterClosed),2:3) = NaN;
        %     display(find(stackBeginsWhenShutterClosed));
        stackEndsWhenShutterClosed = stackTimes(:,2)>shutterTimes(si,1) & stackTimes(:,2)<shutterTimes(si,2);
        timeIntensityMat(find(stackEndsWhenShutterClosed),2:3) = NaN;
        shutterClosesMidStack = stackTimes(:,1)<shutterTimes(si,1) & stackTimes(:,2)>shutterTimes(si,2);
        timeIntensityMat(find(shutterClosesMidStack),2:3) = NaN;
        %     % To plot a red bar to indicate the duration of shutter closing:
        %     % First need to figure out the range of signal during this time.
        %     maxSignal
    end;
    %Because the above for loop sets the third column to NaNs, we want to use
    %this to reconstruct the time the chrimson laser came on as the time when the
    %shutter was closed.
    if(nargin==0),
        for(si=1:size(shutterTimes)),
            minIntensityVal = min(timeIntensityMat(:,3));
            plot([shutterTimes(si,1) shutterTimes(si,2)],[1 1]*minIntensityVal,'r','LineWidth',4); hold on;
        end;
    end;
end;
greenSignal = timeIntensityMat(:,3);
numIndices = find(~isnan(greenSignal));
greenInterp = interp1(numIndices,greenSignal(numIndices),1:numel(greenSignal));
% if(nargin==0),
figure(1);
display(color2plot)
plot(timeIntensityMat(:,1),greenInterp,'Color',color2plot);
hold on;
lowerX = min(greenInterp);
upperX = max(greenInterp);
plot([120 120],[lowerX upperX],'Color',[1 0 0]);
plot([240 240],[lowerX upperX],'Color',[1 0 0]);
plot([360 360],[lowerX upperX],'Color',[1 0 0]);
plot([480 480],[lowerX upperX],'Color',[1 0 0]);
xlabel('Time (s)');


%Normalize by mean
% meanNormalizedIntensityMat = timeIntensityMat;
if(isnan(t0_inSeconds)),
    firstShutteredStackIndex = find(isnan(timeIntensityMat(:,3)),1,'first');
else,
    firstShutteredStackIndex = find(timeIntensityMat(:,1)>t0_inSeconds,1,'first');
end;
tMinus30_seconds = timeIntensityMat(firstShutteredStackIndex,1)-30;
% display(size(timeIntensityMat))
% try,
if(isempty(tMinus30_seconds)),
    initialIndex = 1;
else,
initialIndex = find(timeIntensityMat(:,1)<tMinus30_seconds,1,'last');
end;;
if(isempty(initialIndex)),
    initialIndex = 1;
end;
% try,
if(isempty(firstShutteredStackIndex)),
    firstShutteredStackIndex = 1;
end;
timeRelativeToStimulus = timeIntensityMat(:,1)-timeIntensityMat(firstShutteredStackIndex,1);
% end;
% 
% catch,
%     display('meep');
% end
% if(nargin==0),
figure(2);
normalizedSignal = greenInterp/nanmean(greenInterp(initialIndex:(firstShutteredStackIndex)));
plot(timeRelativeToStimulus,normalizedSignal,'Color',color2plot); hold on;
if(plotSignal)
    for(si=1:size(shutterTimes)),
        minIntensityVal = min(timeIntensityMat(:,3));
        plot([shutterTimes(si,1) shutterTimes(si,2)]-timeIntensityMat(firstShutteredStackIndex,1),[1 1]*min(normalizedSignal),'r','LineWidth',4); hold on;
    end;
end;
%     baselineValue = greenSginal(1:(firstShutteredStackIndex)),
% end;

timeIntensityMat(:,3) = greenInterp;
if(size(shutterTimes,1)==0),
    voltOutTimes = [NaN NaN];
else,
    voltOutTimes = [shutterTimes(1,1) shutterTimes(end,2)];
end;

fileName = strrep(signalMatname,'.mat','.txt');
fID = fopen(fileName,'w');
% fprintf(fID,'%1.5f,',timeValsToPlot);
% fprintf(fID,'\n');
% % fprintf(fID,'%s',rowToWrite(:));
% for(ri = 1:size(imageSCmat,1)),
%     stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
%     stringToWrite = strrep(stringToWrite,'NaN','');
for(i = 1:size(timeIntensityMat,1)),
fprintf(fID,'%1.5f,',timeIntensityMat(i,:)); %rowToWrite,imageSCmat(fi,:));
fprintf(fID,'\n');
end;
% fprintf(fID,'%1.5f,',sortedVecToWrite); %rowToWrite,imageSCmat(fi,:));
%     % fprintf(fID,'%s','\n');
% end;
fclose(fID);