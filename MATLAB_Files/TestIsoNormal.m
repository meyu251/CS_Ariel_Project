%TestIsoNormal
clear all
%close all
tic

%ISO226_2003 %Read ISO threshold and Freq
%load ResultsFinal2016

Freq=[100 125 160 200 250 315 400 500 630 800 1000 ...
    1250 1600 2000 2500 3150 4000 5000 6300 8000 10000 12500];

ISO_Thres=[26.5 22.1 17.9 14.4 11.4 8.6 6.2 ...
    4.4 3.0 2.2 2.4 3.5 1.7 -1.3 -4.2 -6.0 -5.4 -1.5 6.0 12.6 13.9 12.3];

Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
En=1111; %quiet
testedPowerLevels = -10:5:120;
%f=[100, 250,500,1000,2000,3000,3500,4000,8000];
f=Freq(1:20);
OHC_Vector=0.5; IHC_Vector=8;
delete('AudioLabCM.mexw64')

copyfile('OldAudioLabCM.mexw64', 'AudioLabCM.mexw64')
SetCochlearParametersOld
[JNDrefOld ]= CalculateJNDfiles2(f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

delete('AudioLabCM.mexw64')

copyfile('NewAudioLabCM.mexw64', 'AudioLabCM.mexw64')
%SetCochlearParametersNew
JNDrefNew= CalculateJNDfiles2(f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

delete('AudioLabCM.mexw64')

copyfile('New2AudioLabCM.mexw64', 'AudioLabCM.mexw64')
JNDrefNew2= CalculateJNDfiles2(f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

figure1 = figure(1);

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

semilogx(Freq,ISO_Thres+6,'k--','LineWidth',2) %ISO ref
hold on
semilogx(f,JNDrefOld,'r','LineWidth',2)  %Simulation

hold on
semilogx(f,JNDrefNew,'g','LineWidth',2)  %Simulation

semilogx(f,JNDrefNew,'b','LineWidth',2)  %Simulation

%errorbar(AudioFreq,MeanNormal+GSIref+AudioGSIcorrection,stdNormal,'b','LineWidth',2)
grid on
axis([90 9000 -5 40])
hold off 
 legend('ISO 266-2003','SimulationOld','SimulationNew','SimulationNew2','Location','southwest')


% Create ylabel
ylabel('Threshold Level [dB-SPL]','FontWeight','bold');

% Create xlabel
xlabel('Freqency [Hz]','FontWeight','bold');

box(axes1,'on');
grid(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',14,'FontWeight','bold','XMinorTick','on','XScale',...
    'log');




