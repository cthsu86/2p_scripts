%demovid_behaviorOnly_v2.m

%January 04, 2021 - Presumably this is different from the 2018 version of
%demovid_behaviorOnly.m
%because I am older and wiser (and also because in vivo imaging is now my
%main project).
%
%Also assumes that a concatenated fullMovement signal has been produced.

close all; clear all;
movementFileName = 'TSeries-11162020-1436-551_Cycle00001_Ch2__maskReg137 154_Cycle00001_fullMovementAndBrainSignal.mat';
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
aviInput = 'fc2_save_2020-11-16-154724-_2Xspeed_frame117000to125999.avi';
movementStartIndex = 117000;
movementEndIndex = 125999;

behavior_fps = 30;

cd(rootdir);
A = load(movementFileName);
movementValues = A.fullMovementAndBrainSignal(:,1);

signalAmplitude = 50/A.laserMovementThresh;
signalOffset = 450;


% %Use the behavior video as a frame of reference.
behaviorVid = VideoReader(aviInput);
% if(strcmp(behaviorEndFrame,'end')),
%     behaviorEndFrame = behaviorVid.NumberofFrames;
% end;
% behaviorVid2show = read(behaviorVid,[1 behaviorVid.NumberofFrames]);%[behaviorStartFrame behaviorEndFrame]);

vidObj = VideoWriter(strrep(aviInput,'.avi','_withMovementTrace.avi'));
open(vidObj);

h=figure(1);
for(bfi = 1:behaviorVid.NumberofFrames), %size(behaviorVid2show,4));
    im2show = read(behaviorVid,bfi);
    subplot(1,1,1);
    imshow(im2show); %behaviorVid2show(:,:,:,bfi));
    hold on;
        
    secs2plot = 5;
    currentMovementIndex = bfi+movementStartIndex-1;
    signalStart2plot = round(currentMovementIndex-behavior_fps*secs2plot);
    signalEnd2plot= round(currentMovementIndex+behavior_fps*secs2plot);
    if(signalStart2plot<1),
        signalStart2plot = 1;
    end;
    if(signalEnd2plot>numel(movementValues))
        signalEnd2plot = numel(movementValues); %max(size(A.normalizedIntensity,1));
    end;
    plot(movementValues(signalStart2plot:signalEnd2plot)*-signalAmplitude+signalOffset);
    plot([secs2plot secs2plot]*behavior_fps,[signalOffset-signalAmplitude*max(movementValues) signalOffset],'Color',[1 1 0]);
%     plot([0 2*secs2plot],[signalOffset signalOffset],'Color',[1 1 0]);
    
%     if(relativeToLEDoffset),
%         secondsSinceLEDoffset = tFrameNumber/brain_fps-redLEDoffset_secs;
%         ledCaption = sprintf('%0.1f seconds since 1 min 660nm pulse turned off',secondsSinceLEDoffset);
%     else,
%         ledCaption = sprintf('%0.1f seconds',tFrameNumber/brain_fps);
%     end;
    text(10,size(im2show,1)*1.1,['frame ' num2str(currentMovementIndex) ', seconds =' num2str(currentMovementIndex/behavior_fps)],'Color','r');% ledCaption,'Color','r');
    I = getframe(h);
    writeVideo(vidObj,I);
end;
close(vidObj);