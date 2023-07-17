%% plotMovementFromNoMovementParameters_v2
% February 06, 2021
%
% Differs from version 1 in that it is designed to take advantage of very
% very short "movements" to eliminate noise from the laser. This was an
% issue encountered when examining Fly 201116, frames fc2_save_2020-11-16-154724-_2Xspeed_frame117000to125999

function plotMovementFromNoMovementParameters_v2(varargin)
close all

if(nargin==0),
    rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB077B\200915';
    movementFile = 'TSeries-09152020-1554-481_Cycle00001_Ch2__maskReg5 6_Cycle00001_fullMovementAndBrainSignal.mat';
    smallVsLargeMovementBoundary = 200;
    framesPerMin = 30*60;
    minutesPerVid = 5;
    framesPerVid = framesPerMin*minutesPerVid; %30 fps* 60 sec/min*5 min
else,
end;

noMoveDurationThresh = 3;

cd(rootdir);
output = strrep(movementFile,'.mat','');
if(exist([output '.ps'],'file')),
    delete([output '.ps']);
end;

moveDat = load(movementFile);
moveBrainDat = moveDat.fullMovementAndBrainSignal;
movementUpperBound = moveDat.laserMovementThresh; %Useful for ylimit axes.
% isLaserOn = moveDat.laserIsOn;
% 
movementDat = moveBrainDat(:,1);
% finalIsNumIndex = find(~isnan(movementDat),1,'last');
% movementDat = movementDat(1:finalIsNumIndex);

%By manually examining the movement trace, large movements appear to be in
%the range of 400-1800 while small movements appear to be ~200 (although of
%course there is some overlap between what we are defining as large and small).

smallMovementIndices = find(movementDat<smallVsLargeMovementBoundary);
h1 = figure(1);
set(h1,'Position',[10 500 1020*1.3 (576/2)*1.5]);

smallMovements = movementDat(smallMovementIndices);
h2 = figure(2);
set(h2,'Position',[10 500 1020*1.3 (576/2)*1.5]);

subplot(2,3,1);
delta_smallMovements = diff(smallMovements);
% laserOnIndices = find(isLaserOn==1);
% if(laserOnIndices(end)>numel(delta_smallMovements)),
%     laserOnIndices = laserOnIndices(1:(end-1));
% end;
[n,xout] = hist(abs(delta_smallMovements),0:1:smallVsLargeMovementBoundary);
plot(xout,n);
xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['# of frames']);

zeroIndices = find(n==0);
% figure;
subplot(2,3,2);
log10_n = log10(n);
plot(xout,log10_n); hold on;
title(['Use the movement differential to set background noise to 0']);

xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['log_1_0 (# of frames)']);

log10_n(zeroIndices) = 0;

% log10_n contains the log of the number of frames that contain a first
% order differential as indicated by the xout axis.
subplot(2,3,3);
normalizedLogNumFrameCumSum = cumsum(log10_n)/sum(log10_n);
plot(xout,normalizedLogNumFrameCumSum); hold on;
%Want to compare it to the identity line:
identityLine = ones(size(xout));
identityLine = cumsum(identityLine)/sum(identityLine);
plot(xout,identityLine);

identityXY = [xout(:) identityLine(:)];
numFramesXY = [xout(:) normalizedLogNumFrameCumSum(:)];

% distancePerFrameBin = NaN(numel(xout),1);
% for(di = 1:size(distancePerFrameBin,1)),
ptList = [numFramesXY];
v1 = [identityXY(1,:)];% 0];
v2 = [identityXY(end,:)];% 0];
distancePerFrameBin=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);

[maxval, maxIndex] = max(distancePerFrameBin);
plot(xout(maxIndex),normalizedLogNumFrameCumSum(maxIndex),'ro');
text(xout(maxIndex),0.95,num2str(xout(maxIndex)),'Color','r');

noMovementThresh = xout(maxIndex);

xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['Cumulative Fraction (log_1_0 (# of frames))']);

subplot(2,3,4);
diff1 = diff(normalizedLogNumFrameCumSum);
diff2 = diff(diff1);
plot(xout(2:end),diff1);
xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['diff(log_1_0 (# of frames))']);

subplot(2,3,5);
plot(xout(3:end),diff2);
hold on;
xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['diff2(log_1_0 (# of frames))']);
inflectionIndex = find(diff2>=0,1);
% Because this inflection point was computed from the
% normalizedLogNumFrameCumSum, we need to go back to that subplot to
% indicate the corresponding point.
subplot(2,3,2);
hold on;
noMovementDiffThresh = xout(inflectionIndex+2);
plot(xout(inflectionIndex+2),log10_n(inflectionIndex+2),'ro');
text(xout(inflectionIndex+2),1.1*log10_n(inflectionIndex+2),[num2str(noMovementDiffThresh) ' = noMovementDiffThresh'],'Color','r');

%%
figure (3);
fig3_spHandles = plotMovement(movementDat,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary);
axes(fig3_spHandles(1));
title(['No movement diff1 threshold = ' num2str(noMovementDiffThresh) ', red']);

%% Now: going to set all of the values below the smallVsLargeMovementBoundary and where the differential is less than the noMovementDiffThresh to 0.
figure (4);
smallMovementBinary = movementDat<smallVsLargeMovementBoundary;
movementDiffBelowThresh = abs(diff(movementDat))<noMovementDiffThresh;
noMovementBinary = [movementDiffBelowThresh; 0];
movementDat_noMoveZero = movementDat;
zeroIndices = find(smallMovementBinary & noMovementBinary);
movementDat_noMoveZero(zeroIndices) = 0;
fig4sp_handles = plotMovement(movementDat_noMoveZero,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,movementUpperBound,[0.5 0.5 0.5]);

%% In case there are still short false positives of movement (from the laser onset), want to set movements that are 1 frame or less in duration to 0.

% noMoveStartIndices = find(diff(noMovementBinary)==1)'+1;
% %If the first non-nan value of noMovemementBinary is 1 (first value is
% %probably a NaN because of the differential).
% firstNoMoveIndex = find(~isnan(noMovementBinary),1);
% if(noMovementBinary(firstNoMoveIndex)),
%     noMoveStartIndices = [firstNoMoveIndex; noMoveStartIndices];
% end;
% noMoveEndIndices = find(diff(noMovementBinary)==-1);
% if(noMovmentBinary==1),
% end;
%     noMove
movementBinary = ~noMovementBinary;
moveStartIndices = find(diff(movementBinary)==1)+1;
%If the first non-nan value of noMovemementBinary is 1 (first value is
%probably a NaN because of the differential).
firstNonNanIndex = find(~isnan(movementBinary),1);
% display(size(moveStartIndices));
if(movementBinary(firstNonNanIndex)),
    moveStartIndices = [firstNonNanIndex; moveStartIndices];
end;
moveEndIndices = find(diff(movementBinary)==-1);
if(movementBinary(end)),
    moveEndIndices = [moveEndIndices; numel(movementBinary)];
end;

% display(size(moveStartIndices))
% display(size(moveEndIndices))

moveDurations = moveEndIndices-moveStartIndices+1;
falseMoveIndices = find(moveDurations<=noMoveDurationThresh);
if(~isempty(falseMoveIndices)),
    for(fi = 1:numel(falseMoveIndices)),
        movementDat_noMoveZero(moveStartIndices(falseMoveIndices(fi)):moveEndIndices(falseMoveIndices(fi)))=0;
    end;
end;
% The variable "noMovementBinary" was already used in the section above,
% but we should probably keep updating it to our most recent (therefore
% most accurate?) definition of "no movement". It is also referenced in the
% subsequent section.
noMovementBinary = (movementDat_noMoveZero==0);
%% Using movementDat_noMoveZero, we can now move forward with distinguishing between small and large movement:
% What are the parameters that we want to characterize for small vs large
% movements?
% 1) magnitude (max)
% 2) integral. When combined with duration, reflects MEAN magniude rather than MAX magnitude.
% 3) Preceding "no movement" phase.
% 4) Lagging "no movement" phase
% 5) Duration? Probably not too independent from magnitude and integral,
% but worth saving. 

%But first, need to pull out data on the movement bouts;
isMovingBinary = ~noMovementBinary;
movementStartIndices = find(diff(isMovingBinary)==1)+1;
if(isMovingBinary(1)),
    movementStartIndices = [1; movementStartIndices];
end;
movementEndIndices = find(diff(isMovingBinary)==-1);
if(isMovingBinary(end))
    movementEndIndices = [movementEndIndices; numel(isMovingBinary)];
end;

probability_noMovement = nansum(noMovementBinary)/numel(movementDat_noMoveZero); %This is 0.2781 for an awake fly.

%% 
% But before we go into movement, we need to doublecheck our inactivity
% bouts - need to find a threshold below which an inactivity bout is
% actually considered inactivity.
inactivityStartIndices = find(diff(noMovementBinary)==1)+1;
if(noMovementBinary(1)),
    inactivityStartIndices = [1; inactivityStartIndices(:)];
end;
inactivityEndIndices = find(diff(noMovementBinary)==-1)+1;
if(noMovementBinary(end)),
    inactivityEndIndices = [inactivityEndIndices(:); numel(noMovementBinary)];
end;

duration = inactivityEndIndices-inactivityStartIndices;
% 
% movementBoutParameters_frames = NaN(numel(movementStartIndices),5);
% duration = movementEndIndices-movementStartIndices+1;
% movementBoutParameters_frames(:,5) = duration(:);
% 
% timeSincePrecedingMovement = movementStartIndices(2:end)-movementEndIndices(1:(end-1));
% timeSincePrecedingMovement = [movementStartIndices(1); timeSincePrecedingMovement(:)];
% % At the end of this want to use a linear support vector machine to break
% % up small and large movements. Use the line? plane? that's perpendicular
% % to the axes defined by principal component analysis 
% %
% % Or should we use kmeans clustering to divide into two clusters (take log
% % if histograms show it is necessary?)
% %
% % By naked eye though it looks like duration ought to be enough.
[n,xout] = hist(duration,5:5:(framesPerMin/3));
h5 = figure(5);
set(h5,'Position',[10 500 1020*1.3 (576/2)*1.5]);
subplot(2,3,1);
plot(xout,n);
subplot(2,3,2);
log10_n = log10(n);
plot(xout,log10_n);
zeroIndices = find(n==0);
log10_n(zeroIndices) = 0;
subplot(2,3,3);
cumsum_NormalizedDurationByNumFrames = cumsum(log10_n)/sum(log10_n);
plot(xout,cumsum_NormalizedDurationByNumFrames); hold on;
xlabel('Inactivity Duration');
ylabel('Cum sum # of frames');

%Find line of unity going through the maximum point:
xout_maxIndex = numel(xout); %find(cumsum_NormalizedDurationByNumFrames==1,1);
xval = xout(1:xout_maxIndex);
ptList = [xval(:) cumsum_NormalizedDurationByNumFrames(1:xout_maxIndex)'];
v1 = [xval(1) cumsum_NormalizedDurationByNumFrames(1)];% 0];
v2 = [xval(end) cumsum_NormalizedDurationByNumFrames(xout_maxIndex)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);

[maxval, maxIndex] = max(distancePerBout);
trueInactivityDurationCutoff = xout(maxIndex);
plot(xout(maxIndex),cumsum_NormalizedDurationByNumFrames(maxIndex),'ro');
plot([xval(1) xval(end)],[cumsum_NormalizedDurationByNumFrames(1) cumsum_NormalizedDurationByNumFrames(xout_maxIndex)]);
text(xout(maxIndex),0.95*cumsum_NormalizedDurationByNumFrames(maxIndex),num2str(trueInactivityDurationCutoff),'Color','r');
% End subplot (2,3,3): cum sum # of frames with inactivity.

%In examining above plots (figure 5, subplots 1 to 3), important to keep in mind that this
%is NUMBER OF BOUTS: it is skewed in favor of shorter bouts because there
%are so many of them (even when they represent less of the fraction of
%time.)
[sorted_duration, sorted_duration_indices] = sort(duration,'ascend');
subplot(2,3,4);
plot(cumsum(sorted_duration)/sum(sorted_duration)); hold on;
cumsumNormalized_sortedDuration = cumsum(sorted_duration)/sum(sorted_duration);
% differential is not great at picking out the inflection point here - too
% smooth for second order differential?
% diff2_sortedDuration = diff(diff(cumsum(sorted_duration)/sum(sorted_duration)));
% subplot(2,3,5);
% plot(diff2_sortedDuration);
% subplot(2,3,5);
xval = 1:numel(sorted_duration);
ptList = [xval' cumsumNormalized_sortedDuration(:)];
v1 = [xval(1) cumsumNormalized_sortedDuration(1)];% 0];
v2 = [xval(end) cumsumNormalized_sortedDuration(end)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);
% display(max(distancePerFrameBin));
% display(min(distancePerFrameBin));
[maxval, maxIndex] = max(distancePerBout);
plot(maxIndex,cumsumNormalized_sortedDuration(maxIndex),'ro');
trueInactivityDurationCutoff_rankOrder = sorted_duration(maxIndex);
text(maxIndex,0.9*cumsumNormalized_sortedDuration(maxIndex),[num2str(trueInactivityDurationCutoff_rankOrder) ' = trueInactivityDurationCutoff._rankOrder'],'Color','r');
ylabel(['Normalized Cum Sum (bout durations)']); xlabel('Inactivity Bouts in Rank Order (ascending duration)');

%Now that we have computed trueInactivityDurationCutoff, we can use it to
%check all the inactivity bouts and confirm that they are long enough to
%actually be considered inactivity.

movementDat_trueInactivity = movementDat;
for(bi = 1:numel(inactivityStartIndices)),
    if(duration(bi)>trueInactivityDurationCutoff),
        movementDuringBout = movementDat(inactivityStartIndices(bi):inactivityEndIndices(bi));
        if(mean(movementDuringBout)<smallVsLargeMovementBoundary),
       	movementDat_trueInactivity(inactivityStartIndices(bi):inactivityEndIndices(bi)) = 0;
        end;
    end;
end;
% 
figure(4);
plotMovement(movementDat_trueInactivity,framesPerVid,framesPerMin,minutesPerVid,0,movementUpperBound,[0.2 0.5 1],fig4sp_handles);
axes(fig4sp_handles(1));
%title(['No movement duration threshold = ' num2str(trueInactivityDurationCutoff) ' frames, sky blue']);

%%
% Now that we have a movement trace with trueInactivity set to 0, need to
% revisit the question of what the magnitude and duration threshold for a
% micromovement is.

noMovementBinary = movementDat_trueInactivity==0;
inactivityStartIndices = find(diff(noMovementBinary)==1)+1;
if(noMovementBinary(1)),
    inactivityStartIndices = [1; inactivityStartIndices(:)];
end;
inactivityEndIndices = find(diff(noMovementBinary)==-1)+1;
if(noMovementBinary(end)),
    inactivityEndIndices = [inactivityEndIndices(:); numel(noMovementBinary)];
end;
inactivity_duration = inactivityEndIndices-inactivityStartIndices;

movementBinary = movementDat_trueInactivity>0;
movementStartIndices = find(diff(movementBinary)>0);
if(movementBinary(1)),
    movementStartIndices = [1; movementStartIndices(:)];
end;
movementEndIndices = find(diff(movementBinary)==-1)+1;
if(movementBinary(end)),
    movementEndIndices = [movementEndIndices(:); numel(movementBinary)];
end;
movement_duration = movementEndIndices-movementStartIndices;
movement_maxMagnitude = NaN(size(movement_duration));
movement_integral = NaN(size(movement_duration));
for(mi = 1:numel(movement_maxMagnitude)),
    movement_maxMagnitude(mi) = max(movementDat_trueInactivity(movementStartIndices(mi):movementEndIndices(mi)));
    movement_integral(mi) = nansum(movementDat_trueInactivity(movementStartIndices(mi):movementEndIndices(mi)));
%     display([num2str(movementStartIndices(mi)) ' ' num2str(movementEndIndices(mi))
end;

figure(6);
[n,xout] = hist(movement_duration,5:5:(framesPerMin/3));
subplot(2,3,1);
plot(xout,n);
subplot(2,3,2);
log10_n = log10(n);
plot(xout,log10_n);
zeroIndices = find(n==0);
log10_n(zeroIndices) = 0;
subplot(2,3,3);
cumsum_NormalizedDurationByNumFrames = cumsum(log10_n)/sum(log10_n);
plot(xout,cumsum_NormalizedDurationByNumFrames); hold on;
xlabel('Movement Bout Duration');
ylabel('Cum sum # of frames');

%Find line of unity going through the maximum point:
xout_maxIndex = numel(xout); %find(cumsum_NormalizedDurationByNumFrames==1,1);
xval = xout(1:xout_maxIndex);
ptList = [xval(:) cumsum_NormalizedDurationByNumFrames(1:xout_maxIndex)'];
v1 = [xval(1) cumsum_NormalizedDurationByNumFrames(1)];% 0];
v2 = [xval(end) cumsum_NormalizedDurationByNumFrames(xout_maxIndex)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);

[maxval, maxIndex] = max(distancePerBout);
trueInactivityMovementCutoff = xout(maxIndex);
plot(xout(maxIndex),cumsum_NormalizedDurationByNumFrames(maxIndex),'ro');
plot([xval(1) xval(end)],[cumsum_NormalizedDurationByNumFrames(1) cumsum_NormalizedDurationByNumFrames(xout_maxIndex)]);
text(xout(maxIndex),0.95*cumsum_NormalizedDurationByNumFrames(maxIndex),num2str(trueInactivityMovementCutoff),'Color','r');

%In examining above plots (figure 5, subplots 1 to 3), important to keep in mind that this
%is NUMBER OF BOUTS: it is skewed in favor of shorter bouts because there
%are so many of them (even when they represent less of the fraction of
%time.)
[sorted_duration, sorted_duration_indices] = sort(movement_duration,'ascend');
subplot(2,3,4);
plot(cumsum(sorted_duration)/sum(sorted_duration)); hold on;
cumsumNormalized_sortedDuration = cumsum(sorted_duration)/sum(sorted_duration);
% differential is not great at picking out the inflection point here - too
% smooth for second order differential?
% diff2_sortedDuration = diff(diff(cumsum(sorted_duration)/sum(sorted_duration)));
% subplot(2,3,5);
% plot(diff2_sortedDuration);
% subplot(2,3,5);
xval = 1:numel(sorted_duration);
ptList = [xval' cumsumNormalized_sortedDuration(:)];
v1 = [xval(1) cumsumNormalized_sortedDuration(1)];% 0];
v2 = [xval(end) cumsumNormalized_sortedDuration(end)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);
% display(max(distancePerFrameBin));
% display(min(distancePerFrameBin));
[maxval, maxIndex] = max(distancePerBout);
plot(maxIndex,cumsumNormalized_sortedDuration(maxIndex),'ro');
maxSmallMovementCutoff = sorted_duration(maxIndex);
text(maxIndex,0.95*cumsumNormalized_sortedDuration(maxIndex),num2str(maxSmallMovementCutoff),'Color','r');
ylabel(['Normalized Cum Sum (bout durations)']); xlabel('Movement Bouts in Rank Order (ascending duration)');

subplot(2,3,5)
plot(movement_duration,movement_maxMagnitude,'ko');
xlabel(['Movement duration']); ylabel(['Max magitude']);

subplot(2,3,6)
plot(movement_duration,movement_integral,'ko');
xlabel(['Movement duration']); ylabel(['Movement integral']);
%Although the relationship between movement duration and integral is
%linear, there appears to be a cluster of low integral, low duration bouts.
%This roughly matches the threshold defined in subplot (2,3,4) though (the
%inflection point of the rank order durations).

%Next 20 lines (between now and the next section break identify
%smallMovements on the basis of duraiton only

% smallMovementsOnly = zeros(size(movementDat_trueInactivity));
% for(mi = 1:numel(movementStartIndices)),
%     if(movement_duration(mi)<maxSmallMovementCutoff),
%     smallMovementsOnly(movementStartIndices(mi):movementEndIndices(mi)) = movementDat_trueInactivity(movementStartIndices(mi):movementEndIndices(mi));
%     end;
% end;
% 
% 

%% At this point:
% We have identified smallMovements based on those with
% duration<maxSmallMovementCutoff.
% Have also identified trueInactivity on the basis of the inactivity bouts
% with a duration greater than trueInactivityDurationCutoff.
% Implement a verion of the Tudor Locke algorithm.
bedtime_initiation_duration = trueInactivityDurationCutoff;
waketime_initiation_duration = maxSmallMovementCutoff;

inBedIndices = find(inactivity_duration>=bedtime_initiation_duration);
awakeBinary = ~noMovementBinary;
wakeStartIndices = find(diff(awakeBinary)==1)+1;
if(awakeBinary(1)),
    wakeStartIndices = [1; wakeStartIndices(:)];
end;
wakeEndIndices = find(diff(awakeBinary)==-1);
if(awakeBinary(end)),
    wakeEndIndices = [wakeEndIndices(:); numel(awakeBinary)];
end;
wakeDurations = wakeEndIndices-wakeStartIndices+1;
trueWakeDuration_subIndices = find(wakeDurations>=waketime_initiation_duration);
trueWakeStarts = wakeStartIndices(trueWakeDuration_subIndices);

%For each inBedIndices, find the wakeStartTime that immediately follows it.
inBedToWakeMinutes = NaN(numel(inBedIndices),3);
%Column 1: in bed index, column 2: wake index, column 3: difference.

for(ibi = 1:numel(inBedIndices)),
    boutIndex = inBedIndices(ibi);
    inBedToWakeMinutes(ibi,1) = inactivityStartIndices(boutIndex);
    %Find the subsequent wake strt.
    wakeStartIndex = find(trueWakeStarts>inactivityStartIndices(boutIndex),1);
    if(isempty(wakeStartIndex)),
        inBedIndices(ibi,2) = numel(noMovementBinary);
    else,
        inBedToWakeMinutes(ibi,2) = trueWakeStarts(wakeStartIndex);
    end;
end;
%Need to get rid of overlapping in bed periods.
[uniqueWakeTimes, uniqueWakeIndices] = unique(inBedToWakeMinutes(:,2));
inBedToWakeMinutes = inBedToWakeMinutes(uniqueWakeIndices,:);
%Column 1: in bed index, column 2: wake index, column 3: difference.

smallMovementsOnly = zeros(size(movementDat_trueInactivity));
for(ibi = 1:size(inBedToWakeMinutes,1)),
    boutEnd = inBedToWakeMinutes(ibi,2);
    if(isnan(boutEnd)),
        boutEnd = numel(movementDat_trueInactivity);
    end;
    smallMovementsOnly(inBedToWakeMinutes(ibi,1):boutEnd) = ...
        movementDat_trueInactivity(inBedToWakeMinutes(ibi,1):boutEnd);
%     end;
end;

%noMovementBinary = movementDat_trueInactivity==0;
figure(4); 
plotMovement(smallMovementsOnly,framesPerVid,framesPerMin,minutesPerVid,0,movementUpperBound,[0.5 0 0.5],fig4sp_handles);
axes(fig4sp_handles(1));
title(['Inactivity duration > ' num2str(trueInactivityDurationCutoff) ' frames where diff1 < ' num2str(noMovementDiffThresh) ', sky blue; Samll movement duration < ' num2str(maxSmallMovementCutoff)]);


for(fignum = 2:6),
    orient(figure(fignum),'landscape');
    print(figure(fignum),'-dpsc2',[output '.ps'],'-append');
%     close(figure(fignum));
end;

ps2pdf('psfile', [output '.ps'], 'pdffile', [output '.pdf'], ...
    'gspapersize', 'letter',...
    'verbose', 1, ...
    'gscommand', 'C:\Program Files\gs\gs9.21\bin\gswin64.exe');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function plotMovement(movementDat,framesPerVid,framesPerMin,minutesPerVid,noMovementThresh,ylim_upperBound);

function ha = plotMovement(movementDat,framesPerVid,framesPerMin,minutesPerVid,noMovementThresh,ylim_upperBound,varargin);
num_subplots = ceil(numel(movementDat)/framesPerVid);
% display(num_subplots);
fig = get(gcf);
hf = fig.CurrentAxes;
if(isempty(hf)),
[ha,pos] = tight_subplot(num_subplots,1,0.01,0.05,0.05);
else,
%     display('meep.');
% ha = findall(gcf);
% % axes = 
ha = varargin{2};
end;
for(i = 1:framesPerVid:numel(movementDat))
    lastIndex = i+framesPerVid-1;
    if(lastIndex>numel(movementDat)),
        lastIndex = numel(movementDat);
    end;
    subplot_num = ceil(lastIndex/framesPerVid);
    
%     display(subplot_num);
% try,
    axes(ha(subplot_num));
% catch,
%     axes = gca(ha(subplot_num));
% end;
    if(lastIndex~=numel(movementDat)),
        if(nargin>6),
                    area(1:framesPerVid,movementDat(i:lastIndex),'FaceColor',varargin{1},'EdgeColor',varargin{1}); hold on;
        else
        area(1:framesPerVid,movementDat(i:lastIndex)); hold on;
        end;
    else,
        if(nargin>6),
            area(1:(numel(movementDat)-i+1),movementDat(i:end),'FaceColor',varargin{1},'EdgeColor',varargin{1}); hold on;
        else,
        area(1:(numel(movementDat)-i+1),movementDat(i:end)); hold on;
        end;
    end; hold on;
    plot([1 framesPerVid],[noMovementThresh noMovementThresh],'r-');
    xlim([0 framesPerVid]);
    ylim([0 ylim_upperBound]); %framesPerVid;
    ylabel(num2str(i));
    if(lastIndex~=numel(movementDat)),
%         if(subplot_num==1),
%             title(strrep(vidRootName,'_','..'));
%         end;
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',''); %0:30:(minutesPerVid*30));
        %         set(ha(subplot_num),'YTickLabel','','YLabel', num2str(i),'XTick',[0:framesPerVid:framesPerMin],'XTickLabel','','xlim',[0 framesPerMin],'ylim',[0 laserMovementThresh]); %framesPerVid;
    else, %We are at the bottom subplot, so we want to put in x labels.
        set(ha(subplot_num),'YTickLabel','','XTick',[0:(framesPerMin/2):framesPerVid],'XTickLabel',0:30:(minutesPerVid*30*2));
        
    end;
end;