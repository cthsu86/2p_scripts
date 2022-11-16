%%function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime_vsTime_multipleCycles (varargin)
%  - Best used in instances where it is necessary to compute when the shutter
% closes over the scanner (for instance, in the chrimson stimulation case).
% - Can also be used on slow timecourse data (once every 5 minutes) which
% records the data as consecutive cycles.
% 
% Assumes extractRegionsFromMaskeVid_zStack.m was run previously.
%
% Edited on May 15, 2021 (*_multipleCycles.m) so that, when given a range of cycles, will
% iterate over ALL cycles in addition to the regions saved in the
% '*Intensities.mat' name. This happens sometimes when images are acquired
% in a T series (rather than with a repeating script) and 
% without the Piezo. It is less necessary to run this version if you are
% doing an ex-vivo type of experiment that involves multiple trials, as
% this particular script will plot the trials one after another rather than
% superimposed. For plotting trials superimposed, refer to the original
% output2P_intensityVsTime.m script.

function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime_multipleCycles(varargin)

if (nargin==0),
    rootdir = 'D:\Cynthia\23E10LexA_GCaMP7b_23E10GtACR'; %210806\'; %210803'
    signalMatname = 'TSeries-09252022-1527-961_Cycle00001_Ch2__userDrawnMask_Cycle00001_Intensities.mat'; %strrep(TProjMask, '.mat','Intensities.mat')
    cycleRankNum = 1; %Set to 0 if there is no voltage output (such as from csChrimson stimulation laser) being used.
    xmlName = 'TSeries-09252022-1527-961.xml';
    cycleList = 6205; %:73; %:18; %[1:1:475];
    cycleTextToReplace = 'Cycle00001_Intensities';
    originalSignalMatname = signalMatname;
else,
    rootdir = varargin{1};
    signalMatname = varargin{2};
    cycleRankNum = varargin{3};
    xmlName = varargin{4};
end;
% cycleList = [1:

cd(rootdir);

[stackTimes, shutterTimes, lastBaselineIndex] = readTimeFromXML(xmlName,cycleRankNum);
for(ci = 1:numel(cycleList));
    cycleText = ['Cycle' num2str(cycleList(ci),'%05.0f') '_Intensities'];
    %     imgRootForCycle = strrep(TImgRoot,cycleStartString,cycleText);
    
    signalMatname = strrep(originalSignalMatname, cycleTextToReplace,cycleText)
    
    A = load(signalMatname);
    regions = A.regionPropsArray;
    %For reference: the commented out code fragment below is copied from
    %extractRegionsFromMaskedVid.m
    % pxIntensitiesForRegions{ai,2} = medFiltFrame(thisRegion.PixelIdxList);
    % pxIntensitiesForRegions{ai,1} = medFiltMask(thisRegion.PixelIdxList);
    % regionPropsArray{ti,1} = realAreas;
    % regionPropsArray{ti,2} = pxIntensitiesForRegions;
    if(ci==1),
        meanPixelIntensityPerFrame = NaN(size(regions,1)*numel(cycleList),2);
    end;
    for(ti = 1:size(regions,1)),
        thisFrameRegions = regions{ti,2};
        %thisFrameRegions is a two cell array of pixel intensities. The first cell contains pixel intensity data
        %from the MASK (probably the mCherry signal). The second cell contains
        %the pixel intensity data from the frames being masked (probably the
        %GCamP6m signal).
        
        sumPixelIntensity = 0;
        numPixels = 0;
        sumGCaMPIntensity = 0;
        numPixels_GCaMP = 0;
        for(si = 1:size(thisFrameRegions,1)),
            
            %First block of code: run the average mean pixel intensity for the
            %first channel (mCherry).
            sumPixelIntensity = sumPixelIntensity+sum(thisFrameRegions{si,1});
            numPixels = numPixels+numel(thisFrameRegions{si,1});
            
            sumGCaMPIntensity = sumGCaMPIntensity+sum(thisFrameRegions{si,2});
            numPixels_GCaMP = numPixels_GCaMP+numel(thisFrameRegions{si,2});
        end;
        %     display(sumPixelIntensity);
        %     display(numPixels);
        meanPixelIntensityPerFrame((ci-1)*size(regions,1)+ti,1) = sumPixelIntensity/numPixels;
        
        meanPixelIntensityPerFrame((ci-1)*size(regions,1)+ti,2) = sumGCaMPIntensity/numPixels_GCaMP;
        
    end;
end;
%
if(size(stackTimes,1)<size(meanPixelIntensityPerFrame,1)),
    numSlices = size(meanPixelIntensityPerFrame,1)/size(stackTimes,1);
else,
    %One possible explanation for entering this clause is that the successive
    %stacks are numbered by Cycle, rather than saved to a single
    %*Intensities.mat
%         display('what?');
%         display(size(stackTimes))
%         display(size(meanPixelIntensityPerFrame));
end;
timeIntensityMat = [stackTimes(:,1) meanPixelIntensityPerFrame(numSlices:numSlices:end,:)];

%But, we also have to check the voltage:
%We want to set to NaN any stacks where either the start or the end time is
%in between the shutter's opening and closing times.
if(isempty(shutterTimes)),
    if(numel(cycleList)>1),
    deltaT = stackTimes(:,2);
    stackStarts = cumsum([0; deltaT(:)]);
    timeIntensityMat(:,1) = stackStarts(1:size(timeIntensityMat,1));
    timeIntensityMat(:,1) = stackStarts(2:(size(timeIntensityMat,1)+1));
    end;
else,
    for(si = 1:size(shutterTimes,1)),
        %     display(si)
        % if(si==2),
        %     display('pause.');
        % end;
        stackBeginsWhenShutterClosed = stackTimes(:,1)>shutterTimes(si,1) & stackTimes(:,1)<shutterTimes(si,2);
        timeIntensityMat(find(stackBeginsWhenShutterClosed),2:3) = NaN;
        %     display(find(stackBeginsWhenShutterClosed));
        stackEndsWhenShutterClosed = stackTimes(:,2)>shutterTimes(si,1) & stackTimes(:,2)<shutterTimes(si,2);
        timeIntensityMat(find(stackEndsWhenShutterClosed),2:3) = NaN;
        shutterClosesMidStack = stackTimes(:,1)<shutterTimes(si,1) & stackTimes(:,2)>shutterTimes(si,2);
        timeIntensityMat(find(shutterClosesMidStack),2:3) = NaN;
        if(nargin==0),
            plot([shutterTimes(si,1) shutterTimes(si,2)],[31 31],'r','LineWidth',4); hold on;
        end;
    end;
end;


greenSignal = timeIntensityMat(:,3);
numIndices = find(~isnan(greenSignal));
greenInterp = interp1(numIndices,greenSignal(numIndices),1:numel(greenSignal));
if(nargin==0),
    endIndex = find(~isnan(greenInterp),1,'last');
    plot((timeIntensityMat(1:endIndex,1)-timeIntensityMat(1,1))/60,greenInterp(1:endIndex));
    xlabel('Time (min)');
    try
    xlim([0 timeIntensityMat(endIndex,1)-timeIntensityMat(1,1)]/60);
    catch,
    end;
end;
timeIntensityMat(:,3) = greenInterp;
if(size(shutterTimes,2)>=2),
    voltOutTimes = [shutterTimes(1,1) shutterTimes(end,2)];
else,
    voltOutTimes = [];
end;
% %

%     signalMatname = 'TSeries-08192022-1429-884_Cycle00001_Ch2__userDrawnMask_Cycle00001_Intensities.mat'; %strrep(TProjMask, '.mat','Intensities.mat')
fileName = strrep(signalMatname,'.mat','.txt');
fID = fopen(fileName,'w');
% fprintf(fID,'%1.5f,',timeValsToPlot);
% fprintf(fID,'\n');
% % fprintf(fID,'%s',rowToWrite(:));
% for(ri = 1:size(imageSCmat,1)),
%     stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
%     stringToWrite = strrep(stringToWrite,'NaN','');
for(i = 1:size(timeIntensityMat,1)),
fprintf(fID,'%1.5f,',timeIntensityMat(i,:)); %rowToWrite,imageSCmat(fi,:));
fprintf(fID,'\n');
end;
% fprintf(fID,'%1.5f,',sortedVecToWrite); %rowToWrite,imageSCmat(fi,:));
%     % fprintf(fID,'%s','\n');
% end;
fclose(fID);