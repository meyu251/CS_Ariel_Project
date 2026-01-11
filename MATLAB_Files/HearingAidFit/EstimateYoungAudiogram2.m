%EstimateYoungAudiogram2
clear all
close all

Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
En=1111;
ISO226_2003 %Conversion GSI HL to SPL
x=0:3.5/256:3.5-3.5/256;
testedPowerLevels = -20:3:120;
OHC_Vector=0.5; IHC_Vector=8;

load AudiogramThreshold8 %Simulated Audiograms with const. IHC & OHC
f=AudioFreq;
JNDref= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
%AudioFreq=[250 500 1000 2000 3000 4000 6000 8000];

TestFreq=[500 1000 2000 4000];


HI(1,:)=[16.4  6  16  37.5] %-[17.4 7.9 11.8  11.3]
% HI(2,:)=[10 10 11 17 20 22 30];
% HI(3,:)=[15 15 16 25 40 58 61];
% HI(4,:)=[21 21 22 40 60 80 90];
Ages=[20] ; % 40 60 90];


AudioFreq=TestFreq;

OHC=[0:0.05:0.35 0.36:0.01:0.5];

j=1;

%Taudiogram=HI(j,1:7)+GSIref+AudioGSIcorrection;
Taudiogram=HI;
for Lo=1:length(OHC)
    OHC_Vector=OHC(Lo);
    x0=FindCFohc(TestFreq,OHC_Vector);
    Th=IHCvsTh(Lo).Th;
    IHC=IHCvsTh(Lo).IHC;
   
    Mt=length(Taudiogram);
    ft=[2 3 4 6]; %For TestFreq
    for f=1:Mt
        Lt=find(Th(ft(f),:)~=inf);
        G(f)=interp1(Th(ft(f),Lt),IHC(ft(f),Lt),Taudiogram(f),'linear','extrap'); 
    end
    x1=[3.5 x0 0];
    G1=[G(1) G G(Mt)];
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




%Determine Threshold for noise
% signal=noise;
% En=1111;
% [jnd_final, jnd_rms] = CalculateJNDfiles2( signal,noise,run_time,En, testedPowerLevels, OHC_Vector, IHC_Vector);
% NoiseThrs(j)=jnd_final;

figure(j)

subplot(5,1,[1,2])

plot(AudioFreq,Taudiogram,'ro','LineWidth',2) 
hold on
plot(AudioFreq,JND,'k','LineWidth',2)


xlabel('Frequency (Hz)','FontSize',16)
ylabel('Threshold(dB-SPL)','FontSize',16)
title(['Age ' num2str(Ages(j))])
legend('Measured','Simulated Audiogram',...
    'Location','NorthWest')

text(4500,10,['MSE= ' num2str(MSE) ' dB']);
axis([0 6000 0 120])


pX=flip([x x(256) x(1)]);
OHC0=100*OHC_Vector/0.5;
IHC0=100*IHC_Vector/8;
pOHC=flip([ OHC0*ones(1,256) 0 0]);
pIHC=flip([IHC0 0 0]);
subplot(5,1,4); fill(pX,pIHC,'b'); axis([ 0 3.5 0 100]); box off
ylabel('%IHC','FontSize',16)

subplot(5,1,5); fill(pX,pOHC,'g'); axis([0 3.5 0 100]);box off
xlabel('Distance from Stapes [cm]','FontSize',16)
ylabel('%OHC','FontSize',16)

