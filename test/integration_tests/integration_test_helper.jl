using HDF5
using Printf
include("../../src/LCMsim_v2.jl")
using .LCMsim_v2

function integration_test(
    meshfile::String, 
    partfile::String,
    simfile::String,
    t_max::Float64,
    i_model::Int,
    true_results::String,
    test_frequency::Int,
    fixed_deltat::Float64,
    mesh = nothing
)::Bool

    if i_model == 1
        modeltype = LCMsim_v2.model_1
    elseif i_model == 2         
        modeltype = LCMsim_v2.model_2
    else
        modeltype = LCMsim_v2.model_3
    end

    case = nothing
    if isnothing(mesh)
        case = LCMsim_v2.create(meshfile, partfile, simfile, modeltype)
    else
        model = LCMsim_v2.create_SimParameters(mesh, simfile, modeltype) 
        state = LCMsim_v2.create_initial_state(mesh, model)

        case = LCMsim_v2.LcmCase(
            mesh,
            model,
            state
        )
    end

    # test volume
    test_volume = Vector{Float64}(undef, case.mesh.N)
    test_permeability = Vector{Float64}(undef, case.mesh.N)
    for i in 1:case.mesh.N
        test_volume[i] = case.mesh.cells[i].volume
        test_permeability[i] = case.mesh.cells[i].permeability
    end

    h5open(true_results, "r") do fid
        true_volume = read_dataset(fid["/mesh/aux"], "cellvolume")
        volume_diff, volume_ind = findmax(abs.(true_volume .- test_volume))
        @info "Maximum volume difference (" * string(volume_ind) * ", " * string(volume_diff) * ")" 

        true_permeability = read_dataset(fid["/mesh/parameters"], "cellpermeability")
        permeability_diff, permeability_ind = findmax(abs.(true_permeability .- test_permeability))
        @info "Maximum permeability difference (" * string(permeability_ind) * ", " * string(permeability_diff) * ")" 
    end
    LCMsim_v2.save_plottable_mesh(case.mesh, "test.h5")
    LCMsim_v2.save_state(case.state, "test.h5")

    test = false
    h5open(true_results, "r") do fid
        true_states = fid["/simulation"]
        test = compare_state(case.state, true_states)
    end

    if test == false
        return false
    end

    state = case.state
    t = 0.
    while t < t_max
        state = LCMsim_v2.solve(case.model, case.mesh, state, t_max, LCMsim_v2.silent, test_frequency, fixed_deltat)
        if state.t > t_max
            return true
        end
        h5open(true_results, "r") do fid
            true_states = fid["/simulation"]
            test = compare_state(state, true_states)
        end
        if test == false 
            return false
        end
    end
    return true
end 

function compare_state(
    test_state::LCMsim_v2.State,
    true_states::HDF5.Group,
    eps=1e-9
)

    state_string = @sprintf("state%09i", test_state.iter)   
    state_group = true_states[state_string]

    true_t = read_attribute(state_group, "t")

    if abs(true_t - test_state.t) >= eps
        @info "Comparing state " * string(test_state.iter) * ": Timestamps do not match."
        return false
    end

    true_p = read_dataset(state_group, "p")
    true_rho = read_dataset(state_group, "rho")
    true_u = read_dataset(state_group, "u")
    true_v = read_dataset(state_group, "v")
    true_gamma = read_dataset(state_group, "gamma")

    (p_diff, p_ind) = findmax(abs.(true_p .- test_state.p))
    (rho_diff, rho_ind) = findmax(abs.(true_rho .- test_state.rho))
    (u_diff, u_ind) = findmax(abs.(true_u .- test_state.u))
    (v_diff, v_ind) = findmax(abs.(true_v .- test_state.v))
    (gamma_diff, gamma_ind) = findmax(abs.(true_gamma .- test_state.gamma))

    pass = true

    if p_diff >= eps
        @info "Comparing state " * string(test_state.iter) * ": 'p's do not match. Maximum difference: (" * string(p_ind) * ", " * string(p_diff) * ")"
        pass = false
    end
    
    if rho_diff >= eps
        @info "Comparing state " * string(test_state.iter) * ": 'rho's do not match. Maximum difference: (" * string(rho_ind) * ", " * string(rho_diff) * ")"
        pass = false
    end

    if u_diff >= eps
        @info "Comparing state " * string(test_state.iter) * ": 'u's do not match. Maximum difference: (" * string(u_ind) * ", " * string(u_diff) * ")"
        pass = false
    end

    if v_diff >= eps
        @info "Comparing state " * string(test_state.iter) * ": 'v's do not match. Maximum difference: (" * string(v_ind) * ", " * string(v_diff) * ")"
        pass = false
    end

    if gamma_diff >= eps
        @info "Comparing state " * string(test_state.iter) * ": 'gamma's do not match. Maximum difference: (" * string(gamma_ind) * ", " * string(gamma_diff) * ")"
        pass = false
    end

    if pass == false
        return false
    end
    
    max_diff = maximum([p_diff rho_diff u_diff v_diff gamma_diff])

    @info "Sucessfully compared state " * string(test_state.iter) * ". Maximum difference: " * string(max_diff)
    return true
end