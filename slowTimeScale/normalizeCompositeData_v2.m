%% function normalizeCompositeData_v2()
%
% June 14, 2022
% Functionally equivalent ot normalizeCompositeData.m but with MOAR
% features:
% 1) Outputs Mean & SEM plots
% 2) Outputs txt with time, mean & SEM.
% 3) Plots individual points instead of lines.

function normalizeCompositeData_v2()

close all; %clear all;
% 
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale\per0';
% 
% xlname = 'per0_23E10_summary_GFPonly.xlsx';
% % cellsToRead = 'A15:AD75';
% rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB122B_UASdnClk_23E10LexA_GCaMP7b';
% xlname = 'MB122B_UASdnClk_summary_noDeadFlies_ZT_fanGFPonly.xlsx';
% cellsToRead = 'A3:AN75';
rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10_slowTimescale'; %\per0';
xlname = '23E10_slowTimescale_noRFP_compositeData_ZT22start_sansHr1.xlsx';
cellsToRead = 'A3:AH75';
stacksPerHr = 12;
individualLineWidths = 0.5;

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
for(ti = 1:(size(timeVals_sortedByStart,2))-1),
    % Want to normalize each value by the one before it:
    currentTime = timeVals_sortedByStart(:,ti);
    currentTime = currentTime(find(~isnan(currentTime)));
    if(ti==12),
        display('meep');
    end;
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
    %Computations related to imageSC
    intensityVals_sortedByStart_normalized(:,ti) =  currentIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
    flyIDs(:,ti) = ti;
    
    offsetIndex = round((timeVals_sortedByStart(:,ti)-minTimeVal)*stacksPerHr)+1;
    imageSCmat(ti,offsetIndex:(offsetIndex+size(timeVals_sortedByStart,1)-1)) = intensityVals_sortedByStart(:,ti)';
    
    if(ti==(size(timeVals_sortedByStart,2)-1)),
        display(size(nextTime));
        display(size(nextIntensity));
        if(numel(nextIntensity)>numel(nextTime)),
            nextIntensity = nextIntensity(find(~isnan(nextIntensity)));
        end;
        plot(nextTime,nextIntensity,'Color',color2plot,'LineWidth',individualLineWidths); %,'LineStyle','none','Marker','o','MarkerSize',1.5); 
        hold on; %,'ko'); hold on;
        intensityVals_sortedByStart(1:numel(nextIntensity),ti+1) = nextIntensity;
        
        offsetIndex = round((nextTime-minTimeVal)*stacksPerHr)+1;
        imageSCmat(ti+1,offsetIndex:(offsetIndex+size(timeVals_sortedByStart,1)-1)) = nextIntensity; %intensityVals_sortedByStart_normalized(:,ti+1)';
    end;
%     display(imageSCmat(ti:(ti+1),:));
end;
%
%         % intensityVals_sortedByStart_normalized(:,ti+1) =  nextIntensity; %intensityVals_sortedByStart(:,ti)/avgCurrentIntensity;
%         flyIDs(:,ti+1) = ti+1;
% display(intensityVals_sortedByStart)
% display(timeVals_sortedByStart)

% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);

%% Code pertaining to mean.

%This chunk superimposes the mean onto the 
endTimeToPlot = minTimeVal + ceil(numTimeBins/stacksPerHr); %stacksPerHr*numTimeBins
timeValsToPlot = [minTimeVal:(1/stacksPerHr):endTimeToPlot];
% display(size(timeValsToPlot));
% display(size(imageSCmat));
timeValsToPlot = timeValsToPlot(1:size(imageSCmat,2));
% Median as a gray line:
%plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0 0]);
% Median as a gray dots:
% s = plot(timeValsToPlot,nanmedian(imageSCmat,1),'Marker','o','LineWidth',1,'MarkerSize',5,...
%     'MarkerEdgeColor',[0.5 0.5 0.5],'MarkerFaceColor','none','LineStyle','none');
% % hold off;
% % alpha(s,0.5);
hold on;

%Plot the 0 line and the day night transitions:
plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
% ylim([0.6 1.4])
% xlim([0 24]); %xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
ylim([0.5 2]);

%New figure with JUST the mean.
figure(3);
plot(timeValsToPlot,nanmedian(imageSCmat,1),'LineWidth',2,'Color',[0.5 0.5 0.5]); hold on;
display([timeValsToPlot(:) nanmedian(imageSCmat,1)']);

%Plot the 0 line and the day night transitions:
plot([12 12],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([24 24],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 0],[0.5 2],'Color',[0.5 0.5 0.5],'LineStyle',':');
plot([0 24],[1 1],'Color',[0.5 0.5 0.5],'LineStyle',':');
% xlim([0 24]);
% xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);
ylim([0.5 2]);

%xlname = 'pdf4han_23E10Gal4_GCaMP7b summary_ZTandSignalOnly.xlsx';
%%cellsToRead = 'A15:T75';
numFlies = numel(timeVals_sortedByStart);
rowToWrite = ['%1.5f,'];
for(fi = 1:size(numFlies,1)),
    rowToWrite = [rowToWrite '%1.5f,'];
end;
% rowToWrite = [rowToWrite '\n'];
fID = fopen(strrep(xlname,'.xlsx',[strrep(cellsToRead,':','_') '.csv']),'w');
fprintf(fID,'%1.5f,',timeValsToPlot);
fprintf(fID,'\n');
% fprintf(fID,'%s',rowToWrite(:));
for(ri = 1:size(imageSCmat,1)),
    stringToWrite = sprintf(rowToWrite,imageSCmat(ri,:));
    stringToWrite = strrep(stringToWrite,'NaN','');
    fprintf(fID,'%s\n',stringToWrite); %rowToWrite,imageSCmat(fi,:));
    % fprintf(fID,'%s','\n');
end;
fclose(fID);