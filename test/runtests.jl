using Test
using Selafin

@testset "Selafin.jl" begin
    @test (data = Selafin.Read("../data/t2d_malpasset.slf")).nbnodes == 13541
    @test (data = Selafin.Read("../data/t2d_malpasset.slf")).nbsteps == 1
    @test (data = Selafin.Read("../data/t2d_malpasset.slf")).nbvars == 5
    @test (data = Selafin.Read("../data/t2d_malpasset.slf")).markposition == 474932
    @test isapprox((data = Selafin.Read("../data/t2d_malpasset.slf")).x[1], 5905.615234375)
    @test isapprox((data = Selafin.Read("../data/t2d_malpasset.slf")).y[13541], 4427.7314453125)
    @test min(Selafin.Quality((Selafin.Read("../data/t2d_malpasset.slf")))...) > 0.12
    @test Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 2) == nothing
    @test isapprox(min(Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 3, 1)...), 0.)
    @test size(Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 5, 1))[1] == 13541
end
