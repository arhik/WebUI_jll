using Test
using WebUI_jll
using Libdl

@testset "WebUI_jll Tests" begin
    @testset "Library Loading" begin
        @test isfile(libwebui)
        handle = dlopen(libwebui, RTLD_LAZY)
        @test handle != C_NULL
        dlclose(handle)
    end
end