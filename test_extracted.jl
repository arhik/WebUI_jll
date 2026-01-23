#!/usr/bin/env julia
# Test Extracted Upstream WebUI Library

using Libdl

# Path to extracted upstream library
upstream_dir = joinpath(@__DIR__, "webui-windows-msvc-x64", "webui-windows-msvc-x64")
lib_path = joinpath(upstream_dir, "webui-2.dll")

if !isfile(lib_path)
    error("Library not found: $lib_path")
end

println("="^70)
println("Testing Extracted Upstream WebUI Library")
println("="^70)
println()
println("Library: $lib_path")
println()

handle = dlopen(lib_path)
println("✓ Library loaded")
println()

println("Frameless Window Functions:")
println("-"^70)

functions_to_check = [
    "webui_set_frameless",
    "webui_set_transparent",
    "webui_set_center",
    "webui_minimize",
    "webui_maximize",
    "webui_set_resizable",
    "webui_set_min_size",
    "webui_set_minimum_size"
]

found = String[]
missing = String[]

for func in functions_to_check
    try
        dlsym(handle, Symbol(func))
        println("  ✓ $func")
        push!(found, func)
    catch
        println("  ✗ $func")
        push!(missing, func)
    end
end

println()
println("="^70)
println("SUMMARY: $(length(found))/$(length(functions_to_check)) functions available")
println("="^70)

if length(found) == length(functions_to_check)
    println()
    println("🎉 SUCCESS: All frameless functions are available!")
    println()
else
    println()
    println("⚠️  Some functions are missing:")
    for f in missing
        println("  - $f")
    end
end

dlclose(handle)
println()
println("Done.")
