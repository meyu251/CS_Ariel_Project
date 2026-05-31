%TestSignalNoise.m
clear all

Fs=20000;
run_time=0.2;
testedPowerLevels = -10:5:120;
OHC_Vector=0.5; IHC_Vector=8;

noise1='MaskedNoise.wav';
[Noisein, FsIn] = audioread(noise1);
En1=db(sqrt(mean(Noisein.*Noisein))/(2e-5));

signal1='TestSignal.wav';

t = 0:1/Fs:run_time-1/Fs;
s = sin(2*pi*1000*t);
audiowrite('TestFreq.wav',s,Fs);
signal2 = 'TestFreq.wav';

JND1000New1= CalculateJNDfiles2(1000,noise1,run_time,En1,testedPowerLevels,OHC_Vector, IHC_Vector);
JND1000New2 = CalculateJNDfiles(signal2, noise1,run_time,En1,testedPowerLevels,OHC_Vector, IHC_Vector);
JNDSignalNew = CalculateJNDfiles( signal1,noise1,0.2,En1,testedPowerLevels)

disp([JND1000New1,JND1000New2,JNDSignalNew]) 