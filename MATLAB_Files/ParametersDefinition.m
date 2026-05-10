%ParametersDefinition
noise='ISOnoise.wav';
ISO226_2003 %Conversion GSI HL to SPL
Fs=20000;
run_time=0.2;
En=1111;
testedPowerLevels = -10:5:120;
x=0:3.5/256:3.5-3.5/256;

%JNDref=[17.6941   13.4530   10.3338    2.4528    2.2692   27.5879]';
OHC_Vector=0.5; IHC_Vector=8;
if Nf==6
    f=[250 500 1000 2000 4000 8000];
    JNDref=[17.6941   13.4530   10.3338    2.4528    2.2692   27.5879]';
elseif Nf==8
    f=[250 500 1000 2000 3000 4000 6000 8000];
    JNDref=[17.6941   13.4530   10.3338    2.4528   -0.5295    2.2692   11.3500   27.5879]';
end

%x=0:3.5/256:3.5-3.5/256;
xm0=(2.5:5:100)*3.5/100; %location in percentage 

load Parabolicfit
[Egt, at bt, ct]=fitParabola(IH,mIH,mGa); 

