#include "mex.h"

/* Minimal MEX entry point for testing the build toolchain. */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    mexPrintf("Hello from cochlea MEX stub.\n");

    if (nrhs > 0) {
        mexPrintf("First input type: %s\n", mxGetClassName(prhs[0]));
    }

    if (nlhs > 0) {
        plhs[0] = mxCreateDoubleScalar(42);
    }
}
