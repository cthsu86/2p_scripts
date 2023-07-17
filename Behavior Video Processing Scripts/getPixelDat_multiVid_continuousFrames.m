% function	getPixelDat_multiVid_continuousFrames.m()
% •	Create a raw mean pixel vector for the BEHAVIOR video.
%
% Unlike previous versions of getPixelDat_multiVid, this script was written
% on October 8, 2020,and does not require an external Excel spreadsheet
% with annotations of laser onset and laser offset. This was developed to
% be compatible with our new format of continuous recordings, where the
% laser light is on continuously and frames are also recorded continuously.
% To facilitate file managemennt however, the frames are converted to a
% series of *.avis after the recording period using the script
% writeFrames2BehaviorVid.m. getPixelDat_multiVid_continuousFrames assumes
% that writeFrames2BehaviorVid.m was run before it.
%
% Edited on Feb 03, 2021 to include a "userDrawnLaserArea.mat" to exclude.

function getPixelDat_multiVid_continuousFrames()
% beh_rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201119';
beh_rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
cd(beh_rootdir);

%Assuming that the *.avis in the file follow the same naming format as in
%writeFrames2BehaviorVid.m
recordedFPS = 30;
framesPerVid = 5*60*recordedFPS;


% aviRoot = 'fc2_save_2020-11-19-154903-_2Xspeed_frame';
aviRoot = 'fc2_save_2020-11-16-154724-_2Xspeed_frame'; %63000to71999
% aviRoot = 'fc2_save_2020-09-14-170551-_3Xspeed_frame'; 
%Stop before frame numbers (up to and including the word 'frame')
frameStart = 117000; %9000; %Usually equal to 0. Matches the first frame of the first video.
lastFrameNum = 125999; %164703; %Easiest if we just manually put this in after looking at what was the last frame (last video) in the folder.

numZeroPad = 4;
currentUpperBound = 10^(numZeroPad+1);
% 
% userDrawnAreaToExclude_file = 'fc2_save_2020-11-16-154724-_2Xspeed_frame117000to125999_frame1to9000userDrawnLaserArea.mat';
% userDrawnAreaToExclude_imgMat = load(userDrawnAreaToExclude_file);
% userDrawnAreaToExclude_imgMat = userDrawnAreaToExclude_imgMat.maskmat;
% pixelsToExclude = find(userDrawnAreaToExclude_imgMat(:)>0);

for(segmentFrameStart = [frameStart:framesPerVid:lastFrameNum]),
    frameEnd = segmentFrameStart+framesPerVid-1;
    if(frameEnd>=lastFrameNum),
        frameEnd = lastFrameNum; %-1 since it starts at zero.
    end;
    vidname = [aviRoot num2str(segmentFrameStart) 'to' num2str(frameEnd) '.avi'];
    
    numFramesInVidSegment = frameEnd-segmentFrameStart+1;
%         bgImgName = computeBGandSDForFrameRange(vidname,1,numFramesInVidSegment);

    bgImgName = computeBackgroundForFrameRange(vidname,1,numFramesInVidSegment);
    bgsubtractAndDiffForFrameRange(vidname,1,numFramesInVidSegment,bgImgName); %,pixelsToExclude);
    %Movement while the laser is on. - The code below is most likely from
    %before 2020.
%         bgImgName = computeBackgroundForFrameRange(vidname,laserOnFrame,laserOffFrame);
%         bgsubtractAndDiffForFrameRange(vidname,laserOnFrame,laserOffFrame,bgImgName)
    %     %
    %     if(lri==size(laserDat,1)),
    %         bgImgName = computeBackgroundForFrameRange(vidname,laserOffFrame,'end');
    %         bgsubtractAndDiffForFrameRange(vidname,laserOffFrame,'end',bgImgName);
    %     end;
    %     %
    %     prevVidName = vidname;
    %     prevOnset = laserOnFrame;
    %     prevOffset = laserOffFrame;
end;