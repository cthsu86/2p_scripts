function normalizeCompositeData()

close all; %clear all;

rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\MB122B_UASdnClk_23E10LexA_GCaMP7b';
xlname = 'MB122B_UASdnClk_summary_noDeadFlies_ZT_fanGFPonly.xlsx';
cellsToRead = 'A3:AN75';

cd(rootdir);
[num,txt,raw] = xlsread(xlname,cellsToRead);

timeVals = squeeze(num(:,1:2:end));
intensityVals = squeeze(num(:,2:2:end));

% cmap = colormap(winter(size(timeVals,2)))*0.5;
cmap = colormap(winter(5))*0.5;

%I guess the first thing we do is sort by timeVals.
[sortedStartTimes, sortedIndices] = sort(timeVals(1,:));
timeVals_sortedByStart = NaN(size(timeVals)); %timeVals(:,sortedIndices);
intensityVals_sortedByStart = NaN(size(intensityVals)); %(:,sortedIndices);

for(si = 1:numel(sortedIndices)),
    timeVals_sortedByStart(:,si) = timeVals(:,sortedIndices(si));
    intensityVals_sortedByStart(:,si) = intensityVals(:,sortedIndices(si));
end;


for(ti = 1:(size(timeVals_sortedByStart,2))-1),
    % Want to normalize each value by the one before it:
    if(ti==16),
        display('meep.');
    end;
    
    currentTime = timeVals_sortedByStart(:,ti);
    currentTime = currentTime(find(~isnan(currentTime)));
    nextTime = timeVals_sortedByStart(:,ti+1);
    nextTime = nextTime(find(~isnan(nextTime)));
    nextTime_firstNonOverlapIndex = find(nextTime>currentTime(end),1,'first');
    if(isempty(nextTime_firstNonOverlapIndex)),
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
        end;
        intensityVals_sortedByStart(:,ti+1) = nextIntensity;
    end;

    color2plot = cmap(mod(ti,size(cmap,1))+1,:);
    plot(timeVals_sortedByStart(:,ti),intensityVals_sortedByStart(:,ti),'Color',color2plot,'LineWidth',1.5); hold on; %,'ko'); hold on;
    if(ti==(size(timeVals_sortedByStart,2)-1)),
        display(size(nextTime));
        display(size(nextIntensity));
        if(numel(nextIntensity)>numel(nextTime)),
            nextIntensity = nextIntensity(find(~isnan(nextIntensity)));
        end;
        if(nextIntensity(1)>10),
            display('meep.');
        end;
        try,
        plot(nextTime,nextIntensity,'Color',color2plot,'LineWidth',1.5); hold on; %,'ko'); hold on;
        catch,
            display(['what?']);
        end;
        intensityVals_sortedByStart(1:numel(nextIntensity),ti+1) = nextIntensity;
    end;
end;
display(intensityVals_sortedByStart)
display(timeVals_sortedByStart)

% ylim([0.6 1.4])
xlim([timeVals_sortedByStart(1,1) max(timeVals_sortedByStart(:,end))]);