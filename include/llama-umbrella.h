// Umbrella header for the Llama SwiftPM module.
//
// Aggregates the public C surfaces of llama and ggml so Swift sees a
// single `Llama` module. The order matters: ggml types are referenced
// by llama.h, so ggml headers come first.

#ifndef LLAMA_UMBRELLA_H
#define LLAMA_UMBRELLA_H

#include "ggml.h"
#include "ggml-alloc.h"
#include "ggml-backend.h"
#include "ggml-cpu.h"
#include "ggml-opt.h"
#include "gguf.h"

#include "llama.h"

// Removed llama-cpp.h because it contains C++ features like std::unique_ptr
// which cannot be imported into regular Swift modules without full C++ interop
// enabled in every consumer. Regular Swift-C interop only supports C headers.

#endif /* LLAMA_UMBRELLA_H */
