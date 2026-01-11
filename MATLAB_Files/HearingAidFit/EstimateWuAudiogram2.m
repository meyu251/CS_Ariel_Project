%EstimateWuAudiogram2
clear all
close all

Fs=20000;
run_time=0.2;
noise='ISOnoise.wav';
ISO226_2003 %Conversion GSI HL to SPL
x=0:3.5/256:3.5-3.5/256;
AudioFreq=[250 500 1000 2000 3000 4000 6000];

load('WuData.mat')
f0=f*1000;
HI=(interp1(f0,Audio,AudioFreq))';

OHC=[0:0.05:0.35 0.36:0.01:0.5];

load AudiogramThreshold %Simulated Audiograms with const. IHC & OHC

for j= 1:3

Taudiogram=HI(j,:)+GSIref+AudioGSIcorrection;

for Lo=1:length(OHC)
    OHC_Vector=OHC(Lo);
    x0=FindCFohc(AudioFreq,OHC_Vector);
    Th=IHCvsTh(Lo).Th;
    IHC=IHCvsTh(Lo).IHC;
    
    for f=1:7
        Lt=find(Th(1,:)~=inf);
        G(f)=interp1(Th(f,Lt),IHC(f,Lt),Taudiogram(f),'linear','extrap'); 
    end
    x1=[3.5 x0 0];
    G1=[G(1) G G(7)];
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
%plot(AudioFreq,JND_Noise,'LineWidth',2)

xlabel('Frequency (Hz)','FontSize',16)
ylabel('Threshold(dB-SPL)','FontSize',16)
%title(['Age ' num2str(Ages(j))])
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



%JND_All(j,:,:)=JND_Noise;
end
%save AgedAudiograms JND_All  TestedLevels AudioFreq Ages


