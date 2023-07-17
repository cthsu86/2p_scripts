% October 7, 2020
% Wrote to account for the following issues:
% 1) Prolonged 90 minute video, which requires capturing in *.pgm rather than *.avi format.
% 2) The fact that for 90 minutes, we end up with SIX digits and flycapture

close all; clear all;

rootdir = 'D:\HugS2_ASAP2'; %File outputs will be saved here.
flyTiffFolder = '210519_HugASAP2s_behavior'; %Location of the frames. Assuming this is a subfolder of rootdir (above).
behaviorImgRoot = 'fc2_save_2021-05-19-152655-'; %everything but the zero padded 4 to 6 digit frame rank order.

recordedFPS = 30;
fps2write = 60;
xSpeedVal = round(fps2write/recordedFPS*100)/100;
framesPerVid = 5*60*recordedFPS;

tic;
cd(rootdir);
% First, want to take a look at how many frames we have:
cd(flyTiffFolder);
tiffList = dir([behaviorImgRoot '*.pgm']);
%display(numel(tiffList));
numFrames = numel(tiffList);

% Now, go back into the root directory and begin writing videos:
numZeroPad = 4; %Number of zeros in first (zeroth) frame - note that Flycap will automatically increase the number of digits once this is exceeded.
currentUpperBound = 10^(numZeroPad+1);

frameStart = 0;
% frameStartText = num2str(ti-1,['%0' num2str(numZeroPad) '.0f']);
allVidsEnd = (numFrames-1);

for(segmentFrameStart = [frameStart:framesPerVid:allVidsEnd]);
    frameEnd = segmentFrameStart+framesPerVid-1;
    if(frameEnd>=numFrames),
        frameEnd = (numFrames-1); %-1 since it starts at zero.
    end;
    cd(rootdir);
%     tic;
    vidObj = VideoWriter([behaviorImgRoot '_' num2str(xSpeedVal) 'Xspeed_frame' num2str(segmentFrameStart) 'to' num2str(frameEnd) '.avi'],'Motion JPEG AVI');
    vidObj.FrameRate = fps2write;
    open(vidObj);
    
    cd(flyTiffFolder);
    for(fi = segmentFrameStart:frameEnd), %numel(tiffList)),
        if(fi>currentUpperBound);
            numZeroPad = numZeroPad + 1;
            currentUpperBound = 10^(numZeroPad+1);
        end;
%         display(fi);
%         display(currentUpperBound);
%         display(numZeroPad);
        imgName = [behaviorImgRoot sprintf(['%0' num2str(numZeroPad) '.0f'],fi) '.pgm'];
        if(exist(imgName,'file')),
        thisFrame = imread(imgName);
        writeVideo(vidObj,thisFrame);
        end;
%         if(mod(fi,100)==0),
%             display(fi);
%             toc;
%         end;
    end;
    close(vidObj);
    display(['frameStart = ' num2str(segmentFrameStart) ', last Frame Written: ' imgName]);
end;

%Two photon started at 176.
%9927
% cd ..
% save([flyTiffFolder '_vid.mat'],allFrames);