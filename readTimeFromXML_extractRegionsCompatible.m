% function [stackTimes, shutterTimes, lastBaselineIndex,varargout] = readTimeFromXML_extractRegionsCompatible(varargin)
%
% November 11, 2020
% Modified from original readTimeFromXML so that it also outputs a list of
% the relevant tifs to read for each stack.

function [stackTimes, shutterTimes, lastBaselineIndex,varargout] = readTimeFromXML_extractRegionsCompatible(varargin)

if(nargin==0),
    rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10\201116';
    xmlname = 'TSeries-11162020-1436-551.xml';
    cycleRankToReturn = 0; %Starts at 0, rather than 1.
    useAbsoluteTime = 1;
    cd(rootdir);
else,
    %Assume the parent function has already put us in the proper directory.
    xmlname = varargin{1};
    cycleRankToReturn = varargin{2};
    useAbsoluteTime=0;
end;

maxStacks = 5*20*60; %5 Hz, 20 minutes, 60 seconds.

frameTimeLabel = '<Frame relativeTime="';
voltageNameLabel = '<VoltageOutput name="';
% sequenceStartLabel = '<Sequence type="TSeries ZSeries Element" cycle="';
dateTimeLabel='<PVScan version="5.4.64.700" date="';
tiffNameLabel = '<File channel="2" channelName="Ch2" filename="';
%       <File channel="1" channelName="Ch1" filename="TSeries-11022020-1620-547_Cycle00001_Ch1_000002.ome.tif" />
%       <File channel="2" channelName="Ch2" filename="TSeries-11022020-1620-547_Cycle00001_Ch2_000002.ome.tif" />

tiffListForStack_allTimepts = cell(maxStacks,1);
if(exist('rootdir','var')),
    fID = fopen(xmlname);
    subdirectoryEntered = 0;
else,
    if(~exist(xmlname,'file')),
        xmlStartIndex = strfind(xmlname,'.xml');
        cd(xmlname(1:(xmlStartIndex-1)));
        subdirectoryEntered = 1;
    else,
        subdirectoryEntered = 0;
    end;
    fID = fopen(xmlname);
end;
% catch,
% end;

stackNum = 1;
voltIndex = 0;
while(~feof(fID) && voltIndex<=cycleRankToReturn),
    line = fgets(fID);
    frameTimeLineCharNumber = strfind(line,frameTimeLabel);
    tiffNameLabelNumber = strfind(line, tiffNameLabel);
    if(~isempty(strfind(line,dateTimeLabel))),
        timeStartIndex = strfind(line,dateTimeLabel);
        endOfLine = line((timeStartIndex+numel(dateTimeLabel)):end);
        quoteIndices = strfind(endOfLine,'"');
        dateTimeString = endOfLine(1:(quoteIndices(1))-1)
        startTime_dateNum = datenum(dateTimeString); %Gets saved to the matrix at the very end.
    elseif(~isempty(frameTimeLineCharNumber) && ((voltIndex==cycleRankToReturn)||cycleRankToReturn==0)),
        %         display(['Reading relativeTime when voltnum=' num2str(voltIndex) ', Line: ' line]);
        % <Frame relativeTime="36.872451" absoluteTime="499.962451" index="4" parameterSet="CurrentSettings">
        %
        % 1) Want to parse the line:
        
        quoteIndices = strfind(line,'"');
        relativeTime = str2num(line((quoteIndices(1)+1):(quoteIndices(2)-1))); %relativeTime reinitializes at the start of each cycle.
        absoluteTime = str2num(line((quoteIndices(3)+1):(quoteIndices(4)-1)));
        sliceIndexNum = str2num(line((quoteIndices(5)+1):(quoteIndices(6)-1)));
        if(useAbsoluteTime), %varargtou = 1
            relativeTime = absoluteTime;
        end;
        
        if(sliceIndexNum==1),%Then we are at the start of a stack.
            stackStartTime = relativeTime;
            if(exist('prevStackStartTime','var')),
                if(~exist('stackStartAndEnd','var')),
                    stackStartAndEnd = NaN(maxStacks,2);
                    stackStartAndEnd(1,1) = prevStackStartTime;
                end;
            end;
            if(exist('prevSliceTime','var')),
                stackStartAndEnd(stackNum,1) = stackStartTime;
                stackStartAndEnd(stackNum-1,2) = prevSliceTime;
                if(exist('tiffListForStack','var')),
                    numSlices = size(tiffListForStack,1);
                    tiffListForStack_allTimepts{stackNum-1,1} = tiffListForStack;
                    clear tiffListForStack;
                    tiffListForStack = cell(numSlices,1);
                end;

            end;
            prevStackStartTime = stackStartTime;
            stackNum = stackNum+1;
            if(mod(stackNum,100)==0),
                display(stackNum);
            end;
        end;
        %         prevSliceIndexNum = sliceIndexNum;
        prevSliceTime = relativeTime;
    elseif(~isempty(tiffNameLabelNumber) && ((voltIndex==cycleRankToReturn)||cycleRankToReturn==0)),
        endOfLine = line((numel(tiffNameLabel)+1):end);
        %       <File channel="2" channelName="Ch2" filename="TSeries-11022020-1620-547_Cycle00001_Ch2_000002.ome.tif" />
        quoteIndices = strfind(endOfLine,'"');
        tiffName =endOfLine((quoteIndices(1)+1):(quoteIndices(2)-1));
        if(exist('tiffListForStack','var')),
            if(sliceIndexNum>size(tiffListForStack,1)),
                temp = cell(sliceIndexNum,1);
                for(si = 1:(sliceIndexNum-1)),
                    temp(si) = tiffListForStack(si);
                end;
                temp{sliceIndexNum} = tiffName;
                tiffListForStack = temp;
            else,
                temp{sliceIndexNum} = tiffName;
            end;
        else, %This is where the tiffListForStack variable first gets initialized.
            tiffListForStack = cell(1,1);
            tiffListForStack{1} = tiffName;
        end;
    elseif(~isempty(strfind(line,voltageNameLabel)) && voltIndex<=cycleRankToReturn),
        display(['Reading voltageName when voltnum=' num2str(voltIndex) ', Line: ' line]);
        quoteIndices = strfind(line,'"');
        voltName = line((quoteIndices(1)+1):(quoteIndices(2)-1)) %This reinitializes at the start of each cycle.
        if(voltIndex<=cycleRankToReturn),
            [shutterTimes,seconds_baseline] = shutterStartAndStopFromText(voltName);
        end;
        voltIndex = voltIndex+1;
    else,
    end;
end;
varargout{1} = tiffListForStack_allTimepts;
%
stackStartAndEnd(stackNum-1,2) = prevSliceTime; %stackStartTime;
trueMaxFrame = find(isnan(stackStartAndEnd(:,1)),1)-1;
if(~isempty(trueMaxFrame)),
    stackTimes = stackStartAndEnd(1:trueMaxFrame,:);
else,
    stackTimes = stackStartAndEnd;
end;
% stackStartAndEnd(stackNum-1,2) = prevSliceTime;
if(exist('seconds_baseline','var') && ~isnan(seconds_baseline)),
    firstActivationIndex = find(stackTimes(:,1)>seconds_baseline,1);
    lastBaselineIndex = firstActivationIndex-1;
else,
end;

fclose(fID);

if(subdirectoryEntered),
    cd ..
end;

save(strrep(xmlname,'.xml','_stackTimesFromXML.mat'),'stackTimes','startTime_dateNum','tiffListForStack_allTimepts');
% clearvars -except stackTimes shutterTimes
% %Lastly, need to select for the stackStartAndEnd of the cycle in question
% sortedStackStarts = sort(stackStartAndEnd(:,1),'ascend');
% % sorted
% cycleStartIndices = find(stackStartAndEnd(:,1)==0);


% stackTimes, shutterTimes
% stackTimes = stackStartAndEnd(cycleStartIndices(cycleRankToReturn):(cycleStartIndices(cycleRankToReturn)-1));
% shutterTimes = shutterCellMat(voltIndex);