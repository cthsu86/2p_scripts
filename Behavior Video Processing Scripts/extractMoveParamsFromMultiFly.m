%% function extractMoveParamsFromMultiFly
% 
% Feb 7, 2021
%
% Outputs a *.png graphing three movement parameters, based on the
% movements provided in the file xl2read:
% 1) Movement differential, used to set background noise to 0.
% 2) Inactivity duration threshold (for setting inactivity.
% 3) Movement duration threshold, for setting the boundaries between
% micromovements and macromovements.

function [noMovementDiffThresh, trueInactivityDurationCutoff, maxSmallMovementCutoff] = extractMoveParamsFromMultiFly()
close all;
primedir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo';
xl2read ='trainingSet_Feb2021.xlsx';
smallVsLargeMovementBoundary = 200;
noMoveDurationThresh = 3;
fps = 30;
framesPerMin = fps*60;

cd(primedir);
[num,txt,raw] = xlsread(xl2read);

currentMovementArrays = cell(size(raw,1),1);
for(ri = 1:size(raw,1)),
    
    cd(raw{ri,1});
    
    moveDat = load(raw{ri,2})
    moveDat = moveDat.fullMovementAndBrainSignal;
    movementDat = moveDat(:,1);

    % For every moveDat, need to pull out the following information:
    % 1) Movement differential, used to set background noise to 0.
    % 2) Inactivity duration threshold (for setting inactivity.
    % 3) Movement duration threshold, for setting the boundaries between
    % micromovements and macromovements.
    % BUT: will need to iterate multiple times, since each value is
    % dependent on the one previous (updates to the main movementDat vector are required.
    
    smallMovementIndices = find(movementDat<smallVsLargeMovementBoundary);
    smallMovements = movementDat(smallMovementIndices);
    delta_smallMovements = diff(smallMovements);
    [n_oneTrial,xout] = hist(abs(delta_smallMovements),0:1:smallVsLargeMovementBoundary);
    if(ri==1),
        n=n_oneTrial;
    else,
        n=n+n_oneTrial;
    end;
    
    currentMovementArrays{ri,1} = movementDat;
end;

%once we've accumulated the histogram values for all delta_smallMovemements
zeroIndices = find(n==0);
log10_n = log10(n);
log10_n(zeroIndices) = 0;
normalizedLogNumFrameCumSum = cumsum(log10_n)/sum(log10_n);
diff1 = diff(normalizedLogNumFrameCumSum);
diff2 = diff(diff1);
inflectionIndex = find(diff2>=0,1);
noMovementDiffThresh = xout(inflectionIndex+2);

subplot(1,3,1);
log10_n = log10(n);
plot(xout,log10_n); hold on;
title(['Use the movement differential to set background noise to 0']);

xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['log_1_0 (# of frames)']);
hold on;
plot(xout(inflectionIndex+2),log10_n(inflectionIndex+2),'ro');
text(xout(inflectionIndex+2),1.1*log10_n(inflectionIndex+2),[num2str(noMovementDiffThresh) ' = noMovementDiffThresh'],'Color','r');


%%
%Next for loop: accumulate the relevant information for computing the
%inactivity threshold:
for(ri = 1:size(currentMovementArrays,1)),
    movementDat = currentMovementArrays{ri,1};
    smallMovementBinary = movementDat<smallVsLargeMovementBoundary;
    movementDiffBelowThresh = abs(diff(movementDat))<noMovementDiffThresh;
    noMovementBinary = [movementDiffBelowThresh; 0];
    movementDat_noMoveZero = movementDat;
    zeroIndices = find(smallMovementBinary & noMovementBinary);
    movementDat_noMoveZero(zeroIndices) = 0;
    
    % Next, need to remove "false positive movements" (namely short
    % flickers caused by the laser turning on:
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
    
    moveDurations = moveEndIndices-moveStartIndices+1;
    falseMoveIndices = find(moveDurations<=noMoveDurationThresh);
    if(~isempty(falseMoveIndices)),
        for(fi = 1:numel(falseMoveIndices)),
            movementDat_noMoveZero(moveStartIndices(falseMoveIndices(fi)):moveEndIndices(falseMoveIndices(fi)))=0;
        end;
    end;
    
    % Now that false positives have been removed, need to recompute the
    % activity and inactivity durations:
    
    moveDurations = computeBinaryDurations(movementDat_noMoveZero>0);
    inactivityDurations = computeBinaryDurations(movementDat_noMoveZero==0);
    if(ri==1),
        moveDurations_all = moveDurations(:);
        inactivityDurations_all = inactivityDurations(:);
    else,
        moveDurations_all = [moveDurations_all; moveDurations(:)];
        inactivityDurations_all = [inactivityDurations_all; inactivityDurations(:)];
    end;
    currentMovementArrays{ri,1} = movementDat_noMoveZero;
end;

%%
% Use moveDurations_all and inactivityDurations_all to differentiate
% between micro and macromovements.
% 1) Find trueInactivityMovementCutoff (duration)
% 2) Find moveDurationCutoff.
histUpperBound = framesPerMin;
%Originally, histUpperBound = framesPerMin/3 (20 seconds, but this is quite
%early relative to the asymptote when 

[n,xout] = hist(inactivityDurations_all,5:5:histUpperBound);
log10_n = log10(n);
figure(1);
zeroIndices = find(n==0);
log10_n(zeroIndices) = 0;
cumsum_NormalizedDurationByNumFrames = cumsum(log10_n)/sum(log10_n);

subplot(1,3,2);
plot(xout,cumsum_NormalizedDurationByNumFrames); hold on;
xlabel(['Inactivity Durations (frames)']);
ylabel('Cum sum (log_1_0 (# of frames))');

xout_maxIndex = numel(xout); %find(cumsum_NormalizedDurationByNumFrames==1,1);
xval = xout(1:xout_maxIndex);
ptList = [xval(:) cumsum_NormalizedDurationByNumFrames(1:xout_maxIndex)'];
v1 = [xval(1) cumsum_NormalizedDurationByNumFrames(1)];% 0];
v2 = [xval(end) cumsum_NormalizedDurationByNumFrames(xout_maxIndex)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);
plot([v1(1) v2(1)], [v1(end) v2(end)],'b-');
% plot(ptList(:,1), ptList(:,2),'b-');

[maxval, maxIndex] = max(distancePerBout);
trueInactivityDurationCutoff = xout(maxIndex);
plot(xout(maxIndex),cumsum_NormalizedDurationByNumFrames(maxIndex),'ro');
title(['Inactivity duration > ' num2str(trueInactivityDurationCutoff) ' frames where diff1 < ' num2str(noMovementDiffThresh)]); 
% ', sky blue; Samll movement duration < ' num2str(maxSmallMovementCutoff)]);

%Next, find moveDurationCutoff:
[sorted_duration, sorted_duration_indices] = sort(moveDurations_all,'ascend');
cumsumNormalized_sortedDuration = cumsum(sorted_duration)/sum(sorted_duration);
xval = 1:numel(sorted_duration);
ptList = [xval' cumsumNormalized_sortedDuration(:)];
v1 = [xval(1) cumsumNormalized_sortedDuration(1)];% 0];
v2 = [xval(end) cumsumNormalized_sortedDuration(end)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);
% display(max(distancePerFrameBin));
% display(min(distancePerFrameBin));
[maxval, maxIndex] = max(distancePerBout);
maxSmallMovementCutoff = sorted_duration(maxIndex);

subplot(1,3,3);
plot(cumsum(sorted_duration)/sum(sorted_duration)); hold on;
plot(maxIndex,cumsumNormalized_sortedDuration(maxIndex),'ro');
text(1.1*maxIndex,0.95*cumsumNormalized_sortedDuration(maxIndex),...
    ['Micromovement duration = ' num2str(maxSmallMovementCutoff)],'Color','r');
ylabel(['Normalized Cum Sum (bout durations)']); xlabel('Movement Bouts in Rank Order (ascending duration)');


saveas(figure(1),strrep(xl2read,'.xlsx','.png'));


%% In plotMovementFromNoMovementParameters_v2.m, we at this point
% implemented the Tudor-Lock algorithm (shown below). However, since the
% purpose of this cde is to just extract movement parameters (for running
% on a different set of flies, we do not need to implement this in this
% function.
% %% At this point:
% % We have identified smallMovements based on those with
% % duration<maxSmallMovementCutoff.
% % Have also identified trueInactivity on the basis of the inactivity bouts
% % with a duration greater than trueInactivityDurationCutoff.
% % Implement a verion of the Tudor Locke algorithm.
% bedtime_initiation_duration = trueInactivityDurationCutoff;
% waketime_initiation_duration = maxSmallMovementCutoff;
% 
% inBedIndices = find(inactivity_duration>=bedtime_initiation_duration);
% awakeBinary = ~noMovementBinary;
% wakeStartIndices = find(diff(awakeBinary)==1)+1;
% if(awakeBinary(1)),
%     wakeStartIndices = [1; wakeStartIndices(:)];
% end;
% wakeEndIndices = find(diff(awakeBinary)==-1);
% if(awakeBinary(end)),
%     wakeEndIndices = [wakeEndIndices(:); numel(awakeBinary)];
% end;
% wakeDurations = wakeEndIndices-wakeStartIndices+1;
% trueWakeDuration_subIndices = find(wakeDurations>=waketime_initiation_duration);
% trueWakeStarts = wakeStartIndices(trueWakeDuration_subIndices);
% 
% %For each inBedIndices, find the wakeStartTime that immediately follows it.
% inBedToWakeMinutes = NaN(numel(inBedIndices),3);
% %Column 1: in bed index, column 2: wake index, column 3: difference.
% 
% for(ibi = 1:numel(inBedIndices)),
%     boutIndex = inBedIndices(ibi);
%     inBedToWakeMinutes(ibi,1) = inactivityStartIndices(boutIndex);
%     %Find the subsequent wake strt.
%     wakeStartIndex = find(trueWakeStarts>inactivityStartIndices(boutIndex),1);
%     if(isempty(wakeStartIndex)),
%         inBedIndices(ibi,2) = numel(noMovementBinary);
%     else,
%         inBedToWakeMinutes(ibi,2) = trueWakeStarts(wakeStartIndex);
%     end;
% end;
% %Need to get rid of overlapping in bed periods.
% [uniqueWakeTimes, uniqueWakeIndices] = unique(inBedToWakeMinutes(:,2));
% inBedToWakeMinutes = inBedToWakeMinutes(uniqueWakeIndices,:);
% %Column 1: in bed index, column 2: wake index, column 3: difference.
% 
% smallMovementsOnly = zeros(size(movementDat_trueInactivity));
% for(ibi = 1:size(inBedToWakeMinutes,1)),
%     boutEnd = inBedToWakeMinutes(ibi,2);
%     if(isnan(boutEnd)),
%         boutEnd = numel(movementDat_trueInactivity);
%     end;
%     smallMovementsOnly(inBedToWakeMinutes(ibi,1):boutEnd) = ...
%         movementDat_trueInactivity(inBedToWakeMinutes(ibi,1):boutEnd);
% %     end;
% end;