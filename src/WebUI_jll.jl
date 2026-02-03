module WGPU_jll

using Artifacts
using Reexport

include("LibWebUI.jl")
@reexport using .LibWGPU

function __init__()
    if Sys.iswindows()
        libpath = joinpath(artifact"WebUI", "lib", "wgpu_native.dll")
        chmod(libpath, filemode(libpath) | 0o755)
    end
end

end
