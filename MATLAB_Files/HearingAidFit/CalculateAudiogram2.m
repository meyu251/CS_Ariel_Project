%CalculateAudiogram2

testedPowerLevels =-20:3:120;

JND0  = CalculateJNDfiles2( TestFreq,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

%Lf1=find(JND0>=130);
%Lf2=find(JND0<130);
Lf1=find(JND0>=130);
Lf2=find(JND0<130);
if isempty(Lf1)
  JND1(Lo,Lf2)=JND0(Lf2);
 else
     
   %JND1(Lo,Lf1)=inf;
   JND1(Lo,Lf1)=120;
   JND1(Lo,Lf2)=JND0(Lf2);
  end
Ref=JND1(Lo,Lf2);
MSE1(Lo)=sqrt(sum((Taudiogram(Lf2)-Ref).^2)/length(Lf2)); 

