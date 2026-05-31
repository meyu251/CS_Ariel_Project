function [jnd_final, jnd_rms] = calculateJNDfiles( signal,noise,run_time,En, testedPowerLevels, OHC_Vector, IHC_Vector, PrescriptionName )
%CALCULATEGENERALJND calculates JND for any signal and noise
%   signal should be wav file name (relative path to current folder
%   suffice)
%   noise should be wav file name (relative path to current folder
%   suffice), will take noise current power and measure it against diffrent
%   signal levels
%   OHC_Vector represents gmmma along partitions of the cochlea(range 0 to 0.5), if length
%   shorter than 256 will be expanded such that every part will take
%   256/given_length
%   IHC_Vector represents IHC nerve amplification along partitions of the cochlea(range 5 to 8), if length
%   shorter than 256 will be expanded such that every part will take
%   256/given_length
%   PrescriptionName, if cochlea is damaged, will show response with
%   calculated prescriptions, avaliable prescriptions are: POGO, NAL (its
%   the revised one), BergerITE (Inside the ear), BergerBTE (behind the
%   ear)
    if ( ~exist('PrescriptionName','var') )
        PrescriptionName = ''; % empty string, to not use Hearing Aid, possible prescriptions: BergerITE, BergerBTE, POGO, NAL
    end
%Define Ear's parameters    
    if ( ~exist('OHC_Vector','var') )
        OHC_Vector = 0.5;
    end
    if ( ~exist('IHC_Vector','var') )
        IHC_Vector = 8;
    end
    g = gpuDevice();
    maxSeconds = g.TotalMemory/(120*1024*1024);
    if ( ~exist('run_time','var') )
        run_time = 0.2;
    end
    
    min_intervals = 8;
    max_intervals = 25;
    Allowed_Outputs = 0;   %Generate Outputs
    load Final_Parameters.mat;
    Hearing_Aid_Prescription = 1;
%     if ( ~isCochleaHealthy( OHC_Vector, IHC_Vector ) && ~strcmp(PrescriptionName,'') )
%         % if coclea not healthy, calculate prescription first
%         [ Hearing_Aid_Prescription,~,~] = ...
%             getPrescription( OHC_Vector, IHC_Vector, PrescriptionName );
%     end
    
    [ SignalObject ] = getFileSample( Fs,signal,run_time,0,100,0 );
    run_time = SignalObject.length_cut;
     testedNoises = [En];
    JND_Noise_Source = 1;
    %testedPowerLevels = 20:10:100;% linspace(10,100,max(min_intervals,min(max_intervals,floor(10/SignalObject.length_cut))));
    
    NoiseObject = struct();
    if ( (ischar(noise) && ~strcmp(noise,'')) || (~ischar(noise) && mean(noise.*noise) ~= 0) )
        NoiseObject = getFileSample( Fs,noise,SignalObject.length_cut,0,100,0 );
        JND_Noise_Source = 1;
        % fix SPLref to match oded
        %fix_factor = sqrt(SPLref/2e-5);
        %NoiseObject.data_cut = NoiseObject.data_cut*fix_factor;
        %NoiseObject.data = NoiseObject.data*fix_factor;
        %testedNoises = PA2SPL(mean(NoiseObject.data_cut.*NoiseObject.data_cut),SPLref);
        %testedPowerLevels = linspace(max(10,testedNoises-45),min(120,testedNoises+45),max(min_intervals,min(max_intervals,floor(10/SignalObject.length_cut))));
    end
    powerLevelsNumber = length(testedPowerLevels);
    powerLevelsPerRun = powerLevelsNumber;
    single_run=1;
    while ( (powerLevelsPerRun+1)*run_time > maxSeconds) 
        powerLevelsPerRun=powerLevelsPerRun-1;
        single_run=0;
    end
    AC_Filter_Vector = getTimeSynapsesIIR( 20000,300,1800,3,30);

    jnd_rms = zeros(length(testedNoises),powerLevelsNumber);
    current_index_power_levels = 1;
    while ( current_index_power_levels <= powerLevelsNumber)
        [analyzed,processedStruct,~] = analyzeFile('filesStruct',SignalObject ...
        ,'JND_Include_Legend',7 ...
        ,'Normalize_Sigma_Type_Signal', 1 ...
        ,'Normalize_Sigma_Type', 1 ...
        ,'JND_Delta_Alpha_Time_Factor', 0.2 ...
        ,'Decouple_Filter',10 ...
        ,'OHC_Vector', OHC_Vector ...
        ,'IHC_Vector', IHC_Vector ...
        ,'Noises_per_run',1 ...
        ,'Calculate_JND',1 ...
        ,'Filter_Mode', 2 ...
        ,'Aihc', Aihc ...
        ,'testedPowerLevels', testedPowerLevels(current_index_power_levels:(current_index_power_levels+powerLevelsPerRun-1)) ... % this ensures no normalization on power of input file
        ,'JND_Noise_Source', JND_Noise_Source ...
        ,'NoiseObject',NoiseObject ...
        ,'Hearing_AID_FIR_Transfer_Function', Hearing_Aid_Prescription ...
        ,'Decouple_Unified_IHC_Factor',0 ...
        ,'AC_Filter_Vector', AC_Filter_Vector ...
        ,'JND_Interval_Tail',0.000 ...
        ,'JND_Interval_Head',0.012 ...
        ,'Allowed_Outputs',Allowed_Outputs ...
        ,'testedNoises',testedNoises);
        resultStruct = struct();
        resultStruct.analyzeInputStruct = processedStruct;
        resultStruct.analyzeResult = analyzed;
        %dispFinalJND( resultStruct );
        jnd_final = analyzed.jnd_final;
        jnd_rms(:,current_index_power_levels:(current_index_power_levels+powerLevelsPerRun-1)) = analyzed.jnd_rms;
        current_index_power_levels=current_index_power_levels+powerLevelsPerRun;
        powerLevelsPerRun = min(powerLevelsPerRun,powerLevelsNumber-current_index_power_levels+1);
    end
    if ( ~single_run )
        [temp_value , temp_index] = findpeaks(-1*jnd_rms); %finds local minimum
        if (size(temp_value) == 1) %make sure that there is only one local minimum
           jnd_final = -1*temp_value;
        else 
            if (size(temp_value) ~= 0) 
               jnd_final = jnd_rms(1,1);
               fprintf('WARNING: Failed to find proper minimum\n');
            else
               %% in case of no local minimum points, we put zero (and create a warning)
               jnd_final =  temp_value(1,1);  
               fprintf('WARNING: Found %d minimums\n',length(temp_index));
            end
        end
    end


