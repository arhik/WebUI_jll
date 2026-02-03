module WebUI_jll

using Artifacts
using Reexport

include("LibWebUI.jl")
@reexport using .LibWebUI

function __init__()
    if Sys.iswindows()
        libpath = joinpath(artifact"WebUI", "lib", "webui-2")
        chmod(libpath, filemode(libpath) | 0o755)
    end
end

end
