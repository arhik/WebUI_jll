module WebUI_jll

using Artifacts
using Reexport

include("LibWebUI.jl")
@reexport using .LibWebUI

function __init__()
    if Sys.iswindows()
        libpath = joinpath(artifact"webui", "lib", "webui-2.dll")
        chmod(libpath, filemode(libpath) | 0o755)
    end
end

end
