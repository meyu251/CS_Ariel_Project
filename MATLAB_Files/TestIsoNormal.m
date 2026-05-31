%TestIsoNormal
clear all
%close all
tic

ISO226_2003 %Read ISO threshold and Freq
%load ResultsFinal2016

Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
En=1111; %quiet
testedPowerLevels = -10:5:120;
%f=[100, 250,500,1000,2000,3000,3500,4000,8000];
f=Freq(1:20);
OHC_Vector=0.5; IHC_Vector=8;
%delete('AudioLabCM.mexw64')

%copyfile('OldAudioLabCM.mexw64', 'AudioLabCM.mexw64')
%[JNDrefOld ]= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

%delete('AudioLabCM.mexw64')

%copyfile('NewAudioLabCM.mexw64', 'AudioLabCM.mexw64')
JNDrefNew= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

figure1 = figure(1);

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

semilogx(Freq,ISO_Thres+6,'k--','LineWidth',2) %ISO ref
hold on
%semilogx(f,JNDrefOld,'r','LineWidth',2)  %Simulation
hold on
semilogx(f,JNDrefNew,'g','LineWidth',2)  %Simulation

JNDrefNew

%errorbar(AudioFreq,MeanNormal+GSIref+AudioGSIcorrection,stdNormal,'b','LineWidth',2)
grid on
axis([90 9000 -5 40])
hold off 
 legend('ISO 266-2003','SimulationNew','Location','southwest')


% Create ylabel
ylabel('Threshold Level [dB-SPL]','FontWeight','bold');

% Create xlabel
xlabel('Freqency [Hz]','FontWeight','bold');

box(axes1,'on');
grid(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',14,'FontWeight','bold','XMinorTick','on','XScale',...
    'log');




