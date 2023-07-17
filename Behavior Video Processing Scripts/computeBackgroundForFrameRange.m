%% function bgImgName = computeBackgroundForFrameRange(varargin)
% Outputs an image NAME of a background image (not hte image of itself).
% If none is available, will save it to the local root directory.


function bgImgName = computeBackgroundForFrameRange(varargin) %vidname,laserStart,laserEnd)
if(nargin==0),
    beh_rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180601';
    vid2read = 'fc2_save_2018-06-01-153937-0000.avi';
    %     frameStart = 483;
    cd(beh_rootdir);
    frameStart = 1;
    frameEnd = 144;
else,
    vid2read = varargin{1};
    frameStart = varargin{2};
    frameEnd = varargin{3};
end;

bgImgName = strrep(vid2read,'.avi',['_frame' num2str(frameStart) 'to' num2str(frameEnd) '.png'])

% Create a raw mean pixel vector for the BEHAVIOR video. 
% Look at the distribution in the mean pixel intensity, the median pixel intensity, and
% the max pixel intensity. 
% Use this to assign ranges of video to mean
% subtract for background subtraction. ?	Figure out how to go about
% picking out the pixel intensity of the laser – maybe consider plotting an
% imagesc of pixel intensities 1:255 in the Y, the number of pixels with
% the intensity in question, and the time on the x-axis. ?	Create a frame
% by frame background subtracted image => maybe run it through the
% getPixelDat.m script again?
if(~exist(bgImgName,'file')),
    tic;
    % if(~exist(strrep(vid2read,'.avi','.mat'))),
    display(pwd);
    display(vid2read);
    vid = VideoReader(vid2read);
    if(strcmp(frameEnd,'end')),
        frameEnd = vid.NumberofFrames;
    end;
    % NaN(
    for(ti = frameStart:frameEnd),
        display(ti);
        thisFrame = read(vid,ti);
        if(ti == frameStart)
            sumOfFrames = double(thisFrame);
        else,
            sumOfFrames = sumOfFrames+double(thisFrame);
        end;
    end;
    toc
    display(['Writing ' bgImgName]);
    display(['Write directory ' pwd]);
    imwrite(uint8(sumOfFrames/(frameEnd-frameStart+1)),bgImgName);
end;