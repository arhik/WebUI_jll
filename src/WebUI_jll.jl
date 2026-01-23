"""
Julia package for WebUI nightly builds.

Downloads WebUI libraries from GitHub nightly releases with automatic updates.

# Exports
- `webui_path()` - Path to the WebUI library
- `webui_header()` - Path to the WebUI header file
- `update()` - Update to the latest nightly build
- `version()` - Get version information

# Example
```julia
using WebUI_jll

# Get library and header paths
lib_path = webui_path()
header_path = webui_header()

# Check version
v = version()

# Update to latest nightly
update()
```
"""
module WebUI_jll

using Libdl, Downloads, SHA, Serialization, Dates

# Version info for nightly builds
const NIGHTLY_VERSION = "nightly"
const VERSION_DATE = Ref{String}(Dates.format(Dates.now(Dates.UTC), "yyyy-mm-dd"))

# URLs for nightly builds on different platforms
const LIBRARIES = Dict(
    :linux_gcc_x64     => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-gcc-x64.zip",
    :linux_clang_x64   => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-clang-x64.zip",
    :linux_gcc_arm64   => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-gcc-arm64.zip",
    :linux_gcc_arm     => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-gcc-arm.zip",
    :linux_clang_arm64 => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-clang-arm64.zip",
    :linux_clang_arm   => "https://github.com/webui-dev/webui/releases/download/nightly/webui-linux-clang-arm.zip",
    :macos_clang_x64   => "https://github.com/webui-dev/webui/releases/download/nightly/webui-macos-clang-x64.zip",
    :macos_clang_arm64 => "https://github.com/webui-dev/webui/releases/download/nightly/webui-macos-clang-arm64.zip",
    :windows_msvc_x64  => "https://github.com/webui-dev/webui/releases/download/nightly/webui-windows-msvc-x64.zip",
    :windows_gcc_x64   => "https://github.com/webui-dev/webui/releases/download/nightly/webui-windows-gcc-x64.zip",
)

# Cache for downloaded library path
const _lib_path = Ref{String}("")

# Cache for version metadata
const _version_info = Dict{Symbol, Any}()

"""
    get_library_key()

Determine the appropriate library key for the current platform and architecture.
"""
function get_library_key()
    if Sys.islinux()
        if Sys.ARCH == :x86_64
            return :linux_gcc_x64
        elseif Sys.ARCH == :aarch64 || Sys.ARCH == :arm64
            return :linux_gcc_arm64
        elseif Sys.ARCH == :armv7l || Sys.ARCH == :armv6l
            return :linux_gcc_arm
        end
    elseif Sys.isapple()
        if Sys.ARCH == :x86_64
            return :macos_clang_x64
        elseif Sys.ARCH == :aarch64 || Sys.ARCH == :arm64
            return :macos_clang_arm64
        end
    elseif Sys.iswindows()
        if Sys.ARCH == :x86_64
            return :windows_msvc_x64
        elseif Sys.ARCH == :aarch64 || Sys.ARCH == :arm64
            return :windows_msvc_arm64
        end
    end
    error("Unsupported platform: $(Sys.MACHINE) with architecture $(Sys.ARCH)")
end

"""
    get_library_name(key::Symbol)

Get the directory/library name for a given platform key.
"""
function get_library_name(key::Symbol)
    names = Dict(
        :linux_gcc_x64     => "webui-linux-gcc-x64",
        :linux_clang_x64   => "webui-linux-clang-x64",
        :linux_gcc_arm64   => "webui-linux-gcc-arm64",
        :linux_gcc_arm     => "webui-linux-gcc-arm",
        :linux_clang_arm64 => "webui-linux-clang-arm64",
        :linux_clang_arm   => "webui-linux-clang-arm",
        :macos_clang_x64   => "webui-macos-clang-x64",
        :macos_clang_arm64 => "webui-macos-clang-arm64",
        :windows_msvc_x64  => "webui-windows-msvc-x64",
        :windows_msvc_arm64=> "webui-windows-msvc-arm64",
        :windows_gcc_x64   => "webui-windows-gcc-x64",
    )
    return get(names, key, string(key))
end

"""
    get_cache_dir()

Get the cache directory for WebUI libraries.
"""
function get_cache_dir()
    cache_dir = joinpath(homedir(), ".cache", "webui_jll")
    mkpath(cache_dir)
    return cache_dir
end

"""
    get_extract_dir(key::Symbol)

Get the extraction directory for a specific library key.
"""
function get_extract_dir(key::Symbol)
    lib_name = get_library_name(key)
    return joinpath(get_cache_dir(), lib_name)
end

"""
    get_version_file()

Get the path to the version metadata file.
"""
function get_version_file()
    return joinpath(get_cache_dir(), "version.info")
end

"""
    load_version_info()

Load cached version information.
"""
function load_version_info()
    version_file = get_version_file()
    if isfile(version_file)
        try
            return open(version_file, "r") do io
                return Serialization.deserialize(io)
            end
        catch
            return Dict{Symbol, Any}()
        end
    end
    return Dict{Symbol, Any}()
end

"""
    save_version_info(info::Dict)

Save version information to cache.
"""
function save_version_info(info::Dict)
    version_file = get_version_file()
    try
        open(version_file, "w") do io
            Serialization.serialize(io, info)
        end
    catch e
        @warn "Failed to save version info" exception=e
    end
end

"""
    find_library_in_dir(extract_dir::String)

Find the WebUI library file in the extraction directory.
Returns tuple of (lib_path, header_path).
"""
function find_library_in_dir(extract_dir::String)
    if !isdir(extract_dir)
        error("Extraction directory does not exist: $extract_dir")
    end

    # Library patterns for different platforms (prefer newer versions)
    lib_patterns = if Sys.iswindows()
        ["webui-2.dll", "webui.dll", "webui-2.lib", "webui.lib"]
    elseif Sys.isapple()
        ["libwebui-2.dylib", "libwebui.dylib", "webui-2.dylib", "webui.dylib"]
    else
        ["libwebui-2.so", "libwebui.so", "webui-2.so", "webui.so"]
    end

    # Additional patterns for header files
    header_patterns = ["webui.h", "webui-2.h"]

    lib_files = String[]
    header_files = String[]
    
    # Collect all files recursively
    all_files = String[]
    for (root, dirs, files) in walkdir(extract_dir)
        for file in files
            push!(all_files, joinpath(root, file))
        end
    end
    
    for pattern in lib_patterns
        for file in all_files
            if occursin(pattern, file) && isfile(file)
                push!(lib_files, file)
            end
        end
    end

    for pattern in header_patterns
        # Search recursively in all subdirectories
        for (root, dirs, files) in walkdir(extract_dir)
            for file in files
                if occursin(pattern, file)
                    push!(header_files, joinpath(root, file))
                end
            end
        end
    end

    if isempty(lib_files)
        error("No WebUI library found in $extract_dir")
    end

    # Prefer non-secure, non-debug, non-static versions
    preferred = filter(f ->
        !occursin("secure", f) &&
        !occursin("debug", f) &&
        !occursin("-static", f) &&
        !occursin(".a", f) &&
        !occursin(".lib", f),
        lib_files
    )

    if !isempty(preferred)
        # Sort to prefer newer versions (higher numbers)
        sort!(preferred, rev=true)
        lib_path = first(preferred)
    else
        lib_path = first(lib_files)
    end

    # Find header
    header_path = if !isempty(header_files)
        first(header_files)
    else
        ""
    end

    return lib_path, header_path
end

"""
    download_and_extract(url::String, extract_dir::String, key::Symbol)

Download and extract a WebUI library archive.
"""
function download_and_extract(url::String, extract_dir::String, key::Symbol)
    cache_dir = get_cache_dir()
    zip_path = joinpath(cache_dir, "webui-$(key).zip")

    # Clean up old extraction if it exists
    if isdir(extract_dir)
        rm(extract_dir, recursive=true)
    end

    @info "Downloading WebUI nightly build for $key..."
    @info "URL: $url"

    try
        # Download with progress
        Downloads.download(url, zip_path)

        @info "Extracting to $extract_dir..."

        # Extract to a temporary directory first
        temp_dir = joinpath(cache_dir, "webui-temp-$(key)")
        if isdir(temp_dir)
            rm(temp_dir, recursive=true)
        end
        mkpath(temp_dir)

        # Extract based on platform
        if Sys.isapple() || Sys.islinux()
            run(`unzip -o -q $zip_path -d $temp_dir`)
        else
            # Use PowerShell Expand-Archive on Windows for better compatibility
            if is_windows_powershell_available()
                run(`powershell -Command "Expand-Archive -Path '$zip_path' -DestinationPath '$temp_dir' -Force"`)
            else
                run(`unzip -o $zip_path -d $temp_dir`)
            end
        end
        rm(zip_path, force=true)

        # Find the actual extracted content (zip may contain a subdirectory)
        extracted_items = readdir(temp_dir)
        
        # Create extract_dir and move contents
        mkpath(extract_dir)
        
        if length(extracted_items) == 1 && isdir(joinpath(temp_dir, first(extracted_items)))
            # Zip contained a single subdirectory, copy its contents to extract_dir
            inner_dir = joinpath(temp_dir, first(extracted_items))
            cp(inner_dir, extract_dir, force=true)
        else
            # Move items directly
            for item in readdir(temp_dir, join=true)
                cp(item, joinpath(extract_dir, basename(item)), force=true)
            end
        end
        rm(temp_dir, recursive=true)

        @info "Successfully extracted WebUI to $extract_dir"

        # Get file hash for verification
        lib_path, _ = find_library_in_dir(extract_dir)
        if isfile(lib_path)
            open(lib_path, "r") do io
                sha_hash = bytes2hex(sha256(io))
                @info "Library SHA256: $sha_hash"
            end
        end

    catch e
        # Clean up on failure
        if isfile(zip_path)
            rm(zip_path, force=true)
        end
        if isdir(extract_dir)
            rm(extract_dir, recursive=true)
        end
        rethrow(e)
    end
end

"""
    is_windows_powershell_available()

Check if PowerShell is available for archive extraction.
"""
function is_windows_powershell_available()
    if !Sys.iswindows()
        return false
    end
    try
        success(`powershell -Command "Get-Process"`)
        return true
    catch
        return false
    end
end

"""
    check_for_updates(key::Symbol)

Check if a newer nightly build is available.
"""
function check_for_updates(key::Symbol)
    url = get(LIBRARIES, key, "")
    if isempty(url)
        @warn "No URL configured for $key"
        return false
    end

    try
        response = Downloads.request(url; method="HEAD")
        if response.status == 200 || response.status == 302
            return true
        end
    catch e
        @warn "Failed to check for updates" exception=e
    end
    return false
end

"""
    update_library(key::Symbol)

Force update the library to the latest nightly.
"""
function update_library(key::Symbol)
    url = get(LIBRARIES, key, "")
    if isempty(url)
        error("No URL configured for $key")
    end

    extract_dir = get_extract_dir(key)

    # Clear cached path
    _lib_path[] = ""

    # Download and extract
    download_and_extract(url, extract_dir, key)

    # Update version info
    info = load_version_info()
    info[key] = Dict(
        "version" => NIGHTLY_VERSION,
        "date" => VERSION_DATE[],
        "url" => url,
    )
    save_version_info(info)

    return get_lib_path()
end

"""
    get_lib_path()

Get the path to the WebUI library, downloading if necessary.
"""
function get_lib_path()
    if !isempty(_lib_path[])
        return _lib_path[]
    end

    key = get_library_key()
    url = get(LIBRARIES, key, "")
    if isempty(url)
        error("No WebUI library URL configured for platform: $(Sys.MACHINE)")
    end

    extract_dir = get_extract_dir(key)

    if !isdir(extract_dir)
        # Download for the first time
        download_and_extract(url, extract_dir, key)

        # Save version info
        info = load_version_info()
        info[key] = Dict(
            "version" => NIGHTLY_VERSION,
            "date" => VERSION_DATE[],
            "url" => url,
        )
        save_version_info(info)
    else
        # Check for updates (optional - nightly builds auto-update)
        if check_for_updates(key)
            @info "Newer WebUI nightly build available. Run `WebUI_jll.update()` to update."
        end
    end

    # Find the library file
    lib_path, _ = find_library_in_dir(extract_dir)

    _lib_path[] = lib_path
    return lib_path
end

"""
    get_header_path()

Get the path to the WebUI header file.
"""
function get_header_path()
    key = get_library_key()
    extract_dir = get_extract_dir(key)

    if !isdir(extract_dir)
        get_lib_path()  # This will download if needed
    end

    _, header_path = find_library_in_dir(extract_dir)
    return header_path
end

"""
    __init__()

Initialize WebUI_jll by loading the library.
"""
function __init__()
    try
        lib_path = get_lib_path()
        if isfile(lib_path)
            # Try to load with global scope to enable downstream libraries
            dlopen(lib_path, RTLD_GLOBAL | RTLD_NOW)
            @info "WebUI library loaded successfully" lib=lib_path
        else
            @warn "WebUI library not found at: $lib_path"
        end
    catch e
        @error "Failed to load WebUI library" exception=e
    end
end

"""
    webui_path()

Return the path to the WebUI library.
"""
webui_path() = get_lib_path()

"""
    webui_header()

Return the path to the WebUI header file.
"""
webui_header() = get_header_path()

"""
    update()

Update to the latest WebUI nightly build.
"""
function update()
    key = get_library_key()
    update_library(key)
    @info "WebUI updated successfully"
end

"""
    version()

Return the current WebUI version information.
"""
function version()
    key = get_library_key()
    info = load_version_info()
    if haskey(info, key)
        return info[key]
    else
        return Dict("version" => "unknown", "date" => "unknown")
    end
end

# Export commonly used functions
export webui_path, webui_header, update, version

end  # module WebUI_jll