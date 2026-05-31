%SetCochlearParametersOld.m


L_co=3.5; % Cochlear length in cm
Nsec=256; %no of cochlear sections
dx=L_co/Nsec;
x=0:dx:L_co-dx;

eps= 2.2204e-16; %Convergence parameter

% IHC Parameters  
Aihc_H=70*ones(1,Nsec);
Aihc_L=5*ones(1,Nsec); 
Aihc_M=26*ones(1,Nsec);
Aihc={Aihc_H,Aihc_M,Aihc_L};


%Aihc_vs_v, 
%Aihc_vs_x, 

%Synapse Filter&Parameters

Fs=20000;
Apass=3; 
Astop=30;  
Fpass=300;
Fpass=300;
Fstop=1800; 
delta= 0.0020;

Ts=1/Fs; 

eta_AC=1; 
eta_DC=100; 


% ihc_1, 
% IHC_Vector,
% IHC_Vector_full, 

%JND_method_flag,

lambda_sat=500; 
lambda_spont=[60;3;0.1]; 

M=120*ones(1,Nsec); %number of auditory fibers

%Noise_TH, 
%noise_type_flag,

% ohc_l, 
% OHC_Vector, 
% OHC_Vector_full, 

Scale_BM_Velocity_For_Lambda_Calculation=1;

SPLref=4.0000e-08; 

w=[0.61;0.23;0.16]; 


save Final_Parameters 
