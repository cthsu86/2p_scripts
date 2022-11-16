function quiescenceTriggeredAverage_testPlots(varargin)
% clear all;
close all;
tic;
if(nargin==0),
    rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
    matname = 'TSeries-11162020-1436-551_Cycle00001_Ch2__maskReg137 154_Cycle00001_fullMovementAndBrainSignal.mat';
    
    frame2start = 9001;
    frame2end = 13500;
else,
    rootdir = varargin{1};
    matname = varargin{2};
    frame2start = varargin{3};
    frame2end = varargin{4};
end;

% fc2_save_2020-09-14-170551-_3Xspeed_frame108000to116999_frame1to9000
% frame2start = 108001;
% frame2end = 117000;

smoothingWindow = round(0.5*30); %200 ms, 30 frames per second.

cd(rootdir)

A = load(matname);
movementAndBrainSignal = A.fullMovementAndBrainSignal;
seconds = [1:(frame2end-frame2start+1)]/30;

smoothedMovement = smooth(movementAndBrainSignal((frame2start-2*smoothingWindow):(frame2end+2*smoothingWindow),1),smoothingWindow);
smoothedBrainSignal = smooth(movementAndBrainSignal((frame2start-2*smoothingWindow):(frame2end+2*smoothingWindow),2),smoothingWindow);
display(['Have finished smoothing.']);
toc

figure(1);
display(size(seconds));
display(size(smoothedMovement));
area(seconds,smoothedMovement((2*smoothingWindow+1):(end-2*smoothingWindow))); hold on;

% minBrainSignal = min(movementAndBrainSignal(frame2start:frame2end,1),2);
% maxBrainSignal = max(movementAndBrainSignal(frame2start:frame2end,2)-minBrainSignal);
% normalizedBrainSignal = (movementAndBrainSignal(frame2start:frame2end,2)-minBrainSignal)/maxBrainSignal*A.laserMovementThresh/3;

%Normalizing relative to the whole trace (rather than the frames of interest) seems to get rid of extraneous
%noise during no movement parts?
% minBrainSignal = quantile(movementAndBrainSignal(:,2),0.05);
minBrainSignal = min(smoothedBrainSignal);
%But using "minBrainSignal" specific to the frames of interest helps
%prevent the
maxBrainSignal = max(smoothedBrainSignal-minBrainSignal);
normalizedBrainSignal = (smoothedBrainSignal((2*smoothingWindow+1):(end-2*smoothingWindow))-minBrainSignal)/maxBrainSignal*A.laserMovementThresh*0.6;


plot(seconds,normalizedBrainSignal,'g','LineWidth',2);
% title(['Brain signal axis limits = [' num2str(min(normalizedBrainSignal))

if(nargin>0),
    saveas(figure(1),strrep(matname,'.mat',[num2str(frame2start) 'to' num2str(frame2end) '.png']));
end;