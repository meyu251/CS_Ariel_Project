function [b a]=HearingAidFilter(audiogram,freqs_Hz,target_gain_dB)
fs=20000;
%audiogram = [10 20 30 40 50 60];                    % Simulated hearing loss
%freqs_Hz = [250 500 1000 2000 4000 8000];              % Corresponding frequencies

%processed_audio = apply_nal_gain(audio, fs, audiogram, freqs);
%function y_out = apply_nal_gain(audio_in, fs, audiogram_dB, freqs_Hz)
% Applies frequency-dependent gain to an audio signal based on an audiogram
%
% Inputs:
%   audio_in      - input audio signal (vector)
%   fs            - sampling rate in Hz
%   audiogram_dB  - hearing loss at each frequency (e.g., [10 20 30 40 50 60])
%   freqs_Hz      - frequencies corresponding to audiogram_dB (e.g., [250 500 1000 2000 4000 8000])
%
% Output:
%   y_out         - processed audio signal

% Step 1: Calculate target gain (NAL-NL2 approx: gain = 0.46 * HL)
%target_gain_dB = 0.46 * audiogram;
target_gain_lin = 10.^(target_gain_dB / 20);  % convert dB to linear gain


% Step 2: Design bandpass filters for each frequency band
num_bands = length(freqs_Hz);
h = zeros(2000,1);

for i = 1: num_bands
    if i == 1
        f_low = 100;
        f_high = (freqs_Hz(1) + freqs_Hz(2))/2;
    elseif i == num_bands
        f_low = (freqs_Hz(end-1) + freqs_Hz(end))/2;
        f_high = fs/2 - 100;
    else
        f_low = (freqs_Hz(i-1) + freqs_Hz(i))/2;
        f_high = (freqs_Hz(i) + freqs_Hz(i+1))/2;
    end
    
    % Design 4th-order bandpass Butterworth filter
    [b(:,i), a(:,i)] = butter(4, [f_low, f_high]/(fs/2), 'bandpass');
    
    % Apply filter and gain
    band(:,i) = impz(target_gain_lin(i)*b(:,i), a(:,i),2000);
    h = h + band(:,i); 
end
%stem(h)

% Normalize to avoid clipping
h = h / max(abs(h)) * 0.95;

