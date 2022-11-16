%% function normalizeCompositeData_v2_timeAlign()
%
% July 7, 2022

function normalizeCompositeData_v2_timeAlign()

close all; %clear all;

rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale\per0';
xlname = 'per0_23E10_summary_GFPonly.xlsx';
cellsToRead = 'A15:AH75';
% 
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale';
% xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';
% cellsToRead = 'A3:AH63';
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\pdfrhan5046_23E10Gal4_GCaMP7b_tdTomato'; %\per0';
% xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
% cellsToRead = 'A15:T75';
stacksPerHr = 12;
individualLineWidths = 0.5;

cd(rootdir);
[num,txt,raw] = xlsread(xlname,cellsToRead);

timeVals = squeeze(num(:,1:2:end));
intensityVals = squeeze(num(:,2:2:end));

% cmap = colormap(winter(size(timeVals,2)))*0.5;
cmap = colormap(jet(size(timeVals,2)));
%Set 'yellow' values to half of what they are
yellowIndices = find(cmap(:,1)==1 & cmap(:,2)==1);
if(~isempty(yellowIndices)),
    for(yi = 1:numel(yellowIndices)),
        yellowIndex = yellowIndices(yi);
        cmap(yellowIndex,:) = cmap(yellowIndex,:)/2;
    end;
end;

%I guess the first thing we do is sort by timeVals.
[sortedStartTimes, sortedIndices] = sort(timeVals(1,:));
timeVals_sortedByStart = NaN(size(timeVals)); %timeVals(:,sortedIndices);
intensityVals_sortedByStart = NaN(size(intensityVals)); %(:,sortedIndices);

minTimeVal = sortedStartTimes(1);
maxTimeVal = max(timeVals(:));

for(si = 1:numel(sortedIndices)),
    timeVals_sortedByStart(:,si) = timeVals(:,sortedIndices(si));
    currentIntensity = intensityVals(:,sortedIndices(si));
    if(abs(currentIntensity(end))<0.01),
        display(currentIntensity);
        currentIntensity = currentIntensity*1000;
    end;
    intensityVals_sortedByStart(:,si) = currentIntensity;

end;

%We need to preallocate a matrix, imageSCmat, whose X values are the
%hour range spanned by the input values multipled by six (for the 5 minute
%imaging interval).
firstHrMean = nanmean(intensityVals_sortedByStart(1:stacksPerHr,:));
intensityVals_sortedByStart = (intensityVals_sortedByStart-repmat(firstHrMean,size(intensityVals_sortedByStart,1),1))./repmat(firstHrMean,size(intensityVals_sortedByStart,1),1);; 
% Need to evenly distribute the text.
yUpperBound = max(intensityVals_sortedByStart(end,:));
yLowerBound = min(intensityVals_sortedByStart(end,:));
deltaY = (yUpperBound-yLowerBound)/size(intensityVals_sortedByStart,2);
for(ti = 1:(size(timeVals_sortedByStart,2))),
    % Want to normalize each value by the one before it:
    currentTime = timeVals_sortedByStart(:,ti);
    isNumIndices = find(~isnan(currentTime));
    currentTime = currentTime(isNumIndices);
    currentIntensity = intensityVals_sortedByStart(isNumIndices,ti);
    color2plot = cmap(ti,:);
%     display(size(currentTime));
%     display(size(currentIntensity));
% y2plot = (currentIntensity-currentIntensity(1))/currentIntensity(1);
    plot(currentTime-currentTime(1),currentIntensity,'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5); 
    hold on; %,'ko'); hold on;
    timeStringToWrite = sprintf('ZT %1.2f',currentTime(end));
    textY = yUpperBound-deltaY*(ti-1);
    text(currentTime(end)-currentTime(1)+0.1, textY,timeStringToWrite,'Color',color2plot,'FontSize',14);
    timeStartToWrite = sprintf('ZT %1.2f',currentTime(1));
    text(-1.5, textY,timeStartToWrite,'Color',color2plot,'FontSize',14);
    
end;
xlim([-1.8 7]);
%
%         % intensityVals_sortedByStart_normalized(:,ti+1) =  nextIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
%         flyIDs(:,ti+1) = ti+1;
% display(intensityVals_sortedByStart)
% display(timeVals_sortedByStart)

% ylim([0.6 1.4])
% xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);

% %% Code pertaining to mean.
% 
% %This chunk superimposes the mean onto the 
% endTimeToPlot = minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
% timeValsToPlot = [minTimeVal:(1/stacksPerHr):endTimeToPlot];
% % display(size(timeValsToPlot));
% % display(size(imageSCmat));
% timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));
% % Median as a gray line:
% %plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0 0]);
% % s = plot(timeValsToPlot,nanmedian(imageSCmat,1),'Marker','o','LineWidth',1,'MarkerSize',5,...
% %     'MarkerEdgeColor',[0.5 0.5 0.5],'MarkerFaceColor','none','LineStyle','none');
% % hold off;
% % alpha(s,0.5);
% hold on;
% 
% %Plot the 0 line and the day night transitions:
% plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
% % ylim([0.6 1.4])
% xlim([0 24]); %xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
% ylim([0.5 2]);
% 
% %New figure with JUST the mean.
% figure(3);
% plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]); hold on;
% 
% %Plot the 0 line and the day night transitions:
% plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
% plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
% xlim([0 24]);
% % xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
% ylim([0.5 2]);
% 
% %% variables numReplicates_string and vecToWrite_string are used by JTK
% firstNonZeroIndex = find(timeVals_sortedByStart>=0,1);
% % % timeValsOffset = timeVals_sortedByStart(1:(firstNonZeroIndex-1))+24;
% % lastNegativeTimedFlyIndex = find(~isnan(imageSCmat(:,firstNonZeroIndex-1)),1,'last');
% % valuesToShift = imageSCmat(1:lastNegativeTimedFlyIndex,1:firstNonZeroIndex);
% % display(size(valuesToShift));
% % display(lastNegativeTimedFlyIndex);
% % display(firstNonZeroIndex);
% % imageSCmat(1:lastNegativeTimedFlyIndex,(end-firstNonZeroIndex+1):end) = valuesToShift;
% display(size(imageSCmat));
% imageSCmat = imageSCmat(:,firstNonZeroIndex:end);
% display(size(imageSCmat))
% numReplicates = sum(~isnan(imageSCmat),1);
% numReplicates_string = sprintf('%i,',numReplicates)
% imageSCmat = imageSCmat';
% vecToWrite = imageSCmat(:)';
% isNumIndex = find(~isnan(vecToWrite));
% vecToWrite_string = sprintf('%2.5f,',vecToWrite(isNumIndex))
% 
% % firstNonZeroIndex = 
% 
% %
% %
% 
% %xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
% %%cellsToRead = 'A15:T75';
% % numFlies = numel(timeVals_sortedByStart);
% % rowToWrite = ['%1.5f,'];
% % for(fi = 1:size(numFlies,1)),
% %     rowToWrite = [rowToWrite '%1.5f,'];
% % end;
% % % rowToWrite = [rowToWrite '\n'];
% % fID = fopen(strrep(xlname,'.xlsx',[strrep(cellsToRead,':','_') '.csv']),'w');
% % fprintf(fID,'%1.5f,',timeValsToPlot);
% % fprintf(fID,'\n');
% % % fprintf(fID,'%s',rowToWrite(:));
% % for(ri = 1:size(imageSCmat,1)),
% %     stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
% %     stringToWrite = strrep(stringToWrite,'NaN','');
% %     fprintf(fID,'%s\n',stringToWrite); %rowToWrite,imageSCmat(fi,:));
% %     % fprintf(fID,'%s','\n');
% % end;
% % fclose(fID);