function [Gain IHC_Vector OHC_Vector]= CochlearHearingAid(Audiogram,TestFreq)


%Insert Hearing Test
%TestFreq= [250 500 1000 2000 4000 6000 8000];
%Audiogram= [90 90 90 90 90 85 85];

% load AudioMeasurements
% Audiogram=Audio(51,:);
% TestFreq= [250 500 1000 2000 4000 8000];

Fs=20000;
run_time=0.2;
noise='WhiteNoise.wav';
En=1111;
ISO226_2003 %Conversion GSI HL to SPL
x=0:3.5/256:3.5-3.5/256;
testedPowerLevels = -20:3:120;
OHC_Vector=0.5; IHC_Vector=8;
JNDref= CalculateJNDfiles2( TestFreq,noise,run_time,...
    En,testedPowerLevels,OHC_Vector, IHC_Vector);
load Parabolicfit
[Egt, at bt, ct]=fitParabola(IH,mIH,mGa); 

Taudiogram=Audiogram+JNDref';

load AudiogramThreshold8 %Simulated Audiograms with const. IHC & OHC


%AudioFreq=[250 500 1000 2000 3000 4000 6000 8000];




FreqIndex=[];
for j=1:length(TestFreq)
     Lf=find(AudioFreq==TestFreq(j));
     FreqIndex=[FreqIndex, Lf];
end
Lf=length(FreqIndex);


OHC=[0:0.05:0.35 0.36:0.01:0.5];

for Lo=1:length(OHC)
    OHC_Vector=OHC(Lo);
    x0=FindCFohc(TestFreq,OHC_Vector);
    Th=IHCvsTh(Lo).Th;
    IHC=IHCvsTh(Lo).IHC;
    
    for f=1:Lf
        Lt=find(Th(FreqIndex(f),:)~=inf);
        G(f)=interp1(Th(FreqIndex(f),Lt),IHC(FreqIndex(f),Lt),...
            Taudiogram(f),'linear','extrap'); 
    end
    Mt=max(find(x0>0)); %correct for x0==0
    if Mt <Lf
        At=find(x0==0);
        xref=x0(At(1)-1);
        for l=1:length(At)
            x0(At(l))=xref-xref/5*(At(l)-At(1)+1);
        end
    end
    
    x1=[3.5 x0 0];
    G1=[G(1) G G(Lf)];
    IHC_Vector=interp1(x1,G1,x,'linear','extrap');
    IHC_Vector0(Lo,:)=IHC_Vector;
    En=1111;
    CalculateAudiogram2 %Calculate JND1 and MSE1(f,Lo)
    
end

[Am Im]=min(MSE1);
JND=JND1(Im,:);
OHC_Vector=OHC(Im);
IHC_Vector=IHC_Vector0(Im,:);
MSE=MSE1(Im); %Error in Quiet

%Find Hearing Aid Gain

Gain= CalculateJNDfiles2( TestFreq,noise,run_time,...
    En,testedPowerLevels,0.5, IHC_Vector)-JNDref;


PlotEstimationResults  %PlotResults


