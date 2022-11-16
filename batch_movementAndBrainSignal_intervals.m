rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
matname = 'TSeries-11162020-1436-551_Cycle00001_Ch2__maskReg137 154_Cycle00001_fullMovementAndBrainSignal.mat';

frame2start = 13501;
frame2end = 153001;

frameRanges = [frame2start:4500:frame2end];

for(fi=1:(numel(frameRanges)-1)),
    quiescenceTriggeredAverage_testPlots(rootdir,matname,frameRanges(fi),frameRanges(fi+1));
end;