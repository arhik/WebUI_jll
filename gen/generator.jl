using Clang.Generators

arch = lowercase(String(Sys.ARCH))
kernel = lowercase(String(Sys.KERNEL))

if kernel == "darwin"
	kernel = "macos"
	compiler = "clang"
elseif kernel == "nt"
	arch = "x64"
	kernel = "windows"
	compiler = "msvc"
else
	kernel = "linux"
	compiler = "gcc"
end

upstreamVersion = "2.5.0-beta.3"

releasefile = "webui-$(kernel)-$(compiler)-$(arch).zip"
url = "https://github.com/webui-dev/webui/releases/download/nightly/$(releasefile)"

download(url, releasefile)

rm("weblib", recursive=true, force=true)
mkdir("weblib")
run(`unzip $(releasefile) -d weblib`)

rm(releasefile)

extracted_dir = "webui-$(kernel)-$(compiler)-$(arch)"
header_path = joinpath("weblib", extracted_dir, "include", "webui.h")

const WEBUI_HEADERS = [header_path]

options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, joinpath(@__DIR__, "weblib", extracted_dir, "include"))

ctx = create_context(WEBUI_HEADERS, args, options)

build!(ctx)

rm("weblib", recursive=true, force=true)
