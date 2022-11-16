%% function extractRegionsFromMaskedVid_zStack_v3.m()
%
% May 4, 2022
% Modified from extractRegionsFromMaskedVid_zStack.m, but in the absence of
% RFP data, will provide the mean data outside the signal. 
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
% save(outname,'-struct','A.mat

function extractRegionsFromMaskedVid_zStack()
rootdir = 'E:\MB122B_UASdnClk_23E10LexA_GCaMP7b'
% rootdir = 'D:\Hugin\emptyChrimson_HugS3_Arclight';
TSeriesFolder = 'TSeries-05252022-1151-751'; %_Cycle00001_Ch2__userDrawnMask';
% D:\Hugin\HugLexA_csChrimson_hugArclight\201007\TSeries-Mask10072020-1456-494
cycleStart = 1;
cycleStartString = ['Cycle' num2str(cycleStart,'%05.0f')];

TImgRoot = [TSeriesFolder '_' cycleStartString '_Ch2_'];%000001.ome
% TMaskRoot = strrep(TImgRoot,'Ch2','Ch1');
% TProjMask = [TSeriesFolder '_Cycle00001_Ch2__maskReg3.mat']
TProjMask = 'TSeries-05252022-1151-751_Cycle00001_Ch2__userDrawnMask.mat';

slicesPerStack = 19;

% cycleList = [cycleStart:70:212];
%If Piezo is not used, each stack is a separate cycle.
% cycleList = [1:1:475]; %1793]; %cycleStart 685 1368 2051]; % 938 1406 66 130 194 402 610 818 1174];
cycleList = 1:46; %cycleStart:73; %:73; %[2 1046]; %In high speed T-series, just one cycle for the entire series.
readChannel1 = 0; 
writeVid = 0;
upperStretchLim = 0.1;
medfiltSize = 1;

cd(rootdir);

if(writeVid),
    %     vidObj = VideoWriter([TImgRoot '_BWthresh' num2str(bwThresh) '_upperStretchLim ' num2str(upperStretchLim) '_medfilt'  num2str(medfiltSize) '.avi']);
    vidObj = VideoWriter([TImgRoot '_upperStretchLim ' num2str(upperStretchLim) '.avi']);
end;
A = load(TProjMask);
tProjMaskMat = A.bwFrame;
tProjRegions = regionprops(tProjMaskMat>0,'Area','BoundingBox','Centroid','PixelIdxList'); %,'PixelValues');
bgRegions = regionprops(tProjMaskMat==0,'Area','BoundingBox','Centroid','PixelIdxList')

if(writeVid),
    open(vidObj);
end;

maskImg = tProjMaskMat;
for(ci = 1:numel(cycleList)),
    cd(TSeriesFolder);
    cycleText = ['Cycle' num2str(cycleList(ci),'%05.0f')]
    imgRootForCycle = strrep(TImgRoot,cycleStartString,cycleText);
    tiffList = dir([imgRootForCycle '*.ome.tif']);
    outname = strrep(TProjMask, '.mat',['_' cycleText '_' 'Intensities.mat']);

    maxFrame2read = numel(tiffList);
    regionPropsArray = cell(maxFrame2read,2);
    for(ti = 1:maxFrame2read),
        if(ti<=200 || mod(ti,100)==0),
            display(ti);
            if(ti==200),
                display(['Have demonstrated first 200 frames are read. Now outputting once every 100 frames.']);
            end;
        end;
        %         end;
        imgName = [imgRootForCycle num2str(ti,'%06.0f') '.ome.tif'];
        if(exist(imgName,'file'))
            try,
                rawImg = imread(imgName); %This rawImg contains the data that we probably want to extract data from (GCamp6m)
            catch,
                rawImg(:) = NaN; %(size(rawImg,1),size(rawImg,2));
            end;
            if(readChannel1),
                maskName = strrep(imgName,'Ch2','Ch1');
                if(exist(maskName,'file')),
                    try,
                        maskImg = imread(maskName);
                        %                 display(['Successfully read in ' maskName]);
                    catch,
                        maskImg(:) = NaN;
                        display(['Could not read ' maskName]);
                    end;
                else,
                    maskImg(:) = NaN;
                    display(['Could not find a file matching maskName']);
                end;
                %                         else,
            end;
            if(mod(ti,slicesPerStack)==1),
                imageDataInStack = NaN(size(rawImg,1)*size(rawImg,2),slicesPerStack);
                maskDataInStack = NaN(size(rawImg,1)*size(rawImg,2),slicesPerStack);
                if(ti~=1 && writeVid),
                    I = getframe(h);
                    writeVideo(vidObj,I);
                    close(figure(1));
                end;
            elseif(mod(ti,slicesPerStack)==0 && writeVid),
                sumProjectionVector = nansum(imageDataInStack,2);
                sumProjection = reshape(sumProjectionVector,size(rawImg,1),size(rawImg,2));
                h = figure(1);
                imagesc(sumProjection,[0 4000]); %*13]); %1000]); %*13]);
            end;
            stackIndex = mod(ti,slicesPerStack);
            if(stackIndex~=0), %Just save the data into the stack.
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
                %ctrlMedFiltFrame stores the mask data. 
                
                bwSignal = im2bw(medFiltFrame.*tProjMaskMat,0);
%                 bwCtrl = im2bw(ctrlMedFiltFrame.*tProjMaskMat,0);
                pxIntensitiesForRegions = cell(numel(tProjRegions));
                for(si = 1:numel(tProjRegions)),
                    thisRegion = tProjRegions(si);
                    if(0),
                        plot(thisRegion.BoundingBox(1),thisRegion.BoundingBox(2),'ro');
                    end;
                    realAreas{si} = thisRegion;
                    pxIntensitiesForRegions{si,2} = medFiltFrame(thisRegion.PixelIdxList);
                end;
                regionPropsArray{ti,2} = pxIntensitiesForRegions;
                %Second column of the array contains the actual signal
                %data.
                clear pxIntensitiesForRegions;
                pxIntensitiesForRegions = cell(numel(bgRegions));
                for(si = 1:numel(bgRegions)),
                    thisRegion = bgRegions(si);
                    pxIntensitiesForRegions{si,1} = medFiltFrame(thisRegion.PixelIdxList);
                end;
                    
                regionPropsArray{ti,1} = pxIntensitiesForRegions;
                clear pxIntensitiesForRegions;
            end;
            
        end;
    end;
    cd(rootdir);
    A.regionPropsArray = regionPropsArray;
    A.TProjMask = TProjMask;
    A.TSeriesFolder = TSeriesFolder;
    save(outname,'-struct','A','-v7.3');
end;
if(writeVid),
    close(vidObj);
end;
