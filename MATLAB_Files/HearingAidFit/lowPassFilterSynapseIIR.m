function [ b,a ] = lowPassFilterSynapseIIR( Fpass,Fstop,Fs,Apass,Astop )
%LOWPASSFILTERSYNAPSEIIR Summary of this function goes here
%   Detailed explanation goes here
    match = 'stopband'; % Band to match exactly
        D_ihc  = fdesign.lowpass('Fp,Fst,Ap,Ast', Fpass, Fstop ,Apass, Astop, Fs); %chose Fs equal to Fs of input signal (obligatory?)
        H_ihc = design(D_ihc, 'butter', 'MatchExactly', match); % Design a Butterworth lowpass filter
        [b,a] = tf(H_ihc); %Get the transfer function values 


end

