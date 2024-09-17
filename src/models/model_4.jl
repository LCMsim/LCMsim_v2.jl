function update_rho(
    model::Model_4,
    Δt::Float64, 
    props::ScaledProperties,
    rho_old::Float64, 
    F_rho_num::Float64, 
    cellporositytimescellporosityfactor_old::Float64
    )::Float64

    rho_new = (props.porosity * rho_old - Δt * F_rho_num / props.volume) / props.porosity

    return max(rho_new, 0.0)
end

function update_porosity_times_porosity(
    model::Model_4,
    props::ScaledProperties
)

    return 1.0
end

function scale_properties(
    model::Model_4,
    cell::LcmCell,
    p_old::Float64,
    porosity_times_porosity_old::Float64,
    viscosity::Float64,
    iter::Int
    )::ScaledProperties

    faces = [x.face_area for x in cell.neighbours]

    return ScaledProperties(
        cell.thickness,
        cell.volume,
        faces,
        cell.porosity,
        cell.permeability,
        viscosity,
        cell.alpha
    )
end

function update_doc(
    model::Model_4,
    Δt::Float64, 
    props::ScaledProperties,
    doc_old::Float64, 
    gamma_old::Float64,
    gamma_new::Float64,
    F_doc_num::Float64, 
    F_doc_num1::Float64, 
    cellporositytimescellporosityfactor_old::Float64,
    k_doc::Float64, 
    n_doc::Float64
    )::Float64

    #To do: Modify this equation
    if gamma_old<=0.001  #Convection of doc only active after filling if above threshold, otherwise artificially fully cured very small amount of cured material in cell
        fact_conv=0.
    else
        fact_conv=1.
    end
    S_doc=k_doc*(1-doc_old)^n_doc  #k_doc*(doc_old)^n_doc  #
    #doc_new = (props.porosity * doc_old * (gamma_old+1e-6) - Δt *0* (F_doc_num - doc_old*F_doc_num1 ) / props.volume   + Δt*S_doc*props.porosity ) / (props.porosity*(gamma_new+1e-6))
    doc_new = (props.porosity * doc_old * (gamma_old+1e-6) - Δt *fact_conv* (F_doc_num - doc_old*gamma_old*F_doc_num1 ) / props.volume   + Δt*S_doc*props.porosity*gamma_old ) / (props.porosity*(gamma_old+1e-6))
    #@info "k_doc = $k_doc."
    #@info "n_doc = $n_doc."
    #@info "doc_new = $doc_new."

    return max(min(doc_new,1.0), 0.0)
end

function update_viscosity(
    model::Model_4,
    scaled_properties::ScaledProperties,
    gamma_new::Float64,
    doc_new::Float64
)
    viscosity_new=model.mu_resin*exp(model.k_mu*doc_new)    #Multiply input viscosity model.mu_resin with a function which is zero at doc=0. and one at doc=1.;
                      #An addition model parameter could be required.
    return viscosity_new
end