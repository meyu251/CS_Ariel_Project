%TestHairCellEstimation

clear all
Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
En=1111; %quiet
testedPowerLevels = -10:5:120;
f=[250 500 1000 2000 3000 4000 6000 8000];
OHC_Vector=0.5; IHC_Vector=8;
Nsub=1;
Nf=8;  %number of tested frequencies
GetTunedAudiograms;
for sub=1:Nsub
     Audio(sub,:)=TunedAudiograms(sub,:); 
    
     delete('AudioLabCM.mexw64')
     
     copyfile('OldAudioLabCM.mexw64', 'AudioLabCM.mexw64')
     SetCochlearParametersOld
     [OHC0_Old(sub) VecIHC_Old(sub,:) JND_Old(sub,:)]= FindHCfromAudioTest(Audio(sub,:)',Nf);
     JNDrefOld= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
     
     delete('AudioLabCM.mexw64')
     
     copyfile('NewAudioLabCM.mexw64', 'AudioLabCM.mexw64')
     SetCochlearParametersNew
     [OHC0_New(sub) VecIHC_New(sub,:) JND_New(sub,:)]= FindHCfromAudioTest(Audio(sub,:)',Nf);
     JNDrefNew= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
end
PlotResultsTest