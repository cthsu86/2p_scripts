rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\MB107\OK107 GCaMP6m 180131';
vid2read = 'fc2_save_2018-01-31-174845-0000.avi';
vid2read_fps = 30;
timeThresh = 60; %vid2read_fps*1.2; %in frames.
%ideally should encompass twice the period length of the two photon.
% twoPhoton_fps = 20;

cd(rootdir);

vid = VideoReader(vid2read);
% read(vid,[1 vid]);
meanPxIntensity = NaN(vid.NumberofFrames,1);
% display(size(vid));
for(ti = 1:(vid.NumberofFrames)),
% for(ti = 1:(vid2read_fps*5)), %(vid.NumberofFrames)),
    display(ti);
    thisFrame = read(vid,ti);
    meanPxIntensity(ti) = sum(thisFrame(:))/numel(thisFrame);
end;

plot(meanPxIntensity);
display(max(meanPxIntensity(1:500)));
%Examine this output to determine when the light turned on.
lightOnThresh = 49;
display(lightOnThresh);

% pause; %Pause to make sure this is accurate.
close(figure(1));
ti_prev = ti;
for(ti = ti_prev:vid.NumberofFrames),
    display(ti);
    thisFrame = read(vid,ti);
    meanPxIntensity(ti) = sum(thisFrame(:))/numel(thisFrame);
end;

isLightOn = ones(size(meanPxIntensity));
putativeLightsEnd = find(diff(meanPxIntensity<lightOnThresh)==1)+1;
putativeLightsStart = find(diff(meanPxIntensity<lightOnThresh)==-1);
if(meanPxIntensity(1)<lightOnThresh),
    putativeLightsEnd = [1; putativeLightsEnd];
end;
if(meanPxIntensity(end)<lightOnThresh),
    putativeLightsStart = [putativeLightsStart; numel(meanPxIntensity)];
end;

lightsOffTime = putativeLightsStart-putativeLightsEnd;
trueLightsOffIndex = find(lightsOffTime>timeThresh);
for(ti = 1:numel(trueLightsOffIndex)),
    isLightOn(putativeLightsEnd(trueLightsOffIndex(ti)):putativeLightsStart(trueLightsOffIndex(ti))) = 0;
end;
plot(meanPxIntensity); hold on;
bar(isLightOn*40,'r');