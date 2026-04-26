classdef configCochlea < matlab.mixin.SetGet
    %CONFIGCOCHLEA create and maintain ini config file for cochlea.exe
    %   Detailed explanation goes here
    properties(Constant)
        defaultConfigFile = 'cochlea_reserved_file.par';
    end
    properties
        configFile;%target file for writing this paramaters use when run the cochlea tm exe
        configMatFile; % matlab file mat to parser parameters from (writeFile processing the struct)
        loadedStruct;
        isFrequencies=0;
        creatingDatabase=0;
        %% input type read from the handles
        selectedInputType;
        %% file parameters
        %Assumptions:
        %1.Avoid adding Gamma_file will set automatically Gamma=0.5(healthy
        %man)
        %2.Avoid Nerve File will set the IHC as 1(Healthy Man)
        %3.Avoiding output_results will set the output in
        %Data\output_result.bin
        %4.Avoiding all the Lambda inputs will put the output in
        %Data\Lambda_<name>.bin
        Fs;%Sampling Rate wil be 20000 if not modified, use in HZ
        % will be number of time blocks calculated per interval, default 8
        % example if set to 12 than each interval 0.24 seconds of sounds
        % will be processed
        Scale_BM_Velocity_For_Lambda_Calculation; % use 1 for cm/s or 0.01 for m/s velocity
        Time_Block_Length; % duration (seconds) of time synchronized input processed must be greater than 0.02 seconds, works in resolution of milliseconds
        Sim_Type;% put 4 for full JND calculation, 0 for single input old mode
        Continues;%Flag- should be 1 
        Show_Transient; % put 1,if 1 will output firat overlap period (default overlap period is 5ms)
        %% if sim type is 3 will create fro each combination of frequency,power level,noise an interval to check
        testedFrequencies; % array of frequencies to test intervals, note analyzeFile supply this automatically
        testedNoises; % array of power of white noises in dB SPL to test intervals
        testedPowerLevels; % array of power levels in dB SPL to test intervals
        OHC_Vector; % const value to all OHC 0.5 healthy, 0 completely sick , override file if OHC_Mode==1
        OHC_Mode; % should be one to work with OHC_Vector
        IHC_Vector; % const value to all IHC 8 healthy, 5 completely sick , override file if IHC_Mode==1
        IHC_Mode; % should be 1 to work with IHC_Vector
        Filter_Mode; %2 from ac filter vector, 0 - AC filter from file, 1 calculated from function
        Function_Filter; % params from filter function
        AC_Filter_Vector; % direct input of filter vector for processing
        Lambda_SAT; % lambda saturation, if not written its 500
        Tdelta; % IHC Integration time (in seconds) will be 0.002 if not set
        eta_AC; % IHC AC coupling [V/s/cm]
        eta_DC; % IHC DC coupling [V/cm]
        MAX_TIME_STEP; % BM calculation maximum time step of scan as logaritmic scale such that 60 => 1e-6 seconds, 80 => 1e-8 seconds, default value 60
        MIN_TIME_STEP; % BM calculation minimum time step of scan same translation as MAX bt default value 160
        Calculate_JND; % 1 to calculate JND, 0 not to
        JND_File_Name; % name of JND output must be not empty if Calculate_JND is true
        JND_Interval_Duration; % duration per calculation of JND inetrval, include padding
        JND_Interval_Head; % duration to ignore at the begging of each interval
        JND_Interval_Tail; % duration to ignore at the end of each interval JND
        W; % modifiable nerves groups weight default = 0.61 0.23 0.16
        Aihc; % modifiable nerves group A, default = [70e-3 50e-3 30e-3]
        JND_Tail_Intervals; % set to 1 if all refrence intervals at the end of the input
        JND_Reference_Rate; % set to the relation of refrence intervals per calculated+1
        JND_Single_Reference_Rate; % if its 1 will use only last interval as reference
        Calculate_JND_Types; % bitwise flags for jnd types of calculation 1 is RMS, 2 is AI
        Generate_One_Ref_Per_Noise_Level; % generate single interval per noise power level
        spontRate; % nerves sopntanous rate default is 60 3 0.1
        SPLRef; % spl reference base, default 2e-5 (Pascal)
        Input_Signal; % input signal as array of doubles can be stored here, will use only when read configuration from matlab file
        Input_Noise; % input noise as array of doubles can be stored here, will use only when read configuration from matlab file
        Show_Generated_Input; % set 1 if you want to output generated input int the Input_File
        Decouple_Filter; % if 0 it will use backward calculating for each block except the first, otherwise it will decouple the input every [Decouple_Filter] number of time blocks
        Max_dB_SPL_JND; % max level in dB spl that jnd result can get, default 150
        JND_Raw_File_Name; % in case of complex jnd calculation Sim_Type==4 => will write middle results to this file
        View_Complex_JND_Source_Values; % view complex assembly parts if 1
        Calculate_From_Mean_Rate; % 1, will calculate aggreagated jnd from mean rates, 0 will calculate from ai
        Discard_BM_Velocity_Output; % if 1 do not write bm velocity to disk
        Discard_Lambdas_Output; % if 1 do not write lambdas output to disk
        Complex_Profile_Noise_Level_Fix_Factor; % fix start test level of minimum value with factor noise generated input tests
        Complex_Profile_Noise_Level_Fix_Addition; % fix start test level of minimum value with addition tonoise generated input tests
        Complex_Profile_Power_Level_Divisor; % this number will change power dependent of noise level (for noiseless it will be ignored)
        % example if power level 10:10:80 currently on noise level 60 dB and
        % you are testing 30 dB with this parameter as 20 actual power
        % level of the signal will be 10 + (30-10)*(20/60) = 16.66 dB, this
        % allows compression of range on high level of noise since most of
        % the time you'll want to get better resolution
        JND_Delta_Alpha_Time_Factor; % for the lines in wanted jnd...
        Normalize_Noise_Energy_To_Given_Interval; % if noise generated normalize energy to given signal
        Remove_Generated_Noise_DC; % if 1 removes the 0 frequency value from noise
        % lambda_mean = lambda_mean_calc(lambda);
        % lambda_ref_mean = lambda_mean_calc(lambda_ref);
        % d_lambda_mean = (lambda_mean-lambda_ref_mean)./d_alpha;
        % T = Ts*size(lambda,4);
        % CRLB_RA(i,j,:) = (T./lambda_ref_mean(i,j,:).*(d_lambda_mean(i,j,:).^2)).^(-0.5);
        M_tot; % total number of fibers
        Approximated_JND_EPS_Diff; % minimum level to negate values for calculations
        Signal_Name; % for mex legends
        Noise_Name; % for mex legends
        Complex_JND_Calculation_Types; % bit array in case of complex jnd aggregation 1 - is for minimu calculation, 2 - for wanted type(Approximated_JND_EPS_Diff for epsilon), must not be zero
        TEST_File_Target; % output target for some debugs
        Type_TEST_Output; % stage name for output MeanRate by default
        Show_Filter; % show filter read from file or generated
        JND_Noise_Source; % 0 - self generate, 1 - read from input file
        JND_Signal_Source; % 0 - self generate from frequencies, 1 - from Input_Signal or Input_File
        Normalize_Sigma_Type; % 0 - normalize sigma to 1, 1 - normalize sigma summary to avg 1, 2 - normalize sigma summary to given time interval at Normalize_Noise_Energy_To_Given_Interval
        Normalize_Sigma_Type_Signal; % 0 - normalize sigma to 1, 1 - normalize sigma summary to avg 1 1, 2 - normalize sigma summary to given time interval at Normalize_Noise_Energy_To_Given_Interval
        Noise_Sigma_Accumulating_Boundaries; % when generated white noise will normalize power by this boundaries
        Filter_Noise_Flag; % if 1 will filter the signal, filter noise file must be provided
        Filter_Noise_File; % for filtering noise
        JND_Include_Legend; % bit array 1 for final, 2 for rms, 4 for AI
        Allowed_Outputs; %  flag array for allowed outputs 0 bit for BM velocity and 1-3 are lambda high to lambda low accordingly
        %% parameters below this line are either legacy or for debugging please ignore them
        Run_Fast_BM_Calculation; % will run BM calculation with relaxed memory requirements, default no (0)
        Verbose_BM_Vectors; % verbose vectors aggragated at fast BM calculation can be Q,S_ohc,S_tm,R_tm,M_bm,R_bm,S_bm
        Run_Stage_Calculation; % if not 0 will calculate from either velocity or lambda
        Sin_Freq;%input for tones Game, ignore now
        Sin_dB;%input for tones Game, ignore now
        Disable_Lambda;%Flag- 0 or 1. if 1 do not calculate and show lambda
        %0-Will compute Lambda ouputs for the BM output.
        %1-Won't compute Lambda outputs for the BM output.
        Offset;%offset of time (sec) from the begning of file to read the input file
        Duration;%On which length from the signal you want to process (sec), start from the offset
        AC_Filter_File; %FIR OR IIR filter structure first number order 2nd is 1 if FIR 0 otherwise. than array a of the filter(NOT IN FIR) than array b
        %"GOOD"=not miliseconds taken for end of file data corruption
        Input_File;%name of file is inside '' or absolute path, ends with .bin
        Input_Noise_File;%name of file is inside '' or absolute path, ends with .bin
        Run_Stage_Vector; % for BM velocity and lambda start calculation
        Overlap_Time; % duration(seconds) transient time must be at least 0.005 seconds, works in resolution of milliseconds
        Processed_Interval; % duration (seconds) of input processed per single graphic process run mutual exclusive with Time_Blocks
        JND_USE_Spont_Base_Reference_Lambda; % if 0 will calculate reference lambda without spont rate (so dont use noiseless)
        Noise_Expected_Value_Accumulating_Boundaries; % when white noise generated will remove expected value calculated by this boundaries
        Calculate_JND_On_CPU; % will calculate JND  on cpu only relevant if JND calculated
        Run_Stage_File_name; % if run from bm velocity or lambda and data loaded from file
        Review_Lambda_Memory; % for debug if set to 1 will view allocated sizes of memories, for advanced use
        Review_AudioGramCall; % for debug
        Hearing_AID_FIR_Transfer_Function; % hearing aid fir function coefficents array
        Hearing_AID_IIR_Transfer_Function; % hearing aid iir function coefficents array
        BMOHC_Kernel_Configuration; % cuda prefered cahce division to main kernel, numeral values see 
        Decouple_Unified_IHC_Factor; % split time blocks to smaller parts for lambda calculating...
        Show_Generated_Configuration; % for debugging shw profiles of created input
        Perform_Memory_Test; % for debug purposes show available memory left while running
        Gamma_File;%256 double of Gammas for each section of the BM
        Force_IHC_on_CPU; % force lambda calculation on cpu instead of GPU for debugging purposes
        Nerves_File;%256 double of,A Number between 0-1, Health Factor in dB scale of nerves conncected to the IHC
        Output_Result;% linear velocity(cm/sec),(dB ONLY in execute CUDA) per time, per unit length,,
        Lambda_High;%Number of high spikes per unit(sec) time per length(cm).
        Lambda_Medium;%Number of medium spikes per unit(sec) time per length(cm).
        Lambda_Low;%Number of low spikes per unit(sec) time per length(cm).
        Time_Blocks; % number of processed intervals (each one at duration of Time_Block_Length seconds) each gui run
        Show_JND_Configuration; % for debugging sJND array sizes
        Database_Creation;%ignore
        Load_Previous;%Flag that says if to connect different blocks 0.16 sec.
        Remove_Transient_Tail; % if transient exist will remove the overlap tail from the end of the output, ignore otherwise
        %0-Don't stitch two Lambda blocks data (ignore the past) 
        %1-Stitch two 0.16 sec Lamda blocks data (icludes the past, correct
        %form of reality)
        Load_Previous_File;% Name or full path of the file that contains BM velocity of the previous 8 "GOOD" milisec in a .bin
        %, actually a pivot.
        Mex_Debug_In_Output; % relevant to mex run only if 1 debug verbossing will go into output struct
        Show_Device_Data; % 1 - show cuda device full data for debugging and optimization
        MAX_M1_SP_ERROR; % base m1 sp tolerance factor on logarithmic scale default number -15
        MAX_TOLERANCE; % base throw tolerance of max error
        Tolerance_Fix_Factor;
        M1_SP_Fix_Factor; % 
        RELATIVE_ERRORS; % makes MAX_M1_SP_ERROR and MAX_TOLERANCE relative to summary of previous errors if this parameter is 1
        Show_Calculated_Power; % shows max power in dBSPL per time block if flagged
        Show_Run_Time; % show run time for cuda functions
        JACOBBY_Loops_Fast; % number of jacobby loops on fast approximation cycle default number 2
        JACOBBY_Loops_Slow; % number of jacobby loops on slow approximation cycle default number 20
        Cuda_Outern_Loops; % max control loops per sample, defult 10
        Show_CPU_Run_Time; %  array of flags to show run time for CPU sub routines
        Power_Frequencies; % this remains here for reasons unknown, gui dependent
    end
    properties (Dependent)
        evaluatedStruct;
        evaluatedMatStruct;
        %% data calculated from the control panel base on selected input, ignores sim type current value
        isMic;
        isFile;
        isGenerator;
        isfileWrite;
        isFrequency;
        isSpecificFound;
    end
    methods
        %% constructor
        function obj = configCochlea()
            obj.configFile = obj.defaultConfigFile;
            obj.loadedStruct = struct;
            %obj = obj.readFile();
            %obj.configFile = 'cochlea_test.par';
        end
        %% get evaluated struct to write in configuration file
        function est = get.evaluatedStruct(obj)
            est = struct;
            excludeProps = {};
            semiDynamicProps = {
                'Fs','Time_Blocks','MAX_TIME_STEP','MIN_TIME_STEP','Show_Transient','Scale_BM_Velocity_For_Lambda_Calculation','Processed_Interval','Time_Block_Length','Overlap_Time','Gamma_File','Load_Previous','Load_Previous_File',...
                'Calculate_JND','JND_File_Name','JND_Interval_Duration','JND_Interval_Head','JND_Interval_Tail',...
                'JND_Tail_Intervals','Calculate_JND_Types','JND_Reference_Rate','JND_Single_Reference_Rate','spontRate',...
                'Nerves_File','Calculate_JND_On_CPU','Sim_Type','Disable_Lambda','Lambda_SAT',...
                'OHC_Vector','IHC_Vector','OHC_Mode','IHC_Mode','AC_Filter_File','Tdelta','Allowed_Outputs', ...
                'Run_Stage_File_name','Run_Stage_Calculation','JND_Include_Legend','AC_Filter_Vector' ...
                'BMOHC_Kernel_Configuration','Decouple_Unified_IHC_Factor','Mex_Debug_In_Output', ...
                'Signal_Name','Noise_Name','Normalize_Sigma_Type_Signal','Complex_Profile_Power_Level_Divisor',...
                'JACOBBY_Loops_Fast','JACOBBY_Loops_Slow','Cuda_Outern_Loops','Show_CPU_Run_Time','Run_Fast_BM_Calculation',...
                'eta_AC','eta_DC','Review_Lambda_Memory','Review_AudioGramCall','Complex_JND_Calculation_Types',...
                'Filter_Noise_Flag','Filter_Noise_File','Show_Calculated_Power','Show_Run_Time','Verbose_BM_Vectors', ...
                'MAX_M1_SP_ERROR','MAX_TOLERANCE','RELATIVE_ERRORS','M1_SP_Fix_Factor','Tolerance_Fix_Factor','Show_Device_Data',...
                'Force_IHC_on_CPU','Function_Filter','Filter_Mode','SPLRef','Remove_Transient_Tail',...
                'Output_Result','Lambda_High','Lambda_Medium','Lambda_Low','Noise_Expected_Value_Accumulating_Boundaries',...
                'Show_Filter','Calculate_From_Mean_Rate','Type_TEST_Output','JND_Noise_Source','JND_Signal_Source', ...
                'JND_USE_Spont_Base_Reference_Lambda','Aihc','W','Normalize_Sigma_Type','Input_Noise_File',...
                'Complex_Profile_Noise_Level_Fix_Factor','Complex_Profile_Noise_Level_Fix_Addition',...
                'Normalize_Noise_Energy_To_Given_Interval','Remove_Generated_Noise_DC', ...
                'Continues','Sin_Freq','Max_dB_SPL_JND','Sin_dB','Input_File','Offset','Duration',...
                'testedFrequencies','JND_Raw_File_Name','testedPowerLevels','testedNoises','Show_JND_Configuration',...
                'Show_Generated_Configuration','Show_Generated_Input','Decouple_Filter','Generate_One_Ref_Per_Noise_Level',...
                'View_Complex_JND_Source_Values','Discard_BM_Velocity_Output' ... 
                ,'M_tot','Approximated_JND_EPS_Diff','JND_Delta_Alpha_Time_Factor','Hearing_AID_FIR_Transfer_Function' ...
                ,'Hearing_AID_IIR_Transfer_Function','Discard_Lambdas_Output','Perform_Memory_Test','TEST_File_Target' ...
                };
            if ( obj.Sim_Type ~= 3 && obj.Sim_Type ~= 4)
                excludeProps{end+1} = 'testedFrequencies';
                excludeProps{end+1} = 'testedPowerLevels';
                excludeProps{end+1} = 'testedNoises';
            end
            if ( obj.Sim_Type == 3 || obj.Sim_Type == 4)
                excludeProps{end+1} = 'Duration';
            end
            if ( obj.Sim_Type ~= 1)
                excludeProps{end+1} = 'Sin_Freq';
                excludeProps{end+1} = 'Sin_dB';
            end
            if ( obj.creatingDatabase == 0 )
                 excludeProps{end+1} = 'Database_Creation';
            end
            if ( ~isempty(obj.Processed_Interval) )
                excludeProps{end+1} = 'Time_Blocks';
            end
            for i = 1:numel(semiDynamicProps)
                if ( isempty(find(ismember(excludeProps,semiDynamicProps{i}), 1))*isprop(obj,semiDynamicProps{i})*(1-isempty(obj.(semiDynamicProps{i})))==1 )
                    %fprintf('%s=%s\n',fields{i},s.(fields{i}));
                    est.(semiDynamicProps{i}) = obj.(semiDynamicProps{i});
                end
            end
        end
        %% calculates the config + mat array
        function est = get.evaluatedMatStruct(obj)
            est = obj.evaluatedStruct;
            if ( (1-isempty(obj.Input_Signal))==1 )
                %fprintf('%s=%s\n',fields{i},s.(fields{i}));
                est.Input_Signal = obj.Input_Signal;
                if ( ~isrow(est.Input_Signal) )
                    est.Input_Signal = est.Input_Signal';
                end
            end
            if ( (1-isempty(obj.Input_Noise))==1 )
                est.Input_Noise = obj.Input_Noise;
                if ( ~isrow(est.Input_Noise) )
                    est.Input_Noise = est.Input_Noise';
                end
            end
            if ( (1-isempty(obj.Run_Stage_Vector))==1 )
                est.Run_Stage_Vector = obj.Run_Stage_Vector;
            end
        end
        %% test if isMic
        function ism = get.isMic(obj)
            ism = strcmp(obj.selectedInputType,'source_mic_tag');
        end
        %% test if is file input
        function ism = get.isFile(obj)
            ism = strcmp(obj.selectedInputType,'source_file_tag');
        end
        %% test if is file auto generator
        function ism = get.isGenerator(obj)
            ism = strcmp(obj.selectedInputType,'source_generator_tag');
        end
        %% test if is frequency concatenation
        function ism = get.isFrequency(obj)
            ism = strcmp(obj.selectedInputType,'source_freq_tag');
        end
        %% tests if writing data to file
        function ism = get.isfileWrite(obj)
            ism = obj.isFile+obj.isMic;
        end
        %% tests if data calculated directly from the control panel
        function ism = get.isSpecificFound(obj)
            ism = 3*obj.isFrequency+obj.isGenerator;
        end
        
        %% update configuration file
        function obj = writeFile(obj,isstdOutput)
             if ( exist('isstdOutput','var') == 0 )
                 isstdOutput = 0;
             end
             if ( ~isstdOutput )
                fid = fopen(obj.configFile,'w+');
             else
                fid = 1;
             end
             s = obj.evaluatedStruct;
             if ( ~isstdOutput )
                sfull = obj.evaluatedMatStruct;
                obj.configMatFile = regexprep(obj.configFile,'.PAR','.mat','ignorecase');
                save(obj.configMatFile,'sfull');
             end
             fields = fieldnames(s);
             %celldisp(fields);
             if ( isfield(s,'Input_File') && ~isempty(s.Input_File) )
                %fprintf('Input file configed: %s\n',s.Input_File);
             end
%              if ( isfield(s,'Duration') && ~isempty(s.Duration) && isfield(s,'Offset') && ~isempty(s.Offset)  )
%                 fprintf('Running from %.3f to %.3f:\n',s.Offset,s.Offset+s.Duration);
%              end
             for i = 1:numel(fields)
                if ( ischar(s.(fields{i})) == 1 )
                    fprintf(fid,'%s = "%s"\n',fields{i},s.(fields{i}));
                elseif ( ~isscalar(s.(fields{i})) )
                    if ( isempty(find(s.(fields{i}) - floor(s.(fields{i}))~=0,1)) )
                        fprintf(fid,'%s = "%s"\n',fields{i},num2str(s.(fields{i}),'%.0f '));
                    else
                        fprintf(fid,'%s = "%s"\n',fields{i},num2str(s.(fields{i}),'%.3f '));
                    end
                elseif ( isfloat(s.(fields{i})) == 1 && floor(s.(fields{i}))~=s.(fields{i}) )
                    numberOfDigits = 0;
                    maximalDigit=0; % if smaller than one will find most significant digit position
                    fl = s.(fields{i});
                    if ( abs(fl) < 1)
                        afl = abs(fl);
                        maximalDigit = abs(floor(log10(afl)));
                    end
                    while ( floor(fl)~=fl )
                        numberOfDigits = numberOfDigits+1;
                        fl=fl*10;
                    end
                    if ( numberOfDigits<=6 || maximalDigit < 3 )
                        numberOfDigits = max(numberOfDigits,6);
                        fprintf(fid,['%s = %.' num2str(numberOfDigits) 'f\n'],fields{i},s.(fields{i}));
                    else
                        fprintf(fid,['%s = %.3e\n'],fields{i},s.(fields{i}));
                    end
                elseif ( islogical(s.(fields{i})) == 1 || (isfloat(s.(fields{i})) == 1 && floor(s.(fields{i}))==s.(fields{i})) )
                    fprintf(fid,'%s = %d\n',fields{i},s.(fields{i}));
                end
             end
             if ( ~isstdOutput )
                fclose(fid);
             end
        end
        %% read configuration file and generate object from it
        function obj = readFile(obj)
            obj.loadedStruct = struct;
            if ( exist(obj.configFile,'file') == 2)
                fid = fopen(obj.configFile);
                tline = fgetl(fid);
                obj.creatingDatabase = 0;
                while ischar(tline)
                    scan = regexp(tline,'(?<fieldName>[a-zA_Z0-9_]+)\s+\=\s+\"?(?<fieldVal>(?<=")[^"]*(?=")|(?<!")\d+(?:\.\d+)?(?!"))\"?','ignorecase','names');
                    
                    obj.creatingDatabase = obj.creatingDatabase + strcmp(scan.fieldName,'Database_Creation');
                    fprintf('%s >>>>> %s\n',scan.fieldName,scan.fieldVal);
                    if ( sum(isstrprop(scan.fieldVal, 'alpha')) > 0 )
                        %disp(trimmedString{1});
                        obj.loadedStruct.(scan.fieldName) = char(scan.fieldVal);
                    else
                        obj.loadedStruct.(scan.fieldName) = str2double(scan.fieldVal);
                    end
                    if ( isfield(obj.loadedStruct,scan.fieldName)*isprop(obj,scan.fieldName) == 1 )
                        obj.(scan.fieldName) = obj.loadedStruct.(scan.fieldName);
                    end
                    %disp(tline);
                    %disp(scan);
                    tline = fgetl(fid);
                end

            end
        end
        %% set poer frequencies for frequencies tests
        function obj = setPowerFrequencies(obj,powerFreq)
           obj.Power_Frequencies = powerFreq;
        end
        
        %% set set default power frequencies
        function obj = setDefaultPowerFrequencies(obj)
            obj.setPowerFrequencies([45 8 23 23 23 23 23 12]);
        end
        
        %% load data from graphic handles to config object
        function obj = initFromHandles(obj,handles,database_creation,time_offset)
            
          load Final_Parameters.mat;
          obj.Fs = Fs; %#ok<*CPROPLC>
          obj.eta_AC = eta_AC;
          obj.eta_DC = eta_DC;
          obj.Show_Generated_Input = 1;
          obj.Nerves_File = sprintf('%s\\%s',pwd,'cochlea_reserved_nerves.bin');
          obj.Gamma_File = sprintf('%s\\%s',pwd,'cochlea_reserved_gamma.bin');
          obj.M_tot = M;
          %obj.Time_Blocks = 8;
          obj.Filter_Mode = 0;
          obj.Scale_BM_Velocity_For_Lambda_Calculation = 1;
          obj.SPLRef = SPLref;
          %obj.AC_Filter_Vector = 
          obj.Function_Filter = 'Wpass=1,Wstop=60,Fpass=400,Fstop=1600,Order=70,View=1,Type=EquiRipple';
          if ( database_creation == 1)
              obj.Sim_Type = 4;
              obj.Database_Creation = [pwd '\' databaseDirectory()];
              obj.Calculate_JND = 1;
          else
              if ( exist('time_offset','var') == 1 && time_offset >=0 )
                  obj.Offset = time_offset;
              end
              if ( isempty(obj.Offset) == 1 )
                  obj.Offset = 0;
              end
              obj.selectedInputType = handles.button_source_select_tag.SelectedObject.Tag;
              
              obj.Sim_Type = 4;
              obj.Calculate_JND = 0;
              if ( handles.override_auto_tag.Value == 1 )
                isNerveFile = handles.nerves_file_tag.Value;
                if ( isNerveFile == 1 )
                    obj.Nerves_File = handles.nerve_filename_tag.String;
                end
                isGammaFile = handles.gamma_file_tag.Value;
                if ( isGammaFile == 1 )
                    obj.Gamma_File = handles.gamma_filename_tag.String;
                end
              end
              obj.Continues = obj.Sim_Type>1;
              Freq = 1000.0*str2double(handles.gen_freq_in_tag.String);
              obj.testedFrequencies = Freq;
              obj.testedPowerLevels = obj.isGenerator*str2double(handles.gen_amp_in_tag.String)+(obj.Sim_Type==3)*getVarFreqAmp();
              obj.JND_Signal_Source = obj.isfileWrite;
              obj.JND_Noise_Source = 0;
%              obj.Sin_dB = obj.isGenerator*str2double(handles.gen_amp_in_tag.String)+(obj.Sim_Type==3)*getVarFreqAmp();

%               if (obj.isfileWrite) 
%                 inputFileName = [pwd '\record.bin'];   
%                 if ( obj.isMic == 0 )
%                     inputFileName = handles.input_file_name_tag.String;
%                 end 
%                 obj.Input_File = inputFileName;
%               end
          end
          if ( database_creation )
              obj.testedFrequencies = getDefaultTestedFrequencies();
              obj.testedPowerLevels = getPowerLevels();
              
          end
         
          obj.Continues = 0;
          obj.Duration = obj.Time_Blocks*getTimeBlockLength(); % for constant length for all cases
          % warning not all paramters has been initialized due to missing
          % data from the rest of the program to ensure fidelty use global
          % data to init and update when necessary
      end
    end
    methods(Static)
        
      function obj = loadobj(s)
         obj = configCochlea();
         if ( exist('s','var') == 1 )
             %disp(s);
             if ( isstruct(s) )
                 fields = fieldnames(s);
                 for i = 1:numel(fields)
                    if ( isprop(obj,fields{i}) )
                        %fprintf('%s=%s\n',fields{i},s.(fields{i}));
                        obj.(fields{i}) = s.(fields{i});
                    end
                 end
             end
         end
      end
      
      
    end
      
    
end

