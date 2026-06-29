# src/ — Source Files Reference

## AudioLabCM.cpp
**Role:** MEX DLL entry point. Defines `mexFunction()` which MATLAB calls when it invokes `AudioLabCM(matStruct)`.
**Key logic:**
- On first call (`global_counter == 0`): creates the singleton `MexResources` object (which owns `CParams`, `CSolver`, GPU device) and registers `destroyGlobalResources()` with `mexAtExit` so resources are freed when the MEX is cleared from MATLAB memory.
- On every call: parses the MATLAB struct input via `params->parseMexFile`, calls `GSolver->updateStatus`, `GSolver->init_params(0)`, then `GSolver->Run(0.0)`.
- Calls `mexLock()` / `mexUnlock()` around the run to prevent MATLAB from unloading the DLL mid-run.
- Wraps everything in typed `catch` blocks; maps C++ exceptions to `mexErrMsgIdAndTxt` so MATLAB receives readable error messages.
- After `Run()`, flushes output via `params->vhout->clearPrimaryMajor(0)` and clears the model via `GSolver->clearModel()`.
**Non-obvious:** The `global_counter` persists between MATLAB calls. The solver (`GSolver`) is not re-created each call — it is reused. MATLAB struct output is managed through `VirtualHandler`/`MEXHandler`, not returned directly from `Run()`.
**Calls:** `MexResources`, `CParams::parseMexFile`, `CSolver::updateStatus`, `CSolver::init_params`, `CSolver::Run`, `CSolver::clearModel`, `VirtualHandler::clearPrimaryMajor`.
**Called by:** MATLAB runtime (the `mexFunction` symbol is the MEX ABI entry point).

---

## MEXHandler.cpp
**Role:** Concrete I/O handler for the MATLAB MEX interface. Implements `VirtualHandler` to provide reading from MATLAB structs and writing float/string data back to MATLAB output structs.
**Key functions:**
- `loadStruct(file_name)` — opens a `.mat` file with `matOpen`, reads the first variable as a MATLAB struct, sets `data_found` status codes (0=ok, 1=no file, 2=no var, 3=not struct, 4=not read yet).
- `write_vector(minor, major, float*, length, offset, M)` — the primary output method. Finds (or creates) an `mxArray` struct field `major.minor` and appends a float block via `mexplus::MxArray::append`. The `minor` is a sub-field name (e.g., `"BM_velocity"`), `major` is the top-level MATLAB output struct name. `M` is the number of rows (sections=256 typically).
- `claimFieldHandler(minor, major)` — looks up the `mxArray*` for `major` from `_output_buffers`, wraps it in a `mexplus::MxArray` RAII wrapper. Returns empty array if `major` not found (with a debug print).
- `Output_Major(major, output_target)` — called at the end: copies the built `mxArray` to the MATLAB output slot `plhs[i]` via `mxDuplicateArray`.
- `Flush_Major(major)` — writes the struct to a `.mat` file on disk instead of returning it to MATLAB (used when `Is_Larget_Output()` returns true, i.e., for the `ConfigFileHandler` path).
**Non-obvious:**
- `_output_buffers` is a `map<string, mxArray*>` that holds *raw pointers* to MATLAB-allocated structs. Ownership is complex: `_terminate_data=true` means the MEXHandler owns the input data; outputs are owned by MATLAB after `mxDuplicateArray`.
- The `minor_buffers_positions` map tracks how many floats have been written so far per `minor.major` key, enabling incremental append without tracking it externally.
- Large commented-out blocks represent earlier direct `mxSetField`/`mxGetData` approach before mexplus was used.
- Hebrew comments exist (the code was maintained in Hebrew-speaking research context).
**Calls:** `mexplus::MxArray`, MATLAB MAT-file API (`matOpen`, `matGetNextVariable`, `matClose`), `VirtualHandler` base class methods.
**Called by:** `CParams::parseMexFile` (for input), `AudioGramCreator::saveLambdas` and other output functions (for output).

---

## solver.cpp
**Role:** Implements `CSolver`, the main simulation orchestrator.
**Key functions:**
- Constructor `CSolver(device_id)`: initializes tri-diagonal matrix solver (`CTriMat` with 256 sections), acquires GPU device properties, creates `AudioGramCreator`.
- `updateStatus(tparams, num_params)`: creates a new `CModel` from the given params array. Called each MEX invocation.
- `init_params(params_set_counter)`: sets run time based on sim type (voice file duration vs. fixed `REF_RUN_TIME`), calls `Init_Tri_Matrix()`, creates `CState` objects for `_now` and `_past` (two-level time stepping).
- `Run(start_time)` / `Run_Cuda(start_time)`: top-level simulation loop — iterates over time blocks, calls CUDA kernel launchers, drives the cochlear ODE integration.
- `compressDeviceData()` / `showDeviceData()`: reports GPU capability (name, memory, SM count) back to MATLAB as a struct.
- `generateLongWN(params_set_counter)`: pre-generates a white noise array for the entire simulation duration (used when `sim_type == SIM_TYPE_JND_COMPLEX_CALCULATIONS`).
**Non-obvious:**
- Two `CState` objects (`_now`, `_past`) implement predictor-corrector (Euler + Trapezoidal) ODE integration. They are heap-allocated and swapped each time step.
- `maxTimeBlocks()`, `longestTimeBlock()`, `inputBufferTimeNodes()` — these "max" helpers iterate over all param sets to find the worst-case allocation sizes, ensuring buffers are large enough for any configuration.
- `continueRunningInputFile` / `continueRunningProfileGenerator` — loop control predicates for the two main run modes.
- The solver does NOT allocate GPU memory itself; that is done inside `cochlea.cu` kernel infrastructure and `AudioGramCreator`.
**Calls:** `CModel`, `CState`, `CTriDiag`, `AudioGramCreator`, CUDA runtime API, `CParams`, `Log`.
**Called by:** `AudioLabCM.cpp::mexFunction`.

---

## model.cpp
**Role:** Implements `CModel` constructor, which computes all spatially-varying cochlear physical parameters along the 256 sections.
**Key logic (constructor):**
- Populates `_M_bm`, `_R_bm`, `_S_bm` using exponential laws: `M0*exp(M1*dx*i)`, `R0*exp(R1*dx*i)`, `S0*exp(S1Cochlear*dx*i)`.
- `_w_cf_pow2[i] = _S_bm[i]/_M_bm[i]` — characteristic frequency squared per section.
- TM (tectorial membrane) arrays copy BM resistance/stiffness with scaling.
- Creates one `SubModel` per param set (stored in `configurations` vector), each SubModel holding OHC gamma vector, IHC nerves vector, and the AC/noise time-domain filters.
**Non-obvious:** All constants (`M0`, `R0`, `S0`, `S1Cochlear`, etc.) are compile-time `#define` in `const.h`. The BM mass increases exponentially from base to apex — this creates the tonotopic frequency map (high frequencies near base, low near apex).
**Calls:** `SubModel`, `CParams`.
**Called by:** `CSolver::updateStatus`.

---

## state.cpp (CState)
**Role:** Implements `CState`, the time-state container. Each instance represents one time snapshot of all cochlear state variables (BM displacement/velocity/acceleration, OW motion, OHC potential, TM motion, pressure).
**Key functions:**
- `get_sample()` / `gen_new_sample()` — compute or return the current acoustic input sample from the pre-loaded `_input_buffer`.
- `gen_input_data(inp_array, start_time, size, freq, amp)` — generates a pure-tone sine input.
- `load_input_data(inp_array, start_time, size, amp)` — loads a chunk of the file-based input signal.
- `copy_state(obj2copy)` / `restart_state(time, step)` — utility for time-stepping.
**Non-obvious:** `CState` inherits from `ode` (Euler/Trapezoidal methods). The actual ODE solving step happens by calling these inherited methods on the state vectors. GPU-based solving bypasses the CPU `CState` ODE path for BM calculation; `CState` is then used only for boundary conditions and CPU-side OHC.
**Calls:** `ode`, `CTriDiag`, `CModel`.
**Called by:** `CSolver::init_params`, `CSolver::Run`.

---

## params.cpp (CParams)
**Role:** Implements `CParams` — the runtime configuration struct that holds all ~100+ parameters parsed from the MATLAB input struct.
**Key functions:**
- `parseMexFile(prhs, plhs)` — reads the MATLAB struct (`prhs[0]`) field by field via `MEXHandler::getValue<T>`, sets up `vhout` (output handler pointing to `plhs[0]`), and registers all output field names with the handler.
- `parse_parameters_file(pfname)` / `parse_params_map()` — alternative text-file parsing path for non-MEX (CLI) usage via `ConfigFileHandler`.
- The `VirtualHandler *vh` (input) and `VirtualHandler *vhout` (output) pointers use runtime polymorphism — in MEX mode these point to `MEXHandler` instances; in CLI mode they point to `ConfigFileHandler`.
**Non-obvious:**
- `Allowed_Outputs` is a bitmask: bit 0 = BM velocity, bits 1-3 = lambda high/medium/low. `Discard_BM_Velocity_Output` and `Discard_Lambdas_Output` flags interact with it in a subtle order (see `BM_Velocity_Lambda_Output_Guide.txt`).
- `inputProfile` (vector of `device_jnd_params`) and `complexProfiles` (vector of `ComplexJNDProfile`) hold the expanded grid of test configurations for JND mode.
- `Run_Stage_Calculation` (0/1/2) allows starting computation mid-pipeline: 0=full BM+IHC+JND, 1=start from BM velocity (skip BM/OHC), 2=start from lambda (skip BM/OHC/IHC).
**Calls:** `MEXHandler`, `ConfigFileHandler`, `VirtualHandler`, `ComplexJNDProfile`.
**Called by:** `AudioLabCM.cpp::mexFunction`.

---

## cochlea.cu
**Role:** The 4400-line CUDA source containing all GPU kernels for the basilar membrane (BM) equation solver, OHC calculation, IHC pipeline, lambda (auditory nerve firing rate) computation, and cuFFT-based frequency analysis.
**Key kernel/device functions:**
- `warpReduceSum` / `blockReduceSum` — warp-level and block-level reduction templates using `__shfl_down_sync`.
- `linearDerivateApproximation`, `quadraticDerivateApproximation`, `cubicDerivateApproximation` — spatial derivative approximations for the pressure equation ∂²P/∂x².
- BM solve kernel: implements the Jacobi-like iterative solver for the tri-diagonal pressure system. Controlled by `_CUDA_JACOBBY_LOOPS`, `_CUDA_JACOBBY_LOOPS1`, `_CUDA_JACOBBY_LOOPS2`.
- IHC pipeline on GPU: AC filter (FIR or IIR) → DC filter → lambda calculation using the Meddis/Sumner synapse model.
- `updateCUDALambdaArray<JNDFloat>` template — copies lambda results from GPU to host.
- `cudaHolderGeneratedData` struct — owns device-side per-block tolerance/index arrays needed by the adaptive time-stepper.
**Constants on GPU (CUDA constant memory):**
- `model_constants[64]` — float model params (BM mass, stiffness, etc. per section).
- `model_constants_integers[16]` — int params (sample rate, block sizes).
- `model_Aihc[256*3]` — IHC amplitude per section per fiber group (3 groups: high/medium/low SR).
- `model_constants_longs[8]` — long params.
**Non-obvious:**
- The file is ~4400 lines; the BM kernel uses `FIRST_STAGE_MEMSIZE=256` elements in shared memory (`float cochlea_data_array[FIRST_STAGE_MEMSIZE+2]`) to store one full section sweep with boundary padding.
- `KERNEL_BLOCKS` is set to 4 or 5 depending on compute capability (≥sm_500 = 5 blocks/SM for `__launch_bounds__`).
- The Jacobi iterative solver runs `_CUDA_JACOBBY_LOOPS` fast loops then `_CUDA_JACOBBY_LOOPS1` slow loops with convergence checking. The outer loop (`_CUDA_OUTERN_LOOPS`) checks Lipschitz condition to decide whether to retry.
- `CUFFT_FLAG=1` means FFT-based spectral analysis is used for lambda calculation.
- `TIME_SECTIONS=8` CUDA blocks process 8 time blocks in parallel on the GPU.
**Calls:** cuFFT API, CUDA runtime.
**Called by:** `AudioGramCreator::runInCuda`, `CSolver::Run_Cuda`.

---

## cochlea_gold.cpp
**Role:** CPU reference implementation of 2D convolution (`convolutionClampToBorderCPU`). This is a straight-forward nested-loop convolution with clamp-to-border boundary handling.
**Non-obvious:** This is NOT a full CPU reference for the cochlear ODE — it is only the convolution reference used for verifying GPU convolution results (the copyright says NVIDIA). The name "gold" follows NVIDIA sample convention where `_gold` = CPU reference. It is only used when `VERIFY_RESULTS=1` (compile-time flag, currently 0).
**Called by:** Conditionally by kernel testing code (not in normal MEX run).

---

## cochlea_utils.cpp
**Role:** String utility functions used throughout the project.
**Key functions:**
- `transformString(input, tr)` — applies a character-level transform (via `std::function<char(char, locale)>`).
- `getFileType(fileName)` — extracts and uppercases the file extension.
- `converToLower` / `converToUpper` — locale-aware case conversion.
- `splitToVector(str, regextest)` — splits a string by regex pattern into a `vector<string>`. Used heavily in `ConfigFileHandler` to parse parameter values.
- `createCharMatrix(v)` — converts `vector<string>` to `vector<const char*>` for MATLAB API calls that need C-string arrays.
**Called by:** `ConfigFileHandler`, `MEXHandler`, `params.cpp`, `VirtualHandler`.

---

## AudioGramCreator.cpp
**Role:** The IHC pipeline and JND calculation engine. Takes BM velocity output from the CUDA solver and computes: AC filter → DC filter → lambda (neural firing rate) → JND (Just Noticeable Difference).
**Key functions:**
- `setupCreator(...)` / `valuesSetupCreator(...)` — allocates all working buffers (`AC`, `DC`, `IHC`, `Lambda`, `MeanRate`, `FisherAI`, etc.) based on time/section dimensions.
- `readFilter(rawFilterData)` — loads FIR/IIR AC synapse filter coefficients into `filter_a[]` / `filter_b[]` arrays.
- `runInCuda(host_bm_velocity, log)` — copies BM velocity to GPU, launches all CUDA IHC/lambda kernels, copies results back.
- `ac_filter()` — applies the AC (high-pass) synapse filter to BM velocity. Converts BM velocity (cm/s or m/s depending on `scaleBMVelocityForLambdaCalculation`) to IHC receptor potential AC component.
- `filterDC()` — computes the DC (low-pass/envelope) component.
- `IHCCalc()` — combines AC and DC to form the IHC output using eta_AC and eta_DC coupling parameters.
- `calcLambda(lambda_index)` / `calcLambdas(log)` — computes neural firing rate λ for each fiber group (high/medium/low spontaneous rate) using the Meddis synapse model.
- `calcJND(log)` / `calcJNDFinal()` — CPU-side JND calculation using Cramér-Rao Lower Bound on lambda (Fisher Information approach).
- `calcComplexJND(values)` — calls `ComplexJNDProfile::calculateMinValue` to find the JND threshold from a sweep of power levels.
- `saveLambdas(overlap_reduce, overlap_offset, log)` — writes lambda arrays back to output via `VirtualHandler::write_vector`.
- `saveArrayToDisk(...)` — binary file I/O for intermediate results (used when `ConfigFileHandler` path active).
**Non-obvious:**
- The three lambda groups correspond to three auditory nerve fiber populations: HIGH SR (60 spikes/s spont), MEDIUM SR (3 spikes/s), LOW SR (0.1 spikes/s) — defined in `const.h` as `HIGH_FREQ_NERVE=70`, `MEDIUM_FREQ_NERVE=50`, `LOW_FREQ_NERVE=30` and `SPONT_HIGH_RATE`, `SPONT_MEDIUM_RATE`, `SPONT_LOW_RATE`.
- `backup_speeds` is a float array used to carry the last few milliseconds of BM velocity from one interval to the next (for IHC filter continuity across blocks).
- `is_first_time_for_set` tracks whether this is the first interval for a given param set to handle filter initialization.
- The `LAMBDA_COUNT=3` constant controls how many lambda arrays are tracked.
- Output field names in MATLAB are `"lambda_high"`, `"lambda_medium"`, `"lambda_low"`, `"output_results"` (BM velocity).
**Calls:** CUDA kernel functions declared in `cochlea.cuh`, `HFunction`, `ComplexJNDProfile`, `VirtualHandler`.
**Called by:** `CSolver::Run_Cuda`.

---

## ComplexJNDProfile.cpp
**Role:** Finds the JND threshold (minimum distinguishable level difference) from a sweep of raw JND values over multiple power levels/noise conditions.
**Key functions:**
- `calculateMinValue(rawJNDValues, Failed_Signal_Indexes, eps, view_parts)` — finds the minimum of `rawJNDValues` at positions specified by `_intervals`. Uses local minima search (value smaller than both neighbors). If no local minimum found, picks boundary minimum and sets `calculateMinValueWarning=1`.
- `calculateGradientMinMaxValue(...)` — alternative: finds the first adjacent pair where the second value is greater than the first by `eps` (gradient method).
- `viewCaptured(minValueFound, tested_values, minimums_captured)` — debug string showing the captured minimum and candidates.
**Non-obvious:** `_intervals` is a vector of indices into `rawJNDValues` that this profile cares about (for complex multi-frequency test configurations, not all tested intervals belong to each profile). `Failed_Signal_Indexes` tracks which intervals failed GPU convergence — these are flagged with `Failed_Convergence_Warning`.
**Called by:** `AudioGramCreator::calcComplexJND`.

---

## tridiag.cpp
**Role:** Implements `CTriDiag`, a Thomas algorithm tri-diagonal matrix solver for the spatial pressure equation `U*P = Y`.
**Key functions:**
- `SetUpperDiag`, `SetMidDiag`, `SetLowerDiag` — set the three diagonals. When all three are set (`Init()` returns true), triggers `ReCalc()`.
- `ReCalc()` — performs LU decomposition: computes `_k[i]` (modified diagonal) and `_h[i]` (upper/k ratio) for the forward sweep. The backward substitution happens in `Solve(Y)` (defined in the header).
**Non-obvious:** The solver is precomputed once (`Init_Tri_Matrix` in `CSolver`) since the BM mass/stiffness matrix is time-invariant. Only the RHS vector `Y` changes each time step.
**Called by:** `CSolver::Init_Tri_Matrix`, then the result is passed to `CState`.

---

## ode.cpp
**Role:** Base class `ode` providing Euler and Trapezoidal ODE integration methods.
**Key functions:**
- `Euler(V_past, dV_past, dt)` — forward Euler: `V(t+dt) = V(t) + dt*dV(t)`.
- `Trapezoidal(V_past, dV_past, dV_now, dt)` — implicit trapezoidal: `V(t+dt) = V(t) + 0.5*dt*(dV(t) + dV(t+dt))`.
- `Tester(past_sp, past_acc, now_sp, now_acc, step, another_loop, is_next_time_step)` — adaptive step-size controller using Lipschitz condition. If error exceeds threshold, halves the step; if small, doubles it.
**Non-obvious:** The Tester implements the `LIPSCHITS_BIG_GAP`/`LIPSCHITS_SMALL_GAP`/`LIPSCHITS_THR` logic from `const.h`. In CUDA mode (`USE_CUDA=1`) the adaptive stepping is mostly replaced by fixed `CONST_TIME_STEP_VAL=1e-6` controlled inside the GPU kernel; the CPU `ode.cpp` path is used only for OW (oval window) scalars.
**Called by:** `CState` (inherits from `ode`).

---

## mex_global_resources.cpp
**Role:** Implements `MexResources`, the singleton that holds all inter-call global state for the MEX function.
**Key members:** `params` (CParams*), `GSolver` (CSolver*), `deviceProp` (CUDA device info), `mainlog` (Log), `counter` (call count).
**Key functions:**
- Constructor: calls `initDevice()` → `cudaSetDevice(0)`, `findGraphicsGPU()`, then creates `CParams(1)` and `CSolver(0)`.
- `initDevice()` — also validates that the found GPU is a "graphics" GPU (excludes Tesla compute-only cards via `checkHW` in `aux_gpu.cpp`).
- `updateRunTimes()` — increments call counter, clears the log for the new call.
- Destructor: calls `GSolver->clearSolver()`, deletes both `GSolver` and `params`.
**Non-obvious:** `CParams(1)` allocates params for 1 MEX call set. The `GSolver` is created with device_id=0 (always GPU 0). There is no support for multi-GPU. The `mainlog` persists across calls and is only cleared at the start of each new call.
**Called by:** `AudioLabCM.cpp::mexFunction` (creates on first call, destroyed via `mexAtExit`).

---

## aux_gpu.cpp
**Role:** GPU device discovery utilities.
**Key functions:**
- `findGraphicsGPU(name, show_verbose)` — iterates over all CUDA devices, filters out "Tesla" cards (considers them compute-only), returns count of graphics GPUs and name of first one.
- `checkHW(name, gpuType, dev)` — checks if a GPU device name starts with a given prefix (case-insensitive).
**Non-obvious:** The "graphics GPU" filter (not Tesla) is a heuristic from NVIDIA SDK samples. It excludes datacenter GPUs. In modern CUDA systems with no display GPU, this may return 0 even with valid CUDA GPUs — the check in `MexResources::initDevice` would then print a "not supported" message but continues anyway (`cutilExit` is redefined to throw a runtime_error).
**Called by:** `mex_global_resources.cpp::MexResources::initDevice`.

---

## cochlea_utils.cpp (see above)

---

## tridiag.cpp, ode.cpp, bin.cpp, mutual.cpp, smaller_than.cpp, Log.cpp, debug.cpp

### bin.cpp
**Role:** `CBin` — binary file I/O class for reading double-precision arrays. Opens file on construction, provides `Read()` for sequential double reads. Used for legacy file-based input (gammas, nerve files, expected reference outputs).
**Non-obvious:** File length is computed as `tellg()/sizeof(double)` — all files are assumed to contain raw `double` arrays. The `TBin<double>` template (see `TBin.h`) is the preferred modern version for typed binary reading.

### mutual.cpp
**Role:** Contains only `pause()` — a console "Press Enter to continue" utility. All the heavy vector math (`vmax`, `vmin`, `abs`, operator overloads) is in `mutual.h` as inline/template functions.

### smaller_than.cpp
**Role:** `smaller_than` functor with an integer threshold. Used as a comparison predicate for STL algorithms (e.g., `std::remove_if`).

### Log.cpp
**Role:** `Log` — high-resolution timer + string accumulation logger.
**Key functions:**
- `markTime(index)` — records a `std::chrono::high_resolution_clock::now()` into `interrupts[index]`.
- `elapsedTimeView(prefix, start_idx, end_idx)` — prints elapsed time between two marked indices to the internal `ostringstream oss`.
- `flushToIOHandler(Log&, minor_tag)` — splits the accumulated log string by newlines and writes each line as a string entry to the `VirtualHandler` output (so log appears in MATLAB output struct).
- `clearLog()` / `flushLog()` — clear/print the log buffer.
**Non-obvious:** `INTERRUPTS_NUMBER=64` allows up to 64 simultaneously tracked time points. The MEX entry point uses indices 0-8 for coarse timing (parse, update, init, run, exit). AudioGramCreator uses its own `audiogramlog`.

### debug.cpp
**Role:** Legacy MATLAB-side debug plotting (calls mclInitializeApplication and MATLAB plot functions via C API). Guarded by `#ifdef __DEBUG_MATLAB` — not compiled in normal builds. Contains `Plot_On_Screen()` which plots `CState::_BM_sp` to a MATLAB figure each N steps.
**Non-obvious:** This was from an early development phase when the model ran as a standalone executable with embedded MATLAB engine. In current MEX architecture, this code is completely inactive.

---

## SubModel.cpp
**Role:** Implements `SubModel` — per-param-set OHC/IHC configuration and filter initialization.
**Key members:** `_gamma` (256 OHC relative density values, 0=deaf, 0.5=healthy), `_nerves` (256 IHC health factors), `_ac_time_filter` (HFunction for AC synapse filter), `_noise_filter` (HFunction for noise pre-filter).
**Key functions:**
- Constructor: reads `gamma_file` (if provided) or uses `ohc_vector` from params; reads `nerve_file` or uses `ihc_vector`. Calls `analyzeACFilter()` to build the AC filter.
- `analyzeACFilter()` — depending on `ac_filter_mode` (0=from file, 1=from function, 2=from direct vector), builds the IHC AC bandpass filter. Uses `calcFIRPM()` (Parks-McClellan) or Iowa Hills IIR design.
- `calcFIRPM(OmegaC, transitionWidth, weightPass, weightStop, NumTaps)` — calls the `firpm` library (`pm.h`) to design an optimal equiripple FIR filter.
- `calcMinimumOrder(delta1, delta2, transitionWidth)` — Oppenheim & Schafer formula 7.104 for minimum FIR order.
- `toLinear`, `toDB`, `toDelta` — dB/linear conversion utilities.
**Non-obvious:** Multiple `SubModel` instances (one per param set) can have different OHC/IHC damage profiles, allowing comparison of healthy vs. impaired cochlea in a single MEX call.
**Called by:** `CModel` constructor.

---

## HFunction.cpp
**Role:** `HFunction` — represents a digital filter as numerator and denominator polynomial coefficient vectors (IIR: both; FIR: denominator = [1]).
**Key functions:**
- `load(Numerator, Denominator)` — sets the coefficient vectors.
- `reshapeIIRFilterSection(iirCoeffs, section_number)` — copies Iowa Hills biquad section `section_number` coefficients into the H function.
- `multiplicateHFunctions(hfunctionsArray, section_number)` — cascades multiple biquad sections by polynomial multiplication.
- `decodeBinFile(binBuffer)` — parses a binary buffer in a specific format: first element = filter order, second = 1 (FIR) or 0 (IIR), then A coefficients (if IIR), then B coefficients.
- `isFIR()` — returns true if `Denominator` is empty or `[1]`.
- `setFIRGain(gain_dB)` — scales the numerator by `10^(gain/20)`.
**Called by:** `SubModel`, `AudioGramCreator`.

---

## ConfigFileHandler.cpp
**Role:** Alternative to MEXHandler for CLI (non-MEX) operation. Reads a `.par` text configuration file (key=value format), populates `paramsMap` string map, and implements `VirtualHandler` write operations by appending to `OutputBuffer<float>` files on disk.
**Key functions:**
- `loadFile(fileName)` / `processFile()` — reads the text file, splits by lines, parses `key=value` pairs into `paramsMap`.
- `getString(variable_name)` — looks up a key in `paramsMap`.
- `getValue<V>(variable_name)` — template that calls `parseToScalar<V>` or `parseToVector<ValueType>` on the string value.
- `write_vector(minor, major, float*, length, offset, M)` — writes float data to an `OutputBuffer<float>` file on disk (streaming binary output). `Is_Larget_Output()` returns 1 (always true) so data goes to disk.
**Non-obvious:** `filtersMap` / `filtersMapRaw` / `filtersKeysStat` handle a sub-section of the config file dedicated to filter function parameters. `Is_Matlab_Formatted()` returns 0 (vs. MEXHandler's 1) — this flag is used in some output paths to decide format.
**Called by:** `CParams` when running in CLI mode (no MATLAB MEX).
