%% function bgImgName = computeBGandSDForFrameRange(varargin)
%
% February 03, 2021.
% Modified from computeBackgroundForFrameRange, which outputs an image NAME of a background image (not hte image of itself).
% If none is available, will save it to the local root directory.
%
% Abandoned on February 05, 2021, upon discovering that this approach is
% too memory intensive.


function bgSD_matname = computeBackgroundForFrameRange(varargin) %vidname,laserStart,laserEnd)
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
bgSD_matname = strrep(bgImgName,'.png','_bg_SD.mat');

% bgDiffVector = NaN(frameEnd-frameStart+1,1);

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
if(~exist(bgSD_matname,'file')),
    tic;
    % if(~exist(strrep(vid2read,'.avi','.mat'))),
    display(pwd);
    display(vid2read);
    vid = VideoReader(vid2read);
    if(strcmp(frameEnd,'end')),
        frameEnd = vid.NumberofFrames;
    end;
    allFrames = read(vid, [frameStart frameEnd]);
    
    %    rgb2gray converts RGB values to grayscale values by forming a weighted sum of the R, G, and B components:
    %0.2989 * R + 0.5870 * G + 0.1140 * B
    allFrames_gray = squeeze(0.28989*allFrames(:,:,1,:)+0.5870*allFrames(:,:,2,:)+0.1140*allFrames(:,:,3,:));
    clear allFrames;
    allFrames_gray_double = single(allFrames_gray);
    allFrames_avg = mean(allFrames_gray_double,3);
    allFrames_sd = std(abs(allFrames_gray_double),3);
    allFrames_bgDiff = abs(allFrames_gray_double-allFrames_avg);
    allFrames_sd_diff = std(allFrames_gray_double-allFrames_avg,3);
    allFrames_bgDiff_2xSD = allFrames_bgDiff>(2*allFrames_sd_diff);
    bgDiffVector = squeeze(sum(squeeze(sum(allFrames_bgDiff_2xSD,1)),1));
    bgDiffVector = bgDiffVector(:);
    
    display(['Writing ' bgImgName]);
    display(['Write directory ' pwd]);
    imwrite(uint8(allFrames_avg),bgImgName);
    save(bgSD_matname,'-struct','allFrames_gray','allFrames_avg','allFrames_sd','allFrames_sd_diff','bgDiffVector');
end;