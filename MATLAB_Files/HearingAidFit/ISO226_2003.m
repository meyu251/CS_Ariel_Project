%ISO226_2003
%Freq=[20 25 31.5 40 50 63 80 
    Freq=[100 125 160 200 250 315 400 500 630 800 1000 ...
    1250 1600 2000 2500 3150 4000 5000 6300 8000 10000 12500];
%ISO_Thres=[78.5 68.7 59.5 51.1 44.0 37.5 31.5 
    ISO_Thres=[26.5 22.1 17.9 14.4 11.4 8.6 6.2 ...
    4.4 3.0 2.2 2.4 3.5 1.7 -1.3 -4.2 -6.0 -5.4 -1.5 6.0 12.6 13.9 12.3];

load GSIref
GSIisoFreq=interp1(AudioFreq,GSIref,Freq,'linear','extrap');
GSIcorrection=ISO_Thres+6-GSIisoFreq;
Correction=GSIisoFreq+GSIcorrection; 
AudioGSIcorrection=interp1(Freq,GSIcorrection,AudioFreq);

HRTF=[-1 -1 -1 -1 -1 -1 -1 -1 -0.5 -0.5 0 0 0.5 1 2 2.5 3 4 ...
6 8 10 16 19 18 14 12 -3 4 4];


   
%  semilogx(Freq,ISO_Thres+6+HRTF,Freq,ISO_Thres+6)
% grid on 