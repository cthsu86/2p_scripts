%% function normalizeCompositeData_v4_smoothed30min()
%
% July 23, 2022
%
% v4, as opposed to v3, was an attempt to normalize through mean subtraction of overlapping
% timepoints in addition to dividing by the mean (so that values are
% zero-centered instead of one-centered). As of July 23, 2022, stil could
% not get this to work out right. Unclear if this is appropriate, since the
% simplified version of the algorithm would set all values at 0.
%
% Based on function normalizeCompositeData_v2_forJTK():
% Converts data into a format to streamline input into the Missing replicates script in JTK:
% group.sizes = c(8,12,10,11,10,9)
% #number of replicates per time point
%
% Addition of smoothing for individual flies, so that each fly is counted
% as 10 replicates instead of 60 (for each timepoint).


function normalizeCompositeData_v4_smoothed30min()

close all; %clear all;

%% WT
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale';
% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';
% cellsToRead = 'A3:AH64';
%% per0
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale\per0';
% xlname = 'per0_23E10_summary_GFPonly.xlsx';
% cellsToRead = 'A15:AH75';
%% MB122B
rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB122B_UASdnClk_23E10LexA_GCaMP7b';
xlname = 'MB122B_UASdnClk_summary_noDeadFlies_ZT_fanGFPonly.xlsx';
cellsToRead = 'A15:AT82';
%% pdfr
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\pdfrhan5046_23E10Gal4_GCaMP7b_tdTomato'; %\per0';
% xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
% cellsToRead = 'A15:AJ75';

%% Generalizable to all genotypes
stacksPerHr = 12;
individualLineWidths = 0.5;
windowForBinning = stacksPerHr/2;

cd(rootdir);
[num,txt,raw] = xlsread(xlname,cellsToRead);

timeVals = squeeze(num(:,1:2:end));
intensityVals = squeeze(num(:,2:2:end));

% cmap = colormap(winter(size(timeVals,2)))*0.5;
cmap = colormap(jet(7))*0.5;

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

%We need to preallocate a matrix, imageSCmat, whose X values are the
%hour range spanned by the input values multipled by six (for the 5 minute
%imaging interval).
intensityVals_sortedByStart_normalized = NaN(size(intensityVals_sortedByStart));
flyIDs = NaN(size(intensityVals_sortedByStart_normalized));

numTimeBins = ceil((maxTimeVal-sortedStartTimes(1))*stacksPerHr+1);
imageSCmat = NaN(size(timeVals_sortedByStart,2),numTimeBins); %Each row is going to be a fly ID.
binTimeBounds = [0:windowForBinning:numTimeBins]/stacksPerHr;
% binMidpoints = (binTimeBounds(2:end)-binTimBounds(1:(end-1))-2);
binnedFlyByTime = NaN(size(timeVals_sortedByStart,2),(numel(binTimeBounds)-1));

oneValPerFly = NaN(size(timeVals_sortedByStart,3),2); %Column 1 is ZT, column 2 is value.
for(ti = 1:(size(timeVals_sortedByStart,2))-1),
    % Want to normalize each value by the one before it. To do so, first need to compute the indices over which fly ti and fly (ti+1) overlap:
    currentTime = timeVals_sortedByStart(:,ti);
    currentTime = currentTime(find(~isnan(currentTime)));
    nextTime = timeVals_sortedByStart(:,ti+1);
    nextTime = nextTime(find(~isnan(nextTime)));
    nextTime_firstNonOverlapIndex = find(nextTime>currentTime(end),1,'first');
    if(isempty(nextTime_firstNonOverlapIndex)||nextTime_firstNonOverlapIndex==1),
        nextTime_firstNonOverlapIndex=numel(nextTime);
    end;
    currentTime_firstOverlapIndex = find(currentTime>nextTime(1),1,'first');
    if(isempty(currentTime_firstOverlapIndex))
        currentTime_firstOverlapIndex = 1;
    end;
    
    currentIntensity = intensityVals_sortedByStart(:,ti);
    if(nextTime_firstNonOverlapIndex>1),
        avgCurrentIntensity = nanmean(currentIntensity(currentTime_firstOverlapIndex:end));
        currentIntensity = (currentIntensity-avgCurrentIntensity)/avgCurrentIntensity;
        %Have now computed the subtracted and divided normalization for
        %currentIntensity. 
%         avgNextIntensity = nanmean(intensityVals_sortedByStart(1:(nextTime_firstNonOverlapIndex-1),ti+1));
%         nextIntensityNormFactor = avgCurrentIntensity/avgNextIntensity;
%         nextIntensity = (intensityVals_sortedByStart(:,ti+1)-avgNextIntensity); %/avgNextIntensity;
%         if(ti==1),
%             intensityVals_sortedByStart(:,ti) = currentIntensity;
%         else,
%             nextIntensity = (nextIntensity-avgNextIntensity)*nextIntensityNormFactor; %avgCurrentIntensity;
%             %If we are missing overlapping timepoints, avgCurrentIntensity
%             %causes a disproportionate amplication of nextIntensity
%         end;
%         intensityVals_sortedByStart(:,ti+1) = nextIntensity;
    end;
    color2plot = cmap(mod(ti,size(cmap,1))+1,:);
    plot(timeVals_sortedByStart(:,ti),currentIntensity,'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5);
    hold on; %,'ko'); hold on;
    oneValPerFly(ti,1) = nanmedian(timeVals_sortedByStart(:,ti));
    oneValPerFly(ti,3) = nanmedian(intensityVals_sortedByStart(:,ti));
    
    %Computations related to imageSC
    intensityVals_sortedByStart_normalized(:,ti) =  currentIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
    flyIDs(:,ti) = ti;
    
    offsetIndex = round((timeVals_sortedByStart(:,ti)-minTimeVal)*stacksPerHr)+1;
    imageSCmat(ti,offsetIndex:(offsetIndex+size(timeVals_sortedByStart,1)-1)) = intensityVals_sortedByStart(:,ti)';
    
    % Computations related to binnedFlyByTime:
    % First, need to figure out the first
    positiveZT = timeVals_sortedByStart(1,ti);
    [~,offsetI] = min(abs(binTimeBounds-positiveZT));
    %offsetI now returns the bin bound that is closest to the first ZT time for this fly.
    if(positiveZT<binTimeBounds(offsetI)),
        %Want to remove the excess - find the first time bin that is
        %greater than the value.
        offsetInTimeSeries = find(timeVals_sortedByStart(:,ti)>=binTimeBounds(offsetI),1);
        truncatedZT = timeVals_sortedByStart(offsetInTimeSeries:end,ti);
        display(['ti=' num2str(ti) ', truncatedZT = ' num2str(truncatedZT(1))]);
        truncatedIntensity = intensityVals_sortedByStart(offsetInTimeSeries:(offsetInTimeSeries+numel(truncatedZT)-1),ti);
        %Need to compute numValues:
        numValues = ceil(numel(truncatedIntensity)/windowForBinning)*windowForBinning;
        nanPadded_Intensity = NaN(numValues,1);
        nanPadded_Intensity(1:numel(truncatedIntensity)) = truncatedIntensity;
    else,
        numValues = ceil(numel(intensityVals_sortedByStart(:,ti))/windowForBinning)*windowForBinning;
        nanPadded_Intensity = NaN(numValues,1);
        nanPadded_Intensity((end-size(intensityVals_sortedByStart,1)+1):end) = intensityVals_sortedByStart(:,ti);
    end;
    reshapedIntensity = reshape(nanPadded_Intensity,windowForBinning,numValues/windowForBinning);
    binnedFlyByTime(ti,offsetI:(offsetI+size(reshapedIntensity,2)-1)) = nanmedian(reshapedIntensity,1);
    
    %     if(ti==(size(timeVals_sortedByStart,2)-1)),
    %         display(size(nextTime));
    %         display(size(nextIntensity));
    if(numel(nextIntensity)>numel(nextTime)),
        nextIntensity = nextIntensity(find(~isnan(nextIntensity)));
    end;
    plot(nextTime,nextIntensity,'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5);
    hold on; %,'ko'); hold on;
    intensityVals_sortedByStart(1:numel(nextIntensity),ti+1) = nextIntensity;
    oneValPerFly(ti+1,1) = nanmedian(timeVals_sortedByStart(:,ti+1));
    oneValPerFly(ti+1,3) = nanmedian(intensityVals_sortedByStart(:,ti+1));
    
    offsetIndex = round((nextTime-minTimeVal)*stacksPerHr)+1;
    imageSCmat(ti+1,offsetIndex:(offsetIndex+size(timeVals_sortedByStart,1)-1)) = nextIntensity;
    
    %         ti = ti+1;
    positiveZT = timeVals_sortedByStart(1,ti+1);
    [~,offsetI] = min(abs(binTimeBounds-positiveZT));
    %offsetI now returns the bin bound that is closest to the first ZT time for this fly.
    if(positiveZT<binTimeBounds(offsetI)),
        %Want to remove the excess - find the first time bin that is
        %greater than the value.
        offsetInTimeSeries = find(timeVals_sortedByStart(:,ti+1)>=binTimeBounds(offsetI),1);
        truncatedZT = timeVals_sortedByStart(offsetInTimeSeries:end,ti+1);
        truncatedIntensity = intensityVals_sortedByStart(offsetInTimeSeries:(offsetInTimeSeries+numel(truncatedZT)-1),+1);
        %Need to compute numValues:
        numValues = ceil(numel(truncatedIntensity)/windowForBinning)*windowForBinning;
        nanPadded_Intensity = NaN(numValues,1);
        nanPadded_Intensity(1:numel(truncatedIntensity)) = truncatedIntensity;
    else,
        numValues = ceil(numel(intensityVals_sortedByStart(:,+1))/windowForBinning)*windowForBinning;
        nanPadded_Intensity = NaN(numValues,1);
        nanPadded_Intensity((end-size(intensityVals_sortedByStart,1)+1):end) = intensityVals_sortedByStart(:,ti+1);
    end;
    reshapedIntensity = reshape(nanPadded_Intensity,windowForBinning,numValues/windowForBinning);
    binnedFlyByTime(ti+1,offsetI:(offsetI+size(reshapedIntensity,2)-1)) = nanmedian(reshapedIntensity,1);
    %     end;
end;
oneValPerFly(:,2) = round(oneValPerFly(:,1));
% binnedFlyByTime
ZTtimes_repmat = repmat(binTimeBounds(:)',size(binnedFlyByTime,1),1);
ZTtimes_vec = ZTtimes_repmat(:);
binnedFlyByTime_vec = binnedFlyByTime(:);
isNumIndices = find(~isnan(binnedFlyByTime));
ZTtimes_vec = ZTtimes_vec(isNumIndices);
binnedFlyByTime_vec = binnedFlyByTime_vec(isNumIndices);

% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
% 
%% Code pertaining to mean.

%This chunk superimposes the mean onto the
endTimeToPlot = minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
timeValsToPlot = [minTimeVal:(1/stacksPerHr):endTimeToPlot];
% display(size(timeValsToPlot));
% display(size(imageSCmat));
timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));
% Median as a gray line:
%plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0 0]);
% s = plot(timeValsToPlot,nanmedian(imageSCmat,1),'Marker','o','LineWidth',1,'MarkerSize',5,...
%     'MarkerEdgeColor',[0.5 0.5 0.5],'MarkerFaceColor','none','LineStyle','none');
% hold off;
% alpha(s,0.5);
hold on;

%Plot the 0 line and the day night transitions:
plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
% ylim([0.6 1.4])
xlim([0 24]); %xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
% ylim([0.5 2]);

%New figure with JUST the mean.
figure(3);
plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]); hold on;
display(nanmedian(imageSCmat,1)');

%Plot the 0 line and the day night transitions:
plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
xlim([0 24]);
% xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
% ylim([0.5 2]);

%% variables numReplicates_string and vecToWrite_string are used by JTK
% firstNonZeroIndex = find(timeValsToPlot>=0,1);
% % timeValsOffset = timeVals_sortedByStart(1:(firstNonZeroIndex-1))+24;
% lastNegativeTimedFlyIndex = find(~isnan(imageSCmat(:,firstNonZeroIndex-1)),1,'last');
% valuesToShift = imageSCmat(1:lastNegativeTimedFlyIndex,1:firstNonZeroIndex);
% display(size(valuesToShift));
% display(lastNegativeTimedFlyIndex);
% display(firstNonZeroIndex);
% imageSCmat(1:lastNegativeTimedFlyIndex,(end-firstNonZeroIndex+1):end) = valuesToShift;
% display(size(imageSCmat));
% lastBelow24Index = find(timeValsToPlot<=24,1,'last');
% imageSCmat = imageSCmat(:,firstNonZeroIndex:end); %lastBelow24Index); %end);
% timeValsToPlot = timeValsToPlot(:,firstNonZeroIndex:end); %lastBelow24Index); %end);
% % display(size(imageSCmat))
% numReplicates = sum(~isnan(imageSCmat),1);
% numReplicates_string = sprintf('%i,',numReplicates);
% imageSCmat = imageSCmat';
% vecToWrite = imageSCmat(:)';
% isNumIndex = find(~isnan(vecToWrite));
% vecToWrite = vecToWrite(isNumIndex);
% vecToWrite_string = sprintf('%2.5f,',vecToWrite); %(isNumIndex));

%% Write a *.csv file for running through MetaCycle.
binString = ['_' num2str(round(mean(diff(binTimeBounds))*60)) 'minBins'];
fileToWrite = strrep(xlname,'.xlsx',[strrep(cellsToRead,':','_') '_' binString ]);
fID = fopen([fileToWrite '.csv'],'w');
% ZTtimes_vec = ZTtimes_vec(isNumIndices);
% binnedFlyByTime_vec = binnedFlyByTime_vec(isNumIndices);

fprintf(fID,'ZT,');
fprintf(fID,'%1.2f,',ZTtimes_vec);
fprintf(fID,'\n');
fprintf(fID,[fileToWrite ',']);
% % % fprintf(fID,'%s',rowToWrite(:));
% % for(ri = 1:size(imageSCmat,1)),
% %     stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
% %     stringToWrite = strrep(stringToWrite,'NaN','');
fprintf(fID,'%1.5f,',binnedFlyByTime_vec); %rowToWrite,imageSCmat(fi,:));
% fprintf(fID,'\n');
% fprintf(fID,'%1.5f,',sortedVecToWrite); %rowToWrite,imageSCmat(fi,:));
% %     % fprintf(fID,'%s','\n');
% % end;
fclose(fID);