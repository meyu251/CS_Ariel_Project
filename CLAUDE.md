# AudioLabCM — Cochlear Model Simulator

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
- CUDA compute capability is hard-coded to `sm_61` (GTX 1080/Titan X/P40 era GPUs).
