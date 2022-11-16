close all; clear all;
[file,path] = uigetfile({'*.mat; *.png'});
if(strcmp(file(end-3):file(end),'.mat')),
    isMat = 1;
else, %assume is PNG?
    isMat = 0;
end;
cd(path);

if(isMat),
    figure(1);
    maskmat = load(file);
    %Under most cases, bwFrame will be equal to the default:
    % bwFrame = maskmat.bwFrame;
    %Under some cases, you will have to determine the appropriate thresholding
    %on the avgFrame:
    imagesc(maskmat.avgImg,[0 40]);
    colorbar;
    
    bwFrame = roipoly;
    if(sum(bwFrame(:))>0),
        
        maskmat.bwFrame = bwFrame;
    end;
    newFileName = strrep(file, 'mask','userDrawnMask');
else, %Assume is PNG?
    I = imread(file);
    imshow(I);
    bwFrame = roipoly;
    if(sum(bwFrame(:))>0),
        maskmat = bwFrame;
    end;
    newFileName = strrep(file, '.png','userDrawnLaserArea.mat');
end;
save(newFileName,'maskmat');