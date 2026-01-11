function [ SignalObject ] = getFileSample( Fs,signal,run_time,start_sample,divider,offset )
%GETFILESAMPLE Summary of this function goes here
%   Detailed explanation goes here
if ( ~exist('divider','var') )
    divider = 10;
end
if ( ~exist('offset','var') )
    offset = 0.01;
end
signal_name = 'target_signal';
if ( ischar(signal) )
    if ( isempty(regexpi(signal,'\.(wav|bin)$','ONCE')) )
        signal = [signal '.wav'];
    end
    [Full_SN,FsDisc] = audioread(signal); 
    signal_data_name = regexpi(signal,'(?<filename>[a-zA-Z0-9_\s]+)(\.[a-zA-Z0-9]+)?$','names');
    signal_name = signal_data_name.filename;
else
    Full_SN = signal;
    FsDisc = Fs;
    run_time = min(run_time,length(signal)/Fs);
end
    if ( ~exist('start_sample','var') || start_sample < 1 )
        start_sample = 1; % randomly start after 50,000 samples (~ 1 second)
    end
    start_sample = max(start_sample,1);
    
    if ( exist('run_time','var') )
        end_point = min(length(Full_SN),start_sample+run_time*FsDisc-1);
        SN = Full_SN(start_sample:end_point);
        run_time = length(SN)/FsDisc;
    else
        SN = Full_SN;
        run_time = length(SN)/Fs;
    end
    [p,q] = rat(Fs/FsDisc,1e-4);
    SignalObject = struct();
    SignalObject.data = resample(SN,p,q)';
    SignalObject.name = signal_name;
    SignalObject.tag_name = signal_name;
    SignalObject.full_name = [pwd '\' SignalObject.name];
    SignalObject.bytes = length(SignalObject.data)*8;
    SignalObject.length = run_time;
    SignalObject.max = max(SignalObject.data);
    i1 = find(SignalObject.data>SignalObject.max/divider, 1, 'first');
    i1 = max(i1-floor(Fs*offset),1);
    i2 = find(SignalObject.data>SignalObject.max/divider, 1, 'last');
    i2 = min(i2+floor(Fs*offset),floor(Fs*SignalObject.length));
    
    i1=1; i2=length(SignalObject.data);
    %fprintf("signal %s,sample %d,%d,%d\n",signal,i1,i2,length(SignalObject.data));
    SignalObject.data_cut = SignalObject.data(i1:i2);
    SignalObject.length_cut = length(SignalObject.data_cut)/Fs;
   
    %plot(SignalObject.data_cut)
 
 
end

