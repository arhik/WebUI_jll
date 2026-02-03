using Libdl
using Pkg
using Pkg.Artifacts

const SIZE_MAX = 2^32
const UINT16_MAX = 0xffff
const UINT32_MAX = 0xffffffff
const UINT64_MAX = 0xffffffffffffffff

artifact_toml = joinpath(@__DIR__, "..", "Artifacts.toml")

webui_hash = artifact_hash("webui", artifact_toml)

webuilibpath = artifact_path(webui_hash)
resourceName = "webui-2"
const libWebUI = "$webuilibpath/lib/$resourceName.$(Libdl.dlext)" |> normpath
const libwebui = libWebUI
export libWebUI
