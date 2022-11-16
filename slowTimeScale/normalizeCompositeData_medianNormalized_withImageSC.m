%% function normalizeCompositeData_medianNormalized_withImageSC()
%
% June 13, 2022
%
% Based on function normalizeCompositeData_medianNormalized.m(), but also
% with code written in that produces an image map (in case that works
% better for visibility.


function normalizeCompositeData_medianNormalized_withImageSC()

close all; %clear all;
rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale';
xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';

cd(rootdir);
[num,txt,raw] = xlsread(xlname,'A3:AH64');
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale';
% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';
stacksPerHr = 12;

cd(rootdir);
[num,txt,raw] = xlsread(xlname,'A3:AH75');

timeVals = squeeze(num(:,1:2:end));
intensityVals = squeeze(num(:,2:2:end));

% cmap = colormap(winter(size(timeVals,2)))*0.5;
cmap = colormap(winter(5))*0.5;

%I guess the first thing we do is sort by timeVals.
[sortedStartTimes, sortedIndices] = sort(timeVals(1,:));
timeVals_sortedByStart = NaN(size(timeVals)); %timeVals(:,sortedIndices);
intensityVals_sortedByStart = NaN(size(intensityVals)); %(:,sortedIndices);

minTimeVal = sortedStartTimes(1);
maxTimeVal = max(timeVals(:));

for(si = 1:numel(sortedIndices)),
    timeVals_sortedByStart(:,si) = timeVals(:,sortedIndices(si));
    intensityVals_sortedByStart(:,si) = intensityVals(:,sortedIndices(si));
end;

intensityVals_sortedByStart_normalized = NaN(size(intensityVals_sortedByStart));
flyIDs = NaN(size(intensityVals_sortedByStart_normalized));

%We need to preallocate a matrix, imageSCmat, whose X values are the
%hour range spanned by the input values multipled by six (for the 5 minute
%imaging interval).


numTimeBins = ceil((maxTimeVal-sortedStartTimes(1))*stacksPerHr+1);
imageSCmat = NaN(size(timeVals_sortedByStart,2),numTimeBins); %Each row is going to be a fly ID.
for(ti = 1:(size(timeVals_sortedByStart,2))),
%     avgCurrentIntensity = mean(intensityVals_sortedByStart(1:24,ti));
    avgCurrentIntensity = nanmean(intensityVals_sortedByStart(:,ti)); %nanmean(intensityVals_sortedByStart(currentTime_firstOverlapIndex:end,ti));
    normalizedIntensity = (intensityVals_sortedByStart(:,ti))/avgCurrentIntensity;
%     normalizedIntensity = (intensityVals_sortedByStart(:,ti)-avgCurrentIntensity)/avgCurrentIntensity;
    color2plot = cmap(mod(ti,size(cmap,1))+1,:);
    plot(timeVals_sortedByStart(:,ti),normalizedIntensity,'Color',color2plot,...
        'LineWidth',1.5,'Marker','o','MarkerSize',2,'LineStyle','none'); hold on; %,'ko'); hold on;
    
    %Computations related to imageSC
    intensityVals_sortedByStart_normalized(:,ti) =  normalizedIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
    flyIDs(:,ti) = ti;
    
    %     [~,offsetIndex] = min(abs(timeVals_sortedByStart(:,ti)-minTimeVal));
    %     minTimeVal
    offsetIndex = round((timeVals_sortedByStart(1,ti)-minTimeVal)*stacksPerHr)+1;
    imageSCmat(ti,offsetIndex:(offsetIndex+size(timeVals_sortedByStart,1)-1)) = intensityVals_sortedByStart_normalized(:,ti)';
end;
% minTimeVal
endTimeToPlot = minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
timeValsToPlot = [minTimeVal:(1/stacksPerHr):endTimeToPlot];
% display(size(timeValsToPlot));
% display(size(imageSCmat));
timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));
plot(timeValsToPlot,nanmean(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]);
% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);


figure(3);
plot(timeValsToPlot,nanmean(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]);
% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);

%% ImageSC code is below (Fig 2), but I don't actually feel like my life is improved by having this code.  
% figure(2);
% colormap jet;
% imagesc(1:size(imageSCmat,1),1:size(imageSCmat,2),imageSCmat',[0.8 1.2]);
%% Code below just produces horizontal lines....
% figure(2);
% % timeVals_sortedByStart_vector = timeVals_sortedByStart(:)
% % imageSCtoPlot = [ flyIDs(:) intensityVals_sortedByStart_normalized(:)];
% isNumIndex = find(~isnan(timeVals_sortedByStart));
% imageSCtoPlot = [timeVals_sortedByStart(isNumIndex) flyIDs(isNumIndex) intensityVals_sortedByStart_normalized(isNumIndex)];
% imagesc(imageSCtoPlot(:,1),imageSCtoPlot(:,2),imageSCtoPlot(:,3));
% % imagesc(timeVals_sortedByStart(:), flyIDs(:),intensityVals_sortedByStart_normalized(:));