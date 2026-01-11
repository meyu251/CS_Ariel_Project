function [cochleaConfig] = loadCochleaConfig(idConfig, disableLambda,duration,Time_Blocks,Fs,Time_Block_Length,Overlap_Time,DebugMode )

    % determine 64 bit or 32 bit mode
    %executableNames = {'cochlea_tm.exe','cochlea_tm_disables_lambda.exe'};
    %executableName = executableNames{mode64index};
    %dataType = dataTypes{mode64index};
    if ( ~exist('DebugMode','var') )
        DebugMode = 0;
    end
    if ( ~exist('Time_Block_Length','var') )
        Time_Block_Length = 0.02;
    end
    if ( ~exist('Overlap_Time','var') )
        Overlap_Time = 0.005;
    end
    directoryTargetExecute = pwd;
    if ( DebugMode )
        
    end
    cochleaConfig = configCochlea();
    cochleaConfig.Duration = duration;
    cochleaConfig.Offset = 0;
    cochleaConfig.Show_Transient = 1;
    cochleaConfig.Input_File = [pwd '\test' num2str(idConfig) '.bin'];
    cochleaConfig.Fs = Fs;
    cochleaConfig.Load_Previous_File = [pwd '\Data\backup_few_ms' num2str(idConfig) '.bin'];
    cochleaConfig.Continues = 1;
    cochleaConfig.Sim_Type = 0;
    %cochleaConfig.Time_Blocks = Time_Blocks;
    cochleaConfig.Time_Block_Length = Time_Block_Length;
    cochleaConfig.Overlap_Time = Overlap_Time;
    cochleaConfig.Processed_Interval = Time_Blocks*cochleaConfig.Time_Block_Length;
    cochleaConfig.Scale_BM_Velocity_For_Lambda_Calculation = 0.01; 
    cochleaConfig.eta_AC = 1;
    cochleaConfig.eta_DC = 100;
%     if ( idConfig == 2 )
         cochleaConfig.AC_Filter_File = [pwd '\Data\AC_time_filter.bin'];
%     else
      %  cochleaConfig.AC_Filter_File = [pwd '\Data\ac_fir_filter.bin'];
%     end
        
    OHC_BASE = 0.5;
    IHC_BASE = 8;
    SECTIONS=256;
    cochleaConfig.OHC_Mode = 1;
    cochleaConfig.OHC_Vector = OHC_BASE;
    cochleaConfig.IHC_Mode = 1;
    cochleaConfig.Filter_Mode = 0;
    %cochleaConfig.Tdelta = 0.008;
    cochleaConfig.Function_Filter = 'Wpass=1,Wstop=30,Fpass=600,Fstop=1600,Order=50,View=1,Type=EquiRipple';
    %if ( idConfig == 1)
    %cochleaConfig.Function_Filter = 'Apass=0.5,Astop=80,Fpass=600,Fstop=1500,view=1,MinOrder=1,Type=EquiRipple';
    %cochleaConfig.Function_Filter = 'Apass=1,Astop=70,Fc=600,View=1,MinOrder=1,Type=EquiRipple';
    %cochleaConfig.Function_Filter = 'Apass=1,Astop=70,Fpass=600,Fstop=1600,View=1,MinOrder=1,Type=EquiRipple';
    %cochleaConfig.Function_Filter = 'Apass=1,Astop=60,Fpass=600,Fstop=1600,View=1,MinOrder=1,Type=Window,WindowType=Kaiser';
    %else
    %cochleaConfig.Function_Filter = 'Apass=3,Astop=30,Fpass=600,Fstop=1600,View=1,MinOrder=1,Mode=Stopband,Type=ButterWorth';
    %end
    %cochleaConfig.Force_IHC_on_CPU = 1;
    cochleaConfig.Disable_Lambda = 0;
    if ( disableLambda )
        cochleaConfig.Disable_Lambda = 1;
    end
    if ( ~disableLambda )
        cochleaConfig.IHC_Vector = IHC_BASE;
        %cochleaConfig.Nerves_File = [pwd '\cochlea_reserved_nerves_test' num2str(idConfig) '.bin'];
    end
    %cochleaConfig.Review_Lambda_Memory = 1;
    %cochleaConfig.Review_AudioGramCall = 1;
    %cochleaConfig.General_Debug = 1;
    cochleaConfig.Output_Result = [pwd '\Data\output_results_test' num2str(idConfig*10) '.bin'];
    if ( ~disableLambda )
        cochleaConfig.Lambda_High = [pwd '\Data\lambda_high_test' num2str(idConfig*10) '.bin'];
        cochleaConfig.Lambda_Medium = [pwd '\Data\lambda_medium_test' num2str(idConfig*10) '.bin'];
        cochleaConfig.Lambda_Low = [pwd '\Data\lambda_low_test' num2str(idConfig*10) '.bin'];
    end
    % writing healthy profiles
%     write_array(cochleaConfig.Gamma_File,OHC_BASE*ones(1,SECTIONS));
%     if ( ~disableLambda )
%         write_array(cochleaConfig.Nerves_File,IHC_BASE*ones(1,SECTIONS));
%     end
    cochleaConfig.configFile = [pwd '\cochlea_reserved_file' num2str(idConfig) '.par'];
    cochleaConfig.writeFile();
end