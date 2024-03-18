using Test
using HDF5
using GeometryBasics
using LinearAlgebra

include("../../src/LCMsim_v2.jl")


@testset "Test mesh parsing" begin
    # load correct results
    HyperMesh_file = "test/unit_tests/test_inputs/permeameter1_HyperMesh.bdf"
    Gmsh_file = "test/unit_tests/test_inputs/permeameter1_Gmsh.bdf"
    results_file = "test/unit_tests/true_results/permeameter1.h5" 
    cellgridid = Matrix{Int}(undef, 0, 3)
    grid = Matrix{Float64}(undef, 0, 3)
    # pids = Vector{Int}(undef, 0) # TODO can't be tested because it's not really supported in original code
    N = 0
    h5open(results_file, "r") do fid
        cellgridid = read_dataset(fid["/mesh/cells"], "cellgridid")
        grid = read_dataset(fid["/mesh/nodes"], "grid")
        # pids = read_dataset(fid["/mesh/aux"], "part_ids")
        N = read_attribute(fid["/mesh/cells"], "N")
    end
    vertices = Vector{Point3{Float64}}(undef, size(grid)[1])
    for i in 1:size(grid)[1]
        vertices[i] = Point3{Float64}(grid[i, :])
    end

    # HyperMesh format
    @test begin
        test_cellgridid, test_vertices, test_pids, test_N = LCMsim_v2.__parse_HyperMesh(HyperMesh_file)

        # test expression
        all(test_cellgridid .== cellgridid) && all(test_vertices .== vertices) && test_N == N
    end

    # Gmsh format
    @test begin
        test_cellgridid, test_vertices, test_pids, test_N = LCMsim_v2.__parse_gmsh(Gmsh_file)
    
        # test expression
        all(test_cellgridid .== cellgridid) && all(test_vertices .== vertices) && test_N == N
    end broken=true
end