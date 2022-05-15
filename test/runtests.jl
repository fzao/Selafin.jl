using Test
using Selafin

@testset "Selafin.jl" begin
    @test (Selafin.Read("../data/t2d_malpasset.slf")).nbnodes == 13541
    @test (Selafin.Read("../data/t2d_malpasset.slf")).nbsteps == 1
    @test (Selafin.Read("../data/t2d_malpasset.slf")).nbvars == 5
    @test (Selafin.Read("../data/t2d_malpasset.slf")).markposition == 474932
    @test isapprox((Selafin.Read("../data/t2d_malpasset.slf")).x[1], 5905.615234375)
    @test isapprox((Selafin.Read("../data/t2d_malpasset.slf")).y[13541], 4427.7314453125)
    @test min(Selafin.Quality((Selafin.Read("../data/t2d_malpasset.slf")))...) > 0.12
    @test isnothing(Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 2))
    @test isapprox(min(Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 3, 1)...), 0.)
    @test size(Selafin.Get(Selafin.Read("../data/t2d_malpasset.slf"), 5, 1))[1] == 13541
    @test (Selafin.Read("../data/t3d_piledepon.slf")).nbnodesLayer == 2280
    @test (Selafin.Read("../data/t3d_piledepon.slf")).nbsteps == 9
    @test (Selafin.Read("../data/t3d_piledepon.slf")).nbvars == 4
    @test (Selafin.Read("../data/t3d_piledepon.slf")).varnames[4] == "VELOCITY W      M/S             "
    @test (Selafin.Read("../data/t3d_piledepon.slf")).timestep == 10
    @test min(Selafin.Quality((Selafin.Read("../data/t3d_piledepon.slf")))...) > 0.47
    @test isapprox(max(Selafin.Quality((Selafin.Read("../data/t3d_piledepon.slf")))...), 0.9931093f0)
    @test all(Selafin.Get(Selafin.Read("../data/t3d_piledepon.slf"),1 ,1 ,1) .< 0)
    @test isnothing(Selafin.Get(Selafin.Read("../data/t3d_piledepon.slf"),1 ,1 ,10))
    @test isapprox(max(Selafin.Get(Selafin.Read("../data/t3d_piledepon.slf"),2, 3, 6)...), 2.4606469f0)
end
