%% function plotMediansFromXLS()
%
% June 7, 2022

function plotMediansFromXLS()
close all;
rootdir = 'C:\Users\User\Dropbox\Sehgal Lab\In Vivo Imaging\Data Analyzed In vivo\23E10 6 hr 5 min summary';
xlname = '23E10_allGenotypes_allMedians.xlsx';
% cells2read = 

cd(rootdir)
[values,txt,raw] = xlsread(xlname);
% display('pause');
% Values contains alternating X, Y values.

numGroups = size(values,2)/2;

%Assume that these are alternating cells of genotype, blank, genotype,
%blank (to correspond with the x and y.
genotypes = txt(1,:); 
colors2plot = txt(2,:);
h = figure(1);
set(h,'DefaultAxesFontSize',14);
for(vi = 1:2:size(values,2)),
    xvals = values(:,vi);
    yvals = values(:,vi+1);
    thisColor = str2num(colors2plot{1,vi});
    plot(xvals,yvals,'Color',thisColor,'LineWidth',2); hold on;
end;

plot([12 12],[0.5 2],'k:');
h = plot([0 24],[1 1],'k:');
xlim([0 24]);
h.FontSize = 14;
xlabel(['ZT Time'],'FontSize',14);
