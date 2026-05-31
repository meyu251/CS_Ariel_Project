%TestIsoNormal
clear all
%close all
tic

ISO226_2003 %Read ISO threshold and Freq
%load ResultsFinal2016

noise='MaskedNoise.wav';
[Noisein, FsIn] = audioread(noise);
%En1=db(sqrt(mean(Noisein.*Noisein))/(2e-5));
En = 1111;

Fs=20000;
run_time=0.2;
testedPowerLevels = -10:1:120;
%f=[100, 250,500,1000,2000,3000,3500,4000,8000];
f=[500, 8000];
OHC_Vector=0.5; IHC_Vector=8;
[JNDrefNew, JNDRms] = CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

JNDrefNew
JNDRms

