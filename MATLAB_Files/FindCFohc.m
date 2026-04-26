function CFx=FindCFohc(AudioFreq,OHC)

N=512;
Pin=1;
x=0:3.5/N:3.5-3.5/N;
%OHC0=max(0.1,OHC);


%make_gamma_vector2 %random Gamma

Gamma(1:N,1) = OHC;
 
Amp=Gamma';

SetParametersA; 
etaX=0;
%AudioFreq=[250 500 1000 2000 3000 4000 6000];
for i=1:length(AudioFreq)
    %w=CF(i);
    f=AudioFreq(i);
    w=f*2*pi;


    s=sqrt(-1)*w;
    %ohc=Amp.*((s-w1)./(s+w0));
    %Z=m*s*s+r*s+k-psy.*ohc;
    ReZbm=r;
    ReZohc=r0-Amp.*(alfa2.*w0-alfa1)./(w*w+w0*w0);
    ReZ=ReZbm+ReZohc-r0;
    ImZbm=m*w-k./w;
    ImZohc=(Amp./w).*(alfa1.*w0+alfa2.*w.*w)./(w*w+w0*w0); %OHC only
    ImZ=ImZbm+ImZohc;
    Z=complex(ReZ,ImZ);
    Zbm=complex(ReZbm,ImZbm);
    Zohc=complex(ReZohc,ImZohc);
    %Z=complex(ReZbm,ImZbm);
    %Z=complex(ReZohc,ImZohc);

    %Gec=1/(w_ow*gama_ow)

    Dme=1./(sigma_ow.*(-w*w+w_ow*w_ow-s*gama_ow+F));
    Rme=2*ro*w*w.*Dme;
    eta=-(2*s*ro*B)./(A*Z);
    etaQ=sqrt(eta);
    etaX=cumsum(etaQ)*h;
    P=-2*w*ro.*Pin./(sqrt(etaQ(1)).*sqrt(etaQ)).*exp(-s*etaX/w);
    V=P./Z;
    
    Pbm=Zbm.*V;
    Pohc=Zohc.*V;
    
    VbmAbs(i,:)=abs(V);
    %VbmAngle=unwrap(angle(V));
    %Delay=unwrap(angle(P))/w;
    %Thr=10*log10(sum(VbmAbs(i,:).^2));
  
    %Pe(i)=20*log10(abs(1-Gme*Gec.*Dme-Gec*P(1).*Dme));
   


%figure(1);hold on; plot(Gamma)
 %figure(2);  hold on; semilogx(CF./(2*pi),150-Thr) ;grid on
 %figure(3); hold on;plot(CF./(2*pi),Pe)


 [M1 I1]=max(VbmAbs');
 I0(i)=I1(i);
  %plot(20*log10(VbmAbs'))
if I0(i)==1
    Az=(db(VbmAbs(i,:)/max(VbmAbs(i,:)))+0.5);
    Bz=find(Az>0);
    I0(i)=max(Bz);
end
    
    CFx(i)=x(I0(i));


%x0=(log(16000)-log(AudioFreq))/1.5;
end
      