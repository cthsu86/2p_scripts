%%brukerMultiFlyZSeriesToTiffSeries.m
%
% First written February 2021
%
% Can also be used on T-series? - No - sums up all of the data in the
% ZSeries # (lines 22 to 33), rather than taking number of slices into account.

rootdir = 'D:\23E10GCaMP7b_slowTimescale\210610\last few';
prefix = 'ZSeries-06102021-1028-';
zInterval = 2;
ZSeries_numList = 981:zInterval:992;
channelList = [1 2];

%%
cd(rootdir);

for(cNum = channelList),
    for(zi = 1:numel(ZSeries_numList)),
        subfolder = [prefix num2str(ZSeries_numList(zi))]
        cd(subfolder);
        tiffList=dir(['*_Ch' num2str(cNum) '_*.ome.tif']);
        for(ti = 1:numel(tiffList)),
            I = im2uint16(imread(tiffList(ti).name));
            if(ti==1),
                zStack_sumProjection = uint16(zeros(size(I)));
                if(zi==1),
                    
                    zStack_sumProj_allTimepoints = zeros(size(I));
                end;
            end;
            zStack_sumProjection = zStack_sumProjection+I;
            zStack_sumProj_allTimepoints = zStack_sumProj_allTimepoints+double(I);
        end;
        
        cd('..');
        imgName = [subfolder '_Ch' num2str(cNum) '.tif'];
        imwrite(zStack_sumProjection,imgName);
        %         writeVideo(vidObj,double(zStack_sumProjection/numel(tiffList)/(2^16)));
    end;
    % At this point, have iterated through all of the timepoints - we next
    % want to generate a mask using zStack_sumProj_allTimepoints
    
    maxval = max(zStack_sumProj_allTimepoints(:));
    zStack_sumProj_allTimepoints_normalized = zStack_sumProj_allTimepoints/maxval;
    vec2mask = sort(zStack_sumProj_allTimepoints_normalized(:),'ascend');
    bwThresh = quantile(vec2mask,0.95);
    %
    %         if(bwThresh>1),
    %         cumsum_n = cumsum(n/sum(n));
    %         highIndex = find(cumsum_n>0.98,1);
    %         bwThresh = xout(highIndex)/maxPxVal;
    %     end;
    %
    %     figure; imagesc(avgImg/maxPxVal);
    %
    bwFrame = im2bw(zStack_sumProj_allTimepoints_normalized,bwThresh);
    %
    s = regionprops(bwFrame>0,'Area','Centroid');
    %
    %     imshow(uint8(avgImg));
    %     figure; imshow(uint8(bwFrame*256));
    %     % for(si = 1:numel(s)),
    %     %     text(s(si).Centroid(1),s(si).Centroid(2),num2str(si),'r');
    %     % end;
    %
    %     % img2mask = strrep(TImgRoot,'_Ch2_', '_Ch1_mask.mat']);
    % prefix = 'ZSeries-01242021-1317-';
    % zInterval = 2;
    % ZSeries_numList = 304:zInterval:433;
    % channelList = [1 2];
    avgImg = uint8(zStack_sumProj_allTimepoints_normalized*256);
    outname = [prefix '_' num2str(ZSeries_numList(1)) '_' num2str(zInterval) '_' num2str(ZSeries_numList(end)) '.mat'];
    save(outname,'avgImg','bwThresh','bwFrame','s');
end;