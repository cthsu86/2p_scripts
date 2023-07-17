rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\MB107\OK107 GCaMP6m 171218';
vid2read = 'fc2_save_2017-12-18-153437-0000.avi';
vid2read_fps = 30;
timeThresh = 60; %vid2read_fps*1.2; %in frames.
%ideally should encompass twice the period length of the two photon.
% twoPhoton_fps = 20;

cd(rootdir);

vid = VideoReader(vid2read);
% read(vid,[1 vid]);
meanPxIntensity = NaN(vid.NumberofFrames,1);
% display(size(vid));
for(ti = 3450:3650), %(vid2read_fps*5)), %(vid.NumberofFrames)),
%     display(ti);
    thisFrame = read(vid,ti);
    meanPxIntensity(ti) = sum(thisFrame(:))/numel(thisFrame);
end;
