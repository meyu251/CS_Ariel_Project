%RunNoisedAudigrams

clear all
close all
tic

%TestedNoises = [1111 33 43 53 58 68 78];
TestedNoises = [1111 30 50 70 ];
%GSI=[0 15 10 0 5 5 5];

ISO226_2003 %Read ISO threshold and Freq
Fs=20000;
run_time=0.2;
%noise='ISOnoise.wav';
noise='ISOnoise.wav';
HL=1; %Normal Ear HL=0; Hearing Loss HL=1
OHC_Vector = 0;
IHC_Vector = 3;
testedPowerLevels = 0:10:140;
for jN=1:length(TestedNoises)
    for f=1:length(Freq)
        InputSignal=['Input' num2str(Freq(f)) '.wav'];
   
        if jN==1
            En=1111;
        else
            En= TestedNoises(jN);
        end
    [JND(f,jN)] = CalculateJNDfiles( InputSignal,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
    
    end
end

toc
%fit=mse(JND,ISO_Thres+6)

%figure(1); plot(testedPowerLevels,jnd_rms')

% figure(jN)
% if  jN==1 
%     semilogx(Freq,ISO_Thres+6,'k--','LineWidth',2)%ISO ref
% end
figure(2)

%semilogx(Freq,-(JND-JND(:,1)),'LineWidth',2)  %Simulation
plot(Freq,JND,'LineWidth',2)  %Simulation
hold on
plot(Freq,ISO_Thres+6+5,'--','LineWidth',2)
plot(Freq,ISO_Thres+6+10,'--','LineWidth',2)
plot(Freq,ISO_Thres+6+20,'--','LineWidth',2)

% load exp_avg_mat % dimensions are:[Noises,testedFrequencies]
% load exp_avg_std_mat % dimensions are:[Noises,testedFrequencies]
% errorbar(AudioFreq,exp_avg_mat(jN,:)+AudioGSIcorrection,exp_avg_std_mat(jN,:),'LineWidth',2)
grid on
%axis([90 9000 -5 100])

% if  jN==1 
%     legend('ISO 266-2003','Simulation','Experimental Results','Location','southwest')
% 
% else
%        legend('Simulation','Experimental Results','Location','northeast')
%        title(['Noise Level= ' num2str(TestedNoises(jN)) 'dB-SPL'])
%        axis([0 8000 -10 70]);
% end
xlabel('Freqency [Hz]')
ylabel('Threshold Level [dB-SPL]')
legend('Quiet',num2str(TestedNoises(2)),num2str(TestedNoises(3)),...
    num2str(TestedNoises(4)),'ISO+10','ISO+20', 'ISO+40', 'Location','northeast')
title(['OHC=' num2str(OHC_Vector) '  IHC=' num2str(IHC_Vector)]) 
hold off

