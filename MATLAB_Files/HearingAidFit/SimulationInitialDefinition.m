%SimulationInitialDefinition

%Parameters Definition
%noise='ISOnoise.wav';
%noise='WhiteNoise.wav';

ISO226_2003 %Conversion GSI HL to SPL
Fs=20000;
run_time=0.2;
En=1111;
testedPowerLevels = -20:3:120;
x=0:3.5/256:3.5-3.5/256;

load AudioSimulationDataBase

OHC_Vector=0.5; IHC_Vector=8;
noise='ISOnoise.wav';
JNDref= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);


Imax=length(IHCtest);
Omax=length(OHCtest); 