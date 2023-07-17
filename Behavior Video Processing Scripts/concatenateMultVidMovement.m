% function	concatenateMultiVidMovement.m()
% •	Assumes that getPixelDat_multiVid_multiLineAVI has been run previously.

function concatenateMultiVidMovement()
close all;
beh_rootdir = 'D:\OK107_UASGCaMP6m\OK107_UASGCaMP6m_180227'; %C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Raw Data\84C10Gal4_UASGCaMP_RFP_180607';
xlsname = 'OK107_UASGCaMP6m_180227.xlsx';
annot_rootdir = beh_rootdir;
vidRootName = 'fc2_save_2018-02-27-'; %Assume that the timestamp of the video will be right after "vidRootName";
fps = 30;
laserOnsetColNum = 1;
laserOffsetColNum = 2;

laserDurationThresh_frames = floor(fps/2);
numPxThresh = 100; %500;

outmatname = [strrep(xlsname,'.xlsx','.mat')];

cd(annot_rootdir);
[num,txt,laserDat] = xlsread(xlsname);
laserDatList = cell(size(laserDat,1),1);
laserOnsetOffsetList = NaN(size(laserDat,1),4); %First two rows are onset/offset, next two rows are where the data is located in the fullMovement array.
% ldRowCount = 1;

%Find the column that contains the VideoName column.
% vidname_colNum = 1;
for(ci = 1:size(laserDat,2)),
    if(~isempty(strfind(laserDat{1,ci},'ideo'))),
        vidname_colNum = ci;
    end;
end;

%Next, want to generate a list of *.avi files in the folder:
cd(beh_rootdir);
% lightTransitionIndices = NaN(size(laserDat,1),1);
for(lri = 1:size(laserDat,1)),
    vidname = laserDat{lri,vidname_colNum};
    %For each video name, we need to extract the time that the video was
    %started, load the behavior file, and check that the timestamps match
    %the behavior (no large accumulation of offsets).
    
    %     if(ischar(vidname) && exist(vidname,'file')),
    if(~isempty(strfind(vidname,vidRootName))),
        timestamp = vidname((numel(vidRootName)+1):(numel(vidRootName)+6));
        timestamp_datenum = datenum([timestamp(1:2) ':' timestamp(3:4) ':' timestamp(5:6)]);
        if(~exist('fullMovement','var')),
            firstFlyVidStartTime = timestamp_datenum;
            %             firstFlyVidStartTime_datenum = datenum(['firstFlyVidStartTim
            fullMovement = NaN(fps*120*60,1);
            isLightTransition = zeros(fps*120*60,1);
        end;
        
        %Then what's listed is an actual video name, not a column title or
        %a comment
        laserOnFrame = laserDat{lri,laserOnsetColNum};
        laserOffFrame = laserDat{lri,laserOffsetColNum};
        %         if(~ischar(laserOnFrame)),
        if(laserOnFrame>1), %Then we need to either run a separate movement detection algorithm on the first part of the video, or from the previous video to the current video.
            if(exist('prevVidName','var') && strcmp(prevVidName,vidname) && ~isempty(strfind(prevVidName,vidRootName))) %exist(prevVidName,'file')), %Then we probably already computed movement when the laser is on in the preceding
                %                 bgImgName = computeBackgroundForFrameRange(vidname,prevOffset,laserOnFrame);
                %                 bgsubtractAndDiffForFrameRange(vidname,prevOffset,laserOnFrame,bgImgName);matname = strrep(vidname,'.avi',['_frame' num2str(prevOffset) 'to' num2str(laserOnFrame) '.mat'])
                matname = strrep(prevVidName,'.avi',['_frame' num2str(prevOffset) 'to' num2str(laserOnFrame) '.mat'])
                mat = load(matname);
                mat = mat.diffArray(prevOffset:laserOnFrame);
                %The actual index number in the "fullMovement" video is the
                %actual timestamp of the video + the frame offsets.
                
                secondsFromStart = (timestamp_datenum-firstFlyVidStartTime)*24*3600-0.96; %This representation is actually off by 0.96 seconds.
                frameOffset = round(secondsFromStart*fps)+prevOffset-1;
                if(~isnan(fullMovement(frameOffset))),
                    overhang = find(isnan(fullMovement(frameOffset:end)),1);
                    frameOffset=frameOffset+overhang-1;
                end;
                
                fullMovement(frameOffset:(frameOffset+numel(mat)-1)) = mat;
%                 isLightTransition(frameOffset) = 1;
                isLightTransition(frameOffset+numel(mat)-1) = 1;
                display(['A: Reading data from file ' vidname ' and writing it into frames ' num2str(frameOffset) ' to ' num2str(frameOffset+numel(mat)-1)]);
                laserDatList{lri} = matname;
                laserOnsetOffsetList(lri,:) = [prevOffset laserOnFrame frameOffset (frameOffset+numel(mat)-1)];
            else,
                %This is the first light pulse the series and we want to compute the movement for the preceding frames when the laser hadn't been turned on yet.
                if(exist('prevVidName','var') && ~isempty(strfind(vidname,vidRootName))), %exist(prevVidName,'file')),
                    %                 bgImgName = computeBackgroundForFrameRange(vidname,prevOffset,'end');
                    %                 bgsubtractAndDiffForFrameRange(vidname,prevOffset,'end',bgImgName);
                    
                    matname = strrep(prevVidName,'.avi',['_frame' num2str(prevOffset) 'toend.mat'])
                    mat = load(matname);
                    mat = mat.diffArray(prevOffset:end);
                    %The actual index number in the "fullMovement" video is the
                    %actual timestamp of the video + the frame offsets.
                    
                    secondsFromStart = (prevVidDateNum-firstFlyVidStartTime)*24*3600-0.96; %This representation is actually off by 0.96 seconds.
                    frameOffset = round(secondsFromStart*fps)+prevOffset-1;
                    if(frameOffset>1),
                        if(~isnan(fullMovement(frameOffset))),
                            overhang = find(isnan(fullMovement(frameOffset:end)),1);
                            frameOffset=frameOffset+overhang-1;
                            
                        end;
                    else,
                        frameOffset = 1;
                    end;
                    
                    fullMovement(frameOffset:(frameOffset+(numel(mat)-1))) = mat;
%                     isLightTransition(frameOffset) = 1;
                    isLightTransition(frameOffset+numel(mat)-1) = 1;
                    display(['B: Reading data from file ' matname ' and writing it into frames ' num2str(frameOffset) ' to ' num2str(frameOffset+numel(mat)-1)]);
                    laserDatList{lri} = matname;
                    laserOnsetOffsetList(lri,:) = [prevOffset prevOffset+numel(mat)-1 frameOffset (frameOffset+numel(mat)-1)];
                end;
                %
                %                 bgImgName = computeBackgroundForFrameRange(vidname,1,laserOnFrame);
                %                 bgsubtractAndDiffForFrameRange(vidname,1,laserOnFrame,bgImgName);
                
                matname = strrep(vidname,'.avi',['_frame1to' num2str(laserOnFrame) '.mat'])
                mat = load(matname);
                mat = mat.diffArray(1:laserOnFrame);
                %The actual index number in the "fullMovement" video is the
                %actual timestamp of the video + the frame offsets.
                
                secondsFromStart = (timestamp_datenum-firstFlyVidStartTime)*24*3600-0.96; %This representation is actually off by 0.96 seconds.
                %                 display(timestamp_datenum);
                %                 display(firstFlyVidStartTime);
                frameOffset = round(secondsFromStart*fps);
                
                if(frameOffset>1),
                    if(~isnan(fullMovement(frameOffset))),
                        overhang = find(isnan(fullMovement(frameOffset:end)),1);
                        frameOffset=frameOffset+overhang;                        
                    end;
                else,
                    frameOffset = 1;
                end;
                %                 try,
                fullMovement(frameOffset:(frameOffset+numel(mat)-1)) = mat;
%                 isLightTransition(frameOffset) = 1;
                isLightTransition(frameOffset+numel(mat)-1) = 1;
                
                display(['C: Reading data from file ' vidname ' and writing it into frames ' num2str(frameOffset) ' to ' num2str(frameOffset+numel(mat)-1)]);
                laserDatList{lri} = matname;
                laserOnsetOffsetList(lri,:) = [1 laserOnFrame frameOffset (frameOffset+numel(mat)-1)];
            end;
        end;
        %Movement while the laser is on.
        %         bgImgName = computeBackgroundForFrameRange(vidname,laserOnFrame,laserOffFrame);
        %         bgsubtractAndDiffForFrameRange(vidname,laserOnFrame,laserOffFrame,bgImgName)
        matname = strrep(vidname,'.avi',['_frame' num2str(laserOnFrame) 'to' num2str(laserOffFrame) '.mat'])
        mat = load(matname);
        mat = mat.diffArray(laserOnFrame:laserOffFrame);
        %The actual index number in the "fullMovement" video is the
        %actual timestamp of the video + the frame offsets.
        
        secondsFromStart = (timestamp_datenum-firstFlyVidStartTime)*24*3600-0.96; %This representation is actually off by 0.96 seconds.
        frameOffset = round(secondsFromStart*fps)+laserOnFrame-1;
        if(frameOffset>1),
            if(~isnan(fullMovement(frameOffset))),
                overhang = find(isnan(fullMovement(frameOffset:end)),1);
                frameOffset=frameOffset+overhang;
            else,
            end;
        else,
            frameOffset = 1;
            isLightTransition(frameOffset) = 1; %When the light turned on.
        end;
        
        fullMovement(frameOffset:(frameOffset+numel(mat)-1)) = mat;
        isLightTransition(frameOffset+numel(mat)-1) = 1; %When the light turned off.
        
        display(['D: Reading data from file ' vidname ' and writing it into frames ' ...
            num2str(frameOffset) ' to ' num2str(frameOffset+numel(mat)-1)]);
        
        laserDatList{lri} = matname;
        laserOnsetOffsetList(lri,:) = [laserOnFrame laserOffFrame frameOffset (frameOffset+numel(mat)-1)];
        
        if(lri==size(laserDat,1)),
            %             bgImgName = computeBackgroundForFrameRange(vidname,laserOffFrame,'end');
            %             bgsubtractAndDiffForFrameRange(vidname,laserOffFrame,'end',bgImgName);
            matname = strrep(vidname,'.avi',['_frame' num2str(laserOffFrame) 'toend.mat'])
            mat = load(matname);
            mat = mat.diffArray(laserOffFrame:end);
            %The actual index number in the "fullMovement" array is the
            %actual timestamp of the video + the frame offsets.
            
            secondsFromStart = (timestamp_datenum-firstFlyVidStartTime)*24*3600-0.96; %This representation is actually off by 0.96 seconds.
            frameOffset = round(secondsFromStart*fps)+laserOffFrame-1;
            if(~isnan(fullMovement(frameOffset))),
                overhang = find(isnan(fullMovement(frameOffset:end)),1);
                frameOffset=frameOffset+overhang;
            end;
            fullMovement(frameOffset:(frameOffset+numel(mat)-1)) = mat;
            isLightTransition(frameOffset) = 1;
            isLightTransition(frameOffset+laserOnFrame-1) = 1;
            display(['E: Reading data from file ' vidname ' and writing it into frames ' num2str(frameOffset) ' to ' num2str(frameOffset+numel(mat)-1)]);
            
            laserDatList{lri} = matname;
            laserOnsetOffsetList(lri,:) = [laserOnFrame laserOffFrame frameOffset (frameOffset+numel(mat)-1)];
        end;
        
        display(['Finished reading ' vidname ' until frame ' num2str(laserOffFrame)]);
        %
        prevVidName = vidname;
        prevOnset = laserOnFrame;
        prevOffset = laserOffFrame;
        prevVidDateNum = timestamp_datenum;
    end;
end;

plot(fullMovement); hold on;
plot(1:numel(isLightTransition),2*10^4*isLightTransition,'r');
isNumIndices = find(~isnan(fullMovement));
interp_movement = interp1(isNumIndices,fullMovement(isNumIndices),1:numel(fullMovement));
lastIndex = max(isNumIndices);
interp_movement = interp_movement(1:lastIndex);
movementBinary = interp_movement>numPxThresh;

movementOnsets = find(diff(movementBinary)>0)+1;
movementOffsets = find(diff(movementBinary)<0);
if(movementBinary(1)>0),
    movementOnsets = [1 movementOnsets];
end;
if(movementBinary(end)>0),
    movementOffsets = [movementOffsets numel(interp_movement)];
end;

figure;
subplot(1,2,1);
[n,xout] = hist(interp_movement,[0:25:1000]);
plot(xout,n);
xlabel(['Change in pixels']);
title(['Distribution of change in pixels before movements are eliminated']);

% display(numel(movementOffsets));
% display(numel(movementOnsets));
movementDurations = movementOffsets-movementOnsets;
[n,xout] = hist(movementDurations,0:1:30);
% figure;
subplot(1,2,2);
plot(xout,n);
xlabel(['Frames']);
title(['Movement durations before short durations are eliminated']);


for(mi = 1:numel(movementDurations)),
    if(movementDurations(mi)<laserDurationThresh_frames),
        interp_movement(movementOnsets(mi):movementOffsets(mi)) = 0;
    end;
end;
figure;
% subplot(1,2,1);
[n,xout] = hist(interp_movement,[0:10:1000]);
plot(xout,n);
xlabel(['Change in pixels']);
title(['Distribution of change in pixels after short movements are eliminated']);

figure;
belowThreshIndices = find(interp_movement<numPxThresh);
interp_movement(belowThreshIndices) = 0;
plot([1:numel(interp_movement)]/fps/60,interp_movement);
xlabel('Time (sec)'); ylabel(['Movement (change in px)']);

%
% figure;
% [n,xout] = hist(fullMovement,0:1:100); %max(fullMovement));
% plot(xout,n);

figure;
sleepBinary = interp_movement==0; %Not real sleep.
sleepOnset = find(diff(sleepBinary)==1)+1;
sleepOffset = find(diff(sleepBinary)==-1);
if(sleepBinary(1)),
    sleepOnset = [1 sleepOnset];
end;
if(sleepBinary(end)),
    sleepOffset = [sleepOffset numel(interp_movement)];
end;
% display(numel(sleepOffset));
% display(numel(sleepOnset));
sleepDurations = (sleepOffset-sleepOnset)/fps;
[n,xout] = hist(sleepDurations,0:15:360);
bar(xout(2:end),n(2:end)/sum(n(2:end)));
xlim([xout(1) xout(end)+xout(2)-xout(1)]);
ylabel(['Fraction of no movement bouts']);
xlabel(['Duration (s)']);
title(['No movement thresh=' num2str(numPxThresh)]);

lightTransitions = find(isLightTransition==1);
betweenLightTransitionFrames = diff([lightTransitions; numel(interp_movement)]);
maxBetweenTransitionLength_frames = max(betweenLightTransitionFrames)
movementSinceTransitionMat = ones(numel(lightTransitions),maxBetweenTransitionLength_frames)*-3000;
for(lti = 1:numel(lightTransitions)),
    frameStart = lightTransitions(lti);
    if(lti==numel(lightTransitions)),
        frameEnd = numel(interp_movement);
    else,
        frameEnd=lightTransitions(lti+1);
    end;
%     display(lti);
%     display(frameEnd-frameStart+1)
%     display(size(movementSinceTransitionMat));
%     display(size(interp_movement))
%     display(frameStart);
%     display(frameEnd);
    try,
    movementSinceTransitionMat(lti,1:(frameEnd-frameStart+1)) = interp_movement(frameStart:frameEnd);
    catch,
%         display('what?');
    end;
end;
figure;
imagesc([1:size(movementSinceTransitionMat,2)]/fps,...
    [1:size(movementSinceTransitionMat,1)],movementSinceTransitionMat,[-1000 3000]); hold on;
for(lti = 1:numel(lightTransitions)),
    frameStart = lightTransitions(lti);
    if(lti==numel(lightTransitions)),
        frameEnd = numel(interp_movement);
    else,
        frameEnd=lightTransitions(lti+1);
    end;
    text((frameEnd-frameStart+5*fps)/fps,lti,num2str(frameEnd),'Color',[1 1 1],'FontSize',7);
end;
colorbar;
xlabel(['Time (s)']);
ylabel(['Light onset/offset #']);
title(['Movement since light transition']);

figure;
movementSinceTransitionBinary = movementSinceTransitionMat>0;
belowZeroIndices = find(movementSinceTransitionMat(:)<0);
movementSinceTransitionMat(belowZeroIndices) = 0; %floor(movementSinceTransitionMat,0);
subplot(1,2,1);
plot([1:size(movementSinceTransitionMat,2)]/fps,nansum(movementSinceTransitionMat,1)/size(movementSinceTransitionMat,1));
subplot(1,2,2);
plot([1:size(movementSinceTransitionMat,2)]/fps,nansum(movementSinceTransitionBinary,1)/size(movementSinceTransitionMat,1));

xloutname = strrep(xlsname,'.xlsx','_fullMovementIndices.xlsx');
if(exist(xloutname,'file')),
    delete(xloutname);
end;
xlswrite(xloutname,laserDatList,1,'A1');
xlswrite(xloutname,laserOnsetOffsetList,1,'B1');

xlswrite(xloutname,{'Sleep Onset Frame','Sleep Duration (s)'},'No movement data','A1');
xlswrite(xloutname,sleepOnset(:),'No movement data','A2');
xlswrite(xloutname,sleepDurations(:),'No movement data','B2');


save(outmatname,'fullMovement','isLightTransition','numPxThresh','laserDurationThresh_frames','interp_movement');

% display(max(sleepDurations));
% display(sort(sleepDurations,'ascend'));

%
% figure;
% [n,xout] = hist(diff(fullMovement),0:10:500); %max(fullMovement));
% plot(xout,n);
%
% lightMovement = find(fullMovement>1000);
% modifiedLightMovement = fullMovement;
% modifiedLightMovement(lightMovement) = 0;
% figure; plot(modifiedLightMovement);
% %
% % Fpass = 15;
% % Fstop = 150;
% % Apass = 1;
% % Astop = 65;
% % Fs = 1e3;
% % d = designfilt('lowpassfir', ...
% %   'PassbandFrequency',Fpass,'StopbandFrequency',Fstop, ...
% %   'PassbandRipple',Apass,'StopbandAttenuation',Astop, ...
% %   'DesignMethod','equiripple','SampleRate',Fs);
% %
% % y = filter(d,fullMovement); %[diffArray; zeros(D,1)]);
% % plot(y(round(Fpass/2):end),'g');
%
% figure(2);
% plot(diff(y));
