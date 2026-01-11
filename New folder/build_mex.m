% Build MEX for the cochlea project on Windows.
% Usage inside MATLAB (from project root):  >> build_mex

%% Resolve paths
thisFile = mfilename('fullpath');
projRoot = fileparts(thisFile);
srcDir   = fullfile(projRoot, 'src');
incDir   = fullfile(projRoot, 'include');
cd(projRoot);

%% Gather C++ sources
cppFiles = {};
searchRoots = {srcDir};
for s = 1:numel(searchRoots)
    subs = strsplit(genpath(searchRoots{s}), pathsep);
    for i = 1:numel(subs)
        p = subs{i}; if isempty(p), continue; end
        d = dir(fullfile(p, '*.cpp'));
        for k = 1:numel(d)
            fn = fullfile(p, d(k).name);
            [~, bn, ~] = fileparts(fn);
            if any(strcmpi(bn, {'memoryTest', 'stdafx', 'cvector'})), continue; end
            cppFiles{end+1} = fn; %#ok<AGROW>
        end
    end
end
cppFiles = unique(cppFiles);
fprintf('Found %d C++ sources.\n', numel(cppFiles));

%% Include paths
incPaths = {incDir, srcDir};
subsInc  = strsplit(genpath(incDir), pathsep);
subsSrc  = strsplit(genpath(srcDir), pathsep);
incPaths = unique([incPaths subsInc subsSrc]);
incArgs  = cellfun(@(p) ['-I' p], incPaths(~cellfun(@isempty, incPaths)), 'UniformOutput', false);

% Ensure CUDA include is passed to mex (not always auto-added in some MATLAB versions)
if ~isempty(CUDA_PATH)
    cudaInc = fullfile(CUDA_PATH, 'include');
    incArgs{end+1} = ['-I' cudaInc]; %#ok<AGROW>
end

%% CUDA settings
useCUDA = true;
CUDA_PATH = getenv('CUDA_PATH');
SAMPLES_PATH = getenv('CUDA_SAMPLES_PATH');
cuFile = fullfile(srcDir, 'cochlea.cu');
objFile = fullfile(projRoot, 'cochlea_mex.obj');
cuBuilt = false;

if useCUDA && ~isempty(CUDA_PATH) && isfile(cuFile)
    commonInc = fullfile(SAMPLES_PATH, 'common', 'inc');
    if ~isempty(SAMPLES_PATH) && isfolder(commonInc)
        incArgs{end+1} = ['-I' commonInc];
    else
        warning('CUDA Samples common/inc not found. helper_cuda.h may be missing.');
    end
    fprintf('Compiling CUDA object from %s\n', cuFile);
    try
        mexcuda('-c', cuFile, '-output', objFile, '-DCUDA_MEX_PROJECT', incArgs{:});
        cuBuilt = true;
    catch ME
        warning('mexcuda failed: %s', ME.message);
    end
else
    warning('CUDA not configured or cochlea.cu missing. Skipping CUDA build.');
end

libArgs = {};
if useCUDA && ~isempty(CUDA_PATH)
    libDir = fullfile(CUDA_PATH, 'lib', 'x64');
    if isfolder(libDir)
        libArgs{end+1} = ['-L' libDir]; %#ok<AGROW>
        libArgs{end+1} = '-lcudart'; %#ok<AGROW>
    else
        warning('CUDA lib dir not found: %s', libDir);
    end
end

%% Build MEX
mexFlags = {'-largeArrayDims', '-DMATLAB_MEX_FILE', '-DCUDA_MEX_PROJECT'};
outName  = 'AudioLabCM';
linkInputs = [cppFiles];
if cuBuilt
    linkInputs = [{objFile} linkInputs];
end

fprintf('Linking MEX: %s\n', outName);
try
    mex('-v', '-output', outName, mexFlags{:}, incArgs{:}, libArgs{:}, linkInputs{:});
    fprintf('Success: %s.%s\n', outName, mexext);
catch ME
    fprintf(2, 'MEX build failed: %s\n', ME.message);
    fprintf('Tips: run "mex -setup C++" and "mexcuda -setup"; verify CUDA_PATH and CUDA_SAMPLES_PATH; ensure VS/MinGW compatible.\n');
    rethrow(ME);
end
