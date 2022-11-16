function plot2PhotonIntensityVsTime_multiTrial()
close all;
primedir = 'D:\Hugin';%\200828';
xlname = '23E10_csChrimson_HugS3_Arclight_CellBodies_100msPulse.xlsx';
secs2Bin = 5;

outname = strrep(xlname,'.xlsx','_timeVsIntensity.xlsx');
outname2 = strrep(xlname,'.xlsx',['_timeVsIntensity_' num2str(secs2Bin) 'sBins.xlsx']);

cd(primedir);
if(exist(outname,'file')),
    delete(outname);
end;
if(exist(outname2,'file')),
    delete(outname2);
end;



[num,txt,raw] = xlsread(xlname);
integralOverSignal = NaN(size(raw,1),2);
integralAfterSignal = NaN(size(raw,1),2);
for(xi = 1:size(raw,1)),
    rootdir = raw{xi,2}
    signalMatname = raw{xi,3};
    cycleRankNum = raw{xi,4};
    xmlName = raw{xi,5};
    
    [timeIntensityMat,lastBaselineIndex, voltOutTimes] = output2P_intensityVsTime(rootdir,signalMatname,cycleRankNum,xmlName);
    
    color2plot = str2num(raw{xi,1});
    
    %     baselineIntensity = mean(timeIntensityMat(1:lastBaselineIndex,3));
    baselineLastTimeSecondsSinceTrialStart = timeIntensityMat(lastBaselineIndex,1);
    baselineFirstTimeSecondsSinceTrialStart = baselineLastTimeSecondsSinceTrialStart-30;
    firstBaselineIndex = find(timeIntensityMat(:,1)>baselineFirstTimeSecondsSinceTrialStart,1);
    
    baselineIntensity_allPts = timeIntensityMat(firstBaselineIndex:lastBaselineIndex,3);
    baselineIntensity_mean = nanmean(baselineIntensity_allPts);
    
    greaterThan10percent = sum(((baselineIntensity_allPts-baselineIntensity_mean)/baselineIntensity_mean)>0.1);
    
    
    normalizedIntensity = (timeIntensityMat(:,3)-baselineIntensity_mean)/baselineIntensity_mean;
    

    if(sum(greaterThan10percent)==0),
        figure(100);
    else,
        figure(99);
    end;
    timevals = timeIntensityMat(:,1)-timeIntensityMat(lastBaselineIndex,1);
    smoothedNormalizedIntensity = smooth(normalizedIntensity,6);
    plot(timevals,smooth(normalizedIntensity,20),'Color',color2plot,'LineWidth',1); hold on;
    
    if(sum(greaterThan10percent)==0),
        lastVoltTime = voltOutTimes(end)-timeIntensityMat(lastBaselineIndex,1);
        lastSignalTime = find(timevals>lastVoltTime,1)-1;
        integralOverSignal(xi,1) = sum(smoothedNormalizedIntensity((lastBaselineIndex+1):lastSignalTime));
        integralOverSignal(xi,2) = color2plot(2);

%         interStackInterval = 30/(lastBaselineIndex-firstBaselineIndex+1);
        stacksPer30seconds = lastBaselineIndex-firstBaselineIndex+1;
        binsPer30seconds = 30/secs2Bin;
        interStackInterval = 30/stacksPer30seconds;
        
        integralAfterSignal(xi,1) = sum(smoothedNormalizedIntensity((lastSignalTime+1):(lastSignalTime+stacksPer30seconds)));
        signal2write = normalizedIntensity(firstBaselineIndex:end);
        stacksPerBin = round(stacksPer30seconds/binsPer30seconds) %interStackInterval*secs2Bin)
        if(~exist('mat2write','var')),
            mat2write = NaN(numel(signal2write)*2,size(raw,1));
            
            binnedMat2Write = NaN(ceil(size(mat2write,1)/stacksPerBin)+1,size(raw,1));
        end;
        mat2write(2:(numel(signal2write)+1),xi) = signal2write;
        mat2write(1,xi) = color2plot(2);

        binnedMat2Write(1,xi) = color2plot(2);
        numBinsForSignal = ceil(numel(signal2write)/stacksPerBin);
        nanPaddedSignal = NaN(numBinsForSignal*stacksPerBin,1);
        nanPaddedSignal(1:numel(signal2write)) = signal2write;
%         try,
        reshapedSignal = reshape(nanPaddedSignal,stacksPerBin,numel(nanPaddedSignal)/stacksPerBin);
%         catch,
%             display(stacksPerBin);
%             display(numel(nanPaddedSignal));
%         end;
        binnedSignal = sum(reshapedSignal,1);
%         try,
        binnedMat2Write(2:(numel(binnedSignal)+1),xi) = binnedSignal(:);
%         catch,
%             display(['Woe and sadness.']);
%         end;
    end;
end;

plot(voltOutTimes-timeIntensityMat(lastBaselineIndex,1),[1.2 1.2],'Color','r','LineWidth',5);
plot([timevals(1) timevals(end)],[0 0],':','Color',[0.5 0.5 0.5]);
xlim([timevals(1) timevals(end)]);

cd(primedir);
saveas(figure(99),strrep(xlname,'xlsx','.png'));
saveas(figure(99),strrep(xlname,'xlsx','.fig'));

xlswrite(outname,mat2write,1); % vmat2write()
% pause(10);
try,
xlswrite(outname,binnedMat2Write,2);
catch,
    display('mrp');
end;
% pause(10);
xlswrite(outname,[integralOverSignal integralAfterSignal],3);

display(integralOverSignal)
% display(lastBaselineIndex-firstBaselineIndex);