%PlotNoiseAudiograms
close all

ISO226_2003 %Read ISO threshold and Freq

%load NoiseAudiogramsIsoNoise
%load NoiseAudiogramsISO_GSI
%load NoiseAudiogramsFilterd
load IsoNoiseAudiograms
load exp_avg_mat % dimensions are:[Noises,testedFrequencies]
load exp_avg_std_mat % dimensions are:[Noises,testedFrequencies]

AudioFreq=[250 500 1000 2000 3000 4000 6000];

figure1 = figure;

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');


semilogx(AudioFreq,JND(:,3:2:7),'LineWidth',2)  %Simulation

hold on
%semilogx(AudioFreq,JND(:,2),'LineWidth',2)  %Simulation

for jN=3:2:7
    errorbar(AudioFreq,exp_avg_mat(jN,:)+AudioGSIcorrection,exp_avg_std_mat(jN,:),'k','LineWidth',2)
  end
 %errorbar(AudioFreq,exp_avg_mat(2,:)+AudioGSIcorrection,exp_avg_std_mat(2,:),'k','LineWidth',2)

 
 grid on
%axis([90 9000 -5 100])
legend (['Noise Level= ' num2str(TestedNoises(3)) 'dB-SPL'],...
        ['Noise Level= ' num2str(TestedNoises(5)) 'dB-SPL'],...
        ['Noise Level= ' num2str(TestedNoises(7)) 'dB-SPL'],...
        'Experimental Results','Location','southwest') 
%         ['Noise Level= ' num2str(TestedNoises(5)) 'dB-SPL'],...
%         ['Noise Level= ' num2str(TestedNoises(6)) 'dB-SPL'],...
%         ['Noise Level= ' num2str(TestedNoises(7)) 'dB-SPL'])
% 
% hold off 

xlabel('Freqency [Hz]','FontWeight','bold')
ylabel('Threshold Level [dB-SPL]','FontWeight','bold')
%PlotSpectrum('ISOnoise.wav',140);
%PlotSpectrum('ISOnoiseGSI.wav',140);
%PlotSpectrum('FilterdNoise.wav',175);
%axis([90 6000  -10 70])
%hold off
box(axes1,'on');
grid(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',12,'FontWeight','bold','XMinorTick','on','XScale',...
    'log');
