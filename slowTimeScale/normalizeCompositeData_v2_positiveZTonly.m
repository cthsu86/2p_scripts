%% function normalizeCompositeData_v2_positiveZTonly()
%
% October 7, 2022
% I think this is the preferred script for computing the intermediate
% timepoints.
%
% July 4, 2022
% Converts data into a format to streamline input into the Missing replicates script in JTK:
% group.sizes = c(8,12,10,11,10,9)
% #number of replicates per time point
% Will also ouptut the maximum values and the ZT times at which they are
% observed


function normalizeCompositeData_v2_positiveZTonly()

close all; %clear all;
plotPeaks = 0; %In case you want to reinstall the function that plots a 'o' over the peak.
%% Normalization Example
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10 6 hr 5 min summary';
% xlname = '23E10_examplesForNormalization.xlsx';
% cellsToRead = 'A3:AF64';

%% WT
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale';
% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';
% cellsToRead = 'A3:AR72';

% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1_splitZeroCrossings.xlsx';
% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansZT5to7.xlsx';
% cellsToRead = 'A3:P72';

%% MB122B>UAS-dnClk
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB122B_UASdnClk_23E10LexA_GCaMP7b';
% xlname = 'MB122B_UASdnClk_summary_noDeadFlies_ZT_fanGFPonly.xlsx';
% cellsToRead = 'A15:AX82';
% xlname = 'MB122B_UASdnClk_summary_noDeadFlies_ZT3to6startOnly.xlsx';
% cellsToRead = 'A15:AP87';

%% per0
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale\per0';
% xlname = 'per0_23E10_summary_GFPonly_sansFirstHr_splitZero.xlsx';
% cellsToRead = 'A3:AT63';

%% pdfr
rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\pdfrhan5046_23E10Gal4_GCaMP7b_tdTomato'; %\per0';
% xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalPeaks_ZT5to7StartOnly.xlsx';
% cellsToRead = 'A15:J75';
xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
cellsToRead = 'A15:AX75';
stacksPerHr = 12;
individualLineWidths = 0.5;

cd(rootdir);
[num,txt,raw] = xlsread(xlname,cellsToRead);

timeVals = squeeze(num(:,1:2:end));
% negativeZTindices = find(timeVals<0);
% timeVals(negativeZTindices)= timeVals(negativeZTindices)+24;
intensityVals = squeeze(num(:,2:2:end));
% for(ti = 1:size(timeVals,2)),
%     thisTimeSeries = timeVals(:,ti);
%     negativeIndices = find(thisTimeSeries<0);
%     if(~isempty(negativeIndices)),
%         timeVals(:,ti) = timeVals(:,ti)+24;
%     end;
% end;


% cmap = colormap(winter(size(timeVals,2)))*0.5;
cmap = colormap(jet(9))*0.5;

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

numTimeBins = ceil((maxTimeVal-minTimeVal)*stacksPerHr+1);
% numTimeBins = ceil((maxTimeVal-sortedStartTimes(1))*stacksPerHr+1);
imageSCmat = NaN(size(timeVals_sortedByStart,2),numTimeBins); %Each row is going to be a fly ID.
peakValsToQuantify = NaN(size(timeVals_sortedByStart,2),4); %First column = ZT time, second column = value, third column = min ZT, fourth column  = max ZT.
for(ti = 1:(size(timeVals_sortedByStart,2))-1),
    % Want to normalize each value by the one before it:
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
    if(nextTime_firstNonOverlapIndex>1),
        avgCurrentIntensity = nanmean(intensityVals_sortedByStart(currentTime_firstOverlapIndex:end,ti));
        avgNextIntensity = nanmean(intensityVals_sortedByStart(1:(nextTime_firstNonOverlapIndex-1),ti+1));
        currentIntensity = intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
        nextIntensity = intensityVals_sortedByStart(:,ti+1)/avgNextIntensity;
        if(ti==1),
            intensityVals_sortedByStart(:,ti) = currentIntensity;
        else,
            nextIntensity = nextIntensity*avgCurrentIntensity;
            %If we are missing overlapping timepoints, avgCurrentIntensity
            %causes a disproportionate amplication of nextIntensity
            
        end;
        intensityVals_sortedByStart(:,ti+1) = nextIntensity;
    end;
    color2plot = cmap(mod(ti,size(cmap,1))+1,:);
    plot(timeVals_sortedByStart(:,ti),intensityVals_sortedByStart(:,ti),'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5); 
    hold on; %,'ko'); hold on;
    [maxV,maxI] = max(intensityVals_sortedByStart(:,ti));
    if(plotPeaks),
    plot(timeVals_sortedByStart(maxI,ti),maxV,'Color',color2plot,'LineStyle','none','Marker','o','MarkerSize',1.5);
    end;
    peakValsToQuantify(ti,1:2) = [timeVals_sortedByStart(maxI,ti) maxV];
    peakValsToQuantify(ti,3:4) = [min(timeVals_sortedByStart(:,ti)) max(timeVals_sortedByStart(:,ti))];
%     display(['timeVals, maxV']);
%     display()
%     if(timeVals_sortedByStart(maxI,ti)==2.75),
%         display('why?');
%     end;

    %Computations related to imageSC
    intensityVals_sortedByStart_normalized(:,ti) =  currentIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
    flyIDs(:,ti) = ti;

%             [~,offsetIndex] = min(abs(timeVals_sortedByStart(:,ti)-minTimeVal));
%         offsetIndex = round(offsetIndex*stacksPerHr)+1;
% display([offsetIndex

    offsetIndex = round((timeVals_sortedByStart(1,ti)-minTimeVal)*stacksPerHr)+1
    nonNanIndices = find(~isnan(intensityVals_sortedByStart(:,ti)'));
%     display(numel(offsetIndex))
    imageSCmat(ti,offsetIndex:(offsetIndex+numel(nonNanIndices)-1)) = intensityVals_sortedByStart(nonNanIndices,ti)';
%     display(size(imageSCmat));
    
    if(ti==(size(timeVals_sortedByStart,2)-1)),
        display(size(nextTime));
        display(size(nextIntensity));
        if(numel(nextIntensity)>numel(nextTime)),
            nextIntensity = nextIntensity(find(~isnan(nextIntensity)));
        end;
        plot(nextTime,nextIntensity,'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5); 
        hold on; %,'ko'); hold on;
        intensityVals_sortedByStart(1:numel(nextIntensity),ti+1) = nextIntensity;
    
        [maxV,maxI] = max(nextIntensity);
%         plot(timeVals_sortedByStart(maxI,ti),maxV,'Color',color2plot,'LineStyle','none','Marker','o','MarkerSize',1.5);
        peakValsToQuantify(ti+1,1:2) = [timeVals_sortedByStart(maxI,ti+1) maxV];
        peakValsToQuantify(ti+1,3:4) = [min(timeVals_sortedByStart(:,ti+1)) max(timeVals_sortedByStart(:,ti+1))];
        
%         [~,offsetIndex] = min(abs(nextTime-minTimeVal));
%         offsetIndex = round(offsetIndex*stacksPerHr)+1;
        offsetIndex = round((nextTime(1)-minTimeVal)*stacksPerHr)+1
%         display(offsetIndex);
%         try,
        imageSCmat(ti+1,offsetIndex:(offsetIndex+size(nextIntensity,1)-1)) = nextIntensity; %intensityVals_sortedByStart_normalized(:,ti+1)';
%         catch,
%             display('meep.');
%         end;
    end;
%     display(imageSCmat(ti:(ti+1),:));
end;
%
%         % intensityVals_sortedByStart_normalized(:,ti+1) =  nextIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
%         flyIDs(:,ti+1) = ti+1;
% [maxv,maxi] = max(intensityVals_sortedByStart);
% display(maxv)
% display('timeVals_sortedByStart(maxi)');
% display(timeVals_sortedByStart(maxi))
% % display(maxi)
% display(timeVals_sortedByStart(maxi-12))
display(peakValsToQuantify)

% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:))]);
% xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);

%% Code pertaining to mean.

%This chunk superimposes the mean onto the 
% endTimeToPlot = max(timeVals_sortedByStart(:)); %minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
% endTimeToPlot = minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
% timeValsToPlot = [minTimeVal:(1/stacksPerHr):endTimeToPlot];
% timeValsToPlot = [minTimeVal:(1/stacksPerHr):maxTimeVal];
timeValsToPlot = (1:size(imageSCmat,2))/stacksPerHr-minTimeVal
% display(size(timeValsToPlot));
% display(size(imageSCmat));
timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));
% Median as a gray line:
% display(nanmedian(imageSCmat,1)');
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
ylim([0.5 2]);

%New figure with JUST the mean.
figure(3);
plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]); hold on;

%Plot the 0 line and the day night transitions:
plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
xlim([0 24]);
% xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
ylim([0.5 2]);

%% variables numReplicates_string and vecToWrite_string are used by JTK
firstNonZeroIndex = find(timeValsToPlot>=0,1);
% % timeValsOffset = timeVals_sortedByStart(1:(firstNonZeroIndex-1))+24;
% lastNegativeTimedFlyIndex = find(~isnan(imageSCmat(:,firstNonZeroIndex-1)),1,'last');
% valuesToShift = imageSCmat(1:lastNegativeTimedFlyIndex,1:firstNonZeroIndex);
% display(size(valuesToShift));
% display(lastNegativeTimedFlyIndex);
% display(firstNonZeroIndex);
% imageSCmat(1:lastNegativeTimedFlyIndex,(end-firstNonZeroIndex+1):end) = valuesToShift;
display(size(imageSCmat));
lastBelow24Index = find(timeValsToPlot<=24,1,'last');
imageSCmat = imageSCmat(:,firstNonZeroIndex:end); %lastBelow24Index); %end);
timeValsToPlot = timeValsToPlot(:,firstNonZeroIndex:end); %lastBelow24Index); %end);
display(size(imageSCmat))
numReplicates = sum(~isnan(imageSCmat),1);
numReplicates_string = sprintf('%i,',numReplicates)
imageSCmat = imageSCmat';
vecToWrite = imageSCmat(:)';
isNumIndex = find(~isnan(vecToWrite));
vecToWrite = vecToWrite(isNumIndex);
vecToWrite_string = sprintf('%2.5f,',vecToWrite) %(isNumIndex));

%% Write a *.csv file for running through MetaCycle.
%plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]); hold on;
% timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));

timeValsToWrite = NaN(numel(imageSCmat),1);
intensityValsToWrite = NaN(numel(imageSCmat),1);
firstIndex = 1;
for(ri = 1:size(imageSCmat,2)),
    display(size(timeValsToPlot));
    display(size(imageSCmat));
    timeValsToWrite(firstIndex:(firstIndex+size(imageSCmat,1)-1)) = timeValsToPlot;
    intensityValsToWrite(firstIndex:(firstIndex+size(imageSCmat,1)-1)) = imageSCmat(:,ri);
    firstIndex = firstIndex+size(imageSCmat,1);
end;
    
isNumIndex = find(~isnan(intensityValsToWrite));
intensityValsToWrite = intensityValsToWrite(isNumIndex);
timeValsToWrite = timeValsToWrite(isNumIndex);
% timevals_1to1_imageSC = repmat(timeValsToPlot,size(imageSCmat,1),1)';
% timevals_1to1_imageSC = timevals_1to1_imageSC(:);
% % timevalsToWrite = timevals_1to1_imageSC(isNumIndex);
% positiveTimeValIndices = find(timeValsToWrite>=0);
% timeValsToWrite = timeValsToWrite(positiveTimevalIndices);
% vecToWrite = vecToWrite(positiveTimevalIndices);
% 

timeValsToWrite = timeValsToWrite(1:numel(vecToWrite));
[sortedTimeValsToWrite, sortedIndices] = sort(timeValsToWrite,'ascend');
sortedVecToWrite = vecToWrite(sortedIndices);
figure; plot(sortedTimeValsToWrite,sortedVecToWrite,'ko');
% isNumIndex = find(~isnan(vecToWrite));

%xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
%%cellsToRead = 'A15:T75';
% numFlies = numel(timeVals_sortedByStart);
% rowToWrite = ['%1.5f,'];
% for(fi = 1:size(numFlies,1)),
%     rowToWrite = [rowToWrite '%1.5f,'];
% end;
% % rowToWrite = [rowToWrite '\n'];
fID = fopen(strrep(xlname,'.xlsx',[strrep(cellsToRead,':','_') '.csv']),'w');
% fprintf(fID,'%1.5f,',timeValsToPlot);
% fprintf(fID,'\n');
% % fprintf(fID,'%s',rowToWrite(:));
% for(ri = 1:size(imageSCmat,1)),
%     stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
%     stringToWrite = strrep(stringToWrite,'NaN','');
fprintf(fID,'%1.5f,',sortedTimeValsToWrite); %rowToWrite,imageSCmat(fi,:));
fprintf(fID,'\n');
fprintf(fID,'%1.5f,',sortedVecToWrite); %rowToWrite,imageSCmat(fi,:));
%     % fprintf(fID,'%s','\n');
% end;
fclose(fID);