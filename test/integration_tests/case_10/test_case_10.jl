using Test
include("../integration_test_helper.jl")

using .LCMsim_v2


function test_result()
    meshfile = "test/integration_tests/case_10/mesh_10.dat"
    partfile = "test/integration_tests/case_10/part_description_10.csv"
    simfile = "test/integration_tests/case_10/simulation_params_10.csv"
    true_results = "test/integration_tests/case_10/true_results.h5"
    deltat = 1e-2
    i_model = 2
    t_max = 3.0
    debug_frequency = 1

    mesh = LCMsim_v2.load_original_mesh(true_results)

    test_result = integration_test(
        meshfile,
        partfile,
        simfile,
        t_max,
        i_model,
        true_results,
        debug_frequency,
        deltat,
        mesh
    )
    test_result
end

@test test_result()