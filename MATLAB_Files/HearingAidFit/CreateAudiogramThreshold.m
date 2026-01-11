%CreateAudiogramThreshold

% Create DataBase of Audigrams with constant OHC and constant IHC

clear all
close all
%
tic

ISO226_2003 %Read ISO threshold and Freq
AudioFreq=[250 500 1000 2000 3000 4000 6000 8000 ];

Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
En=1111; 
OHC=[0:0.05:0.35 0.36:0.01:0.5];
IHC=[3:0.5:4 4.1:0.1:8];

    
for kO=1:length(OHC)
    for kI=1:length(IHC)
        OHC_Vector = OHC(kO);
        IHC_Vector = IHC(kI);
        JND(kO,kI).OHC=OHC_Vector;
        JND(kO,kI).IHC=IHC_Vector;
        
        En=1111;
        testedPowerLevels = -20:3:120;

        [JND0,jnd_rms]  = CalculateJNDfiles2( AudioFreq,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
        Lf1=find(JND0>=120);
        Lf2=find(JND0<120);
        if isempty(Lf1)
            JND1(Lf2)=JND0(Lf2);
        else
             JND1(Lf1)=inf;
             JND1(Lf2)=JND0(Lf2);
        end
        JND(kO,kI).Audiogram=JND1;
        for f=1:length(AudioFreq)
            IHCvsTh(kO).Th(f,kI)=JND(kO,kI).Audiogram(f);
            IHCvsTh(kO).IHC(f,kI)=JND(kO,kI).IHC;
        end
        
        
    end
       
end


    
save AudiogramThreshold8 AudioFreq JND IHCvsTh
    

toc




