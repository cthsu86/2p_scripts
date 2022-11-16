function brainSignalOut = brainSignalInFrameUnits(slicesPerChunk,maxSlice,TSeriesRoot,recordedFPS,stacksPerSec,laserOnsetFrame,fullBrainSignal, slicesPerStack);

%Next, need to iterate through and load the brainSignal
for(tChunkFrameStart = 1:slicesPerChunk:maxSlice),
    chunkEnd = tChunkFrameStart+slicesPerChunk-1;
    if(chunkEnd>maxSlice),
        chunkEnd = maxSlice;
    end;
    %     matname = [vidRootName num2str(segmentFrameStart) 'to' num2str(frameEnd) '_frame1to' num2str(numFramesInVidSegment) '.mat'];
    %Tseries name: TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice1to12510Intensities
    %     TSeriesRoot = 'TSeries-09162020-1554-484_Cycle00001_Ch2__mask_Cycle00001_slice';
    matname = [TSeriesRoot num2str(tChunkFrameStart) 'to' num2str(chunkEnd) 'Intensities.mat'];
    display(['Currently reading matname: ' matname]);
    meanPixelIntensityPerFrame = processTChunk(matname);
    if(chunkEnd==maxSlice),
        display('pause here');
    end;
    firstStackNum = floor(tChunkFrameStart/slicesPerStack);
    thisChunkIndicesToFrames = round(([1:numel(meanPixelIntensityPerFrame)]+firstStackNum)*recordedFPS/stacksPerSec+laserOnsetFrame+1);
    %     display(size(fullBrainSignal));
    
    indexRangeCutoff = find(thisChunkIndicesToFrames>numel(fullBrainSignal),1);
    if(~isempty(indexRangeCutoff)),
            fullBrainSignal(thisChunkIndicesToFrames(1:(indexRangeCutoff-1))) = meanPixelIntensityPerFrame(1:(indexRangeCutoff-1));

    else,
    fullBrainSignal(thisChunkIndicesToFrames) = meanPixelIntensityPerFrame;
    end;
    clear A; clear regions; clear meanPixelIntensityPerFrame;
end;
% display(size(fullBrainSignal));
brainSignalOut = fullBrainSignal;

