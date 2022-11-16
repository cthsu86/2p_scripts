% function	concatenateTSeriesAndMovement.m()
% •	Assumes that user has previously run:
% 1) getPixelDat_multiVid_continuousFrames
% 2) extractRegionsFromMasked_zStack_v2.m

function concatenateTSeriesAndMovement()
close all;

%% Parameters to modify
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed\MB077B\200914';
vidRootName = 'fc2_save_2020-09-14-170551-_3Xspeed_frame';
concatenatedFile = 'TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001__fullMovementAndBrainSignal.mat';

outmatname = [vidRootName '.mat'];

laserDurationThresh_frames = 9; %Manually counted, but should be roughly fps_behVideo/brainStacksPerSec
laserMovementThresh = 1000; %This value will have to be adjusted as appropriate.

%Assuming that the *.avis in the file follow the same nnaming format as in
%writeFrames2BehaviorVid.m
recordedFPS = 30;
framesPerMin = 60*recordedFPS;
minutesPerVid = 5;
framesPerVid = 5*framesPerMin;
lastFrameNum = 137523; %Easiest if we just manually put this in after looking at what was the last frame (last video) in the folder.

frameStart = 0;

% Parameters pertaining to the TSeries:
% By examining the last slice #, the slices per stack, and the stack
% period, we know that the TSeries was recorded over 70 minutes, while the
% video was 76.4 minutes.
% THe XML file contains a parameter called "absoluteTime", which really
% seems to be relative to the start of the TSeries - however, at a later date (later than 10/11/2020) need
% to go back to this file and be able to read
% Need to manually examine the behavior video to figure out the frame the laser
% started.

laserOnsetFrame = 9000+6179; %As noted above, the frameStart was at 0.
slicesPerStack = 12;
stacksPerSec = 1/0.2878;
slicesPerMin = round(slicesPerStack*stacksPerSec*60);
slicesPerChunk = 5*slicesPerMin; %round(slicesPerStack*stacksPerSec*300);
maxSlice = 175128;

%Tseries name: TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice1to12510Intensities
TSeriesRoot = 'TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice'; 

outname = strrep(TSeriesRoot,'slice', '_fullMovementAndBrainSignal.mat');
%%
cd(rootdir);
A = load(concatenatedFile);
fullMovementAndBrainSignal = A.fullMovementAndBrainSignal;
fullMovement = fullMovementAndBrainSignal(:,1);
% fullMovement = NaN(lastFrameNum,1);
% for(segmentFrameStart = [frameStart:framesPerVid:lastFrameNum]),
%     frameEnd = segmentFrameStart+framesPerVid-1;
%     if(frameEnd>=lastFrameNum),
%         frameEnd = lastFrameNum; %-1 since it starts at zero.
%     end;
%     
%     numFramesInVidSegment = frameEnd-segmentFrameStart+1;
%     
%     matname = [vidRootName num2str(segmentFrameStart) 'to' num2str(frameEnd) '_frame1to' num2str(numFramesInVidSegment) '.mat'];
%     mat = load(matname);
%     mat = mat.diffArray;
%     display((segmentFrameStart));
%     display(frameEnd);
%     display(size(mat));
%     fullMovement((segmentFrameStart+1):(frameEnd+1)) = mat;
% end;
% figure;
% plot(fullMovement);
% 
% superBrightIndices = find(fullMovement>laserMovementThresh);
% isNumIndices = find(fullMovement<=laserMovementThresh);
% % fullMovement(superBrightIndices) = NaN;
% fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));
% 
% fullMovementAndBrainSignal = NaN(numel(fullMovement),2);
% fullMovementAndBrainSignal(:,1) = fullMovement;
% 
% % %Next, need to iterate through and load the brainSignal
% % for(tChunkFrameStart = 1:slicesPerChunk:maxSlice),
% %     chunkEnd = tChunkFrameStart+slicesPerChunk; %-1;
% %     if(chunkEnd>maxSlice),
% %         chunkEnd = maxSlice;
% %     end;
% %     %     matname = [vidRootName num2str(segmentFrameStart) 'to' num2str(frameEnd) '_frame1to' num2str(numFramesInVidSegment) '.mat'];
% %     %Tseries name: TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice1to12510Intensities
% %     %     TSeriesRoot = 'TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice';
% %     matname = [TSeriesRoot num2str(tChunkFrameStart) 'to' num2str(chunkEnd) 'Intensities.mat'];
% %     display(['Currently reading matname: ' matname]);
% %     A = load(matname);
% %     regions = A.regionPropsArray;
% %     meanPixelIntensityPerFrame = NaN(size(regions,1),2);
% %     for(ti = 1:size(regions,1)),
% %         thisFrameRegions = regions{ti,2};
% %         %thisFrameRegions is a two cell array of pixel intensities. The first cell contains pixel intensity data
% %         %from the MASK (probably the mCherry signal). The second cell contains
% %         %the pixel intensity data from the frames being masked (probably the
% %         %GCamP6m signal).
% %         
% %         sumPixelIntensity = 0;
% %         numPixels = 0;
% %         sumGCaMPIntensity = 0;
% %         numPixels_GCaMP = 0;
% %         for(si = 1:size(thisFrameRegions,1)),
% %             
% %             %First block of code: run the average mean pixel intensity for the
% %             %first channel (mCherry).
% %             sumPixelIntensity = sumPixelIntensity+sum(thisFrameRegions{si,1});
% %             numPixels = numPixels+numel(thisFrameRegions{si,1});
% %             
% %             sumGCaMPIntensity = sumGCaMPIntensity+sum(thisFrameRegions{si,2});
% %             numPixels_GCaMP = numPixels_GCaMP+numel(thisFrameRegions{si,2});
% %         end;
% % %         display(sumPixelIntensity);
% % %         display(numPixels);
% %         meanPixelIntensityPerFrame(ti,1) = 1; 
% %         meanPixelIntensityPerFrame(ti,2) = sumGCaMPIntensity/numPixels_GCaMP;
% %         clear thisFrameRegions;
% %     end;
% %     % Need to remap the values of meanPixelIntensity into the same
% %     % timescale as the behavior video somehow.
% %     %
% %     % Convert into unit of frames: frames/sec*sec/stack*stackNum
% %     firstStackNum = round(tChunkFrameStart/slicesPerStack);
% %     thisChunkIndicesToFrames = round(([1:size(regions,1)]+firstStackNum)*recordedFPS/stacksPerSec+laserOnsetFrame+1);
% %     fullMovementAndBrainSignal(thisChunkIndicesToFrames,2) = meanPixelIntensityPerFrame(:,2);
% %     clear A; clear regions; clear meanPixelIntensityPerFrame;
% % end;
% fullMovementAndBrainSignal(:,2) = brainSignalInFrameUnits(slicesPerChunk,maxSlice,TSeriesRoot,recordedFPS,stacksPerSec,laserOnsetFrame,fullMovementAndBrainSignal(:,2),slicesPerStack);
% isNumIndices = find(~isnan(fullMovementAndBrainSignal(:,2))); %<=laserMovementThresh);
% % fullMovement(superBrightIndices) = NaN;
% % fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));
% % 
% % fullMovementAndBrainSignal = NaN(2,numel(fullMovement));
% fullMovementAndBrainSignal(:,2) = interp1(isNumIndices,fullMovementAndBrainSignal(isNumIndices,2),1:numel(fullMovement));
% fullMovementAndBrainSignal(:,2) = fullMovementAndBrainSignal(:,2)/max(fullMovementAndBrainSignal(:,2))*laserMovementThresh;
% save(outname,'fullMovementAndBrainSignal');
figure;
num_subplots = ceil(lastFrameNum/framesPerVid);
display(num_subplots);
[ha,pos] = tight_subplot(num_subplots,1,0.01,0.05,0.05);
for(i = 1:framesPerVid:numel(fullMovement))
    lastIndex = i+framesPerVid-1;
    if(lastIndex>numel(fullMovement)),
        lastIndex = numel(fullMovement);
    end;
    subplot_num = ceil(lastIndex/framesPerVid);
    
    display(subplot_num);
    axes(ha(subplot_num));
    if(lastIndex~=numel(fullMovement)),
        area(1:framesPerVid,fullMovement(i:lastIndex)); hold on;
    plot(1:framesPerVid,fullMovementAndBrainSignal(i:lastIndex,2),'g','LineWidth',2);
    else,
        numPoints = lastIndex-i+1;
        area(1:numPoints,fullMovement(i:lastIndex));hold on;
    plot(1:numPoints,fullMovementAndBrainSignal(i:lastIndex,2),'g','LineWidth',2);
    end; 
    xlim([0 framesPerVid]);
    ylim([0 laserMovementThresh]); %framesPerVid;
    ylabel(num2str(i));
    if(lastIndex~=numel(fullMovement)),
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',''); %0:30:(minutesPerVid*30));
        %         set(ha(subplot_num),'YTickLabel','','YLabel', num2str(i),'XTick',[0:framesPerVid:framesPerMin],'XTickLabel','','xlim',[0 framesPerMin],'ylim',[0 laserMovementThresh]); %framesPerVid;
    else, %We are at the bottom subplot, so we want to put in x labels.
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',0:30:(minutesPerVid*30*2));
        
    end;
end;
%
% % Identify the major chunks in pixel intensity difference in the fullMovement data.
% roundedPixelIntensityDiff = round(fullMovement/1000)*1000;
