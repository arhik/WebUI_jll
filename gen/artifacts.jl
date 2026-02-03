using Downloads
using Tar, SHA, Inflate

arch = lowercase(String(Sys.ARCH))
kernel = lowercase(String(Sys.KERNEL))

if kernel == "nt"
	kernel = "windows"
end

version = "v0.1.0"
kernels = ["linux", "macos", "windows"]
archs = ["aarch64", "x86_64", "armv7l", "i686"]

releaseType = "release"
upstreamVersion = "2.5.0-beta.3"

io = IOBuffer()

function writeIO(io, arch, kernel, sha1, sha256, filename, url)
	write(
		io,
		"""
		[[WebUI]]
		arch = "$arch"
		git-tree-sha1 = "$sha1"
		os = "$kernel"

			[[WebUI.download]]
			sha256 = "$sha256"
			url = "$(url)/$(filename)"

		"""
	)
end

remoteurl = "https://github.com/arhik/WebUI_jll/releases/download/$(version)"

function generateArtifacts()
	for kernel in kernels
		for arch in archs
			try
				mapping = getMapping(kernel, arch)
				if mapping === nothing
					continue
				end
				archive_name, lib_name = mapping
				releasefile = "$(archive_name).zip"
				tarfile = "webui.$(upstreamVersion).$(arch)-$(kernel).tar.gz"

				url = "https://github.com/webui-dev/webui/releases/download/nightly/$(releasefile)"
				Downloads.download(url, releasefile)

				rm("weblibs$(arch)$(kernel)", force=true, recursive=true)
				mkdir("weblibs$(arch)$(kernel)")
				run(`unzip $releasefile -d weblibs$(arch)$(kernel)`)

				# Repackage with proper structure in a separate build directory
				build_dir = "build$(arch)$(kernel)"
				rm(build_dir, force=true, recursive=true)
				mkpath(joinpath(build_dir, "lib"))
				mkpath(joinpath(build_dir, "include"))

				# Find and copy library from extracted source
				source_dir = "weblibs$(arch)$(kernel)/$(archive_name)"
				lib_ext = getExtension(kernel)
				for (root, dirs, files) in walkdir(source_dir)
					for file in files
						full_path = joinpath(root, file)
						if endswith(file, lib_ext) && !occursin("secure", file) && !occursin("debug", file) && !occursin("static", file)
							dest_name = getDestName(kernel)
							cp(full_path, joinpath(build_dir, "lib", dest_name), force=true)
							chmod(joinpath(build_dir, "lib", dest_name), 0o755)
						end
						if file == "webui.h"
							cp(full_path, joinpath(build_dir, "include", "webui.h"), force=true)
						end
					end
				end
				run(`tar -C $(build_dir) -czvf $tarfile .`)
				rm(build_dir, recursive=true)
				rm("weblibs$(arch)$(kernel)", recursive=true)
				rm("$releasefile")
				println("Generated $tarfile")
			catch(e)
				println("Skipping $kernel-$arch: $e")
			end
		end
	end
end

function getMapping(kernel, arch)
	if kernel == "linux"
		if arch == "x86_64"
			return ("webui-linux-gcc-x64", "webui-2.so")
		elseif arch == "aarch64"
			return ("webui-linux-gcc-arm64", "webui-2.so")
		elseif arch == "armv7l"
			return ("webui-linux-gcc-arm", "webui-2.so")
		end
	elseif kernel == "macos"
		if arch == "x86_64"
			return ("webui-macos-clang-x64", "libwebui-2.dylib")
		elseif arch == "aarch64"
			return ("webui-macos-clang-arm64", "libwebui-2.dylib")
		end
	elseif kernel == "windows"
		if arch == "x86_64"
			return ("webui-windows-msvc-x64", "webui-2.dll")
		elseif arch == "i686"
			return nothing
		end
	end
	return nothing
end

function getExtension(kernel)
	if kernel == "windows"
		return ".dll"
	elseif kernel == "macos"
		return ".dylib"
	else
		return ".so"
	end
end

function getDestName(kernel)
	if kernel == "windows"
		return "webui-2.dll"
	elseif kernel == "macos"
		return "libwebui-2.dylib"
	else
		return "libwebui-2.so"
	end
end

function writeArtifactsTOML()
	for kernel in kernels
		for arch in archs
			tarfile = "webui.$(upstreamVersion).$(arch)-$(kernel).tar.gz"
			if isfile(tarfile)
				try
					sha256Val = bytes2hex(open(sha256, tarfile))
					# Extract to temp dir and compute git-tree-sha1
					sha1Val = Tar.tree_hash(IOBuffer(inflate_gzip(tarfile)))
					writeIO(io, arch, kernel, sha1Val, sha256Val, tarfile, remoteurl)
					println("Processed $tarfile")
				catch(e)
					println("Error processing $tarfile: $e")
				end
			end
		end
	end
	seek(io, 0)
	f = open("Artifacts.toml", "w")
	write(f, io)
	close(f)
	mv("Artifacts.toml", "../Artifacts.toml", force=true)
end

generateArtifacts()
@info "Done generating Artifacts"
sleep(1)
writeArtifactsTOML()
println("Artifacts.toml created")
