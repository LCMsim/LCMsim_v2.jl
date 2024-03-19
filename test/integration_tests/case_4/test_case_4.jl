using Test
include("../integration_test_helper.jl")



function test_result()
    meshfile = "test/integration_tests/case_4/mesh_permeameter1.hm"
    partfile = "test/integration_tests/case_4/part_description.csv"
    simfile = "test/integration_tests/case_4/simulation_params.csv"
    true_results = "test/integration_tests/case_4/true_results.h5"
    deltat = 1e-2
    i_model = 2
    t_max = 200.
    debug_frequency = 100
    test_result = integration_test(
        meshfile,
        partfile,
        simfile,
        t_max,
        i_model,
        true_results,
        debug_frequency,
        deltat
    )
    test_result
end

@test test_result()