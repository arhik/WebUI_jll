"""
WebUI_jll - Julia package for WebUI library binaries

This package provides the WebUI library binaries as Julia artifacts.
WebUI is a lightweight and easy-to-use library for creating web-based UIs
for desktop applications.

# Exports
- `libwebui` - Path to the WebUI shared library
- `webui_header` - Path to the WebUI header file
- All WebUI C API functions from LibWebUI

# Example
```julia
using WebUI_jll

# Access library path
lib_path = libwebui

# Use WebUI C API
win = webui_new_window()
webui_show(win, "<html><body>Hello</body></html>")
webui_wait()
```
"""
module WebUI_jll

using Artifacts
using Libdl
using Reexport

const libwebui_path = Ref{String}("")
const webui_header_path = Ref{String}("")

@static if Sys.iswindows()
	const LIBNAME = "webui-2.dll"
elseif Sys.isapple()
	const LIBNAME = "libwebui-2.dylib"
else
	const LIBNAME = "libwebui-2.so"
end

function get_artifact_dir()
	return artifact"webui"
end

function get_library_path()
	if isempty(libwebui_path[])
		artifact_dir = get_artifact_dir()
		lib_path = joinpath(artifact_dir, "lib", LIBNAME)

		if !isfile(lib_path)
			alt_path = joinpath(artifact_dir, LIBNAME)
			if isfile(alt_path)
				lib_path = alt_path
			else
				for (root, dirs, files) in walkdir(artifact_dir)
					for file in files
						if file == LIBNAME ||
						   (Sys.iswindows() && occursin("webui", file) && endswith(file, ".dll")) ||
						   (Sys.isapple() && occursin("webui", file) && endswith(file, ".dylib")) ||
						   (!Sys.iswindows() && !Sys.isapple() && occursin("webui", file) && endswith(file, ".so"))
							full_path = joinpath(root, file)
							if !occursin("secure", full_path) &&
							   !occursin("debug", full_path) &&
							   !occursin("static", full_path)
								lib_path = full_path
								break
							end
						end
					end
				end
			end
		end

		libwebui_path[] = lib_path
	end

	return libwebui_path[]
end

function get_header_path()
	if isempty(webui_header_path[])
		artifact_dir = get_artifact_dir()
		header_path = joinpath(artifact_dir, "include", "webui.h")

		if !isfile(header_path)
			for (root, dirs, files) in walkdir(artifact_dir)
				for file in files
					if file == "webui.h"
						webui_header_path[] = joinpath(root, file)
						return webui_header_path[]
					end
				end
			end
			webui_header_path[] = ""
		else
			webui_header_path[] = header_path
		end
	end

	return webui_header_path[]
end

webui_header() = get_header_path()

function __init__()
	global libwebui = get_library_path()
	global webui = libwebui

	if Sys.iswindows() && isfile(libwebui)
		chmod(libwebui, filemode(libwebui) | 0o755)
	end

	if isfile(libwebui)
		try
			dlopen(libwebui, RTLD_GLOBAL | RTLD_NOW)
		catch e
			@warn "Failed to load WebUI library" exception=e
		end
	else
		@warn "WebUI library not found at: $libwebui"
	end

	webui_header()
end

include("LibWebUI.jl")
@reexport using .LibWebUI

export libwebui, webui, webui_header

end # module
