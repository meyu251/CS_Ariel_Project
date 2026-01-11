%RunJNDaudiogramNoise2

%Use CalculateJNDfiles2
clear all
close all
tic
SimulationInitialDefinition
OHC_Vector=0.5; IHC_Vector=8;
noise='WhiteNoise.wav';
%TestedNoises = [1111 33 43 53 58 68 78];
TestedNoises = [1111 10 30 50 70 90 100];
for jN=1:7
     En= TestedNoises(jN);
    JND(:,jN)  = CalculateJNDfiles2(f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
    Th(:,jN)= JND(:,jN) -JNDref;
end

toc
%save IsoNoiseAudiograms Freq JND TestedNoises
%PlotNoiseAudiograms
%plot(TestedNoises(2:7),Th(:,2:7))
for li=1:6
hold on; plot(TestedNoises(2:7),Th(li,2:7))
end

legend('f=250','f=500','f=1000','f=2000','f=4000','f=8000')
hold off
