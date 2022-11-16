close all; clear all;
brain_fps = 1/0.13278*3;
behavior_fps = 30;
signalAmplitude = 50;
signalOffset = 450;

relativeToLEDoffset = 0;
if(relativeToLEDoffset),
    redLEDoffset_secs = 120;
    redLEDoffset_behaviorFrame = 18013;
    secsAfterLEDoffset_start=0;
    brainVideoStart_seconds = redLEDoffset_secs+secsAfterLEDoffset_start; %200;
    behaviorStartFrame = redLEDoffset_behaviorFrame+secsAfterLEDoffset_start*behavior_fps;
    % behaviorEndFrame = 'end';
    behaviorEndFrame = behaviorStartFrame+behavior_fps*60;
else,
    %Relative to start of the two-photon brain data.
    twoPhotonOnset_behaviorFrame = 9923;
    secsAfterTwoPhotonOnset = 0;
    
    %As with relativeToLEDoffset, need to output
    brainVideoStart_seconds = secsAfterTwoPhotonOnset;
    behaviorStartFrame = twoPhotonOnset_behaviorFrame+secsAfterTwoPhotonOnset*behavior_fps;
    behaviorEndFrame = behaviorStartFrame+behavior_fps*120;
end;

medfiltSize = 7;
% brainVideoStart_frames =


rootdir = 'D:\2310lexA_CsChRimson_84C10Gal4_GCaMP6m_180418'
TSeriesFolder = 'TSeries-04182018-1602-207';
behaviorVideoName = 'fc2_save_2018-04-18-172419-0000.avi';

TImgRoot = [TSeriesFolder '_Cycle00001_Ch2_']; %000001.ome
% TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
% Only purpose of TProjMask here is to provide the matname.
TProjMask = [TSeriesFolder '_Cycle00001_Ch1_maskReg7.mat'];
% TSeries-04062018-1633-199_Cycle00001_Ch1_maskReg45Intensities
signalMatname = strrep(TProjMask, '.mat','Intensities.mat');

% rootdir = 'D:\23E10lexA_CsChRimson_84C10Gal4_GCaMP'
% venus_matname = 'TSeries-03132018-1305-179_Cycle00001_Ch1_mask.mat';
% gcamp_matname = strrep(venus_matname,'_Ch1_mask.mat','_Ch2__maskedByCh1.mat');

cd(rootdir)

output = strrep(signalMatname,'.mat','');
if(exist([output '.ps'],'file')),
    delete([output '.ps']);
end;

A = load(signalMatname)
regions = A.regionPropsArray;

%Use the behavior video as a frame of reference.
behaviorVid = VideoReader(behaviorVideoName);
if(strcmp(behaviorEndFrame,'end')),
    behaviorEndFrame = behaviorVid.NumberofFrames;
end;
behaviorVid2show = read(behaviorVid,[behaviorStartFrame behaviorEndFrame]);
%
% meanPixelIntensityPerFrame = NaN(size(regions,1),2);
% for(ti = 1:size(regions,1)),
%     thisFrameRegions = regions{ti,2};
%     %thisFrameRegions is a two cell array of pixel intensities. The first cell contains pixel intensity data
%     %from the MASK (probably the mCherry signal). The second cell contains
%     %the pixel intensity data from the frames being masked (probably the
%     %GCamP6m signal).
%
%     sumPixelIntensity = 0;
%     numPixels = 0;
%     sumGCaMPIntensity = 0;
%     numPixels_GCaMP = 0;
%     for(si = 1:size(thisFrameRegions,1)),
%
%         %First block of code: run the average mean pixel intensity for the
%         %first channel (mCherry).
%         sumPixelIntensity = sumPixelIntensity+sum(thisFrameRegions{si,1});
%         numPixels = numPixels+numel(thisFrameRegions{si,1});
%
%         sumGCaMPIntensity = sumGCaMPIntensity+sum(thisFrameRegions{si,2});
%         numPixels_GCaMP = numPixels_GCaMP+numel(thisFrameRegions{si,2});
%     end;
%     display(sumPixelIntensity);
%     display(numPixels);
%     meanPixelIntensityPerFrame(ti,1) = sumPixelIntensity/numPixels;
%
%     meanPixelIntensityPerFrame(ti,2) = sumGCaMPIntensity/numPixels_GCaMP;
% end;
vidObj = VideoWriter(strrep(behaviorVideoName,'.avi',['Frame' num2str(behaviorStartFrame) 'to' num2str(behaviorEndFrame) '_behavior.avi']));
open(vidObj);

h=figure(1);
for(bfi = 1:size(behaviorVid2show,4));
    subplot(1,1,1);
    imshow(behaviorVid2show(:,:,:,bfi));
    hold on;
    
    %Need to convert the frame # to the corresponding timepoint in the
    %Tseries data.
    secondsSinceBehaviorStart = bfi/behavior_fps;
    tFrameNumber = round(brainVideoStart_seconds*brain_fps+secondsSinceBehaviorStart*brain_fps);
    %     framesSinceLEDoffset = tFrameNumber-redLEDoffset*brain_fps;
    
    
    secs2plot = 5;
    signalStart2plot = round(tFrameNumber-brain_fps*secs2plot);
    signalEnd2plot = round(tFrameNumber+brain_fps*secs2plot);
    if(signalStart2plot<1),
        signalStart2plot = 1;
    end;
    if(signalEnd2plot>max(size(A.normalizedIntensity)))
        signalEnd2plot = max(size(A.normalizedIntensity,1));
    end;
    plot(A.normalizedIntensity(signalStart2plot:signalEnd2plot)*-signalAmplitude+signalOffset);
    %     display(max(A.normalizedIntensity(signalStart2plot:signalEnd2plot)*-10+450));
    %     display(min(A.normalizedIntensity(signalStart2plot:signalEnd2plot)*-10+450));
    plot([secs2plot secs2plot]*brain_fps,[signalOffset-signalAmplitude signalOffset],'Color',[1 1 0]);
    plot([0 2*secs2plot],[signalOffset signalOffset],'Color',[1 1 0]);
    
    if(relativeToLEDoffset),
        secondsSinceLEDoffset = tFrameNumber/brain_fps-redLEDoffset_secs;
        ledCaption = sprintf('%0.1f seconds since 1 min 660nm pulse turned off',secondsSinceLEDoffset);
    else,
        ledCaption = sprintf('%0.1f seconds',tFrameNumber/brain_fps);
    end;
    text(10,size(behaviorVid2show,1)*1.1,ledCaption,'Color','r');
    
    
    %     subplot(1,2,2);
    %     cd(TSeriesFolder)
    %     brainImgName = [TImgRoot num2str(tFrameNumber,'%06.0f') '.ome.tif'];
    %     if(exist(brainImgName,'file')),
    %     rawImg = imread(brainImgName); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
    %     medfiltFrame = medfilt2(rawImg,[medfiltSize medfiltSize]);
    %     imshow(medfiltFrame*100);
    %     end;
    %     cd('..');
    
    %     tFrameNumber =
    I = getframe(h);
    writeVideo(vidObj,I);
    %              close(figure(1));
end;
close(vidObj);