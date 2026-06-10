%TestIsoNormal
clear all
%close all
tic

ISO226_2003 %Read ISO threshold and Freq
%load ResultsFinal2016

noise='MaskedNoise.wav';
[Noisein, FsIn] = audioread(noise);
%En1=db(sqrt(mean(Noisein.*Noisein))/(2e-5));
En = 1111;

Fs=20000;
run_time=0.2;
testedPowerLevels = -10:1:120;
%f=[100, 250,500,1000,2000,3000,3500,4000,8000];
f=[8000];
OHC_Vector=0.5; IHC_Vector=8;
[JNDrefNew, JNDRms, lambda_val] = CalculateJNDfiles2( f,noise,run_time,En,testedPowerLevels,OHC_Vector, IHC_Vector);

JNDrefNew

save('lambda_result.mat', 'lambda_val');

%% Compare with reference from another machine
% Instructions:
%   1. Copy 'lambda_result.mat' from the OTHER computer and rename it
%      'lambda_reference.mat' in the same folder.
%   2. Run this section to see how similar the two results are.

ref_file = fullfile(fileparts(mfilename('fullpath')), 'lambda_reference.mat');
if isfile(ref_file)
    ref = load(ref_file, 'lambda_val');
    lambda_ref = ref.lambda_val;

    if ~isequal(size(lambda_val), size(lambda_ref))
        fprintf('Size mismatch: local=%s  reference=%s\n', ...
            mat2str(size(lambda_val)), mat2str(size(lambda_ref)));
    else
        abs_diff    = abs(lambda_val - lambda_ref);
        max_diff    = max(abs_diff(:));
        ref_norm    = norm(lambda_ref(:));
        rel_err     = norm(abs_diff(:)) / ref_norm;
        exact_match = isequal(lambda_val, lambda_ref);

        fprintf('--- Lambda comparison ---\n');
        fprintf('Exact match    : %s\n',  mat2str(exact_match));
        fprintf('Max abs diff   : %.6e\n', max_diff);
        fprintf('Relative error : %.6e\n', rel_err);

        % Visual diff
        figure;
        imagesc(reshape(abs_diff, 256, [])');
        colorbar;
        title('|lambda local - lambda reference|');
        xlabel('Section'); ylabel('Time sample');
    end
else
    fprintf('No reference file found. Copy lambda_result.mat from the other\n');
    fprintf('machine, rename it lambda_reference.mat, and re-run.\n');
end
