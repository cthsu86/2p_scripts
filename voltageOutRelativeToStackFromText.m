function shutteredStartAndStopTimes = voltageOutRelativeToStackFromText(voltTextString) %,stackStartAndEnd);

seconds_baseline =29.99;
numPulses = 60;
% shutteredStartAndStopTimes = zeros(numPulses,2)+seconds_baseline;

if(strcmp(voltTextString,'200ms 1 Hz 30s baseline')),
    pulseDur = 0.22;
    interPulseInterval = 0.780;
elseif(strcmp(voltTextString,'50ms 1 Hz 30s baseline')),
    pulseDur = 0.07;
    interPulseInterval = 0.925;
elseif(strcmp(voltTextString,'100ms 1 Hz 30s baseline')),
    pulseDur = 0.12;
    interPulseInterval = 0.88;
end;

%Second row of the shutteredStartAndStopTimes array would be
%pulseDur+interPulseInterval after the first one.

pulseCycle = pulseDur+interPulseInterval;
pulseStartTimes = [0:numPulses]*pulseCycle+seconds_baseline;
shutteredStartAndStopTimes = zeros(numPulses,2)+pulseStartTimes;
shutteredStartAndStopTimes(:,2) = shutteredStartAndStopTimes(:,1)+pulseDur;