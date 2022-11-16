% function plotMultiFly()
%
% November 04, 2022
%
function plotMultiFlyBrainSignal_withAveraging()
close all;
primedir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10LexA_csChrimson_23E10_ASAP2s';
xl2read = '23E10LexA_csChrimson_23E10_ASAP2s_summaryFirstTrialOnly.xlsx';

%Columns of xl2read:
%A. Color to plot (in lieu of establishing the categories of individual
%mice). Can be 'r','g','b','c','y','m','k' or RGB values where [1 0 0] =
%red.
%B. Exp_group
%C. flyNum (in case a fly has multiple files associated with it).
%D. FileName
%E. rootdir

% Each FileName is a *.txt of time(s),RFP,GFP
t0_time = 300; %5 minutes of baseline
baseline_numSeconds = 30; %Want to average over 30 seconds.

%
% In order to interpolate over the different imaging rates, want to have a
% binsPerSec value
binsPerSec = 100;
secsPerBin = 1/binsPerBec;

cd(primedir);
T = readtable(xl2read); %,'TextType','string');

for(ti = 1:size(T,1)),
    %Iterating through each mouse.
    try,
        firstDateToRead = T{ti,4}{1};
    catch,
        firstDateToRead = T{ti,4};
    end;
    display(ti);
    rootdir = T{ti,5}{1};
    filename = T{ti,4}{1};
    flyNum = T{ti,3}; %{1};
    expGroup_name = T{ti,2}{1};
    color2plot = str2num(T{ti,1}{1});
    if(numel(rootdir)>0),
        cd(rootdir);
        fID = fopen([filename '.txt']);
        freadOutput = fscanf(fID,'%f,');
        fclose(fID);
        trialTime = double(freadOutput(1:3:end));
        greenSignal = double(freadOutput(3:3:end));
        %         plot(trialTime,greenSignal,'color',color2plot); hold on;
        t0_index = find(trialTime<t0_time,1,'last');
        t0_minusBaselineIndex = find(trialTime<(t0_time-baseline_numSeconds),1,'last');
        trialTime = trialTime-trialTime(t0_index);
        meanGreenBaseline = nanmean(greenSignal(t0_minusBaselineIndex:t0_index));
        greenSignal = (greenSignal - meanGreenBaseline)/meanGreenBaseline;
        plot(trialTime,greenSignal,'color',color2plot); hold on;
        trialTimeInterp = min(trialTime):secsPerBin:max(trialTime);
        greenSignalInterp = interp1(triaTime,greenSignal,trialTimeInterp);

        if(~exist('data2avg','var'))
            trialTimeForAveragingData = trialTimeInterp; %NaN(binsPerSec);
            data2avg = NaN(numel(trialTimeForAveragingData),size(T,1));
        end;
        % Next, need to figure out when relative to
        % trialTimeForAveragingData this signal starts
        %
        % First need to check if the first trial time precedes the first
        % trialTimeForAvergingData timepoint.
        if(trialTimeInterp(1)<trialTimeForAveragingData(1)),
            [~,minI]=min(abs(trialTimeForInterp - trialTimeForAveragingData(1)));
            data2avg(:,ti) = greenSignalInterp(minI:size(data2avg,1));
        else,
            [~,minI]=min(abs(trialTimeForAveragingData - trialTimeForInterp(1)));
            data2avg(minI:(minI+numel(greenSignalInterp)-1),ti) = greenSignalInterp(minI:end);
        end;
    end;
end;
plot([0 0],[-0.15 0.15],'LineStyle',':','Color',[0.5 0.5 0.5])
ylim([-0.15 0.06])
ylim([-0.15 0.08])
grid on;
xlim([-300 330])
plot([0 30],[0.05 0.05],'LineWidth',5,'Color',[1 0 0])
title([strrep(xl2read,'_',' ')]); xlim([-300 330]);
xlabel(['Time (s)'])

figure(2);
plot(trialTimeForAveragingData,mean(data2avg,2));