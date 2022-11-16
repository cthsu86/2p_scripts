function demovid_behaviorMovement();
% close all; clear all;
fps2read = 30;
fps2write = fps2read;
vid_startFrame = 4237;
vid_endFrame = vid_startFrame+fps2read*120; %14707
movement_startFrame = vid_startFrame;
movementEndFrame = vid_endFrame;

signalAmplitude = -0.001;
signalOffset = 450;

rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180607'
behaviorVideoName = 'fc2_save_2018-06-07-121344-0000.avi';
fullMovement_matName = '84C10Gal4_UASGCaMP_RFP_180607.mat';
annotation_name = '84C10Gal4_UASGCaMP_RFP_180607.xlsx';

% rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP'
% venus_matname = 'TSeries-03132018-1305-179_Cycle00001_Ch1_mask.mat';
% gcamp_matname = strrep(venus_matname,'_Ch1_mask.mat','_Ch2__maskedByCh1.mat');

cd(rootdir)

A = load(fullMovement_matName)
movement = A.fullMovement;
interp_movement = A.interp_movement;

%Want to read in the behaviors:
[num,txt,raw] = xlsread(annotation_name,2,'B2:E403');
behtypeStart = num(:,1);
behtypeEnd = num(:,2);
behName = raw(:,4)

%Use the behavior video as a frame of reference.
behaviorVid = VideoReader(behaviorVideoName);
% if(strcmp(behaviorEndFrame,'end')),
%     behaviorEndFrame = behaviorVid.NumberofFrames;
% end;
% behaviorVid2show = read(behaviorVid,[vid_startFrame vid_endFrame]);

vidObj = VideoWriter(strrep(behaviorVideoName,'.avi',['Frame' num2str(vid_startFrame) 'to' num2str(vid_endFrame) '_behaviorMovement.avi'])); %,'Motion JPEG AVI',
vidObj.FrameRate=fps2write;
open(vidObj);

numFrames2read = vid_endFrame-vid_startFrame+1;
for(bfi = 1:numFrames2read);
%     subplot(1,1,1);

h=figure(1);
    frame2show = read(behaviorVid,vid_startFrame+bfi-1); %[vid_startFrame vid_endFrame]);
    imshow(frame2show);
    hold on;
    
    secondsSinceBehaviorStart = bfi/fps2read;
    
    secs2plot = 5;
    signalStart2plot = round(vid_startFrame+bfi-1-secs2plot*fps2read); %tFrameNumber-brain_fps*secs2plot);
    signalEnd2plot = round(vid_startFrame+bfi-1+secs2plot*fps2read); %tFrameNumber+brain_fps*secs2plot);
%     if(signalStart2plot<1),
%         signalStart2plot = 1;
%     end;
%     if(signalEnd2plot>max(size(A.normalizedIntensity)))
%         signalEnd2plot = max(size(A.normalizedIntensity,1));
%     end;
    plot([signalStart2plot:signalEnd2plot]-signalStart2plot,movement(signalStart2plot:signalEnd2plot)*signalAmplitude+signalOffset,'Color',[0.5 0.5 0.5]);
    plot([signalStart2plot:signalEnd2plot]-signalStart2plot,interp_movement(signalStart2plot:signalEnd2plot)*signalAmplitude+signalOffset,'Color',[0 1 0]);
    %     display(max(A.normalizedIntensity(signalStart2plot:signalEnd2plot)*-10+450));
    %     display(min(A.normalizedIntensity(signalStart2plot:signalEnd2plot)*-10+450));
    plot([secs2plot secs2plot]*fps2read,[signalOffset+signalAmplitude*max(movement) signalOffset],'Color',[1 0 0],'LineWidth',2);
    %     behtypeStart = num(:,1);
    % behtypeEnd = num(:,2);
    % behName = raw(:,4);
    indexOfMovement = signalStart2plot+secs2plot*fps2read;
    if(interp_movement(indexOfMovement)<A.numPxThresh),
        text(secs2plot*fps2read,signalOffset+signalAmplitude*max(movement),'AUTO: No movement','Color',[0 1 0]);
    else,
        text(secs2plot*fps2read,signalOffset+signalAmplitude*max(movement),'AUTO: Movement','Color',[0 1 0]);
    end;
    behIndex = find(indexOfMovement>=behtypeStart,1,'last');
    text(secs2plot*fps2read,signalOffset+signalAmplitude*max(movement)+15,['ANNOT:' behName{behIndex}],'Color',[1 1 0]);
    
%     plot([0 2*secs2plot],[signalOffset signalOffset],'Color',[1 1 0]);
%     
%     if(relativeToLEDoffset),
%         secondsSinceLEDoffset = tFrameNumber/brain_fps-redLEDoffset_secs;
        ledCaption = sprintf('%0.1f secs since video start',secondsSinceBehaviorStart);
%     else,
%         ledCaption = sprintf('%0.1f seconds',tFrameNumber/brain_fps);
%     end;
    text(10,size(frame2show,1)*0.97,ledCaption,'Color','r');
    
    
    %     subplot(1,2,2);
    %     cd(TSeriesFolder)
    %     brainImgName = [TImgRoot num2str(tFrameNumber,'%06.0f') '.ome.tif'];
    %     if(exist(brainImgName,'file')),
    %     rawImg = imread(brainImgName); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
    %     medfiltFrame = medfilt2(rawImg,[medfiltSize medfiltSize]);
    %     imshow(medfiltFrame*100);
    %     end;
    %     cd('..');
    
    %     tFrameNumber =
    I = getframe(h);
    writeVideo(vidObj,I);
                 close(figure(1));
end;
close(vidObj);