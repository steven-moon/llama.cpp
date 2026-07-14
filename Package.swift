// swift-tools-version: 6.2
//
// SwiftPM manifest for the steven-moon/llama.cpp fork.
//
// Why this fork exists
// --------------------
// Upstream ggml-org/llama.cpp removed its top-level Package.swift on
// 2025-03-05 (commit a057897ad4) when they centralised on CMake + a
// prebuilt XCFramework for Apple platforms. The XCFramework is great for
// shipping iOS/macOS apps but it cannot run on Linux, which is the whole
// reason ADR-0042 + ADR-0041 exist (PocketCloudServer on Vultr Ubuntu).
//
// This fork's sole job is to re-add SwiftPM support so the workspace can
// consume llama.cpp from sources on every platform we care about:
//
//   * macOS  (.v14)  — dev + ADR-0041 server dev host
//   * iOS    (.v17)  — PocketMind v2 TestFlight
//   * Linux  (default platform) — ADR-0041 production server
//
// Upstream sources remain unchanged. The fork adds this Package.swift and
// `include/module.modulemap`; forwarding headers in `include/` expose ggml's
// canonical headers through SwiftPM's single `publicHeadersPath` without
// maintaining duplicate declarations that can drift during upstream merges.
//
// Workspace fork convention
// -------------------------
// Tagged `0.0.9301-pc.1`, preserving the upstream b9301 build number while
// remaining a valid SwiftPM semantic version. Consumed by
// `Packages/Kernel/AIStack/Package.swift` via `.exact("0.0.9301-pc.1")` per
// the workspace's reproducible-dependency policy (ADR-0019 / ADR-0040).
//
// Scope (-pc.1)
// -------------
// CPU-only build that targets macOS arm64/x86_64, iOS arm64 (device +
// simulator), and Linux x86_64/arm64. Apple Accelerate is linked on
// Apple platforms for BLAS acceleration. Metal acceleration is held for
// `-pc.2` (it needs special handling for `.metal` resources or the
// `GGML_METAL_EMBED_LIBRARY` codegen step).
//
// CUDA / Vulkan / OpenCL / SYCL / CANN / Hexagon / OpenVINO / ROCm /
// MUSA / ZenDNN / zDNN / VirtGPU / WebGPU backends are excluded — they
// require platform-specific toolchains the workspace doesn't ship.

import PackageDescription

// SwiftPM compiles one target's C/C++ sources together. ggml's arch-specific
// files define overlapping symbol sets, so we must keep only one active arch
// subtree per host build to avoid duplicate symbols.
let inactiveCPUArchDirectories: [String] = {
    #if arch(arm64) || arch(arm)
    return [
        "ggml/src/ggml-cpu/arch/x86",
        "ggml/src/ggml-cpu/arch/riscv",
        "ggml/src/ggml-cpu/arch/loongarch",
        "ggml/src/ggml-cpu/arch/powerpc",
        "ggml/src/ggml-cpu/arch/s390",
        "ggml/src/ggml-cpu/arch/wasm",
    ]
    #elseif arch(x86_64) || arch(i386)
    return [
        "ggml/src/ggml-cpu/arch/arm",
        "ggml/src/ggml-cpu/arch/riscv",
        "ggml/src/ggml-cpu/arch/loongarch",
        "ggml/src/ggml-cpu/arch/powerpc",
        "ggml/src/ggml-cpu/arch/s390",
        "ggml/src/ggml-cpu/arch/wasm",
    ]
    #elseif arch(riscv64) || arch(riscv32)
    return [
        "ggml/src/ggml-cpu/arch/arm",
        "ggml/src/ggml-cpu/arch/x86",
        "ggml/src/ggml-cpu/arch/loongarch",
        "ggml/src/ggml-cpu/arch/powerpc",
        "ggml/src/ggml-cpu/arch/s390",
        "ggml/src/ggml-cpu/arch/wasm",
    ]
    #else
    return [
        // Unknown host arch: compile portable generic path only.
        "ggml/src/ggml-cpu/arch",
    ]
    #endif
}()

let package = Package(
    name: "llama-cpp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "Llama",
            targets: ["Llama"]
        )
    ],
    targets: [
        // Single umbrella C++ target. Compiles ggml-base + ggml-cpu +
        // llama core. The ggml backend subtree at `ggml/src/ggml-*` is
        // excluded except for `ggml-cpu`, which is the only one we
        // build in -pc.1 (cross-platform CPU implementation).
        .target(
            name: "Llama",
            path: ".",
            exclude: [
                // Optional ggml backends. Cross-platform parity ships
                // CPU-only; reinstate individual backends in later
                // `-pc.N` tags as the workspace needs them.
                "ggml/src/ggml-blas",
                "ggml/src/ggml-cann",
                "ggml/src/ggml-cuda",
                "ggml/src/ggml-hexagon",
                "ggml/src/ggml-hip",
                "ggml/src/ggml-metal",
                "ggml/src/ggml-musa",
                "ggml/src/ggml-opencl",
                "ggml/src/ggml-openvino",
                "ggml/src/ggml-rpc",
                "ggml/src/ggml-sycl",
                "ggml/src/ggml-virtgpu",
                "ggml/src/ggml-vulkan",
                "ggml/src/ggml-webgpu",
                "ggml/src/ggml-zdnn",
                "ggml/src/ggml-zendnn",
                // Specialized CPU backends.
                "ggml/src/ggml-cpu/amx",
                "ggml/src/ggml-cpu/kleidiai",
                "ggml/src/ggml-cpu/spacemit",
                "ggml/src/ggml-cpu/llamafile",
                // Upstream CMake/scripting metadata.
                "ggml/cmake",
                "ggml/CMakeLists.txt",
                "ggml/src/CMakeLists.txt",
                "ggml/src/ggml-cpu/CMakeLists.txt",
                "ggml/src/ggml-cpu/cmake",
                "src/CMakeLists.txt",
                "CMakeLists.txt",
                "CMakePresets.json",
                "Makefile",
                "build-xcframework.sh",
                // Non-library subtrees from upstream.
                "app", "benches", "ci", "cmake", "common", "conversion",
                "docs", "examples", "flake.nix", "media",
                "models", "pyrightconfig.json", "requirements", "scripts",
                "tests", "tools",
                // Python conversion helpers (out of scope).
                "convert_hf_to_gguf.py",
                "convert_hf_to_gguf_update.py",
                "convert_llama_ggml_to_gguf.py",
                "convert_lora_to_gguf.py",
                // PocketCloud-side cache, never compiled.
                ".pc-cache"
            ] + inactiveCPUArchDirectories,
            sources: [
                // ggml-base (cross-platform CPU graph + memory)
                "ggml/src/ggml.c",
                "ggml/src/ggml.cpp",
                "ggml/src/ggml-alloc.c",
                "ggml/src/ggml-backend.cpp",
                "ggml/src/ggml-backend-dl.cpp",
                "ggml/src/ggml-backend-meta.cpp",
                "ggml/src/ggml-backend-reg.cpp",
                "ggml/src/ggml-opt.cpp",
                "ggml/src/ggml-quants.c",
                "ggml/src/ggml-threading.cpp",
                "ggml/src/gguf.cpp",
                // ggml-cpu (CPU backend; per-arch dirs at
                // ggml-cpu/arch/* compile only their matching #ifdef
                // blocks on each target)
                "ggml/src/ggml-cpu",
                // llama core
                "src"
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Search paths for internal compilation. Public headers
                // live in `include/`; internal headers in `src/` and
                // `ggml/src/`.
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .headerSearchPath("ggml/include"),
                .headerSearchPath("ggml/src"),
                .headerSearchPath("ggml/src/ggml-cpu"),

                // Version information.
                .define("GGML_VERSION", to: "\"0.15.1\""),
                .define("GGML_COMMIT", to: "\"b9630\""),
                .define("LLAMA_BUILD_NUMBER", to: "9630"),

                // Backend selection — CPU only in -pc.1.
                .define("GGML_USE_CPU"),

                // BLAS acceleration via Apple's Accelerate framework
                // (Apple platforms only). On Linux we fall through to
                // ggml's hand-rolled CPU kernels.
                .define("GGML_USE_ACCELERATE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
                .define("GGML_BLAS_USE_ACCELERATE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),

                // Platform feature macros.
                .define("_GNU_SOURCE", .when(platforms: [.linux])),
                .define("_DARWIN_C_SOURCE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
            ],
            cxxSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .headerSearchPath("ggml/include"),
                .headerSearchPath("ggml/src"),
                .headerSearchPath("ggml/src/ggml-cpu"),

                .define("GGML_VERSION", to: "\"0.15.1\""),
                .define("GGML_COMMIT", to: "\"b9630\""),
                .define("LLAMA_BUILD_NUMBER", to: "9630"),

                .define("GGML_USE_CPU"),
                .define("GGML_USE_ACCELERATE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
                .define("GGML_BLAS_USE_ACCELERATE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),

                .define("_GNU_SOURCE", .when(platforms: [.linux])),
                .define("_DARWIN_C_SOURCE", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
                .linkedFramework("Foundation", .when(platforms: [.macOS, .iOS, .visionOS, .tvOS])),
                // libm + pthread are picked up by default on Linux via
                // clang's stdlib selection.
            ]
        )
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .cxx17
)
