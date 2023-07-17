% function	concatenateMultiVidMovement.m()
% •	Assumes that getPixelDat_multiVid_continuousFrames has been run previously.

function concateateMultiVidMovement_fromContinuousFrames()
close all; 

%% Parameters to modify
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201119';
vidRootName = 'fc2_save_2020-11-19-154903-_2Xspeed_frame';
outmatname = [vidRootName '.mat'];

laserDurationThresh_frames = 9; %Manually counted, but should be roughly fps_behVideo/brainStacksPerSec
laserMovementThresh = 1000; %This value will have to be adjusted as appropriate.

%Assuming that the *.avis in the file follow the same nnaming format as in
%writeFrames2BehaviorVid.m
recordedFPS = 30;
framesPerMin = 60*recordedFPS;
minutesPerVid = 5;
framesPerVid = 5*framesPerMin;
lastFrameNum = 162147; %Easiest if we just manually put this in after looking at what was the last frame (last video) in the folder.

frameStart = 0;

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
%     if(frameEnd==lastFrameNum),
%         display((segmentFrameStart));
% display(frameEnd);
% display(size(mat));
%             fullMovement((frameStart+1):lastFrameNum) = mat; %Bug that is carried over from writeFrames2BehaviorVid.m
%     else,
display((segmentFrameStart));
display(frameEnd);
display(size(mat));
    fullMovement((segmentFrameStart+1):(frameEnd+1)) = mat;
%     end;
end;
figure;
plot(fullMovement);

superBrightIndices = find(fullMovement>laserMovementThresh);
isNumIndices = find(fullMovement<=laserMovementThresh);
fullMovement(superBrightIndices) = NaN;
fullMovement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));


figure;
% 
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
    area(1:framesPerVid,fullMovement(i:lastIndex));
    else,
        numPoints = lastIndex-i+1;
        area(1:numPoints,fullMovement(i:lastIndex));
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
