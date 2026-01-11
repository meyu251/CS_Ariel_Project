%EstimateHairCellLoss7

clear all

load LibermanData  %Audio at f; IHC OHC at xm

load ParabolicFit
[Egt, at bt, ct]=fitParabola(IH,mIH,mGa); 

xm0=(2.5:5:100)*3.5/100; %location in percentage 
IHC=100*IHC;
OHC=100*OHC;

Nsub=length(Audio);

[L1O,L2O]=find(~isnan(OHC')); %find nan values in data
[L1I,L2I]=find(~isnan(IHC'));

%Parameters Definition
noise='ISOnoise.wav';
ISO226_2003 %Conversion GSI HL to SPL
Fs=20000;
run_time=0.2;
En=1111;
testedPowerLevels = -10:5:120;
x=0:3.5/256:3.5-3.5/256;

OHC_Vector=0.5; IHC_Vector=8;
JNDref= CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

load AudiogramsDataBase
Imax=length(IHCtest);
Omax=length(OHCtest); 

for l= 2:2 %1:Nsub
 Audioe(:,1)=Audio(l,:)'-10;
 Audioe(:,2)=Audio(l,:)'-5;
 Audioe(:,3)=Audio(l,:)';
 Audioe(:,4)=Audio(l,:)'+5;

 
for jA=1:5 
    for Lo=1:Omax
        for Li=1:Imax
            Eth=IHCvsTh(Lo).Th(Li,:)-JNDref';
            MSEt(Lo,Li,jA)=sqrt(mean((Audioe(:,jA)-Eth').^2));
        end
    end
    MSE0=min(min(MSEt(:,:,jA)));
    [L0(l), Li] = find(MSEt(:,:,jA)==MSE0);

    OHC0(l,jA)=OHCtest(L0(l));
    IHC0(l,jA)=IHCtest(Li);
    Th0(l,jA,:)=IHCvsTh(L0(l)).Th(Li,:);


for fr=1:length(f)
        cJND=IHCvsTh(L0(l)).Th(:,:)+JNDref';
        Lt=find(cJND(:,fr)~=inf);
        G(fr)=interp1(cJND(Lt,fr),IHCtest(Lt),Audioe(fr,jA),'linear','extrap');
end
    G0=min(G,8.01);
    
    CFx= FindCFohc(f,OHC0(l,jA)*0.5/100);
    OHC_Vector= OHC0(l,jA);
    %CFx=3.5-GreenwoodMap(f);
    %CFx= FindCFohcVar(f,flip(OHCm(l,:))*0.5/100,xHC(l,:));
    At=find((CFx==0));
    CFx(At)=0.015;
    x1=[3.5 CFx  0];
    G1=[G0(1) G0 G0(6)];
   
    VecIHC(l,jA,:)=interp1(x1,G1,x,'linear');
    
    IHC_Vector=VecIHC(l,jA,:);
    [JND]  = CalculateJNDfiles2(f,noise,...
                 run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
    
    cTs(:,jA)=  JND-JNDref;  %variable IHC
    MSEs(jA)=sqrt(mean((Audioe(:,jA)-cTs(:,jA)).^2));  
end

    [MSE1 jA0(l)]=min(MSEs);
  
    %jA0(l)=min(find(MSEs==min(MSEs)));
   cTr(:,l)=cTs(:,jA0(l));
   
   % find VecIHC0(l,jA0(l),:) ; OHC0(l,jA);
   
   
end   

%save HairCellEstimationT VecIHC OHC0 jA0 cTr cTs
  