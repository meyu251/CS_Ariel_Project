%SetParametersA.m
%A analytic model of the Cochlea

Cochlear_Length = 3.5;         % in cm         (cochlear length)

L=3.5;
N=512;
h=L/N;
h2=1/(h*h);
hh=h*h;
x=0:h:h*(N-1);


ro=1;
A=0.5;

r0=0.25;

%m=(1.268e-6)*exp(1.5*x);
m=(8.1190e-7)*exp(1.5*x);

k=1.2821e+4*exp(-1.5*x);

r=r0*exp(-0.06*x);
w0=1000*2*pi;
w2OH=w0*w0;
w1=(k./m)/w0;
w2CF=k./m;
psy=w0*r;
CF=sqrt(k./m);
GF=165.4*(10.^(x*0.6)-1);
B=0.003;
alfa1=-r.*k./m;
alfa2=r.*w0;

%middle ear parameters
gama_ow=500*10;
w_ow=2*pi*1500;
sigma_ow=1.85;
Gme=21.4;
Gec=1e5;

F=Gme*Gec/sigma_ow;

%plot(x,CF/(2*pi),3.5-x,GF)