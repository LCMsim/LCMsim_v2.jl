using Test
include("../integration_test_helper.jl")



function test_result()
    meshfile = "test/integration_tests/case_7/mesh_10.dat"
    partfile = "test/integration_tests/case_7/part_description_10.csv"
    simfile = "test/integration_tests/case_7/simulation_params_10.csv"
    true_results = "test/integration_tests/case_7/true_results.h5"
    deltat = 1e-2
    i_model = 1
    t_max = 3.0
    debug_frequency = 1
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