using Test
include("../integration_test_helper.jl")



function test_result()
    meshfile = "test/integration_tests/case_5/mesh_7.dat"
    partfile = "test/integration_tests/case_5/part_description_7.csv"
    simfile = "test/integration_tests/case_5/simulation_params_7.csv"
    true_results = "test/integration_tests/case_5/true_results.h5"
    deltat = 1e-2
    i_model = 2
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