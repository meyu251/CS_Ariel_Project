function [ save_vector ] = getTimeSynapsesIIR( Fs,Fpass,Fstop,Apass,Astop )
%GETTIMESYNAPSESIIR Summary of this function goes here
%   Detailed explanation goes here
    if ( nargin < 4)
        Apass = 3;
        Astop = 30;
    end
    if ( nargin < 1)
        Fs = 20000;
        Fpass = 300;
        Fstop = 1800; 
    end
    [b,a] = lowPassFilterSynapseIIR(Fpass,Fstop,Fs,Apass,Astop);
    size_a = size(a);
    size_a = size_a(2);
    save_vector = [size_a 0 a b];

end

