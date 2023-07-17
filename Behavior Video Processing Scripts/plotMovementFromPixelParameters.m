function plotMovementFromPixelParameters(varargin)
close all

if(nargin==0),
    rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed\MB077C\201102';
    movementFile = 'TSeries-11022020-1620-547_Cycle00001_Ch2__maskReg1 2_Cycle00001_fullMovementAndBrainSignal.mat';
    smallVsLargeMovementBoundary = 200;
    framesPerMin = 30*60;
    minutesPerVid = 5;
    framesPerVid = framesPerMin*minutesPerVid; %30 fps* 60 sec/min*5 min
else,
end;

cd(rootdir);
output = strrep(movementFile,'.mat','');
if(exist([output '.ps'],'file')),
    delete([output '.ps']);
end;

moveDat = load(movementFile);
moveBrainDat = moveDat.fullMovementAndBrainSignal;
movementUpperBound = moveDat.laserMovementThresh; %Useful for ylimit axes.
% 
movementDat = moveBrainDat(:,1);
% %(1): Log of movement
% movement_log = log(movementDat);
% [n,xout] = hist(movement_log,0.1:0.1:3);
% figure;
% plot(xout,n);
% 
% figure;
% plot(xout,cumsum(n));
% 
% figure;
% [n,xout] = hist(movementDat,0:20:200);
% plot(xout,n);
%
%By manually examining the movement trace, large movements appear to be in
%the range of 400-1800 while small movements appear to be ~200 (although of
%course there is some overlap between what we are defining as large and small).

smallMovementIndices = find(movementDat<smallVsLargeMovementBoundary);
h1 = figure(1);
set(h1,'Position',[10 500 1020*1.3 (576/2)*1.5]);

smallMovements = movementDat(smallMovementIndices);
subplot(1,3,1);
[n,xout] = hist(smallMovements,0:5:100);
plot(xout,n);
% figure;
subplot(1,3,2);
plot(xout,log10(n));

log10_n = log10(n);
zeroIndices = find(n==0);
log10_n(zeroIndices) = 0;
subplot(1,3,3);
plot(xout,cumsum(log10_n)/sum(log10_n));

h2 = figure(2);
set(h2,'Position',[10 500 1020*1.3 (576/2)*1.5]);

subplot(2,3,1);
[n,xout] = hist(abs(diff(smallMovements)),0:1:smallVsLargeMovementBoundary);
plot(xout,n);
xlabel(['abs(diff(movement)) < ' num2str(smallVsLargeMovementBoundary) ' px/frame']);
ylabel(['# of frames']);

zeroIndices = find(n==0);
% figure;
subplot(2,3,2);
log10_n = log10(n);
plot(xout,log10_n); hold on;

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
text(xout(inflectionIndex+2),1.1*log10_n(inflectionIndex+2),num2str(noMovementDiffThresh),'Color','r');

%%
figure (3);
fig3_spHandles = plotMovement(movementDat,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary);
axes(fig3_spHandles(1));
title(['No movement diff1 threshold = ' num2str(noMovementDiffThresh) ', red']);

%% Now: going to set all of the values below the smallVsLargeMovementBoundary and where the differential is less than the noMovementDiffThresh to 0.
figure (4);
smallMovementBinary = movementDat<smallVsLargeMovementBoundary;
movementDiffBelowThresh = abs(diff(movementDat))<noMovementDiffThresh;
display(size(movementDiffBelowThresh));
noMovementBinary = [movementDiffBelowThresh; 0];
movementDat_noMoveZero = movementDat;
zeroIndices = find(smallMovementBinary & noMovementBinary);
movementDat_noMoveZero(zeroIndices) = 0;
fig4sp_handles = plotMovement(movementDat_noMoveZero,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary,[0 0 0]);

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
movementStartIndices = find(diff(isMovingBinary)==1);
if(isMovingBinary(1)),
    movementStartIndices = [1; movementStartIndices];
end;
movementEndIndices = find(diff(isMovingBinary)==-1);
if(isMovingBinary(end))
    movementEndIndices = [movementEndIndices; numel(isMovingBinary)];
end;

probability_movement = nansum(isMovingBinary)/numel(movementDat_noMoveZero); %This is 0.2781 for an awake fly.

movementBoutParameters_frames = NaN(numel(movementStartIndices),5);
duration = movementEndIndices-movementStartIndices+1;
movementBoutParameters_frames(:,5) = duration(:);

timeSincePrecedingMovement = movementStartIndices(2:end)-movementEndIndices(1:(end-1));
timeSincePrecedingMovement = [movementStartIndices(1); timeSincePrecedingMovement(:)];
% At the end of this want to use a linear support vector machine to break
% up small and large movements. Use the line? plane? that's perpendicular
% to the axes defined by principal component analysis 
%
% Or should we use kmeans clustering to divide into two clusters (take log
% if histograms show it is necessary?)
%
% By naked eye though it looks like duration ought to be enough.
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
plot(xout,cumsum(log10_n)/sum(log10_n));
xlabel('Duration');
ylabel('Cum sum # of frames');
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
maxSmallMovementCutoff = sorted_duration(maxIndex);
text(maxIndex,0.95*cumsumNormalized_sortedDuration(maxIndex),num2str(maxSmallMovementCutoff),'Color','r');
ylabel(['Normalized Cum Sum (bout durations)']); xlabel('All Bout Rank Order (ascending duration)');

smallMovementsOnly = movementDat_noMoveZero;
for(bi = 1:numel(movementStartIndices)),
    if(duration(bi)>maxSmallMovementCutoff),
        smallMovementsOnly(movementStartIndices(bi):movementEndIndices(bi)) = 0;
    end;
end;

figure(4);
plotMovement(smallMovementsOnly,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary,[0.5 0.8 1],fig4sp_handles);
axes(fig4sp_handles(1));
title(['Small movement duration threshold = ' num2str(maxSmallMovementCutoff) ' frames, sky blue']);

figure(5);
%Need to look at duration from preceding bout:
% plot(duration(2:end), timeSincePrecedingMovement,'ko','MarkerSize',2);
%% What if time since preceding bout is less than the duration threshold?
%This cleary did not work (see below)
% smallMovementOnly = movementDat_noMoveZero;
% for(bi = 1:numel(movementStartIndices)),
% %     if(bi>1)
% %         display([num2str(duration(bi)) ' ' num2str(timeSincePrecedingMovement(bi-1))]);
% %     end;
%     if(duration(bi)>maxSmallMovementCutoff || (bi==1 || timeSincePrecedingMovement(bi-1)<maxSmallMovementCutoff)),
%         %Either too long or too closeto a bigmovement to be considered a small
%         %movement.
%         smallMovementOnly(movementStartIndices(bi):movementEndIndices(bi)) = 0;
%     end;
% end;
% figure(6);
% fig6_spHandles = plotMovement(movementDat_noMoveZero,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary); %,[0.5 0.8 1],fig4sp_handles);
% plotMovement(smallMovementOnly,framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,smallVsLargeMovementBoundary,[0.5 0.8 1],fig6_spHandles); %sp_handles);
% axes(fig4sp_handles(1));

%%
%Rank order duration vs rank order time since preceding bout?
timeSincePrecedingBout_sortedByDur = timeSincePrecedingMovement(sorted_duration_indices);
figure(5);
subplot(2,3,4);
plot(sorted_duration,cumsum(timeSincePrecedingBout_sortedByDur)/sum(timeSincePrecedingBout_sortedByDur));
plot(sorted_duration,1-cumsum(timeSincePrecedingBout_sortedByDur)/sum(timeSincePrecedingBout_sortedByDur));

subplot(2,3,5);
sortedTimeSincePrecedingBout = sort(timeSincePrecedingMovement,'ascend');
cumsumNormalized_sortedTimeSincePrecedingBout = cumsum(sortedTimeSincePrecedingBout)/sum(sortedTimeSincePrecedingBout); %sorted_duration);
plot(cumsumNormalized_sortedTimeSincePrecedingBout); hold on;

xval = 1:numel(sorted_duration);
ptList = [xval' cumsumNormalized_sortedTimeSincePrecedingBout(:)];
v1 = [xval(1) cumsumNormalized_sortedTimeSincePrecedingBout(1)];% 0];
v2 = [xval(end) cumsumNormalized_sortedTimeSincePrecedingBout(end)];% 0];
distancePerBout=point_to_line_distance(ptList,v1,v2); %, , [identityXY(:,end) 0]);
% display(max(distancePerFrameBin));
% display(min(distancePerFrameBin));
[maxval, maxIndex] = max(distancePerBout);
plot(maxIndex,cumsumNormalized_sortedTimeSincePrecedingBout(maxIndex),'ro');
maxSmallMovementCutoff = sortedTimeSincePrecedingBout(maxIndex);
text(maxIndex,0.95*cumsumNormalized_sortedTimeSincePrecedingBout(maxIndex),num2str(maxSmallMovementCutoff),'Color','r');
ylabel(['Normalized Cum Sum (bout durations)']); xlabel('All Bout Rank Order (ascending duration)');

figure(6);
fig6sp_handles = plotMovement(smooth(movementDat_noMoveZero(:),6),framesPerVid,framesPerMin,minutesPerVid,noMovementDiffThresh,movementUpperBound,[0 0 0]);
%% Save the plots in question.
for(fignum = 1:5),
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
        else,
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