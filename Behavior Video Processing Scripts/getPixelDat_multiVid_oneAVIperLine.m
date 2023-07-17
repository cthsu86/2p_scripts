% function	getPixelDat_multiVid.m()
% •	Create a raw mean pixel vector for the BEHAVIOR video.

function getPixelDat_multiVid()

beh_rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180608';
annot_rootdir = beh_rootdir;
beh_fps = 30;
laserOnsetColNum = 3;
laserOffsetColNum = 4;

% laser_fps = 10;
% laserOnFoldChange_bgThresh = beh_fps/laser_fps; %multiply the background image by this intensity when subtracting?

cd(annot_rootdir);
xlsxList = dir(['*.xlsx']);

%Iterate through the xlsxList, looking for the xlsx file which has the
%parameters
for(xi = 1:numel(xlsxList)),
    [status, sheets] = xlsfinfo(xlsxList(xi).name);
    if(size(sheets,1)==1),
        [num,txt,raw] = xlsread(xlsxList(xi).name); %,'Laser');
        display(raw);
        laserDat = raw;
    else,
    for(si = 1:size(sheets,1)),
        try,
            if(strcmp(sheets{si},'Laser')==1),
                [num,txt,raw] = xlsread(xlsxList(xi).name,'Laser');
                display(raw);
                laserDat = raw;
            end;
        catch,
        end;
    end;
    end;
end;

%Find the column that contains the VideoName column.
% vidname_colNum = 1;
for(ci = 1:size(laserDat,2)),
    if(~isempty(strfind(laserDat{1,ci},'ideo'))),
        vidname_colNum = ci;
    end;
end;

%Next, want to generate a list of *.avi files in the folder:
cd(beh_rootdir);
% aviList = dir(['*.avi']);
for(lri = 1:size(laserDat,1)),
% for(ai = 1:size(laserDat,1)),
    vidname = laserDat{lri,vidname_colNum};
    if(ischar(vidname) && exist(vidname,'file')),
%     for(lri = 1:size(laserDat,1)),
%         if(strcmp(laserDat{lri,vidname_colNum},vidname)),
            %getPixelDat_singleVid(vidname,laserDat{lri,1},laserDat{lri,2});
            %outcome: save(strrep([vid2read],'.avi','_pixelDat.mat'),'meanPxIntensity','maxPxIntensity','pxIntensityDistribution','pxIntensityBins','medianPxIntensity');
            laserOnFrame = laserDat{lri,laserOnsetColNum};
            laserOffFrame = laserDat{lri,laserOffsetColNum};
            
            if(laserOnFrame~=0),
            bgImgName = computeBackgroundForFrameRange(vidname,1,laserOnFrame);
            bgsubtractAndDiffForFrameRange(vidname,1,laserOnFrame,bgImgName);
            
            bgImgName = computeBackgroundForFrameRange(vidname,laserOnFrame,laserOffFrame);
            bgsubtractAndDiffForFrameRange(vidname,laserOnFrame,laserOffFrame,bgImgName)

            bgImgName = computeBackgroundForFrameRange(vidname,laserOffFrame,'end');
            bgsubtractAndDiffForFrameRange(vidname,laserOffFrame,'end',bgImgName);
            end;

            %     vidname = varargin{1};
            %     laserStart = varargin{2};
            %     laserEnd = varargin{3};
            
            %Next: will want to subtract the background image from the
            %video. The basic code for this is in the function
            %bgsubtractForFrameRange, BUT:
            % - May be more efficient to combine bgsubtractForFrameRange
            % and bgdiffForFrameRange.
            % - Previous test videos involved running
            % bgsubtractForFrameRange twice (generating a new bakcground the second time) to remove some of the noise. Am
            % not sure if this is necessary?
            % --- Does not seem to be the case, when comparing the
            % consequence of running filterMovement.m on either 
            % % mat2read =
            % 'fc2_save_2018-02-16-162351-0000_frame483to5911_frame1to5429_diff.mat'
            % or'fc2_save_2018-02-16-162351-0000_frame483to5911.mat'
            % - Turn off video writing for when the function is called.
%         end;
    end;
end;