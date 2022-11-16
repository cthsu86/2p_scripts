function plotTSeriesMovementLink()
close all;
rootdir = 'D:\84C10Gal4_UASGCaMP_RFP_180607';
expName = '84C10Gal4_UASGCaMP_RFP_180607';

xls2read = [expName '_TSeriesMovementLink.xlsx'];
output = strrep(xls2read,'.xlsx','');
movementDatName = [expName '.mat'];
xlsMovementIndicesName = [expName '_fullMovementIndices.xlsx'];

cd(rootdir);

if(exist([output '.ps'],'file')),
    delete([output '.ps']);
end;

[num,txt,raw] = xlsread(xls2read);
movementData = load(movementDatName);
% if(isfield(movementData,'fps')),
%     brain_fps = movementData.fps;
% else,
%     brain_fps = 2.7263*9;
% end;
behavior_fps = 30;
% brain_fps =
movement = movementData.interp_movement;

%Also want to read the movementIndices Excel spreadsheet.
[move_num, move_txt, move_raw] = xlsread(xlsMovementIndicesName);
withinVidOnsetIndices = cell2mat(move_raw(:,2));
fullMovementOnsetIndices = cell2mat(move_raw(:,4));

%iterate through all the TSeries:
fignumCount = 0;
subpcount = 1;
numsubp = 5;
for(ti = 1:size(raw,1)),
    tiName = raw{ti,3};
    brain_fps = raw{ti,5};
    intensityMatList = dir([tiName '*Intensities.mat']);
    if(numel(intensityMatList)==1),
        %Then we want to load the data listed.
        display(['Currently analyzing ' intensityMatList(1).name]);
        A = load(intensityMatList(1).name);
        %Also want to line up with the appropriate movement chunk of movement data.
        videoFrameOnset = raw{ti,1};
        indexOfLaserOnset = find(withinVidOnsetIndices==videoFrameOnset);
        if(numel(indexOfLaserOnset)>1),
            %Then need more discerning information.
        elseif(numel(indexOfLaserOnset)==0),
            display(['Could not find any laser onsets that matched ' num2str(videoFrameOnset) ' for imaging session ' intensityMatList(1).Name]);
        else,
            laserOnset_fullMovementFrameIndex = fullMovementOnsetIndices(indexOfLaserOnset);
        end;
        %Now that we have laserOnset_fullMovementFrameIndex, what we want
        %to do is to figure out the endpoint using the duration of the
        %brain activity data.
        brainActivity = A.normalizedIntensity;
        seconds_brainActivity = numel(brainActivity)/brain_fps;
        num_movementFrames = round(seconds_brainActivity*behavior_fps);
        if(subpcount==1),
            fignumCount = fignumCount+1;
            figure;
        end;
        subplot(numsubp,1,subpcount);
        maxBrainVal = max(brainActivity);
        max_ylim = ceil(maxBrainVal);
        display(intensityMatList(1).name);
        movementForBrainSeries = movement(laserOnset_fullMovementFrameIndex:(laserOnset_fullMovementFrameIndex+num_movementFrames-1));
        movementAmplitude = max(movementForBrainSeries)/max_ylim;
        plot([1:num_movementFrames]/behavior_fps,movementForBrainSeries/movementAmplitude,'Color',[0.5 0.5 0.5]); hold on;
        plot([1:numel(brainActivity)]/brain_fps,brainActivity,'b'); hold on;
        title([intensityMatList(1).name]);
        %         display(seconds_brainActivity);
        clear laserOnset_fullMovementFrameIndex;
        if(subpcount ==numsubp),
            subpcount = 1;
        else,
        subpcount = subpcount+1;
        end;
    else,
        display(['Found ' num2str(numel(intensityMatList)) ' files fitting the name structure ' tiName '*Intensities.mat']);
    end;
end;

for(fignum = 1:fignumCount),
    orient(figure(fignum),'landscape');
    print(figure(fignum),'-dpsc2',[output '.ps'],'-append');
%     close(figure(fignum));
end;

ps2pdf('psfile', [output '.ps'], 'pdffile', [output '.pdf'], ...
    'gspapersize', 'letter',...
    'verbose', 1, ...
    'gscommand', 'C:\Program Files\gs\gs9.21\bin\gswin64.exe');