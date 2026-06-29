# AudioLabCM — Cochlear Model Simulator

## Git Conventions
- **Never add Claude as co-author in commits.** Do not include `Co-Authored-By: Claude ...` lines in any commit message.

## Project Purpose
A computational model of the human inner ear (cochlea), compiled as a MATLAB MEX extension (`.mexw64`). Simulates basilar membrane (BM) mechanics, outer hair cell (OHC) nonlinearity, inner hair cell (IHC) response, auditory nerve firing, and Just Noticeable Difference (JND) calculations. Used for hearing research and hearing-loss simulation.

## Tech Stack
- **Core language:** C++ / CUDA (GPU kernels) / C
- **Build system:** CMake 3.12+ → generates Visual Studio `.vcxproj`
- **GPU:** NVIDIA CUDA, compute capability sm_61, uses cuFFT
- **Linear algebra:** Eigen3
- **MATLAB integration:** MEX API (mexplus wrapper in `include/mexplus/`)
- **DSP libraries:** Iowa Hills Filters (`include/IowaHillsFilters/`, `src/IowaHillsFilters/`), Parks-McClellan FIR design (`include/firpm/`, `src/firpm/`)
- **Platform:** Windows 64-bit (output: `AudioLabCM.mexw64`)

## Repository Layout
```
CS_Ariel_Project/
├── CMakeLists.txt          # Build config; output target = AudioLabCM (mexw64)
├── CMakeModules/           # Custom CMake helpers
├── include/                # All header files (57 total)
│   ├── IowaHillsFilters/   # DSP filter headers
│   ├── firpm/              # Parks-McClellan headers
│   └── mexplus/            # MATLAB MEX C++ wrapper
├── src/                    # All source files (42 total)
│   ├── IowaHillsFilters/
│   ├── firpm/
│   └── *.cpp / *.cu        # Core simulation
├── MATLAB_Files/           # MATLAB scripts and config
├── build20/                # CMake build artifacts (gitignored usually)
└── AudioLabCM.mexw64       # Compiled MEX binary
```

## Key Source Files
| File | Role |
|------|------|
| `src/AudioLabCM.cpp` | MEX entry point (`mexFunction`) |
| `include/MEXHandler.h`, `src/MEXHandler.cpp` | MATLAB ↔ C++ data conversion |
| `src/mex_global_resources.cpp` | Global state between MATLAB calls |
| `include/solver.h`, `src/solver.cpp` | `CSolver` — main simulation orchestrator, time-stepping, tri-diagonal solver |
| `include/model.h` | `CModel` — BM/OHC physical parameters |
| `include/state.h` | `CState` — BM displacement/velocity, OHC potential, pressure |
| `include/params.h` | `CParams` — runtime config from MATLAB |
| `src/cochlea.cu`, `include/cochlea.cuh` | CUDA kernels for BM equation solving |
| `src/AudioGramCreator.cpp` | Audiogram (hearing sensitivity) profile builder |
| `src/ComplexJNDProfile.cpp` | JND calculation |
| `src/tridiag.cpp` | Tri-diagonal matrix solver |
| `src/ode.cpp` | ODE integrator |

## MATLAB Interface
- **`MATLAB_Files/configCochlea.m`** — configuration class with 100+ parameters (fs, OHC/IHC modes, JND settings, file I/O paths, filter params)
- **`MATLAB_Files/ProcessAudioLab.m`** — main entry: creates config → calls `AudioLabCM()` MEX
- **`MATLAB_Files/ParametersDefinition.m`** — parameter definitions
- Other scripts: `analyzeFile.m`, `CalculateJNDfiles2.m`, `GetTunedAudiograms.m`

## Build Instructions
```bash
mkdir build20
cd build20
cmake .. -G "Visual Studio 17 2022"
cmake --build . --config Release
```
The output `AudioLabCM.mexw64` must be on the MATLAB path. Install prefix in CMakeLists: `D:/documents/Cochlea_model/Matlab/matlab_files/cochlea_gui`.

## Architecture (data flow)
```
configCochlea.m (MATLAB)
  → AudioLabCM MEX  (AudioLabCM.cpp)
    → MEXHandler    (MATLAB ↔ C++ conversion)
    → CSolver       (orchestrates simulation)
        ├ CModel    (physical cochlea params)
        ├ CState    (simulation state)
        ├ CUDA kernels (cochlea.cu) — GPU-parallel BM solve
        ├ DSP filters (Iowa Hills IIR/FIR)
        ├ AudioGramCreator
        └ ComplexJNDProfile (JND)
  → Output: binary files / MATLAB structs
```

## Important Constants (const.h)
- **256 spatial sections** along cochlea
- **8 time blocks** processed in parallel on GPU
- Default sampling rate: **20 kHz**

## Notes
- No README exists; documentation is embedded in MATLAB scripts and code comments.
- The project models both normal hearing and hearing-impaired states via OHC/IHC parameter modulation (gamma for OHC).
- CUDA compute capability is currently set to `sm_120` in CMakeLists.txt (line 18: `set(CMAKE_CUDA_ARCHITECTURES 120)`). For GTX 1080/Pascal (sm_61) add `61` to that line.

## Undocumented Files (not in original CLAUDE.md)

### Class hierarchy
- `VirtualHandler` (abstract) — I/O abstraction layer
  - `MEXHandler` — MATLAB MEX input/output
  - `ConfigFileHandler` — text `.par` config file + binary disk output
- `ode` (base) → `CState` (time state)
- `AudioGramCreator` — IHC/lambda/JND pipeline (not a base class, standalone)
- `SubModel` — per-param-set OHC/IHC config; owned by `CModel`
- `HFunction` — digital filter H(z)=B(z)/A(z) value object

### Additional source files
| File | Role |
|------|------|
| `src/SubModel.cpp` | OHC gamma, IHC nerves, AC filter construction per param set |
| `src/HFunction.cpp` | HFunction coefficient loading, biquad cascade, FIR gain |
| `src/VirtualHandler.cpp` | VirtualHandler destructor and `flushToIOHandler` |
| `src/ConfigFileHandler.cpp` | Text `.par` file parser and disk binary output writer |
| `src/cochlea_gold.cpp` | CPU reference 2D convolution (NVIDIA sample; inactive in normal builds) |
| `src/cochlea_utils.cpp` | String utilities: split, case convert, char matrix |
| `src/aux_gpu.cpp` | GPU device enumeration (`findGraphicsGPU`, `checkHW`) |
| `src/bin.cpp` | `CBin` binary file reader (double arrays) |
| `src/mutual.cpp` | `pause()` console utility; vector math is in `mutual.h` inline |
| `src/smaller_than.cpp` | `smaller_than` comparison functor |
| `src/Log.cpp` | `Log` — high-resolution timer + string logger |
| `src/debug.cpp` | Legacy MATLAB plot-on-screen (inactive, guarded by `__DEBUG_MATLAB`) |
| `src/ode.cpp` | Euler + Trapezoidal ODE integration; `Tester` adaptive step controller |

### MEX binary variants
Multiple `.mexw64` binaries exist for A/B testing:
- `MATLAB_Files/AudioLabCM.mexw64` — current production (what MATLAB uses)
- `MATLAB_Files/NewAudioLabCM.mexw64` — newer build variant
- `MATLAB_Files/New2AudioLabCM.mexw64` — another variant
- `MATLAB_Files/OldAudioLabCM.mexw64` — legacy build for regression comparison
- `build25/bin/AudioLabCM.mexw64` — latest CMake build output
- `buildDebug/bin/AudioLabCMd.mexw64` — debug build

`TestIsoNormal.m` contains commented-out lines for swapping binaries:
```matlab
%copyfile('OldAudioLabCM.mexw64', 'AudioLabCM.mexw64')
%copyfile('NewAudioLabCM.mexw64', 'AudioLabCM.mexw64')
```

### Output binary format
Binary outputs (when using ConfigFileHandler/CLI mode) are raw float32 streams:
- **BM velocity / output_results**: sequential rows of `[time_float, section_0..255_float]` — each row = 1 time step × 257 floats (1 timestamp + 256 sections).
- **Lambda**: same format, 3 files (high/medium/low SR).
- In MATLAB (MEX mode): data is returned as float arrays in `result.output_results` (BM velocity) and `result.lambda_high/medium/low`.

### Simulation modes (sim_type)
| Value | Constant | Meaning |
|-------|----------|---------|
| 0 | `SIM_TYPE_VOICE` | Process audio file or embedded signal |
| 1 | `SIM_TYPE_SIN` | Single pure tone at sin_freq/sin_dB |
| 2 | `SIM_TYPE_PERF` | Performance benchmark |
| 3 | `SIM_TYPE_PROFILE_GENERATING` | Generate JND profile grid (Cartesian product of freq × power × noise) |
| 4 | `SIM_TYPE_JND_COMPLEX_CALCULATIONS` | Full JND calculation with minimum-finding |

### Run stage modes (Run_Stage_Calculation)
| Value | Meaning |
|-------|---------|
| 0 | Full pipeline: BM solve → OHC → IHC → Lambda → JND |
| 1 | Start from BM velocity (skip BM/OHC solve). Input via `Run_Stage_Vector` (float32, row vector) |
| 2 | Start from Lambda (skip BM/OHC/IHC). Load from `Run_Stage_File_name` |

## Known Gotchas

1. **`Allowed_Outputs` is overwritten by `preAnalyzeFile.m`**: This script always adds `Allowed_Outputs=0` as a default. When `Discard_BM_Velocity_Output=0` is set, it internally sets bit 0 of `Allowed_Outputs` — but then the explicit `Allowed_Outputs=0` from preAnalyzeFile overwrites it. Always pass `'Allowed_Outputs', 1` (for BM vel) or `'Allowed_Outputs', 14` (for lambda) explicitly alongside the Discard flags.

2. **GPU architecture mismatch**: CMakeLists.txt currently targets `sm_120` (Blackwell/RTX 50xx). Running this MEX on a Pascal GPU (GTX 1080, sm_61) triggers JIT compilation via PTX, which may produce incorrect results or fail silently. Fix: `set(CMAKE_CUDA_ARCHITECTURES 61 120)` in CMakeLists.txt line 18.

3. **`ACTIVE_GAMMA_FLAG=false`**: OHC gamma does NOT change dynamically during a simulation run. The gamma profile is static (set once from file or vector). There is compile-time support for dynamic gamma (the `_psi_ohc` and `_active_gamma_flag` exist) but it is disabled.

4. **Two-level time stepping without GPU**: In non-CUDA paths, CState's `Tester()` implements adaptive step sizing. In CUDA mode, the step is fixed at `CONST_TIME_STEP_VAL=1e-6` and only OW (oval window) scalars use adaptive stepping.

5. **`global_counter` persists across MEX calls**: The MEX DLL stays loaded in MATLAB memory until `clear AudioLabCM` is called. The `MexResources` singleton persists between calls, so GPU memory is NOT freed between calls. If parameters change dramatically (e.g., different Fs), the solver state from the previous call is still in memory. Call `clear AudioLabCM` to fully reset.

6. **`mexLock()` without `mexUnlock()` on error**: If an exception is caught, `mexUnlock()` is NOT called (it's only called at the bottom of `mexFunction` after the try/catch). This means a failed call still holds a lock — MATLAB cannot unload the MEX until `clear AudioLabCM` or `clear functions`.

7. **`SubModel` copy constructor required**: `SubModel` has an explicit copy constructor (declared in header). This is because `HFunction` members contain `vector<double>` which need deep copy. When `CModel` pushes `SubModel` objects into `configurations` vector, the copy constructor is invoked.

8. **`dA` vs `dBSPL`**: In JND mode, the tested power levels are in dBSPL relative to `SPLRefVal` (defaults to `2e-5 Pa` from `SPLRef` constant). The `dA` vector in `AudioGramCreator` contains the linear amplitude differences `Δα` between adjacent test levels. The Fisher information JND formula uses `Δα` not `ΔdB`.

9. **`IHC_FACTOR=1e+8`**: The IHC output is scaled by this factor before lambda calculation. This is not physically obvious — it is a normalization constant to bring the IHC voltage into the range expected by the Meddis synapse model.

10. **`SYNAPSE_B_NORMALIZER=1e-6`**: Must be `1e-6` for `Fs=20 kHz` and `1e-9` for `Fs=44.1 kHz`. If switching sample rates, this constant must be changed in `const.h` and the project recompiled.

11. **`preAnalyzeFile.m` loads `Final_Parameters.mat`**: This file must be on the MATLAB path. It contains `Aihc`, `SPLref`, `lambda_spont`, `eta_AC`, `eta_DC` — the calibrated model constants. Without it, `preAnalyzeFile` will error. The file is generated by `SetCochlearParameters.m` + `fitParabola` workflow.

12. **`TestRms.m` is actually `TestIsoNormalNoise.m`**: Despite the name "TestRms", the script runs a noise-masked JND test (En=1111 = quiet) and is designed for cross-machine Lambda comparison, not specifically RMS testing.
