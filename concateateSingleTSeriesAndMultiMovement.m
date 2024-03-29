% function	concatenateTSeriesAndMovement.m()
% �	Assumes that user has previously run:
% 1) getPixelDat_multiVid_continuousFrames
% 2) extractRegionsFromMasked_zStack_v2.m

function concatenateTSeriesAndMovement()
close all;

%% Parameters to modify
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed\MB077B\200916_fly1';
vidRootName = 'fc2_save_2020-09-16-160227-_3Xspeed_frame';

outmatname = [vidRootName '.mat'];

laserDurationThresh_frames = 9; %Manually counted, but should be roughly fps_behVideo/brainStacksPerSec
laserMovementThresh = 1000; %This value will have to be adjusted as appropriate.

%Assuming that the *.avis in the file follow the same nnaming format as in
%writeFrames2BehaviorVid.m
recordedFPS = 30;
framesPerMin = 60*recordedFPS;
minutesPerVid = 5;
framesPerVid = 5*framesPerMin;
lastFrameNum = 164703; %Easiest if we just manually put this in after looking at what was the last frame (last video) in the folder.

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

%Index of frame 0 = 1. 
%Index of last frame in first video = 5*framesPerMin
%Index of first frame in second video = 5*framesPerMin+1
%Within a video, quicktime also starts a video at frame 0.
%Thus, frame 1 in a video that starts at 36,000 = 36,001 (because of the 0
%offset from the first frame.
%Frame 669 in a video that starts at frame 36,000 is equal to 36,700
laserOnsetFrame = 36669; %As noted above, the frameStart was at 0. Thus, determine when the laser comes on and then add 1.
slicesPerStack = 12;
stacksPerSec = 1/0.2878;
% slicesPerMin = round(slicesPerStack*stacksPerSec*60);
% slicesPerChunk = 5*slicesPerMin; %round(slicesPerStack*stacksPerSec*300);
% maxSlice = 175128;

TSeriesName = 'TSeries-09162020-1554-484_Cycle00001_Ch2__userDrawnMask_Cycle00001_Intensities.mat';
TSeriesRoot = 'TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice'; 

outname = strrep(TSeriesRoot,'slice', '_fullMovementAndBrainSignal.mat');
%%
cd(rootdir);

fullMovement = NaN(lastFrameNum,1);
for(segmentFrameStart = [frameStart:framesPerVid:lastFrameNum]),
    frameEnd = segmentFrameStart+framesPerVid-1;
    if(frameEnd>=lastFrameNum),
        frameEnd = lastFrameNum; %-1 since it starts at zero.
    end;
    
    numFramesInVidSegment = frameEnd-segmentFrameStart+1;
    
    matname = [vidRootName num2str(segmentFrameStart) 'to' num2str(frameEnd) '_frame1to' num2str(numFramesInVidSegment) '.mat'];
    mat = load(matname);
    mat = mat.diffArray;
    display((segmentFrameStart));
    display(frameEnd);
    display(size(mat));
    fullMovement((segmentFrameStart+1):(frameEnd+1)) = mat;
end;
figure;
plot(fullMovement);

superBrightIndices = find(fullMovement>laserMovementThresh);
isNumIndices = find(fullMovement<=laserMovementThresh);
% fullMovement(superBrightIndices) = NaN;
fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));

fullMovementAndBrainSignal = NaN(numel(fullMovement),2);
fullMovementAndBrainSignal(:,1) = fullMovement;

tChunkVals = processTChunk(TSeriesName);
thisChunkIndicesToFrames = round(([1:numel(tChunkVals)])*recordedFPS/stacksPerSec+laserOnsetFrame+1);


fullMovementAndBrainSignal(thisChunkIndicesToFrames,2) = tChunkVals;
%brainSignalInFrameUnits(slicesPerChunk,maxSlice,TSeriesRoot,recordedFPS,stacksPerSec,laserOnsetFrame,fullMovementAndBrainSignal(:,2),slicesPerStack);
isNumIndices = find(~isnan(fullMovementAndBrainSignal(:,2))); %<=laserMovementThresh);
% fullMovement(superBrightIndices) = NaN;
% fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));
% 
% fullMovementAndBrainSignal = NaN(2,numel(fullMovement));
fullMovementAndBrainSignal(:,2) = interp1(isNumIndices,fullMovementAndBrainSignal(isNumIndices,2),1:numel(fullMovement));
save(outname,'fullMovementAndBrainSignal');

minBrainSignal = quantile(fullMovementAndBrainSignal(:,2),0.05);
maxBrainSignal = max(fullMovementAndBrainSignal(:,2)-minBrainSignal);
fullMovementAndBrainSignal(:,2) = (fullMovementAndBrainSignal(:,2)-minBrainSignal)/maxBrainSignal*laserMovementThresh;

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
        area(1:numPoints,fullMovement(i:lastIndex));
    end; hold on;
    xlim([0 framesPerVid]);
    ylim([0 laserMovementThresh]); %framesPerVid;
    ylabel(num2str(i));
    if(lastIndex~=numel(fullMovement)),
                if(subplot_num==1),
            title(strrep(vidRootName,'_','..'));
        end;
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',''); %0:30:(minutesPerVid*30));
        %         set(ha(subplot_num),'YTickLabel','','YLabel', num2str(i),'XTick',[0:framesPerVid:framesPerMin],'XTickLabel','','xlim',[0 framesPerMin],'ylim',[0 laserMovementThresh]); %framesPerVid;
    else, %We are at the bottom subplot, so we want to put in x labels.
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',0:30:(minutesPerVid*30*2));
        
    end;
end;
%
% % Identify the major chunks in pixel intensity difference in the fullMovement data.
% roundedPixelIntensityDiff = round(fullMovement/1000)*1000;
