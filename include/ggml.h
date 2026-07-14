#pragma once

// SwiftPM exposes one public include directory. Forward to ggml's canonical
// header so C/C++ targets never compile two independent copies of its types.
#include "../ggml/include/ggml.h"
