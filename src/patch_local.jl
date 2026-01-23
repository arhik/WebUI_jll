"""
WebUI_jll Local Library Patch

This file patches the WebUI_jll module to support using a locally extracted
WebUI library instead of downloading from GitHub releases.

# Usage

```julia
# Apply the patch
include("patch_local.jl")

# Setup local library (point to the DLL you extracted)
use_local_library("C:/Users/arhik/.julia/dev/WebUI_jll/webui-windows-msvc-x64/webui-windows-msvc-x64/webui-2.dll")

# Or use the default location
use_default_local_library()

# Verify the local library
check_local_library()

# Now use WebUI normally - it will use the local library
using WebUI
window = webui_new_window()
webui_set_frameless(window, true)  # This should now work!
```

"""
module WebUI_jll_Patch

using Libdl

# Store the original get_lib_path function
const _original_get_lib_path = Ref{Union{Function, Nothing}}(nothing)

# Track if we're using local library
const _use_local = Ref{Bool}(false)
const _local_lib_path = Ref{String}("")

# Default local library path (adjust based on where you extracted)
const DEFAULT_LOCAL_PATH = joinpath(@__DIR__, "..", "..", "webui-windows-msvc-x64", "webui-windows-msvc-x64", "webui-2.dll")

"""
    is_windows()
Check if we're on Windows.
"""
is_windows() = Sys.iswindows()

"""
    get_local_path()
Get the configured local library path.
"""
get_local_path() = _local_lib_path[]

"""
    is_using_local()
Check if we're currently using a local library.
"""
is_using_local() = _use_local[]

"""
    use_local_library(path::String)
Configure WebUI_jll to use a local library at the specified path.
"""
function use_local_library(path::String)
    if !isfile(path)
        error("Local library not found at: $path")
    end

    # Verify the library has key functions
    handle = try
        dlopen(path)
    catch e
        error("Failed to load library: $e")
    end

    # Check for frameless functions
    frameless_funcs = [
        "webui_set_frameless",
        "webui_set_transparent",
        "webui_set_center",
        "webui_minimize",
        "webui_maximize",
        "webui_set_resizable"
    ]

    available = 0
    for func in frameless_funcs
        try
            dlsym(handle, Symbol(func))
            available += 1
        catch
        end
    end
    dlclose(handle)

    if available > 0
        println()
        println("✓ Local library has $available/$(length(frameless_funcs)) frameless functions")
        if available < length(frameless_funcs)
            println("⚠️  Some frameless functions are missing")
        end
        println()
    end

    _local_lib_path[] = path
    _use_local[] = true

    println("WebUI_jll now using local library: $path")
    println()
end

"""
    use_default_local_library()
Use the default local library path.
"""
function use_default_local_library()
    if isfile(DEFAULT_LOCAL_PATH)
        use_local_library(DEFAULT_LOCAL_PATH)
    else
        error("Default local library not found at: $DEFAULT_LOCAL_PATH")
    end
end

"""
    use_downloaded_library()
Switch back to using the downloaded nightly build.
"""
function use_downloaded_library()
    _use_local[] = false
    _local_lib_path[] = ""
    println("WebUI_jll switched back to downloaded nightly build")
end

"""
    check_local_library()
Check and display information about the local library.
"""
function check_local_library()
    println()
    println("="^60)
    println("WebUI Local Library Check")
    println("="^60)
    println()

    if !is_using_local()
        println("Mode: DOWNLOADED (not using local library)")
        return
    end

    path = get_local_path()
    if !isfile(path)
        println("❌ Local library not found: $path")
        return
    end

    println("Library: $path")
    println()

    # Load and check functions
    handle = try
        dlopen(path)
    catch e
        println("❌ Failed to load: $e")
        return
    end

    # Check function categories
    categories = [
        ("Frameless Window", [
            "webui_set_frameless",
            "webui_set_transparent",
            "webui_set_center",
            "webui_minimize",
            "webui_maximize",
            "webui_set_resizable"
        ]),
        ("Core Window", [
            "webui_new_window",
            "webui_show",
            "webui_bind",
            "webui_wait",
            "webui_exit",
            "webui_close",
            "webui_set_size"
        ]),
        ("Callbacks", [
            "webui_get_string",
            "webui_get_int",
            "webui_get_float",
            "webui_get_bool",
            "webui_return_string",
            "webui_return_int"
        ])
    ]

    total_available = 0
    total_checked = 0

    for (name, funcs) in categories
        println("$name Functions:")
        println("-"^60)
        available = 0
        for func in funcs
            total_checked += 1
            try
                dlsym(handle, Symbol(func))
                println("  ✓ $func")
                available += 1
                total_available += 1
            catch
                println("  ✗ $func")
            end
        end
        println("  ($available/$(length(funcs)) available)")
        println()
    end

    dlclose(handle)

    println("="^60)
    println("SUMMARY: $total_available/$total_checked functions available")
    println("="^60)

    if is_windows()
        println()
        println("🎉 Ready to use WebUI with native functions!")
        println()
        println("Example:")
        println("  using WebUI")
        println("  window = webui_new_window()")
        println("  webui_set_frameless(window, true)")
        println("  webui_set_transparent(window, true)")
        println("  webui_show(window, html)")
    end

    println()
end

"""
    patch_webui_jll()
Apply the patch to make WebUI_jll use the local library.
This modifies the _lib_path cache in WebUI_jll.
"""
function patch_webui_jll()
    if !is_using_local()
        error("Call use_local_library() or use_default_local_library() first")
    end

    path = get_local_path()

    try
        # Try to patch WebUI_jll module
        if isdefined(Main, :WebUI_jll)
            webui_jll = Main.WebUI_jll
            if isdefined(webui_jll, :_lib_path)
                webui_jll._lib_path[] = path
                println("✓ Patched WebUI_jll._lib_path")
            end
        end

        # Pre-load the library with global scope
        handle = dlopen(path, RTLD_GLOBAL | RTLD_NOW)
        println("✓ Pre-loaded library with global scope")

        println()
        println("✅ Patch applied successfully!")
        println("WebUI_jll will now use the local library.")
        println()

    catch e
        @warn "Failed to patch WebUI_jll" exception=e
        println()
        println("Note: You may need to restart Julia for changes to take effect.")
        println("Or manually set WebUI_jll._lib_path[] = \"$path\"")
    end
end

"""
    quick_setup()
One-command setup to use local library and patch WebUI_jll.
"""
function quick_setup()
    println()
    println("WebUI_jll Local Library Quick Setup")
    println("="^60)
    println()

    # Try default location
    if isfile(DEFAULT_LOCAL_PATH)
        println("Found local library at default location")
        use_local_library(DEFAULT_LOCAL_PATH)
    else
        println("Checking for local library...")
        # Try to find it
        search_paths = [
            DEFAULT_LOCAL_PATH,
            joinpath(@__DIR__, "..", "..", "webui-windows-msvc-x64", "webui-2.dll"),
            joinpath(@__DIR__, "..", "webui-windows-msvc-x64", "webui-2.dll"),
        ]

        found = false
        for p in search_paths
            if isfile(p)
                println("Found at: $p")
                use_local_library(p)
                found = true
                break
            end
        end

        if !found
            println()
            println("❌ Local library not found!")
            println()
            println("Please extract the upstream WebUI library to:")
            println("  $(joinpath(@__DIR__, "..", ".."))")
            println()
            return false
        end
    end

    # Check library
    check_local_library()

    # Patch WebUI_jll
    patch_webui_jll()

    return true
end

end  # module
