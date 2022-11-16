% October 11, 2020 - Because of 90 minute imaging sequences, want to
% process the videos in small chunks, comparable to the
% "concatenateMultiVidMovement_frommContinuousFrames.m script. However,
% this code is buggy:
% - The size of the array lengthens as you get towards the end of the time
% series.
% - Seems to be recording the same values for every chunk?
%
%Inputs:
%1) rootdir (where we store the output data).
%2) TSeries folder (where we keep the raw data)
%3) TImgRoot - this refers to the frames we want to extract pixel intensity values from. Generally do
%not have to change this (except to specify Ch2 versus Ch1); should match
%TSeriesFolder.
%4) TMaskRoot - this refers to the name of the images we want to use for
%the mask. In cases where there is mCherry (Ch1) present, then use this to
%mask. Otherwise, use Ch2 for the mask.
%5) TProjMask: Helps restrict the field of view to the region where the
%cells are.

%OUTPUT:
% A.regionPropsArray = regionPropsArray;
% A.TProjMask = TProjMask;
% save(outname,'-struct','A');

function extractRegionsFromMaskedVid()
rootdir = 'E:\23E10_GCaMP7b_tdTomato_slow'
TSeriesFolder = 'TSeries-08132021-1456-649';

cycleStart = 1;
cycleStartString = ['Cycle' num2str(cycleStart,'%05.0f')];

TImgRoot = [TSeriesFolder '_' cycleStartString '_Ch2_'];%000001.ome
% TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
% TProjMask = [TSeriesFolder '_Cycle00001_Ch2__maskReg3.mat']
TProjMask = 'TSeries-08132021-1456-649_Cycle00001_Ch2__mask.mat'; %[TSeriesFolder '_Cycle00001_Ch1_mask.mat']

slicesPerStack = 9;
stacksPerSec = 1/5; %0.2878;
slicesPerMin = round(slicesPerStack*stacksPerSec*60);
slicesPerDataChunk = 5*slicesPerMin;

% cycleList = [cycleStart:70:212];
cycleList = 1; %1793]; %cycleStart 685 1368 2051]; % 938 1406 66 130 194 402 610 818 1174];

writeVid = 0;
upperStretchLim = 0.1;
stretchThreshold = upperStretchLim*4095;
medfiltSize = 1;

recordedFPS = 25;
fps2write = 25;
bwThresh = 0;

cd(rootdir);

if(writeVid),
    vidObj = VideoWriter([TImgRoot '_BWthresh' num2str(bwThresh) '_upperStretchLim ' num2str(upperStretchLim) '_medfilt'  num2str(medfiltSize) '.avi']);
end;
A = load(TProjMask);
tProjMaskMat = A.bwFrame;
tProjRegions = regionprops(tProjMaskMat>0,'Area','BoundingBox','Centroid','PixelIdxList'); %,'PixelValues');

if(writeVid),
    open(vidObj);
end;

maskImg = tProjMaskMat;
for(ci = 1:numel(cycleList)),
    cd(TSeriesFolder);
    cycleText = ['Cycle' num2str(cycleList(ci),'%05.0f')];
    imgRootForCycle = strrep(TImgRoot,cycleStartString,cycleText);
    tiffList = dir([imgRootForCycle '*.ome.tif']);
    
    maxFrame2read = numel(tiffList);
    regionPropsArray = cell(maxFrame2read,2);
    
    chunkStartFrameIndices = [1:slicesPerDataChunk:maxFrame2read];
    for(chunkI = chunkStartFrameIndices);
        chunkStart = chunkI;
        chunkEnd = chunkI+slicesPerDataChunk-1;
        if(chunkEnd>maxFrame2read),
            chunkEnd = maxFrame2read;
        end;
        
        outname = strrep(TProjMask, '.mat',['_' cycleText '_slice' num2str(chunkStart) 'to' num2str(chunkEnd) 'Intensities.mat']);
        for(ti = chunkStart:chunkEnd), %ti in units of slices.
            display(ti);
            imgName = [imgRootForCycle num2str(ti,'%06.0f') '.ome.tif'];
            if(exist(imgName,'file'))
                try,
                    rawImg = imread(imgName,'tif'); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
                catch, %Sometimes for one reason or another Matlab can't recognize these images as *.tifs.
                    rawImg = zeros(size(rawImg,1),size(rawImg,2));
                end;

                if(mod(ti,slicesPerStack)==1), %Then we are at the start of a new stack.
                    imageDataInStack = NaN(size(rawImg,1)*size(rawImg,2),slicesPerStack);
                    maskDataInStack = NaN(size(rawImg,1)*size(rawImg,2),slicesPerStack);
                    if(ti~=1 && writeVid),%Writes the previous stack to the video.
                        I = getframe(h);
                        writeVideo(vidObj,I); %uint16(I)); %, vidObj);
                        close(figure(1));
                    end;
                elseif(mod(ti,slicesPerStack)==0 && writeVid),
                    sumProjectionVector = nansum(imageDataInStack,2);
                    sumProjection = reshape(sumProjectionVector,size(rawImg,1),size(rawImg,2));
                    h = figure(1);
                    imagesc(sumProjection,[0 1000]);
                end;
                stackIndex = mod(ti,slicesPerStack);
                display(sum(rawImg(:)==0));
                if(ti>(maxFrame2read*0.5)),
                    display('pause.');
                end;
                if(stackIndex~=0),
                    imageDataInStack(:,stackIndex) = double(rawImg(:));
                    maskDataInStack(:,stackIndex) = double(maskImg(:));
                else,
                    imageDataInStack(:,slicesPerStack) = double(rawImg(:));
                    maskDataInStack(:,slicesPerStack) = double(maskImg(:));
                    
                    %Find the mean.
                    meanImg = mean(imageDataInStack,2);
                    meanMask = mean(maskDataInStack,2);
                    
                    medFiltFrame = double(medfilt2(uint16(reshape(meanImg,size(rawImg,1),size(rawImg,2))),[medfiltSize medfiltSize]));
                    ctrlMedFiltFrame = double(medfilt2(uint16(reshape(meanMask,size(rawImg,1),size(rawImg,2))),[medfiltSize medfiltSize]));
                    
                    bwSignal = im2bw(medFiltFrame.*tProjMaskMat,0);
                    bwCtrl = im2bw(ctrlMedFiltFrame.*tProjMaskMat,0);
                    
                    for(si = 1:numel(tProjRegions)),
                        thisRegion = tProjRegions(si);
                        if(0), %writeVid),
                            plot(thisRegion.BoundingBox(1),thisRegion.BoundingBox(2),'ro');
                        end;
                        realAreas{si} = thisRegion;
                        pxIntensitiesForRegions{si,2} = medFiltFrame(thisRegion.PixelIdxList);
                        pxIntensitiesForRegions{si,1} = ctrlMedFiltFrame(thisRegion.PixelIdxList);
                        %             display(thisRegion.BoundingBox);
                    end;
                    
                    regionPropsArray{ti,1} = realAreas;
                    regionPropsArray{ti,2} = pxIntensitiesForRegions;
                    
                end;
                
            end;
        end;
        cd(rootdir);
        A.regionPropsArray = regionPropsArray;
        A.TProjMask = TProjMask;
        save(outname,'-struct','A');
    end;
end;
if(writeVid),
    close(vidObj);
end;
