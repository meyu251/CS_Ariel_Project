%HairCellLossEstimationFromAudiogram

clear all

SimulationInitialDefinition  %Define JNDref, and AudioSimulationDataBase

load AudioMeasurements  %Data of 63 audiograms

Audiogram=[35 40 45 40 45 45];
% k=5;  %Choose an audiogram
% Audiogram=Audio(k,:);

%Find HairCell Loss
for Lo=1:Omax
    for Li=1:Imax
            Eth=IHCvsTh(Lo).Th(Li,:)-JNDref';
            MSEt(Lo,Li)=sqrt(mean((Audiogram-Eth).^2));
        end
end
MSE0=min(min(MSEt));
[L0, Li] = find(MSEt==MSE0);

OHC0=OHCtest(L0);
IHC0=IHCtest(Li);
Th0=IHCvsTh(L0).Th(Li,:);


for fr=1:length(f)
        cJND=IHCvsTh(L0).Th(:,:)+JNDref';
        Lt=find(cJND(:,fr)~=inf);
        G(fr)=interp1(cJND(Lt,fr),IHCtest(Lt),Audiogram(fr),'linear','extrap');
end

G0=min(G,8.01);
    
CFx= FindCFohc(f,OHC0);
OHC_Vector= OHC0;
    %CFx=3.5-GreenwoodMap(f);
    %CFx= FindCFohcVar(f,flip(OHCm(l,:))*0.5/100,xHC(l,:));
 At=find((CFx==0));
 CFx(At)=0.0015;
 x1=[3.5 CFx  0];
 G1=[G0(1) G0 G0(6)];
   
  VecIHC=interp1(x1,G1,x,'linear');
    
  IHC_Vector=VecIHC;
  
  [JND]  = CalculateJNDfiles2(f,noise,...
                 run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
    
    cT=  JND-JNDref;  %variable IHC
    MSE=sqrt(mean((Audiogram-cT').^2)); 
    
    [HA]  = CalculateJNDfiles2(f,noise,...
                 run_time,En,testedPowerLevels,0.5, IHC_Vector);
             

[cT Audiogram' HA-JNDref]
  
  