function pixelIntensityPerStack = processTChunk(matname);

A = load(matname);
regions = A.regionPropsArray;
meanPixelIntensityPerFrame = NaN(size(regions,1),2);
for(ti = 1:size(regions,1)),
    thisFrameRegions = regions{ti,2};
    %thisFrameRegions is a two cell array of pixel intensities. The first cell contains pixel intensity data
    %from the MASK (probably the mCherry signal). The second cell contains
    %the pixel intensity data from the frames being masked (probably the
    %GCamP6m signal).
    if(~isempty(thisFrameRegions)),
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
    %         display(sumPixelIntensity);
    %         display(numPixels);
    meanPixelIntensityPerFrame(ti,1) = sumPixelIntensity/numPixels;
    meanPixelIntensityPerFrame(ti,2) = sumGCaMPIntensity/numPixels_GCaMP;
%     else,
%         display('Found an empty region.');
    end;
    clear thisFrameRegions;
end;
isNumIndices = find(~isnan(meanPixelIntensityPerFrame(:,2)));
pixelIntensityPerStack = meanPixelIntensityPerFrame(isNumIndices,2)./meanPixelIntensityPerFrame(isNumIndices,1);
% numFrames = size(regions,1);