function [shutteredStartAndStopTimes, seconds_baseline] = shutterStartAndStopFromText(voltTextString) %,stackStartAndEnd);

if(strcmp(voltTextString,'30s baseline')),
    seconds_baseline =29.99;
    numPulses = 60;
else,
    seconds_baseline = 299.96;
end;
% shutteredStartAndStopTimes = zeros(numPulses,2)+seconds_baseline;

if(strcmp(voltTextString,'200ms 1 Hz 30s baseline')), %||strcmp(voltTextString,'200ms 1 Hz 120s baseline')),
    pulseDur = 0.22;
    interPulseInterval = 0.780;
elseif(strcmp(voltTextString,'50ms 1 Hz 30s baseline')),
    pulseDur = 0.07;
    interPulseInterval = 0.925;
elseif(strcmp(voltTextString,'100ms 1 Hz 30s baseline')),
    pulseDur = 0.12;
    interPulseInterval = 0.88;
elseif(strcmp(voltTextString,'45s stim 100ms 1 Hz pulse 30s baseline')),
        pulseDur = 0.12;
    interPulseInterval = 0.88;
%     numPulses = 45;
elseif(strcmp(voltTextString,'100ms 1 Hz 120s baseline')),
    seconds_baseline = 119.99;
        pulseDur = 0.12;
    interPulseInterval = 0.88;
elseif(strcmp(voltTextString,'60s stim 30s baseline')),
    pulseDur = 0.07; %5 ms pulses. This is a 50 ms placeholder since I don't actually have the shutter durations recorded for this one.
    interPulseInterval = 0.0925;
elseif(strcmp(voltTextString,'200ms 1 Hz 120s baseline'))
    seconds_baseline=119.99;
    pulseDur = 0.22;
    interPulseInterval = 0.780;
elseif(strcmp(voltTextString,'1sOn1sOff120s baseline'))
    numPulses = 30;
    seconds_baseline = 119.99;
    pulseDur = 1.22;
    interPulseInterval = 0.780;
elseif(strcmp(voltTextString,'30s 1 Hz 200 ms stimulus pulse')),
    seconds_baseline=119.99;
    pulseDur = 0.22;
    interPulseInterval = 0.780;
    numPulses = 30;
elseif(seconds_baseline==299.96),
%     pulseDur = 0.002;
pulseDur = 1;
    interPulseInterval = 4;
    numPulses = 12;
else,
    display(['Could not find a match for: ' voltTextString]);
end;

%Second row of the shutteredStartAndStopTimes array would be
%pulseDur+interPulseInterval after the first one.

pulseCycle = pulseDur+interPulseInterval;
pulseStartTimes = [0:(numPulses-1)]*pulseCycle+seconds_baseline;
% display(numel(pulseStartTimes));

shutteredStartAndStopTimes = zeros(numPulses,2);
% display(size(pulseStartTimes));
% display(size(
shutteredStartAndStopTimes(:,1) = shutteredStartAndStopTimes(:,1)+pulseStartTimes';
shutteredStartAndStopTimes(:,2) = shutteredStartAndStopTimes(:,1)+pulseDur;