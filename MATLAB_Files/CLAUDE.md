# MATLAB_Files/ — Scripts Reference

## Workflow: Normal usage (step by step)

1. **Set cochlear parameters:** Run `SetCochlearParameters.m` (or `SetCochlearParametersNew.m`) in MATLAB workspace. This defines `Fs=20000`, `lambda_spont`, `Aihc` cell array, `SPLref`, filter params, etc. — loaded into the workspace as variables.
2. **Load ISO standard:** Run `ISO226_2003.m` to get ISO 226:2003 equal-loudness contours (`Freq`, `ISO_Thres`).
3. **Run the test:** Call `CalculateJNDfiles2(f, noise, run_time, En, testedPowerLevels, OHC_Vector, IHC_Vector)` where:
   - `f` = frequency array (Hz), e.g. `[250 500 1000 2000 4000 8000]`
   - `noise` = WAV file name (e.g. `'ISOnoise.wav'`)
   - `run_time` = seconds per interval (typically 0.2 s)
   - `En` = noise power in dBSPL (use `1111` = silence = `-Inf dB`)
   - `testedPowerLevels` = signal sweep e.g. `-10:5:120`
   - `OHC_Vector` = 0.5 (healthy) or 0–0.5 (impaired)
   - `IHC_Vector` = 8.0 (healthy) or 5–8 (impaired)
4. **The chain:** `CalculateJNDfiles2` → `preAnalyzeFile` → `analyzeFile` → `ProcessAudioLab` → `AudioLabCM` MEX.
5. **Output:** `[jnd_final, jnd_rms]` — JND thresholds per frequency and noise level.
6. **Enable BM velocity output:** Set `'Allowed_Outputs', 1` and `'Discard_BM_Velocity_Output', 0` in `analyzeFile` call. Result is in `analyzed.output_results` (float vector, `N_samples × 256`).
7. **Enable Lambda output:** Set `'Allowed_Outputs', 14` AND `'Discard_Lambdas_Output', 0`. Result is in `analyzed.lambda_high`, `analyzed.lambda_medium`, `analyzed.lambda_low`.

**CRITICAL NOTE on Allowed_Outputs:** `preAnalyzeFile.m` always inserts `Allowed_Outputs=0` as default. If you pass `Discard_BM_Velocity_Output=0` but NOT `Allowed_Outputs=1`, the Discard flag sets bit 0 internally but then `Allowed_Outputs=0` from preAnalyzeFile overwrites it. Always pass both explicitly. See `BM_Velocity_Lambda_Output_Guide.txt` for full details.

---

## configCochlea.m
**Purpose:** MATLAB class (`classdef configCochlea < matlab.mixin.SetGet`) that is the configuration container for the MEX function. Holds ~100 parameters as properties.
**Key properties:**
- `Fs` — sample rate (default 20000 Hz)
- `Sim_Type` — 0=voice/file, 1=sine, 3=profile generation, 4=JND complex calculation
- `OHC_Vector`, `OHC_Mode` — outer hair cell health (0=deaf, 0.5=healthy); Mode=1 to use vector
- `IHC_Vector`, `IHC_Mode` — inner hair cell health (5=impaired, 8=healthy); Mode=1 to use vector
- `Calculate_JND` — boolean, enable JND calculation
- `JND_Interval_Duration` — seconds per JND interval
- `testedFrequencies`, `testedPowerLevels`, `testedNoises` — Cartesian product for JND sweep (only active for Sim_Type 3 or 4)
- `AC_Filter_Vector` — direct IHC AC bandpass filter coefficient array
- `Filter_Mode` — 0=from file, 1=from function, 2=from vector (use 2 with AC_Filter_Vector)
- `Input_Signal`, `Input_Noise` — audio data as double vectors (embedded directly, no file needed)
- `Run_Stage_Calculation` — 0=full, 1=start from BM velocity, 2=start from lambda
- `Run_Stage_Vector` — single-precision float vector for Run_Stage_Calculation=1 (BM velocity input)
**Key computed properties:**
- `evaluatedStruct` — assembles all non-empty, non-excluded properties into a plain MATLAB struct
- `evaluatedMatStruct` — same but also embeds `Input_Signal` and `Input_Noise` as double arrays (needed since MEX cannot receive arbitrary cell arrays, only struct)
**Non-obvious:**
- Properties in `semiDynamicProps` list are included only if non-empty (nil = use C++ default).
- `Sim_Type=3` or `4` excludes `Duration` from the struct (duration is inferred from the tested profiles grid).
- `Sim_Type != 3 and != 4` excludes `testedFrequencies`, `testedPowerLevels`, `testedNoises`.
- `creatingDatabase=1` enables a legacy database-creation mode.

---

## ProcessAudioLab.m
**Purpose:** Thin wrapper that calls `AudioLabCM(matStruct)` MEX and returns the result.
**Inputs:** `configObject` — a `configCochlea` instance.
**Outputs:** `result` (MEX output struct), `matStruct` (the evaluated struct passed in — for debugging).
**Non-obvious:** Calls `configObject.evaluatedMatStruct` which is the struct version of all config properties, with `Input_Signal` and `Input_Noise` embedded as double arrays. The MEX function parses this struct field by field in `CParams::parseMexFile`.

---

## analyzeFile.m
**Purpose:** Main analysis entry point that prepares the cochleaConfig object and calls ProcessAudioLab. Returns the full result struct.
**Inputs:** `varargin{1}` must be an `inputStruct` with at minimum `filesStruct` (signal file information) or `basicTest=true`. Additional name-value pairs override defaults.
**Outputs:** `[result, matStruct, inputStruct]`
**Chain:** `analyzeFile` → `preAnalyzeFile` (builds cochleaConfig) → `ProcessAudioLab` → MEX.
**Non-obvious:** Timer is started with `tic` and ended with `endTimer(...)` which prints duration. The `inputStruct.JND_Signal_Source` flag (1=from file, 0=generate tones) determines the timer message.

---

## preAnalyzeFile.m
**Purpose:** Converts an `inputStruct` (with file references and test parameters) into a `configCochlea` object ready for MEX call. Sets all defaults.
**Critical defaults (set here, can be overridden by caller):**
- `Discard_BM_Velocity_Output = 1` — BM velocity NOT saved by default
- `Discard_Lambdas_Output = 1` — Lambda NOT saved by default  
- `Allowed_Outputs = 0` — no outputs by default
- `Run_Fast_BM_Calculation = 22` — fast BM mode enabled
- `JND_Noise_Source = 0` — noise is self-generated (not from file)
- `Normalize_Sigma_Type = 0` — normalize noise sigma to 1
- `spontRate` — loaded from `Final_Parameters` as `lambda_spont`
**Non-obvious:** Loads `Final_Parameters.mat` which contains model calibration data (`Aihc`, `SPLref`, `lambda_spont`, etc.). The file must be on the MATLAB path. Also calls `gpuDevice()` to warm up the GPU unless `Disable_GPU_Scan=true`.

---

## CalculateJNDfiles2.m
**Purpose:** High-level JND calculation function — builds a sweep of power levels and noise levels, calls `analyzeFile` for each batch.
**Signature:** `[jnd_final, jnd_rms, lambda_output] = CalculateJNDfiles2(AudioFreq, noise, run_time, En, testedPowerLevels, OHC_Vector, IHC_Vector, PrescriptionName)`
**Logic:**
1. Loads `Final_Parameters.mat`.
2. Computes GPU memory limit: `maxSeconds = g.TotalMemory/(120*1024*1024)` — limits how many power levels can be batched per MEX call.
3. Generates AC filter: `getTimeSynapsesIIR(20000, 300, 1800, 3, 30)`.
4. Loops over noise levels and batches of power levels, calling `analyzeFile` with the assembled `inputStruct`.
5. Collects JND results from returned struct.
**Non-obvious:**
- `En=1111` is the sentinel value for "no noise" (maps to -∞ dB).
- `JND_Noise_Source=1` means noise comes from the `noise` WAV file.
- `powerLevelsPerRun` batch size is reduced if GPU memory would be exceeded.
- The function adds `'Allowed_Outputs', 0` by default — to get BM velocity or lambda, pass overrides as name-value pairs to `analyzeFile`.
- `Hearing_Aid_Prescription=1` is a placeholder (the actual prescription calculation is commented out).

---

## SetCochlearParameters.m / SetCochlearParametersNew.m
**Purpose:** Script (not function) that defines all physical model calibration constants in the MATLAB workspace. Run before any simulation.
**Key values defined:**
- `Fs=20000` — sample rate
- `Aihc={Aihc_H, Aihc_M, Aihc_L}` — IHC amplitude arrays (70, 26, 5 spikes/s per section per SR group)
- `lambda_sat=500` — max firing rate [spikes/s]
- `lambda_spont=[60; 3; 0.1]` — spontaneous rates for high/medium/low SR fibers
- `M=120` — number of auditory fibers per section (total = 256×120 ≈ 30720 ≈ AN_FIBERS)
- `eta_AC=1` — IHC AC coupling [V/s/cm]
- `eta_DC=100` — IHC DC coupling [V/cm]
- `SPLref=4e-8` (SetCochlearParameters) or `5e-8` (SetCochlearParametersNew) — SPL reference pressure [Pa]
- `w=[0.61; 0.23; 0.16]` — fiber group weights for JND pooling
- `Scale_BM_Velocity_For_Lambda_Calculation=1` — use cm/s (not m/s) for lambda calculation
- Filter design params: `Apass=3 dB`, `Astop=30 dB`, `Fpass=300 Hz`, `Fstop=1800 Hz`
**Non-obvious:** `SetCochlearParametersNew.m` differs from old only in `SPLref` value (5e-8 vs 4e-8). The new one reflects a model recalibration. Use new unless explicitly reproducing old results.

---

## ParametersDefinition.m
**Purpose:** Legacy script that sets some derived cochlear parameters, loads `Final_Parameters`, and fits a parabola to IHC audiogram data. Mostly used by `FindHCfromAudioTest`.
**Non-obvious:** Calls `ISO226_2003` for equal-loudness data, uses `fitParabola` for audiogram fitting. Depends on `Parabolicfit.mat` being on path.

---

## ISO226_2003.m
**Purpose:** Defines equal-loudness contour data per ISO 226:2003. Produces `Freq` (frequency array) and `ISO_Thres` (threshold in dBSPL) in workspace. Used as the "normal hearing" reference baseline for JND threshold comparison.

---

## GetTunedAudiograms.m
**Purpose:** Defines `TunedAudiograms` — a 10×8 matrix of hearing threshold values in dBHL for 10 pre-defined hearing-impaired profiles at 8 audiometric frequencies (250–8000 Hz). Used for benchmarking the cochlear model against clinical audiograms.

---

## TestIsoNormal.m
**Purpose:** Runs a JND calculation for normal hearing (OHC=0.5, IHC=8) across ISO standard frequencies and compares against the ISO 226:2003 threshold. Plots result on a log-frequency axis.
**Usage:** Edit `f` array (default `Freq(1:20)`), run. Plots simulation JND threshold vs ISO curve.

---

## TestRms.m
**Purpose:** Test script for a single frequency (default 8000 Hz) with noise masking, comparing simulation to reference from another machine. Also demonstrates how to enable Lambda output.
**What it does:**
1. Calls `CalculateJNDfiles2` with `lambda_val` output (3rd return).
2. Saves `lambda_result.mat`.
3. If `lambda_reference.mat` exists (copied from another machine), computes and displays exact match / max abs diff / relative error.
**Non-obvious:** This script is the cross-machine validation tool. See `BM_Velocity_Lambda_Output_Guide.txt` for how to set up the comparison.

---

## TestFilterStages.m
**Purpose:** Tests the IHC pipeline GPU stages individually. Loads a pre-computed BM velocity (`bm_velocity_result.mat`), then runs AudioLabCM in `Run_Stage_Calculation=1` mode (start from BM velocity, skip BM/OHC solve). Captures intermediate stage outputs via `TEST_File_Target`.
**Non-obvious:**
- `Run_Stage_Vector = single(bm_vel(:))'` — BM velocity must be passed as a single-precision row vector, in C-order (all sections for time 0, then all for time 1, etc.). MATLAB column-major needs explicit reshape.
- `Scale_BM_Velocity_For_Lambda_Calculation = 0.01` — converts cm/s to m/s for lambda calculation in this mode.
- `Time_Block_Length = N/Fs` — forces a single time block (all samples in one block).

---

## TestIsoNormalNoise.m
**Purpose:** Similar to `TestIsoNormal.m` but with a noise masker. Tests signal JND in the presence of noise at a given noise level.

---

## TestSignalNoise.m
**Purpose:** Signal + noise JND test variant.

---

## TestHairCellEstimation.m
**Purpose:** Estimates OHC/IHC parameters from a patient audiogram. Uses the audiogram database created by `FindHCfromAudioTest`. Tests that `FindHCfromAudio` / `EstimateHairCellTuned` routines recover the correct parameters.

---

## FindHCfromAudioTest.m / FindHCfromAudio.m
**Purpose:** Given a clinical audiogram (hearing thresholds at several frequencies), finds the best-matching OHC and IHC parameter combination from a pre-computed database (`AudiogramsDataBase{Nf}_Big.mat`).
**Logic:**
1. Loads `AudiogramsDataBase{Nf}_Big.mat` — a grid of `IHCvsTh(OHCi).Th(IHCj,:)` threshold predictions for all (OHC, IHC) combinations.
2. Finds the (OHC, IHC) pair minimizing MSE to the patient's audiogram.
3. Uses `FindCFohc(f, OHC0)` to map audiogram frequencies to cochlear positions.
4. Interpolates IHC at the patient's audiogram frequencies.
**Non-obvious:** The database must be pre-generated (not included in repo). `Nf` is the number of audiometric frequencies (6 or 8).

---

## EstimateHairCellTuned.m
**Purpose:** Estimates hair cell parameters with additional tuning/interpolation over the audiogram database.

---

## PlotResultsTest.m
**Purpose:** Plots JND results from a test run, comparing against reference audiograms.

---

## PlotTunedResults.m
**Purpose:** Plots tuned audiogram results after hair cell estimation.

---

## SetParametersA.m
**Purpose:** Sets additional parameters variant (alternative to SetCochlearParameters).

---

## SetCochlearParametersOld.m
**Purpose:** Legacy version of SetCochlearParameters (old calibration values). Keep for backward compatibility only.

---

## getTimeSynapsesIIR.m
**Purpose:** Designs an IIR bandpass filter for the IHC AC synapse pathway.
**Signature:** `AC_Filter_Vector = getTimeSynapsesIIR(Fs, Fpass, Fstop, Apass, Astop)`
**Default call:** `getTimeSynapsesIIR(20000, 300, 1800, 3, 30)` — 300-1800 Hz bandpass, 3 dB ripple, 30 dB stop attenuation.
**Output format:** coefficient array in format expected by `CParams::AC_Filter_Vector` and decoded by `HFunction::decodeBinFile`.

---

## lowPassFilterSynapseIIR.m
**Purpose:** Designs the IHC DC (low-pass) filter component.

---

## getFileSample.m
**Purpose:** Reads an audio file (WAV or binary) and cuts it to specified duration.
**Signature:** `SignalObject = getFileSample(Fs, filename, duration, offset, power_dB, normalize)`
**Output:** struct with `data` (audio samples), `data_cut` (trimmed), `length_cut` (samples).
**Non-obvious:** Resamples to `Fs` if the file's native sample rate differs.

---

## preAnalyzeFile.m (extended notes)
**Purpose** (see main entry above). Additional notes:
- `inputStruct.filesStruct` must have a `tag_name` field (used in log messages).
- The `Oded_Method=1` / `Yonatan_Method=0` flags select between two JND aggregation algorithms (named after researchers).
- `Complex_Profile_Power_Level_Divisor=0` means power levels are not divided/compressed.

---

## endTimer.m
**Purpose:** Prints elapsed time with `toc` using a printf-style format string. Called at the end of `analyzeFile` to report run duration.

---

## loadCochleaConfig.m
**Purpose:** Loads a saved `configCochlea` object from disk. Used to restore a previous configuration for re-running.

---

## convertNameValue2Struct.m
**Purpose:** Converts MATLAB `varargin` name-value pairs into a struct (merging with the first argument which is already a struct). Used in `preAnalyzeFile` to handle additional overrides passed to `analyzeFile`.

---

## fitParabola.m
**Purpose:** Fits a parabola to IHC audiogram data (used in `ParametersDefinition.m` for parameter estimation).

---

## FindCFohc.m
**Purpose:** Maps audiometric frequencies to cochlear positions (cm) using the Greenwood function or OHC-based characteristic frequency map.

---

## getDefaultTestedFrequencies.m
**Purpose:** Returns the default audiometric frequency array: `[250 500 1000 2000 3000 4000 6000]` Hz.

---

## BM_Velocity_Lambda_Output_Guide.txt
**Purpose:** Engineering guide (written in Hebrew + English) documenting how to enable BM velocity and Lambda outputs from the MEX function, including the subtle `Allowed_Outputs` bitmask interaction bug and cross-machine comparison procedure.
**Critical points summarized:**
- By default in `preAnalyzeFile.m`: `Discard_BM_Velocity_Output=1`, `Discard_Lambdas_Output=1`, `Allowed_Outputs=0` — NO outputs saved.
- **BM velocity:** Pass `'Allowed_Outputs', 1` AND `'Discard_BM_Velocity_Output', 0` to `analyzeFile`. Result in `analyzed.output_results`.
- **Lambda:** Pass `'Allowed_Outputs', 14` (= bits 1+2+3) AND `'Discard_Lambdas_Output', 0`. Result in `analyzed.lambda_high/medium/low`.
- Cannot get BM velocity and Lambda in the same call (choose one).
- **GPU architecture gotcha:** MEX compiled for `sm_120` (Blackwell/RTX 50xx) running on `sm_61` (GTX 1080, Pascal) will use JIT via PTX and may give wrong results. Fix: add `61` to `CMAKE_CUDA_ARCHITECTURES` in CMakeLists.txt.

---

## MEX binary variants (MATLAB_Files/)
- `AudioLabCM.mexw64` — **current production** binary (in MATLAB_Files, copy here to use)
- `NewAudioLabCM.mexw64` — newer build (sometimes used to A/B test)
- `New2AudioLabCM.mexw64` — another build variant
- `OldAudioLabCM.mexw64` — legacy build (kept for regression comparison)
- `build25/bin/AudioLabCM.mexw64` — latest build output from build25 folder
- `buildDebug/bin/AudioLabCMd.mexw64` — debug build with extra assertions
**Non-obvious:** The root `MATLAB_Files/` directory is what MATLAB uses (must be on path). The various `New*`/`Old*` binaries are kept for A/B testing as shown in `TestIsoNormal.m` (commented-out lines show copying between them).
