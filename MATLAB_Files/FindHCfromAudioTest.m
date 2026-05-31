function [OHC0 VecIHC JND]= FindHCfromAudioTest(Audio,Nf)

ParametersDefinition

%load(['AudiogramsDataBase' num2str(Nf) '.mat'])
load(['AudiogramsDataBase' num2str(Nf) '_Big.mat'])

Imax=length(IHCtest);
Omax=length(OHCtest); 


for Lo=1:Omax
        for Li=1:Imax
            Eth=IHCvsTh(Lo).Th(Li,:); %-JNDref';
            MSEt(Lo,Li)=sqrt(mean((Audio-Eth').^2));
        end
    end
    MSEmin=min(min(MSEt(:,:)));
   
       
   [L0, Li] = find(MSEt==MSEmin);

        OHC0=min(0.5,OHCtest(L0));  %add 0.1 yo OHC0
        IHC0=IHCtest(Li);
        Th0=IHCvsTh(L0).Th(Li,:);


for fr=1:length(f)
        cJND=IHCvsTh(L0).Th(:,:); % Audiograms are stored +JNDref';
        Lt=find(cJND(:,fr)<100);  %~=inf);
        G(fr)=interp1(cJND(Lt,fr),IHCtest(Lt),Audio(fr),'linear','extrap');
end
    G0=min(G,8.01);
    
    CFx= FindCFohc(f,OHC0); %FindCFohc(f,OHC0(l,jA)*0.5/100);
    OHC_Vector= OHC0;
    %CFx=3.5-GreenwoodMap(f);
    %CFx= FindCFohcVar(f,flip(OHCm(l,:))*0.5/100,xHC(l,:));
%     At=find((CFx==0));
%     CFx(At)=0.015;
    Mt=max(find(CFx>0)); %correct for x0==0
    if Mt <Nf
        At=find(CFx==0);
        xref=CFx(At(1)-1);
        for l=1:length(At)
            CFx(At(l))=xref-xref/5*(At(l)-At(1)+1);
        end
    end
    x1=[3.5 CFx  0];
    G1=[G0(1) G0 G0(Nf)];
   
    VecIHC=interp1(x1,G1,x,'linear');
    
    IHC_Vector=VecIHC;
    [JND]  = CalculateJNDfiles2(f,noise,...
                 run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);
   
    %cTs=  (min(JND-JNDref,100))';  %variable IHC
     
   