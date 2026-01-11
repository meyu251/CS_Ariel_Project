function [ cochleaConfig,inputStruct ] = preAnalyzeFile( varargin )
%PREANALYZEFILE Summary of this function goes here
%   Detailed explanation goes here
    inputStruct = varargin{1};
    load Final_Parameters % (1)Cf_based M (2)Aihc = [85,26,5] (3)SPLref = 1.5e-8
%            SPLref=3*4e-5;  %Change of SPLref, normailizing by compression

%fprintf('start analyzing file\n');
if ( nargin > 1 )
    inputStruct = convertNameValue2Struct(varargin);
end
if ( ~isfield(inputStruct,'Disable_GPU_Scan') || ~inputStruct.Disable_GPU_Scan )
    gpuDevice();
end
if ( ~isfield(inputStruct,'filesStruct') && (~isfield(inputStruct,'basicTest') || ~inputStruct.basicTest)  )
    error('analyzeFile:filemissing','filesStruct must be present to continue');
end


inputStruct.JND_Signal_Source = 1;
if ( isfield(inputStruct,'basicTest') )
    inputStruct.JND_Signal_Source = ~inputStruct.basicTest; 
end
if ( ~isfield(inputStruct,'JND_Noise_Source') || ~isfield(inputStruct,'NoiseObject') )
    inputStruct.JND_Noise_Source = 0; % atleast for now until diffrent noise source will be enabled
end
if ( ~isfield(inputStruct,'Noises_per_run') )
    inputStruct.Noises_per_run = 1;
end
if ( ~isfield(inputStruct,'Run_Fast_BM_Calculation') )
    inputStruct.Run_Fast_BM_Calculation = 22;
end
if ( ~isfield(inputStruct,'spontRate') )
    inputStruct.spontRate = lambda_spont;
end

if ( ~isfield(inputStruct,'Fs') )
    inputStruct.Fs = Fs;
end
if ( ~isfield(inputStruct,'Hearing_AID_FIR_Transfer_Function') )
    inputStruct.Hearing_AID_FIR_Transfer_Function = 1;
end
if ( ~isfield(inputStruct,'Hearing_AID_IIR_Transfer_Function') )
    inputStruct.Hearing_AID_IIR_Transfer_Function = 1;
end
if ( ~isfield(inputStruct,'Normalize_Sigma_Type') )
    inputStruct.Normalize_Sigma_Type = 0;
end

if ( ~isfield(inputStruct,'Normalize_Sigma_Type_Signal') )
    inputStruct.Normalize_Sigma_Type_Signal = 0;
end
if ( ~isfield(inputStruct,'Oded_Method') )
    inputStruct.Oded_Method = 1;
end
if ( ~isfield(inputStruct,'Test_Window') )
    inputStruct.Test_Window = 11;
end
if ( ~isfield(inputStruct,'Show_Run_Time') )
    inputStruct.Show_Run_Time = 0;
end
if ( ~isfield(inputStruct,'Show_Calculated_Power') )
    inputStruct.Show_Calculated_Power = 0;
end
if ( ~isfield(inputStruct,'Discard_Lambdas_Output') )
    inputStruct.Discard_Lambdas_Output = 1;
end
if ( ~isfield(inputStruct,'Run_Stage_Calculation') )
    inputStruct.Run_Stage_Calculation = 0;
end
if ( ~isfield(inputStruct,'Discard_BM_Velocity_Output') )
    inputStruct.Discard_BM_Velocity_Output = 1;
end
if ( ~isfield(inputStruct,'Allowed_Outputs') )
    inputStruct.Allowed_Outputs = 0;
end
inputStruct.Yonatan_Method = 1 - inputStruct.Oded_Method;

if ( ~isfield(inputStruct,'Complex_Profile_Power_Level_Divisor') )
    inputStruct.Complex_Profile_Power_Level_Divisor = 0;
end
if ( ~isfield(inputStruct,'Show_Generated_Input') )
    inputStruct.Show_Generated_Input = 0;
end


inputStruct.eta_AC = inputStruct.Oded_Method*eta_AC + 1.2*inputStruct.Yonatan_Method;
inputStruct.eta_DC = eta_DC*inputStruct.Oded_Method + 400*inputStruct.Yonatan_Method;
inputStruct.JND_USE_Spont_Base_Reference_Lambda = 1;
inputStruct.Generate_One_Ref_Per_Noise_Level = 1;
if ( ~isfield(inputStruct,'Time_Block_Length') )
    inputStruct.Time_Block_Length = 0.02;
end
if ( ~isfield(inputStruct,'JND_Interval_Head') )
    inputStruct.JND_Interval_Head = 0.005;
end
if ( ~isfield(inputStruct,'JND_Interval_Tail') )
    inputStruct.JND_Interval_Tail = 0.0;
end
% this one calculated due to dependency on file length
if ( inputStruct.JND_Signal_Source )
    inputStruct.Decouple_Filter = floor(inputStruct.filesStruct.length_cut/inputStruct.Time_Block_Length);
else
    if ( ~isfield(inputStruct,'Decouple_Filter') )
        inputStruct.Decouple_Filter = 10;
    end
end

if ( ~isfield(inputStruct,'Overlap_Time') )
    inputStruct.Overlap_Time = 0.005;
end
if ( ~isfield(inputStruct,'Complex_Profile_Noise_Level_Fix_Addition') )
    inputStruct.Complex_Profile_Noise_Level_Fix_Addition = 0;
end
if ( ~isfield(inputStruct,'Complex_Profile_Noise_Level_Fix_Factor') )
    inputStruct.Complex_Profile_Noise_Level_Fix_Factor = 0;
end
if ( ~isfield(inputStruct,'Show_Device_Data') )
    inputStruct.Show_Device_Data = 0;
end
if ( ~isfield(inputStruct,'Show_Generated_Configuration') )
    inputStruct.Show_Generated_Configuration = 0;
end
if ( ~isfield(inputStruct,'Show_CPU_Run_Time') )
    inputStruct.Show_CPU_Run_Time = 0;
end

if ( ~isfield(inputStruct,'Normalize_Noise_Energy_To_Given_Interval') )
    inputStruct.Normalize_Noise_Energy_To_Given_Interval = 0.16*inputStruct.Oded_Method + inputStruct.Yonatan_Method*0.004; % 0.16;% Time_Block_Length-JND_Interval_Head-JND_Interval_Tail;
end
if ( ~isfield(inputStruct,'Sim_Type') )
    inputStruct.Sim_Type = 4;
end
inputStruct.JND_Interval_Duration = inputStruct.Decouple_Filter*inputStruct.Time_Block_Length;
%SPLref = 1.5e-8;
if ( ~isfield(inputStruct,'JND_Delta_Alpha_Time_Factor') )
    inputStruct.JND_Delta_Alpha_Time_Factor = 0;
end
inputStruct.JND_Delta_Alpha_Time_Factor = inputStruct.Oded_Method*inputStruct.JND_Delta_Alpha_Time_Factor;
if ( ~isfield(inputStruct,'SPLref') )
    inputStruct.SPLref = (inputStruct.Yonatan_Method*2e-5) + (inputStruct.Oded_Method*SPLref);
end
if ( ~isfield(inputStruct,'M_tot') )
    inputStruct.M_tot = M;
end

if ( ~isfield(inputStruct,'Calculate_From_Mean_Rate') )
    inputStruct.Calculate_From_Mean_Rate = 1; % 0 == AI. 1 == RA.
end

%%

if ( ~isfield(inputStruct,'Scale_BM_Velocity_For_Lambda_Calculation') )
    inputStruct.Scale_BM_Velocity_For_Lambda_Calculation = 0.01*inputStruct.Yonatan_Method+ inputStruct.Oded_Method;
end
if ( ~isfield(inputStruct,'testedNoises') )
    inputStruct.testedNoises = 1111;%[1111,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115];
end
%testedFrequencies = [1000];
if ( ~isfield(inputStruct,'testedFrequencies') )
    inputStruct.testedFrequencies = getDefaultTestedFrequencies();
end
if ( ~isfield(inputStruct,'testedPowerLevels') )
    inputStruct.testedPowerLevels = getPowerLevels();
end
if ( ~isfield(inputStruct,'JND_Include_Legend') )
    inputStruct.JND_Include_Legend = 0;
end
if ( ~isfield(inputStruct,'View_Complex_JND_Source_Values') )
    inputStruct.View_Complex_JND_Source_Values = 0;
end
if ( ~isfield(inputStruct,'OHC_Mode') )
    inputStruct.OHC_Mode = 1;
end
if ( ~isfield(inputStruct,'IHC_Mode') )
    inputStruct.IHC_Mode = 1;
end
if ( ~isfield(inputStruct,'Lambda_SAT') )
    inputStruct.Lambda_SAT = lambda_sat;
end
if ( ~isfield(inputStruct,'Tdelta') )
    inputStruct.Tdelta = delta;
end
if ( ~isfield(inputStruct,'OHC_Vector') )
    inputStruct.OHC_Vector = 0.5;
end
if ( ~isfield(inputStruct,'IHC_Vector') )
    inputStruct.IHC_Vector = 8;
end
if ( ~isfield(inputStruct,'Show_JND_Configuration') )
    inputStruct.Show_JND_Configuration = 0;
end
inputStruct.Run_Stage_Calculation = 0;

if ( ~isfield(inputStruct,'Decouple_Unified_IHC_Factor') )
    inputStruct.Decouple_Unified_IHC_Factor = 1;
end

if ( ~isfield(inputStruct,'Calculate_JND') )
    inputStruct.Calculate_JND = 0;
end

tflevel = inputStruct.JND_Signal_Source + (1-inputStruct.JND_Signal_Source)*length(inputStruct.testedFrequencies);

inputStruct.duration = inputStruct.JND_Interval_Duration*(length(inputStruct.testedPowerLevels)*(tflevel+ inputStruct.Calculate_JND*(1-inputStruct.Generate_One_Ref_Per_Noise_Level)) + inputStruct.Calculate_JND*inputStruct.Generate_One_Ref_Per_Noise_Level)*length(inputStruct.testedNoises);
inputStruct.Time_Blocks = min(inputStruct.Noises_per_run,length(inputStruct.testedNoises))*round(inputStruct.duration/(inputStruct.Time_Block_Length*length(inputStruct.testedNoises)));

%fprintf('start loading configuration...\n');
cochleaConfig = loadCochleaConfig(1,0,inputStruct.duration,inputStruct.Time_Blocks,inputStruct.Fs,inputStruct.Time_Block_Length,inputStruct.Overlap_Time);
%fprintf('start adjusting loading configuration...\n');
cochleaConfig.Sim_Type = inputStruct.Sim_Type; % testing generate JND automatically
cochleaConfig.Calculate_JND = inputStruct.Calculate_JND;
if ( inputStruct.JND_Signal_Source )
    cochleaConfig.Signal_Name = inputStruct.filesStruct.tag_name;
    cochleaConfig.Input_Signal = inputStruct.filesStruct.data_cut;
else
    cochleaConfig.Signal_Name = 'Pure Tones';
end
if ( inputStruct.JND_Noise_Source )
     cochleaConfig.Noise_Name = inputStruct.NoiseObject.tag_name;
     cochleaConfig.Input_Noise = inputStruct.NoiseObject.data_cut;
else
    cochleaConfig.Noise_Name = 'White Noise';
end
cochleaConfig.Run_Stage_Calculation = inputStruct.Run_Stage_Calculation;
cochleaConfig.JND_Noise_Source = inputStruct.JND_Noise_Source;
cochleaConfig.JND_Signal_Source = inputStruct.JND_Signal_Source;
cochleaConfig.Allowed_Outputs = inputStruct.Allowed_Outputs;
%cochleaConfig.Input_File = [pwd '\recorded_noise.bin'];
cochleaConfig.OHC_Mode = inputStruct.OHC_Mode;
cochleaConfig.IHC_Mode = inputStruct.IHC_Mode;
cochleaConfig.Decouple_Filter = inputStruct.Decouple_Filter;
cochleaConfig.JND_USE_Spont_Base_Reference_Lambda = inputStruct.JND_USE_Spont_Base_Reference_Lambda;
cochleaConfig.OHC_Vector = inputStruct.OHC_Vector;
cochleaConfig.IHC_Vector = inputStruct.IHC_Vector;
cochleaConfig.Normalize_Noise_Energy_To_Given_Interval = inputStruct.Normalize_Noise_Energy_To_Given_Interval;
cochleaConfig.Overlap_Time = inputStruct.Overlap_Time;
cochleaConfig.AC_Filter_File = [pwd '\Data\AC_time_filter.bin'];
cochleaConfig.Show_Filter = 0;
cochleaConfig.Show_Run_Time = inputStruct.Show_Run_Time;
cochleaConfig.Decouple_Unified_IHC_Factor = inputStruct.Decouple_Unified_IHC_Factor;
cochleaConfig.JND_Include_Legend = inputStruct.JND_Include_Legend;
cochleaConfig.Show_CPU_Run_Time = inputStruct.Show_CPU_Run_Time;
cochleaConfig.Show_Device_Data = inputStruct.Show_Device_Data;
cochleaConfig.Lambda_SAT = inputStruct.Lambda_SAT;
cochleaConfig.Complex_JND_Calculation_Types = 1;
cochleaConfig.Run_Fast_BM_Calculation = inputStruct.Run_Fast_BM_Calculation;
cochleaConfig.Filter_Mode = 0;
cochleaConfig.Complex_Profile_Power_Level_Divisor = inputStruct.Complex_Profile_Power_Level_Divisor;
cochleaConfig.eta_AC = inputStruct.eta_AC;
%cochleaConfig.Tdelta = 1e-3;
cochleaConfig.Tdelta = inputStruct.Tdelta;
if ( isfield(inputStruct,'AC_Filter_Vector') )
    cochleaConfig.AC_Filter_Vector = inputStruct.AC_Filter_Vector;
    cochleaConfig.Filter_Mode = 2;
% elseif ( ~isfield(inputStruct,'AC_Filter_Vector') && isfield(inputStruct,'Filter_Mode') && inputStruct.Filter_Mode ==2 )
else
    cochleaConfig.AC_Filter_Vector = getTimeSynapsesIIR( Fs,Fpass,Fstop,Apass,Astop );
    cochleaConfig.Filter_Mode = 2;
end
cochleaConfig.Hearing_AID_FIR_Transfer_Function = inputStruct.Hearing_AID_FIR_Transfer_Function;
cochleaConfig.Hearing_AID_IIR_Transfer_Function = inputStruct.Hearing_AID_IIR_Transfer_Function;
cochleaConfig.eta_DC = inputStruct.eta_DC;
cochleaConfig.JACOBBY_Loops_Slow = 12*inputStruct.Yonatan_Method+20*inputStruct.Oded_Method;
cochleaConfig.JACOBBY_Loops_Fast = 3*inputStruct.Yonatan_Method+2*inputStruct.Oded_Method;
cochleaConfig.Cuda_Outern_Loops = 15*inputStruct.Yonatan_Method+10*inputStruct.Oded_Method;
cochleaConfig.MAX_M1_SP_ERROR = -8*inputStruct.Yonatan_Method -15*inputStruct.Oded_Method;
cochleaConfig.MAX_TOLERANCE = -5*inputStruct.Yonatan_Method-11*inputStruct.Oded_Method;
cochleaConfig.MIN_TIME_STEP = 140*inputStruct.Oded_Method+90*inputStruct.Yonatan_Method;
cochleaConfig.MAX_TIME_STEP = 60;
%cochleaConfig.Verbose_BM_Vectors = 'Q,S_ohc,S_tm,R_tm,M_bm,R_bm,S_bm';
%cochleaConfig.Verbose_BM_Vectors = 'S_bm';
cochleaConfig.RELATIVE_ERRORS = 0;
cochleaConfig.M1_SP_Fix_Factor = 0.04;
cochleaConfig.Tolerance_Fix_Factor = 0.01;
%cochleaConfig.MIN_TIME_STEP = 180;
cochleaConfig.Filter_Noise_Flag = 0;
cochleaConfig.Filter_Noise_File = [pwd '\Data\Noise_filter.bin'];
cochleaConfig.Type_TEST_Output = 'MeanRate';
if ( isfield(inputStruct,'Type_TEST_Output') )
    cochleaConfig.Type_TEST_Output = inputStruct.Type_TEST_Output;
end
cochleaConfig.JND_File_Name = [pwd '\Data\jnd_rate.bin'];
if ( isfield(inputStruct,'TEST_File_Target') )
    cochleaConfig.TEST_File_Target = inputStruct.TEST_File_Target;
end
cochleaConfig.JND_Raw_File_Name = [pwd '\Data\jnd_raw_file.bin'];
cochleaConfig.JND_Interval_Duration = inputStruct.JND_Interval_Duration;
cochleaConfig.JND_Interval_Head = inputStruct.JND_Interval_Head;
cochleaConfig.JND_Interval_Tail = inputStruct.JND_Interval_Tail;
cochleaConfig.JND_Delta_Alpha_Time_Factor = inputStruct.JND_Delta_Alpha_Time_Factor;
cochleaConfig.Calculate_From_Mean_Rate = inputStruct.Calculate_From_Mean_Rate; 
cochleaConfig.M_tot = inputStruct.M_tot;
cochleaConfig.testedNoises = inputStruct.testedNoises;
cochleaConfig.Generate_One_Ref_Per_Noise_Level = inputStruct.Generate_One_Ref_Per_Noise_Level;
cochleaConfig.testedFrequencies = inputStruct.testedFrequencies;
cochleaConfig.testedPowerLevels = inputStruct.testedPowerLevels;
cochleaConfig.Scale_BM_Velocity_For_Lambda_Calculation = inputStruct.Scale_BM_Velocity_For_Lambda_Calculation;
%cochleaConfig.Duration = duration;
%cochleaConfig.Approximated_JND_EPS_Diff = 10;
cochleaConfig.Max_dB_SPL_JND = 150;
cochleaConfig.Show_JND_Configuration =inputStruct.Show_JND_Configuration; 
%cochleaConfig.JND_Raw_File_Name = [pwd '\Data\jnd_raw_rate.bin'];
cochleaConfig.Perform_Memory_Test = 0;
cochleaConfig.Show_Generated_Input = inputStruct.Show_Generated_Input;
cochleaConfig.Normalize_Sigma_Type = inputStruct.Normalize_Sigma_Type;
cochleaConfig.Normalize_Sigma_Type_Signal = inputStruct.Normalize_Sigma_Type_Signal;
cochleaConfig.Output_Result = [pwd '\Data\loggernating_results_test.bin'];
cochleaConfig.Remove_Generated_Noise_DC = 0;
cochleaConfig.Show_Generated_Configuration = inputStruct.Show_Generated_Configuration;
cochleaConfig.View_Complex_JND_Source_Values =inputStruct.View_Complex_JND_Source_Values;
%cochleaConfig.Noise_Expected_Value_Accumulating_Boundaries = [0 0.16];
cochleaConfig.Processed_Interval = inputStruct.Time_Blocks*cochleaConfig.Time_Block_Length;
cochleaConfig.Calculate_JND_On_CPU = 0;
cochleaConfig.SPLRef = inputStruct.SPLref;

cochleaConfig.Aihc = inputStruct.Aihc;
cochleaConfig.spontRate = inputStruct.spontRate;
cochleaConfig.Discard_Lambdas_Output = inputStruct.Discard_Lambdas_Output;
cochleaConfig.Discard_BM_Velocity_Output =inputStruct.Discard_BM_Velocity_Output;
cochleaConfig.Show_Calculated_Power = inputStruct.Show_Calculated_Power;
%cochleaConfig.Noise_Expected_Value_Accumulating_Boundaries = [JND_Interval_Head Time_Block_Length];
%cochleaConfig.Noise_Sigma_Accumulating_Boundaries = [JND_Interval_Head Time_Block_Length];
cochleaConfig.Complex_Profile_Noise_Level_Fix_Factor = inputStruct.Complex_Profile_Noise_Level_Fix_Factor;
cochleaConfig.Complex_Profile_Noise_Level_Fix_Addition = inputStruct.Complex_Profile_Noise_Level_Fix_Addition;
cochleaConfig.Review_Lambda_Memory = 0;



end

