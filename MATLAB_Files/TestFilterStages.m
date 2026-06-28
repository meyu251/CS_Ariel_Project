% TestFilterStages.m
%
% GPU version of TestLambdaCPU.m:
% Takes the same BM velocity interval and runs the IHC pipeline on the GPU,
% capturing the output after each stage via TEST_File_Target.
%
% No MATLAB filter is applied — results come directly from cuda_Buffer1
% (AudioGramCreator.cpp:966, params.cpp stages 9-14).

clear all

%% ── Load BM velocity — identical to TestLambdaCPU.m ─────────────────────
load bm_velocity_result.mat
in     = 58 * 4000;
bm_vel = bm_vel(1:256, in+1:in+4000);   % [256 x 4000], same interval

[SECTIONS, N] = size(bm_vel);
fprintf('Interval: %d sections x %d samples\n', SECTIONS, N);

%% ── Parameters — identical to TestLambdaCPU.m ───────────────────────────
load Final_Parameters   % Aihc, eta_AC, eta_DC, spontRate, ...

Fs     = 20000;
Tdelta = 0.002;

AC_Filter_Vector = getTimeSynapsesIIR(Fs, 300, 1800, 3, 30);

%% ── Build cochleaConfig for a single interval run ────────────────────────
parallel.gpu.enableCUDAForwardCompatibility(true)

cochleaConfig = configCochlea();

% Timing: N samples at Fs = 0.2 seconds, single time block
cochleaConfig.Fs               = Fs;
cochleaConfig.Duration         = N / Fs;          % 0.2 seconds
cochleaConfig.Time_Block_Length = N / Fs;          % one block = full interval
cochleaConfig.Overlap_Time     = 0.005;
cochleaConfig.Processed_Interval = N / Fs;

% Start from BM velocity — skip the BM/OHC computation
% C++ layout: [s0_t0, s1_t0, ..., s255_t0, s0_t1, ...] = bm_vel(:) in MATLAB
cochleaConfig.Run_Stage_Calculation = 1;
cochleaConfig.Run_Stage_Vector      = single(bm_vel(:))';

% IHC / lambda parameters
cochleaConfig.OHC_Vector  = 0.5;
cochleaConfig.IHC_Vector  = 8;
cochleaConfig.OHC_Mode    = 1;
cochleaConfig.IHC_Mode    = 1;
cochleaConfig.eta_AC      = eta_AC;
cochleaConfig.eta_DC      = eta_DC;
cochleaConfig.Tdelta      = Tdelta;
cochleaConfig.Lambda_SAT  = 500;
cochleaConfig.Scale_BM_Velocity_For_Lambda_Calculation = 0.01;

% AC filter — same source as TestLambdaCPU.m
cochleaConfig.AC_Filter_Vector = AC_Filter_Vector;
cochleaConfig.Filter_Mode      = 2;

% Aihc (nerve amplification per section)
cochleaConfig.Aihc = Aihc;

% Match kernel mode used in CalculateJNDfiles2
cochleaConfig.Decouple_Unified_IHC_Factor = 0;

% Disable outputs we don't need
cochleaConfig.Sim_Type               = 0;
cochleaConfig.Calculate_JND          = 0;
cochleaConfig.Disable_Lambda         = 0;
cochleaConfig.Allowed_Outputs        = 0;
cochleaConfig.Discard_Lambdas_Output = 1;
cochleaConfig.Discard_BM_Velocity_Output = 1;

%% ── Run each stage on the GPU ────────────────────────────────────────────
% For each stage: set TEST_File_Target + Type_TEST_Output, call ProcessAudioLab.
% GPU writes raw float32 to bin_file from cuda_Buffer1.
% Layout: [s0_t0, s1_t0, ..., s255_t0, s0_t1, ...] -> reshape(raw,256,[])

stage_names = {'AC', 'Shigh', 'dS', 'DC', 'IHC', 'PRE_IHC'};
stages      = struct();

for k = 1:numel(stage_names)
    name     = stage_names{k};
    bin_file = fullfile(tempdir(), ['stage_' name '.bin']);

    fprintf('GPU stage: %s\n', name);

    cochleaConfig.TEST_File_Target = bin_file;
    cochleaConfig.Type_TEST_Output = name;

    ProcessAudioLab(cochleaConfig);

    fid  = fopen(bin_file, 'rb');
    raw  = fread(fid, inf, 'float32');
    fclose(fid);

    data          = reshape(raw, 256, []);
    stages.(name) = data;
    fprintf('  -> [%d x %d]   min=%.4e  max=%.4e\n', ...
        size(data,1), size(data,2), min(raw), max(raw));
end

%% ── Save ─────────────────────────────────────────────────────────────────
save('filter_stages_result.mat', 'stages');
fprintf('\nSaved filter_stages_result.mat\n');

%% ── Compare against reference from the other machine ────────────────────
%
%  Machine A: run -> filter_stages_result.mat
%             copy to machine B, rename: filter_stages_reference.mat
%  Machine B: run -> compares automatically

ref_file = fullfile(fileparts(mfilename('fullpath')), 'filter_stages_reference.mat');

if ~isfile(ref_file)
    fprintf('\nNo reference file found.\n');
    fprintf('Copy filter_stages_result.mat from the other machine,\n');
    fprintf('rename it filter_stages_reference.mat, then re-run.\n');
    return
end

ref        = load(ref_file, 'stages').stages;
first_diff = '';

fprintf('\n=== Stage-by-stage comparison: local vs reference ===\n');

for k = 1:numel(stage_names)
    name  = stage_names{k};
    local = stages.(name);
    refv  = ref.(name);

    if ~isequal(size(local), size(refv))
        fprintf('[%s] Size mismatch: local=%s  ref=%s\n', ...
            name, mat2str(size(local)), mat2str(size(refv)));
        continue
    end

    abs_diff    = abs(local - refv);
    max_diff    = max(abs_diff(:));
    rel_err     = norm(abs_diff(:)) / (norm(refv(:)) + eps);
    exact_match = isequal(local, refv);

    fprintf('--- %-10s  exact=%-5s  max_diff=%.4e  rel_err=%.4e\n', ...
        name, mat2str(exact_match), max_diff, rel_err);

    if ~exact_match && isempty(first_diff)
        first_diff = name;
        fprintf('    *** FIRST DIVERGENCE HERE ***\n');
    end

    if max_diff > 0
        figure;
        imagesc(abs_diff');
        colorbar;
        title(sprintf('|%s  local - reference|', name));
        xlabel('Section (1-256)');
        ylabel('Time sample');
    end
end

if isempty(first_diff)
    fprintf('\nAll stages identical between the two machines.\n');
else
    fprintf('\nFirst divergence at stage: %s\n', first_diff);
    fprintf('All later stages are likely affected.\n');
end
