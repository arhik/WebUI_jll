# WebUI_jll

Julia JLL package for [WebUI](https://webui.me) - a lightweight library for creating web-based user interfaces for desktop applications using any web browser as a frontend.

## Overview

WebUI_jll provides pre-built WebUI library binaries as Julia artifacts. This package uses Julia's artifact system for reliable, versioned binary distribution across multiple platforms.

## Installation

```julia
using Pkg
Pkg.add("WebUI_jll")
```

## Quick Start

```julia
using WebUI_jll

# Create a new window
window = webui_new_window()

# Show HTML content
webui_show(window, """
    <html>
        <head>
            <script src="webui.js"></script>
        </head>
        <body>
            <h1>Hello from Julia!</h1>
            <button onclick="webui.call('MyButton')">Click Me</button>
        </body>
    </html>
""")

# Bind a callback to a button click
function on_button_click(event)
    println("Button clicked!")
    webui_return_string(event, "Callback received!")
end

# Set up the callback
cb = @cfunction(on_button_click, Cvoid, (Ptr{webui_event_t},))
webui_bind(window, "MyButton", cb)

# Wait for the window to close
webui_wait()
```

## API Reference

### Window Management
- `webui_new_window()` - Create a new window
- `webui_show(window, html)` - Display HTML content
- `webui_show_browser(window, html, browser)` - Show in specific browser
- `webui_close(window)` - Close a window
- `webui_destroy(window)` - Free window resources
- `webui_wait()` - Block until all windows close
- `webui_exit()` - Close all windows and exit

### Event Handling
- `webui_bind(window, element, callback)` - Bind element to callback
- `webui_get_string(event)` - Get string from event
- `webui_get_int(event)` - Get integer from event
- `webui_get_bool(event)` - Get boolean from event
- `webui_return_string(event, string)` - Return string to JavaScript
- `webui_return_int(event, value)` - Return integer to JavaScript
- `webui_return_bool(event, value)` - Return boolean to JavaScript

### JavaScript Execution
- `webui_run(window, script)` - Run JavaScript code
- `webui_script(window, script, timeout, buffer, length)` - Run and get response

### Window Configuration
- `webui_set_kiosk(window, status)` - Enable/disable kiosk mode
- `webui_set_hide(window, status)` - Show/hide window
- `webui_set_size(window, width, height)` - Set window size
- `webui_set_position(window, x, y)` - Set window position
- `webui_set_frameless(window, status)` - Enable frameless mode
- `webui_set_transparent(window, status)` - Enable transparency
- `webui_set_center(window)` - Center window on screen
- `webui_set_resizable(window, status)` - Enable/disable resizing
- `webui_set_min_size(window, width, height)` - Set minimum size

### Library Access
- `libwebui` - Path to the shared library
- `webui_header()` - Path to the C header file

## Supported Platforms

| Platform | Architecture | Status |
|----------|--------------|--------|
| Windows  | x86_64       | Supported |
| macOS    | x86_64       | Planned |
| macOS    | aarch64      | Planned |
| Linux    | x86_64       | Planned |
| Linux    | aarch64      | Planned |
| Linux    | armv7l       | Planned |

## Building Artifacts

To package WebUI binaries into Julia artifacts:

### From Local Files

```julia
cd gen
julia package_local.jl
```

This will:
1. Package the local `webui-windows-msvc-x64` directory
2. Compute the git-tree-sha1 hash
3. Output the Artifacts.toml entry

### From Remote Releases

```julia
cd gen
julia artifact_downloader.jl
```

This downloads binaries from the upstream GitHub releases and packages them.

### Computing SHA256

After creating and uploading the tarball:

```julia
using SHA
sha256 = bytes2hex(open(sha256, "path/to/artifact.tar.gz"))
```

## Project Structure

```
WebUI_jll/
├── Artifacts.toml        # Artifact definitions and hashes
├── Project.toml          # Package metadata and dependencies
├── README.md             # This file
├── src/
│   ├── WebUI_jll.jl      # Main module
│   ├── LibWebUI.jl       # C API bindings
│   └── wrapper.jl        # JLLWrappers integration
├── gen/
│   ├── artifact_downloader.jl  # Download from upstream
│   └── package_local.jl        # Package local files
└── test/
    └── runtests.jl       # Test suite
```

## Dependencies

- Julia 1.6+
- Reexport.jl

## Upstream

- **Repository**: https://github.com/webui-dev/webui
- **Version**: 2.5.0-beta.3
- **License**: MIT

## Similar Projects

- [WGPUNative.jl](https://github.com/JuliaWGPU/WGPUNative.jl) - Similar artifact-based approach for WGPU

## Version History

- v2.5.0-beta.3 - Initial artifact-based release with Windows x86_64 support

## Contributing

To add support for a new platform:

1. Download the upstream binary for your platform
2. Extract it to a directory with the structure:
   ```
   platform-name/
   ├── include/
   │   └── webui.h
   └── lib/
       └── webui-2.{dll,so,dylib}
   ```
3. Run `gen/package_local.jl` to generate the hash
4. Update `Artifacts.toml` with the new entry
5. Create a tarball and upload it to GitHub releases
6. Replace `PLACEHOLDER_SHA256` with the actual SHA256

## License

This Julia wrapper package is released under the MIT License. The WebUI library itself is also MIT licensed.

## See Also

- [WebUI Documentation](https://webui.me)
- [Julia Artifacts Documentation](https://pkgdocs.julialang.org/v1/artifacts/)
- [JLLWrappers.jl](https://github.com/JuliaPackaging/JLLWrappers.jl)
