close all; clear all;
[file,path] = uigetfile('*.mat');

cd(path);
maskmat = load(file);

%Under most cases, bwFrame will be equal to the default:
% bwFrame = maskmat.bwFrame;
%Under some cases, you will have to determine the appropriate thresholding
%on the avgFrame:
figure(1);
imagesc(maskmat.avgImg,[0 50]); %200]);
colorbar;

answer = inputdlg('Enter number of regions');
if(~isempty(answer)),
    answer = answer{1};
    numRegions = str2num(answer);
else,
    errordlg('Hi Camilo, this is your problem now.');
end;

maskInProgress = zeros(size(maskmat.avgImg));
for(ri = 1:numRegions),
    [bw,xi,yi] = roipoly; %This is the line of code where the user selects the ROI.
    bw = poly2mask(xi,yi,size(maskmat.avgImg,1),size(maskmat.avgImg,2));
    maskInProgress = maskInProgress|bw;
%     display('.');
end;
maskmat.bwFrame = maskInProgress;
newFileName = strrep(file, 'mask','userDrawnMask');
save(newFileName,'-struct','maskmat');

% close all; clear all;
% [file,path] = uigetfile('*.mat');
% 
% cd(path);
% maskmat = load(file);
% 
% %Under most cases, bwFrame will be equal to the default:
% % bwFrame = maskmat.bwFrame;
% %Under some cases, you will have to determine the appropriate thresholding
% %on the avgFrame:
% display(['bwThresh*256=' num2str(maskmat.bwThresh*256)]);
% h1 = figure(1);
% set(h1,'Position',[20 300 840 684]);
% % h1.Position = [10 10 256 256];
% % h1.PaperPosition = [10 10 256 256];
% 
% filteredImg = medfilt2(maskmat.avgImg,[3 3]);
% imagesc(filteredImg,[0 200]);
% colorbar;
% 
% answer = inputdlg('Enter bwThreshold');
% if(~isempty(answer)),
%     %     regnumstring = num2str(answer)
%     answer = answer{1};
%     bwThresh = answer;
%     bwFrame = (filteredImg>str2num(bwThresh));
% else,
%     bwFrame = maskmat.bwFrame;
% end;
% 
% figure(2);
% imshow(uint8(bwFrame*256));
% 
% %Find the regions, then ask the user to pick the relevant regions
% s = regionprops(bwFrame>0,'Area','Centroid','PixelIdxList');
% if(numel(s)>30),
%     bwFrame = imfill(bwFrame,'holes');
% end;
% s = regionprops(bwFrame>0,'Area','Centroid','PixelIdxList');
% imshow(uint8(bwFrame));
% figure; imshow(uint8(bwFrame*256)); hold on;
% for(si = 1:numel(s)),
%     centroid = s(si).Centroid;
%     text(centroid(1),centroid(2),num2str(si),'Color','r');
% end;
% 
% answer = inputdlg('Enter region numbers (separated by spaces) to save in this mask: ');
% if(~isempty(answer)),
%     %     regnumstring = num2str(answer)
%     answer = answer{1}
%     
%     bwFrame = zeros(size(bwFrame));
%     if(ischar(answer)),
%         regionIndexList = str2num(answer);
%         newFileName = strrep(file, 'ask',['askReg' answer]);
%     else,
%         regionIndexList = answer;
%         newFileName = strrep(file, 'ask',['askReg' num2str(answer)]);
%     end;
%     newRegionStruct = cell(max(size(regionIndexList)),1);
%     for(ri = 1:numel(regionIndexList)),
%         thisRegion = s(regionIndexList(ri));
%         bwFrame(thisRegion.PixelIdxList) = 1;
%         newRegionStruct{ri} = thisRegion;
%     end;
%     A.bwFrame = bwFrame;
%     %     A.s =
%     
%     save(newFileName,'-struct','A');
%     %
%     % imshow(uint8(avgImg));
%     figure; imshow(uint8(bwFrame*256));
% end;