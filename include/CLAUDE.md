# include/ — Header Files Reference

## const.h  (CRITICAL — read this first)
**Role:** Single header defining ALL compile-time constants. Every other file includes this.
**Critical values:**
| Constant | Value | Meaning |
|----------|-------|---------|
| `SECTIONS` | 256 | Spatial sections along cochlea length (3.5 cm / 256 = 0.01367 cm each) |
| `TIME_SECTIONS` | 8 | CUDA blocks processed in parallel (= 8 time blocks per GPU launch) |
| `SAMPLE_RATE` | 20000 | Default sample rate in Hz |
| `TIME_SECTION` | 21000 | Length of one time block in microseconds (21 ms) |
| `TIME_OFFSET` | 5000 | Overlap/transient period in microseconds (5 ms) |
| `CONST_TIME_STEP_VAL` | 1e-6 | Fixed ODE time step in seconds (1 µs) |
| `LAMBDA_COUNT` | 3 | Number of auditory nerve fiber populations |
| `_CUDA_JACOBBY_LOOPS` | 10 | Fast Jacobi iterations in GPU BM solver |
| `_CUDA_JACOBBY_LOOPS1` | 20 | Slow (convergence-checked) Jacobi iterations |
| `_CUDA_OUTERN_LOOPS` | 10 | Outer control loop limit |
| `MODEL_FLOATS_CONSTANTS_SIZE` | 64 | GPU constant memory: float params count |
| `AN_FIBERS` | 30000 | Total auditory nerve fibers in model |
| `HEALTY_IHC` | 8.0 | IHC health value for normal hearing |
| `HEALTY_OHC` | 0.5 | OHC gamma for normal hearing |

**Physical constants (BM):**
- `M0=1.268e-6, M1=1.5` — BM mass density: `M(x) = M0 * exp(M1 * x)`
- `R0=0.25, R1=-0.06` — BM resistance: `R(x) = R0 * exp(R1 * x)`
- `S0=1.282e4, S1Cochlear=-1.5` — BM stiffness: `S(x) = S0 * exp(S1 * x)`
- Stiffness decreasing from base (high freq) to apex (low freq) creates tonotopic map.

**Oval window (middle ear):**
- `W_OW = 2π×1500` — middle ear resonance angular frequency (~1.5 kHz)
- `SIGMA_OW=0.5` — oval window mass density [g/cm²]
- `GAMMA_OW=20e3` — damping constant [1/s]
- `C_ME` — ossicle mechanical gain (~6×10⁶)

**IHC/AN constants:**
- `HIGH_FREQ_NERVE=70, MEDIUM_FREQ_NERVE=50, LOW_FREQ_NERVE=30` — spontaneous rates [spikes/s]
- `SPONT_HIGH_RATE=60, SPONT_MEDIUM_RATE=3, SPONT_LOW_RATE=0.1`
- `FIBER_HIGH_DIST=0.61, FIBER_MEDIUM_DIST=0.23, FIBER_LOW_DIST=0.16` — fraction of AN fibers per group

**dB conversion:**
- `CONV_dB_TO_AMP(a)` = `10*(20e-6)*pow(10, a/20)` — converts dBSPL to amplitude [cm/s], using SPL reference of 20 µPa

**Output flags:**
- `SIM_TYPE_VOICE=0, SIM_TYPE_SIN=1, SIM_TYPE_PERF=2, SIM_TYPE_PROFILE_GENERATING=3, SIM_TYPE_JND_COMPLEX_CALCULATIONS=4`
- `CALC_LAMBDA_FLAG=1` — enables lambda computation
- `CUFFT_FLAG=1` — enables cuFFT path for frequency-domain lambda

**Non-obvious:**
- `ACTIVE_GAMMA_FLAG=false` means OHC gamma does NOT change dynamically during simulation (static hearing loss model).
- `OHC_NL_FLAG=true` means the nonlinear `tanh(x)` OHC function is used (not linearized).
- `OW_FLAG=true` means oval window boundary condition is active.
- `lambdaFloat` and `JNDFloat` are both `typedef float` — easy to switch to double for higher precision.

---

## solver.h
**Role:** Declares `CSolver` — the main simulation orchestrator.
**Key public members:**
- `input_params` (CParams*) — pointer to param array
- `_now`, `_past` (CState*) — two time-state objects for predictor-corrector integration
- `_model` (CModel*) — cochlear physical model
- `_TriMat` (CTriDiag) — pre-factored tri-diagonal matrix
- `creator` (AudioGramCreator*) — IHC/lambda pipeline
- `_input_buffer` (vector<double>) — pre-loaded input audio samples
- `deviceProp` (cudaDeviceProp) — GPU device info
**Key inline helpers:**
- `getCalcTime(write_time)` — rounds up `write_time` to the nearest multiple of `THREADS_PER_IHC_FILTER_SECTION=64` for GPU alignment
- `getWriteTime(params, remain_time)` — calculates number of time nodes to output for a partial interval
- `maxTimeBlocks()`, `longestTimeBlock()`, `inputBufferTimeNodes()`, `bufferResultsSpeeds()` — buffer sizing helpers that find the worst-case across all param sets
- `continueRunningInputFile(i)` — true if still audio left to process
- `continueRunningProfileGenerator(i, from_profile_index)` — true if more JND test profiles remain

---

## model.h
**Role:** Declares `CModel` — fixed cochlear physical parameters (not time-varying).
**All fields are `const` after construction** (the BM mass/stiffness/resistance are fixed, only gamma changes state).
**Key vectors (all length 256):**
- `_M_bm`, `_R_bm`, `_S_bm` — BM mass, resistance, stiffness per section
- `_M_tm`, `_R_tm`, `_S_tm` — TM (tectorial membrane) parameters
- `_S_ohc` — OHC stiffness
- `_Q` = `2*rho*beta/(area*_M_bm)` — coupling factor for pressure equation
- `_w_cf_pow2` = `_S_bm/_M_bm` — characteristic frequency squared per section
**Key scalars:**
- `_a0`, `_a1`, `_a2` — boundary condition coefficients for oval window
- `_OW_flag`, `_OHC_NL_flag`, `_active_gamma_flag` — feature flags
**Multi-config finders:** `firstLambdaEnabled()`, `firstJNDCalculationSet()`, `firstJNDCalculationSetONGPU()`, `firstGeneratedInputSet()`, `maxJNDIntervals()` — these scan the `configurations` (SubModel) array to find the first/max relevant param set index.

---

## state.h
**Role:** Declares `CState : public ode` — a single time snapshot of the cochlear state.
**Key vectors (all length 256):**
- `_BM_disp`, `_BM_sp`, `_BM_acc` — BM displacement, speed, acceleration [cm, cm/s, cm/s²]
- `_p_ohc`, `_d_p_ohc` — OHC pressure and its derivative [Pa]
- `_psi_ohc`, `_d_psi_ohc` — OHC basolateral potential [V] and derivative
- `_deltaL_disp` — OHC electromotility length change [m]
- `_TM_disp`, `_TM_sp` — tectorial membrane displacement and speed
- `_p_TM` — TM pressure [Pa]
- `_G`, `_Y` — RHS vectors for the pressure PDE: `∂²P/∂t² - Q(x)·P = G(x,t)`, solved as `U·P = Y`
- `_pressure` — net pressure on BM per section
**Key scalars:**
- `_OW_disp`, `_OW_sp`, `_OW_acc` — oval window (stapes) motion
- `_bc` — OW boundary condition value at x=0
**Key methods:**
- `get_sample()` — returns current acoustic input sample (interpolated from `_input_buffer`)
- `gen_new_sample()` — generates next sine input sample (for SIM_TYPE_SIN)
- `copy_state(obj)` — deep-copies all state vectors from another CState

---

## params.h
**Role:** Declares `CParams` — the massive runtime configuration struct (~250 public members).
**Input/file params:** `in_file_name`, `gamma_file_name`, `nerve_file_name`, `output_file_name`, `lambda_high/medium/low_file_name`, `ac_filter_file_name`.
**Signal params:** `Fs` (long, sample rate), `sin_freq`, `sin_dB`, `sin_amp`, `duration`, `offset`, `sim_type`.
**OHC/IHC params:** `ohc_mode` (0=from file, 1=from vector), `ihc_mode`, `ohc_vector` (vector<float>), `ihc_vector` (vector<float>).
**JND params:** `Calculate_JND` (bool), `JND_Interval_Duration`, `JND_Interval_Head/Tail`, `JND_Reference_Intervals_Positions`, `JND_Calculated_Intervals_Positions`, `W` (nerve group weights), `Aihc` (nerve amplitudes), `spontRate`, `complexProfiles`.
**GPU tuning:** `Time_Blocks`, `Time_Block_Length`, `JACOBBY_Loops_Fast/Slow`, `Cuda_Outern_Loops`, `cuda_max/min_time_step`, `BMOHC_Kernel_Configuration`.
**Filter params:** `Fc`, `Fpass`, `Fstop`, `Apass`, `Astop`, `FilterOrder`, `butterType`, `filterName`, `AC_Filter_Vector`.
**Output control:** `Allowed_Outputs` (bitmask), `Discard_BM_Velocity_Output`, `Discard_Lambdas_Output`.
**IO handlers:** `VirtualHandler *vh` (input), `VirtualHandler *vhout` (output).
**Run-stage control:** `Run_Stage_Calculation` (0=full, 1=from BM velocity, 2=from lambda).
**Non-obvious:** `inputProfile` (vector<device_jnd_params>) is the expanded Cartesian product of tested frequencies × power levels × noise levels for JND mode. `complexProfiles` (vector<ComplexJNDProfile>) stores minimum-finding configurations.

---

## VirtualHandler.h
**Role:** Abstract base class (interface) for all I/O. Provides a unified read/write API that works for both MATLAB MEX (MEXHandler) and text/binary file (ConfigFileHandler) backends.
**Design pattern:** Template Method + Strategy. The virtual functions `write_vector`, `write_map`, `writeString`, `Flush_Major`, `Output_Major`, `processData`, `hasVariable` are overridden by concrete subclasses.
**Key concept — Major/Minor terminology:**
- **Major**: top-level output container (e.g., MATLAB output struct `plhs[0]`, or a disk file name)
- **Minor**: sub-field within major (e.g., `"BM_velocity"`, `"lambda_high"`, `"main_log"`)
- `addMinorToMajor(minor, major)` / `hasMajor(minor)` / `getMajor(minor)` — maintain a bidirectional map tracking which minor belongs to which major
- `clearPrimaryMajor(terminate)` — used by AudioLabCM to release the primary output at end of call
**Key template function:**
- `getValue<T>(variable_name)` — dispatches to concrete handler via `getValueStatic<T>(this, variable_name)` which does `dynamic_cast` to ConfigFileHandler or MEXHandler
- `flushToIOHandler(Log&, minor_tag)` — splits log text into lines and writes to the output struct (so MATLAB receives log output in the result struct)
**Non-obvious:** The "primary major" concept allows default-routing writes: if `hasPrimaryMajor()` is true and a minor isn't explicitly registered, writes go to the primary major. This simplifies AudioGramCreator write calls.
**Concrete implementations:** `MEXHandler` (MATLAB), `ConfigFileHandler` (CLI text file + binary disk output).

---

## SubModel.h
**Role:** Per-param-set cochlear configuration: OHC damage profile (gamma), IHC nerve health profile, and DSP filters.
**Key members:**
- `_gamma` (vector<double>, 256) — OHC relative density: 0=completely deaf, 0.5=healthy. Interpolated from `ohc_vector` or loaded from binary file.
- `_nerves` (vector<double>, 256) — IHC amplification health: values typically 5.0–8.0. 8.0=healthy.
- `_ac_time_filter` (HFunction) — the AC synapse filter (bandpass, ~300–1800 Hz FIR or IIR).
- `_noise_filter` (HFunction) — optional noise pre-filter.
- `_dbA` — signal power in dBA for this param set.
**Key methods:**
- `analyzeACFilter()` — builds `_ac_time_filter` using Parks-McClellan (FIR) or Iowa Hills (IIR) design based on `params->ac_filter_mode`.
- `calcFIRPM(OmegaC, transitionWidth, weightPass, weightStop, NumTaps)` — wraps the `firpm` library.
- `calcMinimumOrder(delta1, delta2, transitionWidth)` — Oppenheim & Schafer DSP eq. 7.104.
**Non-obvious:** Each `SubModel` is a different "experiment" within a single MEX call. For example, a JND test might compare 20 different power levels — each is a separate SubModel with identical gamma/nerves but different signal amplitude.

---

## HFunction.h
**Role:** Digital filter transfer function H(z) = B(z)/A(z) as coefficient vectors.
**Key members:**
- `Numerator` (vector<double>) — B coefficients (FIR taps or IIR numerator)
- `Denominator` (vector<double>) — A coefficients (IIR denominator; empty or [1] for FIR)
**Key methods:**
- `isFIR()` — true if Denominator is empty or [1,0,0,...]
- `reshapeIIRFilterSection(iirCoeffs, section_number)` — loads one biquad section from Iowa Hills `TIIRCoeff`.
- `multiplicateHFunctions(array, n)` — cascades n biquad sections (polynomial multiply B arrays, multiply A arrays).
- `decodeBinFile(buffer)` — binary format: `[order, is_fir, a[0..order-1], b[0..order]]`.
- `setFIRGain(gain_dB)` — multiplies B by `10^(gain/20)`.
**Factory functions:**
- `createFIRFunction(double *input, int size)` — wraps raw tap array into HFunction.
- `reshapeIIRFilter(TIIRCoeff&)` — creates HFunction array from Iowa Hills biquad struct.

---

## AudioGramCreator.h
**Role:** Declares `AudioGramCreator` — the IHC/lambda/JND pipeline class. This is the most complex class in the project.
**Key buffer members (all GPU or host-side float vectors):**
- `BM_input` — BM velocity input (section × time) [float, cm/s]
- `AC` — AC component after bandpass filter (IHC receptor potential oscillation)
- `DC` — DC/envelope component (IHC DC depolarization)
- `IHC` — combined IHC output = DC + eta_AC*AC - eta_DC*DC
- `Lambda` — instantaneous firing rate λ per section per SR group [spikes/s]
- `MeanRate` — time-averaged λ per interval
- `CRLB_RA` — Cramér-Rao Lower Bound on the rate estimator
- `FisherAI` — Fisher information for the All-Information (AI) JND metric
- `JND_RA`, `FisherAISum` — JND values from rate (RA) and AI methods
- `RateJNDall`, `AiJNDall`, `ApproximatedJNDall` — JND across all tested intervals
- `gamma`, `dA` — OHC profiles and input level increments
- `Shigh`, `dS`, `dLambda`, `dSquareLambda`, `dSumLambda` — intermediate JND calculation buffers
**Key config members:**
- `filter_a[]`, `filter_b[]` — IIR/FIR filter coefficient arrays (double[DEVICE_MAX_FILTER_ORDER=1024])
- `tffull` (HFunction) — full filter transfer function
- `is_filter_fir` — whether the AC filter is FIR (affects GPU kernel path)
- `backup_speeds` (float*) — last few ms of BM velocity for inter-block filter continuity
- `DC_filter_size` — IIR DC filter order
- `filter_dc` (vector<double>) — DC lowpass filter coefficients
**Nerve cluster layout:**
- `Nerves_Clusters[3*LAMBDA_COUNT]` = 9 floats: `[spont_H, spont_M, spont_L, A_H, A_M, A_L, W_H, W_M, W_L]`

---

## ConfigFileHandler.h
**Role:** Declares `ConfigFileHandler : public VirtualHandler` for text `.par` config file parsing and disk binary output.
**Non-obvious:** `write_vector` appends to `OutputBuffer<float>*` files identified by `major` name (file path). `Is_Larget_Output()` always returns 1 — all data goes to disk, nothing to MATLAB in this mode. `writeString` and `write_map` are no-ops (empty implementations) since the CLI mode doesn't support rich struct output.

---

## cochlea.cuh
**Role:** CUDA header declaring all GPU kernels and device functions used in `cochlea.cu`.
**Key declared functions:**
- `GeneralKernel_Copy_Results_Template<T>` — copies results between GPU buffers (explicit template instantiations for float and double).
- `ReverseKernel_Copy_Results_Template<T>` — copies CPU→GPU in reverse time-major layout.
- `updateCUDALambdaArray<JNDFloat>` — accumulates lambda from GPU kernel output buffers to host.
- Device-side BM solver kernel (name varies by version — look for the `__global__` kernel with `LAUNCHBOUNDS`).
**Non-obvious:** The `extern template` declarations in `AudioGramCreator.h` mean the template specializations are defined once in `cochlea.cu`/`cochlea.cuh` and linked in from there — avoids multiple definition errors across the project.

---

## cochlea_common.h
**Role:** Shared definitions between `cochlea.cu` (GPU) and CPU files. Contains struct definitions for GPU-CPU communication (like `device_jnd_params`) and the `gpuAssert` macro.
**Key types:**
- `device_jnd_params` — compact struct (fits in GPU constant memory) holding one test configuration: frequency, power level, noise level, interval index.
- `butterMatch` enum — filter type selector for Iowa Hills Butterworth IIR design.

---

## cochlea_utils.h
**Role:** Declares string utility functions (`transformString`, `splitToVector`, `createCharMatrix`, `converToLower`, `converToUpper`, `getFileType`) and template utilities.
**Key templates:**
- `mapper<K,V>` — a simple key-value container with separate `_data` (map<K,V>) and `_names` (map<K,string>) — used to bundle numerical and string metadata for MATLAB struct output.
- `is_specialization<T, Template>` — SFINAE helper to detect if T is a specialization of Template (e.g., is `vector<float>` a `vector<>`).
- `parseToScalar<V>(str)` / `parseToVector<V>(str)` — converts strings to numeric scalars/vectors.
- `indexLocatorPredicate<T>` — functor that extracts elements at specified indices from a vector.
- `mxstreambuf` — redirects `std::cout` to `mexPrintf` when running inside MATLAB MEX.

---

## tridiag.h
**Role:** Declares `CTriDiag` — Thomas algorithm (LU decomposition) for symmetric tri-diagonal systems.
**Key members:** `_l`, `_m`, `_u` (lower, middle, upper diagonals), `_k`, `_h` (LU factors).
**Key method:** `Solve(const vector<double>& Y)` — forward/backward substitution using pre-factored `_k` and `_h`.

---

## ode.h
**Role:** Declares `ode` base class providing `Euler`, `Trapezoidal`, and `Tester` methods for ODE integration. `CState` inherits from this.

---

## bin.h / TBin.h
- `CBin` — binary file reader for `double` arrays. Fixed element type.
- `TBin<T>` — template version supporting any numeric type (float, double, int). Used for input audio files via `_input_file` in `CSolver`.

---

## Log.h
**Role:** Declares `Log` — timer + string logger used for performance profiling.
**Key members:** `interrupts` (vector of `chrono::time_point`, size 64), `oss` (ostringstream for accumulated log text), `stopers_all_rounds` (per-round timing data).

---

## OutputBuffer.h
**Role:** Declares `OutputBuffer<T>` — streaming binary file output buffer used by `ConfigFileHandler`. Buffers `T` elements and flushes to disk when full.

---

## mexplus/ (directory)
**Role:** Header-only C++ wrapper for the MATLAB MEX API (`mxArray`, `mxCreate*`, field access) in RAII style.
**Key class:** `mexplus::MxArray` — owns or borrows an `mxArray*`. The `.at<T>(fieldname)` method reads typed values; `.set(fieldname, value)` sets them; `.release()` surrenders ownership; `.append<T>(fieldname, ptr, length, offset, 0, M)` appends float data to a field array.
**Non-obvious:** When `MEXHandler` calls `updateMajor(major, mxa.release())`, it takes ownership of the raw `mxArray*` back from mexplus to store in `_output_buffers`. This raw pointer is eventually passed to MATLAB via `mxDuplicateArray`.

---

## IowaHillsFilters/ (directory)
**Role:** IIR digital filter design library (Butterworth, Chebyshev, Parks-McClellan variants).
**Key header:** `IIRFilterCode.h` — declares `TIIRCoeff` (array of biquad sections) and filter design functions. Used by `SubModel::analyzeACFilter()` to design the IHC AC bandpass filter.

---

## firpm/ (directory)
**Role:** Parks-McClellan optimal FIR filter design library.
**Key headers:** `pm.h` (declares `PMOutput` and `firpm()` function), `band.h` (frequency band specification), `barycentric.h` (Remez algorithm internals).
**Used by:** `SubModel::calcFIRPM()`.
