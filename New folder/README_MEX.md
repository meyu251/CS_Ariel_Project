AudioLab MEX Build (Windows + MATLAB)

Prerequisites
- MATLAB R2019b+ on Windows 64-bit
- Microsoft Visual C++ (VS 2019/2022) with MFC components
- NVIDIA CUDA Toolkit (matching your GPU)
- NVIDIA CUDA Samples (for helper_cuda.h and helper_functions.h)

Setup
1) In MATLAB:
   - Run `mex -setup C++` and select MSVC.
   - Run `mexcuda -setup` and select a supported CUDA NVCC.
2) Ensure environment variables:
   - `CUDA_PATH` (e.g., `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4`)
   - Optionally `CUDA_SAMPLES_PATH` (e.g., `C:\ProgramData\NVIDIA Corporation\CUDA Samples\v12.4`)

Build
1) Open MATLAB in the project root `d:\CS_Ariel_Project`.
2) Run:
   - `build_mex`  (compiles `src/cochlea.cu` to object and links all `.cpp` into `AudioLabCM.mexw64`)

Run
- Call the MEX from MATLAB like a function: `AudioLabCM(inputStruct)`
  The gateway function is in `src/AudioLabCM.cpp` and expects a struct as the first argument.

Troubleshooting
- Missing `helper_cuda.h` / `helper_functions.h`: install CUDA Samples and add `common/inc` to the include path.
- Link errors for CUDA runtime: verify `-L%CUDA_PATH%\lib\x64 -lcudart` is in link args.
- Compiler not found: install Visual Studio C++ Build Tools and run `mex -setup C++`.
- MFC headers missing: install MFC components with Visual Studio.

Notes
- The build defines `CUDA_MEX_PROJECT` to enable MEX-specific code paths.
- Output MEX file: `AudioLabCM.mexw64` in project root.
