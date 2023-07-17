close all; clear all;
rootdir = 'C:\Users\Windows 10\Dropbox\Sehgal Lab\In Vivo Imaging\MB107\OK107_UAS_GCaMP6m_180207_Fly1\'
vid2read = 'TSeries-02072018-1518-083_BW_upperStretchLim 0.4_medfilt15.avi';

cd(rootdir);
vidReader = VideoReader(vid2read);
opticFlow = opticalFlowLK;

while hasFrame(vidReader)
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
  
    flow = estimateFlow(opticFlow,frameGray); 

    imshow(frameRGB) 
    hold on
    plot(flow,'DecimationFactor',[5 5],'ScaleFactor',10)
    hold off 
end