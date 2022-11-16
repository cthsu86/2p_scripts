function demovid_brainBehavior
close all; clear all;
brain_fps = 1/10.3; %2.7263*9;
behavior_fps = 30;
% brainVideoStart_seconds = 200;
behaviorStartFrame = 1; %3538-60; 
behaviorEndFrame = 900; %8349+30*120; %behaviorStartFrame+60*behavior_fps; %13784+behavior_fps*5; %'end';
secondsDelayUntilBrainVideo = 2/3;
slicesPerStack = 44;
% redLEDoffset_secs = 120;

medfiltSize = 3;
% brainVideoStart_frames =


rootdir = 'D:\MB077B\200914\200914_TSeries'
TSeriesFolder = 'TSeries-09142020-1655-478';
behaviorVideoName = 'fc2_save_2020-09-14-170551-_3Xspeed_frame27000to35999.avi';

TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_']; %000001.ome
% TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
% Only purpose of TProjMask here is to provide the matname.
% TProjMask = [TSeriesFolder '_Cycle00001_Ch2__maskReg2.mat'];
% signalMatname = strrep(TProjMask, '.mat','Intensities.mat');

% rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP'
% venus_matname = 'TSeries-03132018-1305-179_Cycle00001_Ch1_mask.mat';
% gcamp_matname = strrep(venus_matname,'_Ch1_mask.mat','_Ch2__maskedByCh1.mat');

cd(rootdir)

% % output = strrep(signalMatname,'.mat','');
% if(exist([output '.ps'],'file')),
%     delete([output '.ps']);
% end;

% A = load(signalMatname)
% regions = A.regionPropsArray;

%Use the behavior video as a frame of reference.
behaviorVid = VideoReader(behaviorVideoName);
if(strcmp(behaviorEndFrame,'end')),
    behaviorEndFrame = behaviorVid.NumberofFrames;
end;
% behaviorVid2show = read(behaviorVid,[behaviorStartFrame behaviorEndFrame]);

vidObj = VideoWriter(strrep(behaviorVideoName,'.avi',['Frame' num2str(behaviorStartFrame) 'to' num2str(behaviorEndFrame) '.avi']));
open(vidObj);

h=figure(1);
for(bfi = 1:5:(behaviorEndFrame-behaviorStartFrame+1));
    subplot(1,2,1);
    
    behaviorImg = read(behaviorVid,(behaviorStartFrame+bfi-1));
    imshow(behaviorImg);
    
    
    %Need to convert the frame # to the corresponding timepoint in the
    %Tseries data.
    secondsSinceBehaviorStart = bfi/behavior_fps;
    if(secondsSinceBehaviorStart>=secondsDelayUntilBrainVideo),
        tFrameNumber = floor((secondsSinceBehaviorStart-secondsDelayUntilBrainVideo)*brain_fps)+1;
        %     framesSinceLEDoffset = tFrameNumber-redLEDoffset*brain_fps;
        %     secondsSinceLEDoffset = tFrameNumber/brain_fps-redLEDoffset_secs;
        
        %     ledCaption = sprintf('%0.1f seconds since 1 min 660nm pulse turned off',secondsSinceLEDoffset);
        %     text(10,size(behaviorVid2show,1)*1.1,ledCaption,'Color','r');
        if(tFrameNumber>0),
        subplot(1,2,2);
        cd(TSeriesFolder)
        
        for(si = 1:slicesPerStack); %(tFrameNumber+slicesPerStack-1)),
            brainImgName = [TImgRoot num2str(si,'%06.0f') '.ome.tif'];
            if(tFrameNumber>1),
            brainImgName = strrep(brainImgName,'Cycle00001',['Cycle' num2str(tFrameNumber,'%05.0f')]);
            end;
%             TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_']; %000001.ome
            if(exist(brainImgName,'file')),
                rawImg = imread(brainImgName); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
                medfiltFrame = medfilt2(rawImg,[medfiltSize medfiltSize]);
                
                if(si==1), %tFrameNumber),
                    summedImg = zeros(size(rawImg,1),size(rawImg,2));
                end;
                summedImg = summedImg+double(medfiltFrame);
%                 display(['Have read imgname ' brainImgName]);
            else,
%                 display(['Could not find ' brainImgName]);
            end;
        end;
        display(['Showing brain frame ' num2str(tFrameNumber) ' for ' num2str(secondsSinceBehaviorStart) ' seconds since behavior start.']);
            imagesc(1:size(summedImg,2),1:size(summedImg,1),summedImg,[300 12000]); axis equal;
            colorbar south;
            set(gca,'XTickLabel',[],'YTickLabel',[]);
        end;
%     imshow(medfiltFrame*100);
    cd('..');

    end;
    
    %     tFrameNumber =
    I = getframe(h);
    writeVideo(vidObj,I);
    %          close(figure(1));
end;
close(vidObj);