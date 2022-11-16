% function	concatenateXMLSingleTSeriesAndMultiMovement_v2.m()
% �	Assumes that user has previously run:
% 1) getPixelDat_multiVid_continuousFrames - this outputs the BEHAVIOR
% (movement) data.
% 2) extractRegionsFromMasked_zStack.m - this outputs the BRAIN data.
% 3) readTimeFromXML.m
%
%
% 10/22/2020 - Discovered a bug but I don't know where it's originating:
% fullMovementAndBrainSignal(thisChunkIndicesToFrames(1:numel(tChunkVals),2) = tChunkVals;
% Why is it that "thisChunkIndicesToFrames (which is generated by
% thelaserOnsetThresh anyway?
% "readTimeFromXML" function) one greater than the number of frames?
%
%11/9/2020 - Different from v1 in that rather than manually determining
%when the laser came on from the video, the timestamps are computed from
%the XML file, which defines the start within one second of resolution,
%after which the closest frame is checked against the laserOnsetThresh.
function concatenateXMLSingleTSeriesAndMultiMovement_v2()
close all;

%% Parameters to modify
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB077B\200914';
vidRootName = 'fc2_save_2020-09-14-170551-_3Xspeed_frame';
% fc2_save_2020-11-16-154724-_2Xspeed_frame162000to165447_frame1to3448
stackTimesFileName = 'TSeries-11162020-1436-551_stackTimesFromXML.mat';
TSeriesName = 'TSeries-11162020-1436-551_Cycle00001_Ch2__maskReg137 154_Cycle00001_Intensities.mat';

lastFrameNum = 137523; %Easiest if we just manually put this in after looking at what was the last frame (last video) in the folder.

% laserDurationThresh_frames = 9; %Manually counted, but should be roughly fps_behVideo/brainStacksPerSec
laserMovementThresh = 2000; %This value may have to be adjusted as appropriate.

%Assuming that the *.avis in the file follow the same naming format as in
%writeFrames2BehaviorVid.m
recordedFPS = 30;
framesPerMin = 60*recordedFPS;
minutesPerVid = 5;
framesPerVid = 5*framesPerMin;

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

% %Index of frame 0 = 1.
% %Index of last frame in first video = 5*framesPerMin
% %Index of first frame in second video = 5*framesPerMin+1
% %Within a video, quicktime also starts a video at frame 0.
% %Thus, frame 1 in a video that starts at 36,000 = 36,001 (because of the 0
% %offset from the first frame.
% %Frame 669 in a video that starts at frame 36,000 is equal to 36,700
% laserOnsetFrame = 7152+1; %As noted above, the frameStart was at 0. Thus, determine when the laser comes on and then add 1.
% % slicesPerStack = 12;

% slicesPerMin = round(slicesPerStack*stacksPerSec*60);
% slicesPerChunk = 5*slicesPerMin; %round(slicesPerStack*stacksPerSec*300);
% maxSlice = 175128;

% TSeriesRoot = TSeriesName; 
TSeriesRoot = 'TSeries-09142020-1655-478_Cycle00001_Ch2__maskReg11 13 12 14 16_Cycle00001_slice';

if(~isempty(strfind(TSeriesRoot,'slice'))),
    outname = strrep(TSeriesRoot,'slice', '_fullMovementAndBrainSignal.mat');
else,
    outname = strrep(TSeriesRoot,'_Intensities.mat', '_fullMovementAndBrainSignal.mat');
end;
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
    try,
    mat = load(matname);
    catch
        display(['Could not load ' matname]);
    end;
    mat = mat.diffArray;
    display((segmentFrameStart));
    display(frameEnd);
    display(size(mat));
    fullMovement((segmentFrameStart+1):(frameEnd+1)) = mat;
end;
figure;
plot(fullMovement);

fullMovementWithLaser = fullMovement; %Need to use this later for aligning the timestamps.
isNumIndices = find(~isnan(fullMovementWithLaser));
fullMovementWithLaser = interp1(isNumIndices,fullMovementWithLaser(isNumIndices),1:numel(fullMovementWithLaser));
if(isnan(fullMovementWithLaser(1))),
    fullMovementWithLaser = fullMovementWithLaser(2:end);
end;

% % Plot FFT?
% Fs = 30;            % Sampling frequency                    
% T = 1/Fs;             % Sampling period       
% L = numel(fullMovementWithLaser);             % Length of signal
% t = (0:L-1)*T;        % Time vector
% Y = fft(fullMovementWithLaser);
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% figure;
% f = Fs*(0:(L/2))/L;
% plot(f,P1);
% ascendingAmplitudes = sort(P1(:),'ascend');
% %Find the inflection point where the amplitude changes the most.
% %Filter out spikes in the frequency domain greater than this.
% %Reverse FFT to get the filtered movement trace?

isNumIndices = find(fullMovement<=laserMovementThresh);
% fullMovement(superBrightIndices) = NaN;
fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));

fullMovementAndBrainSignal = NaN(numel(fullMovement),2);
fullMovementAndBrainSignal(:,1) = fullMovement(:);

% stacksPerSec = 1/0.2878;
if(exist(stackTimesFileName,'file')),
A = load(stackTimesFileName);
stackTimes = A.stackTimes;
stackStart_dateNum = A.startTime_dateNum;

%Need to figure out when the first frame is relative to the video time.
% stackTimes = stackTimes+stackStart_dateNum;
%Can not simply add the stackStart to the stackTimes - they are in
%different units!
%dateNum is in units of days - to get the number of seconds, need to
%multiply by 24 and 3600\, or divide stackTimes accordingly.
% stackStart_dateVec = datevec(stackStart_dateNum);

stackTimes = stackTimes/24/3600+stackStart_dateNum; %stackTimes are now in units of days.

stackMidTimes = (stackTimes(:,1)+stackTimes(:,2))/2;

% vidRootName = 'fc2_save_2020-09-15-162354-_2Xspeed_frame';
vidStartDateString = [vidRootName(10:19) ' ' vidRootName(21:22) ':' vidRootName(23:24) ':' vidRootName(25:26)];
vidStart_dateNum = datenum(vidStartDateString);

tChunkVals = processTChunk(TSeriesName);

secondsOffset = stackMidTimes(1)-vidStart_dateNum;
if(secondsOffset<0), %The stacks started collecting before the start of the video.
    %Thus, need to find the stack # that most closely matches the start of
    %the video:
    vidStart_stackIndex = find(min(abs(stackMidTimes-vidStart_dateNum)));
    tChunkVals = tChunkVals(vidStart_stackIndex:end);
    stackMidTimes = stackMidTimes(vidStart_stackIndex:end)-stackMidTimes(vidStart_stackIndex);
    thisChunkIndicesToFrames = round((stackMidTimes)*recordedFPS);
    if(thisChunkIndicesToFrames(1)==0),
        thisChunkIndicesToFrames = thisChunkIndicesToFrames+1;
    end;
else,
%     stackStart_vidInex = find(min(abs(stackMidtimes(1)-
    thisChunkIndicesToFrames = round((stackMidTimes-stackMidTimes(1,1)+secondsOffset)*recordedFPS*24*3600); %+stackStart_vidIndex-1; %No need to add 1 if the laserOnsetFrame was set with an additional 1 (for starting at index=1 instead of index=0).
    if(thisChunkIndicesToFrames(1)==0),
        thisChunkIndicesToFrames = thisChunkIndicesToFrames+1;
    end;
end;
% BUT: there is one more offset we need to account for - 
% Using the video timestamp only gives us accuracy within a second, so we
% need to figure out where the closest instance of a laser onset is.
laserIsOn = fullMovementWithLaser>laserMovementThresh;
laserStartIndices = find(diff(laserIsOn)==1)+1;
if(laserIsOn(1)),
    laserStartIndices = [1; laserStartIndices(:)];
end;
laserOffsetIndices = find(diff(laserIsOn)==-1);
if(laserIsOn(end)),
    laserOffsetIndices = [laserOffsetIndices; numel(laserIsOn)];
end;

laserMidIndices = (laserStartIndices+laserOffsetIndices)/2;

%Our assumption is that the time the video starts recording is with 0 ms in addition to the seconds denoted.
laserStartIndexAfterChunkStart = find(laserMidIndices>(thisChunkIndicesToFrames(1)-(recordedFPS/2)),1);
laserStartFrameIndexAfterChunkStart = laserMidIndices(laserStartIndexAfterChunkStart); %Get this in terms of the frame indices, not laser start indices.
% if((laserStartFrameIndexAfterChunkStart-thisChunkIndicesToFrames(1))>(recordedFPS/2)),
%     %In this case, the first frame where a laser is detected is over half a second offset after the start of
%     %2P recording (as computed from the video start time).
%     
%     %This suggests that the preceding laser onset was actually closer to
%     %the start of the video 
% end;

diff_laserMovementStart_vidTimestampStart = laserStartFrameIndexAfterChunkStart-thisChunkIndicesToFrames(1);
thisChunkIndicesToFrames = thisChunkIndicesToFrames+diff_laserMovementStart_vidTimestampStart;

%Can now write tChunkVals into the appropriate indices in the array (where
%each index represents a frame).
fullMovementAndBrainSignal(round(thisChunkIndicesToFrames(1:numel(tChunkVals))),2) = tChunkVals;

% stackTimes = stackTimes-stackTimes(1,1); %Since "relative time" actually is nonzero (probably with respect to how long it takes the laser to turn on after clicking "Start TSeries"?

%This is where timing information for the TSeries gets set, stored in units of BEHAVIOR FRAMES.
%If we are assuming that each stack is collected at a constant rate, then:
%1:numel(tChunkVals)])*recordedFPS/stacksPerSec
% thisChunkIndicesToFrames = round(([1:numel(tChunkVals)])*recordedFPS/stacksPerSec+laserOnsetFrame+1);
% try,
% catch,
%     display('mrp.');
% end;
%brainSignalInFrameUnits(slicesPerChunk,maxSlice,TSeriesRoot,recordedFPS,stacksPerSec,laserOnsetFrame,fullMovementAndBrainSignal(:,2),slicesPerStack);
isNumIndices = find(~isnan(fullMovementAndBrainSignal(:,2))); %<=laserMovementThresh);
% fullMovement(superBrightIndices) = NaN;
% fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));
%
% fullMovementAndBrainSignal = NaN(2,numel(fullMovement));
interpBrainSignal = interp1(isNumIndices,fullMovementAndBrainSignal(isNumIndices,2),1:numel(fullMovement));
fullMovementAndBrainSignal(1:numel(interpBrainSignal),2) = interpBrainSignal(:);
end;
if(~exist('laserIsOn','var')),
    laserIsOn = NaN;
end;
save(outname,'fullMovementAndBrainSignal','laserMovementThresh','laserIsOn');

% maxBrainSignal = quantile(fullMovementAndBrainSignal(:,2),0.

% minBrainSignal = quantile(fullMovementAndBrainSignal(isNumIndices,2),0.05);
% maxBrainSignal = max(fullMovementAndBrainSignal(:,2)-minBrainSignal);

medianBrainSignal = median(fullMovementAndBrainSignal(isNumIndices,2));
lowerQuartileBrainSignal = quantile(fullMovementAndBrainSignal(isNumIndices,2),0.25);
upperQuartileBrainSignal = quantile(fullMovementAndBrainSignal(isNumIndices,2),0.75);
minBrainSignal = lowerQuartileBrainSignal;
maxBrainSignal = upperQuartileBrainSignal; %minBrainSignal*2; %medianBrainSignal + minBrainSignal; %upperQuartileBrainSignal;
% interquartileDiff = upperQuartileBrainSignal-lowerQuartileBrainSignal;
% minBrainSignal = medianBrainSignal-2.5*interquartileDiff;
% maxBrainSignal = medianBrainSignal+2.5*interquartileDiff;


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
try,
    saveas(figure(2),strrep(TSeriesRoot,'slice', '_fullMovementAndBrainSignal.png'));
    saveas(figure(2),strrep(TSeriesRoot,'slice', '_fullMovementAndBrainSignal.fig'));
catch,
    saveas(figure(2),[outname '.png']); %strrep(TSeriesRoot,'_Intensities.mat', '_fullMovementAndBrainSignal.png'));
    saveas(figure(2),[outname '.fig']);%strrep(TSeriesRoot,'_Intensities.mat', '_fullMovementAndBrainSignal.fig'));
end;