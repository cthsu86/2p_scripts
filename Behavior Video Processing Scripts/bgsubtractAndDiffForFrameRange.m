function bgsubtractAndDiffForFrameRange(varargin), %vidname,laserStart,laserEnd)
if(nargin==0),
    beh_rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
    vid2read = 'fc2_save_2020-11-16-154724-_2Xspeed_frame117000to125999.avi';
    frameStart = 1; %483;
    frameEnd = 5*60*30;
    bgImgName = strrep(vid2read,'.avi',['_frame' num2str(frameStart) 'to' num2str(frameEnd) '.png']);
    
    cd(beh_rootdir);
else,
    vid2read = varargin{1};
    frameStart = varargin{2};
    frameEnd = varargin{3};
    bgImgName = varargin{4};
    if(nargin==5),
        pixelsToExclude = varargin{5};
    end;
end;
debugVideo = 0;
pxIntensityBins = [0:5:255];

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


tic;
% if(~exist(strrep(vid2read,'.avi','.mat'))),
vid = VideoReader(vid2read);
if(strcmp(frameEnd,'end')),
    frameEnd = vid.NumberofFrames;
end;
bgImg = imread(bgImgName);

vid2write = strrep(bgImgName,'.png','.avi'); %Need this for also creating the diffArray output.
if(nargin==0 || debugVideo),
    vidOut = VideoWriter(vid2write);
    open(vidOut);
end;

diffArray = NaN(vid.NumberofFrames,1);
for(ti = frameStart:2:(frameEnd-1)),
    display(ti);
    
    framePair = read(vid,[ti:ti+1]);
    bgSubImgA = rgb2gray(imsubtract(framePair(:,:,:,1),bgImg));
    %     if(exist('pixelsToExclude','var')),
    %         bgSubImgA(pixelsToExclude)=0;
    %     end;
    if(ti>frameStart),
        %Previously declared bgSubImgB.
        bgImgDiffA =  double(bgSubImgA)-double(bgSubImgB);
        IA = uint8(abs(bgImgDiffA));
        bwIA = double(im2bw(IA,0.1));
        if(exist('pixelsToExclude','var')),
            bwIA(pixelsToExclude)=0;
        end;
        diffArray(ti) = sum(bwIA(:));
        if(nargin==0 || debugVideo);
            writeVideo(vidOut,bwIA);
        end;
    end;
    bgSubImgB = rgb2gray(imsubtract(framePair(:,:,:,2),bgImg));
    %     if(exist('pixelsToExclude','var')),
    %         bgSubImgB(pixelsToExclude)=0;
    %     end;
    bgImgDiffB = double(bgSubImgB)-double(bgSubImgA);
    IB = uint8(abs(bgImgDiffB));
    bwIB = double(im2bw(IB,0.1));
    if(exist('pixelsToExclude','var')),
        bwIB(pixelsToExclude)=0;
    end;
    diffArray(ti+1) = sum(bwIB(:));
    
    if(nargin==0 || debugVideo);
        writeVideo(vidOut,bwIB);
    end;
end;
if(nargin==0),
    close(vidOut);
end
toc

save(strrep(vid2write,'.avi','.mat'),'diffArray');