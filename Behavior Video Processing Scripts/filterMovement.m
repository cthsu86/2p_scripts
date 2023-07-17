function filterMovement(varargin)
if(nargin==0),
    beh_rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Raw Data\OK107_UAS_GCaMP6m_180216';
    %     vid2read = 'fc2_save_2018-02-16-162351-0000_frame483to5911_frame1to5429.avi';
    % mat2read = 'fc2_save_2018-02-16-162351-0000_frame483to5911_frame1to5429_diff.mat'
    mat2read = 'fc2_save_2018-02-16-162351-0000_frame483to5911_diff.mat'
end;

cd(beh_rootdir);
A = load(mat2read);
diffArray = A.diffArray;
if(min(size(diffArray))~=1),
    diffArray = diffArray(:,1);
end;

plot(diffArray,'k'); hold on;

Fpass = 15;
Fstop = 150;
Apass = 1;
Astop = 65;
Fs = 1e3;

d = designfilt('lowpassfir', ...
  'PassbandFrequency',Fpass,'StopbandFrequency',Fstop, ...
  'PassbandRipple',Apass,'StopbandAttenuation',Astop, ...
  'DesignMethod','equiripple','SampleRate',Fs);

y = filter(d,diffArray); %[diffArray; zeros(D,1)]);
plot(y(round(Fpass/2):end),'r');

figure; plot(diff(y));