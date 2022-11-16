%%function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime_hardcodedDemo(varargin)
%
% Best used in instances where it is necessary to compute when the shutter
% closes over the scanner (for instance, in the chrimson stimulation case).
%
% Input Excel file
% Column 4: overwrites the default computation (first closure of the shutter)
% in the fourth row of the Excel spreadsheet input.
% Column 5: "cycleRankNum" = 0 if no shutter/voltage output used.
% Column 6: RGB color value.

function [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime_hardcodedDemo()
close all;
primedir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\HugS3_ASAP2s';
xl2read = 'Gaboxadol.xlsx';

cd(primedir),
[n,t,r] = xlsread(xl2read);

% data2plot = cell(size(r,1),3);
for(ri = 1:size(r,1)),
    rootdir = r{ri,1};
    signalMatname = r{ri,2};
    stackTimesXMLname = r{ri,3};
    
    if(ri==size(r,1)),
        plotSignal = 1;
    else,
        plotSignal = 0;
    end;    
    [timeIntensityMat, lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime(rootdir,signalMatname,...
        r{ri,5},stackTimesXMLname,plotSignal, r{ri,4},str2num(r{ri,6}));
%     data2plot{ri,1} = timeIntensityMat(:,1);
%     data2plot{ri,3} = lastBaselineIndex;
%     data2plot{ri,4} = voltOutTimes;
end;

% pause;

