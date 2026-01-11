%PlotNoiseSpectrum

Fs=20000;
run_time=0.2;
N=Fs*run_time;
for j=1:50
    Noise0=randn(1,N);
    
%   noise='ISOnoise.wav';
    %noise='speech20000.wav';
    %[Noise0, Fs]=audioread(noise);
    Noise=Noise0/max(abs(Noise0));
    
  %Noise0=NoiseOnDisc; %/max(abs(Noise));
  %figure(2); plot(Noise0)
    [pxx1,f] = pwelch(Noise,128,120,128,Fs);
%[pxx1,f] = pwelch(Noise,256,250,256,Fs);
%[pxx1,f] = pwelch(Noise0,8192,8190,8192,Fs);
 %[pxx1,f] = pwelch(Noise0,[],80,Fs/4,Fs);

H(:,j)=20*log10(pxx1(:,1)./max(pxx1(:,1)));
end
mH=mean(H');
sH=std(H');
 errorbar(f,mH,sH,'k','LineWidth',2)
 

%audiowrite('WhiteNoise.wav',Noise,Fs);

