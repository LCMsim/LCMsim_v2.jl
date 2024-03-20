using HDF5

"""
    Writes a list of (name, data) tuples as attributes to 'parent'. 
    Caller is responsible to provide a valid parent and attributes.
"""
function write_attributes(parent::Union{HDF5.File,HDF5.Group}, attributes)::Nothing
    for (name, attr) in attributes
        write_attribute(parent, name, attr)
    end
end

"""
    write_datasets(parent::Union{HDF5.File,HDF5.Group}, datasets)::Nothing

    Writes a list of (name, data) tuples as datasets to 'parent'. 
    Caller is responsible to provide a valid parent and data.
"""
function write_datasets(parent::Union{HDF5.File,HDF5.Group}, datasets)::Nothing
    for (name, arr) in datasets
        write_dataset(parent, name, arr)
    end
end

"""
    saveLcmMesh(mesh::LcmMesh, filename::String)

    Saves a LcmMesh struct instance in hdf-format.
"""
function saveLcmMesh(mesh::LcmMesh, filename::String)
    # collect properties from lcm mesh struct
    neighbours = Matrix{Int}(undef, mesh.N, 3)
    centers = Matrix{Float64}(undef, mesh.N, 3)
    cellvolume = Vector{Float64}(undef, mesh.N)
    T11 = Matrix{Float64}(undef, mesh.N, 3)
    T12 = Matrix{Float64}(undef, mesh.N, 3)
    T21 = Matrix{Float64}(undef, mesh.N, 3)
    T22 = Matrix{Float64}(undef, mesh.N, 3)
    cellfacearea = Matrix{Float64}(undef, mesh.N, 3)
    cellfacenormal = Array{Float64}(undef, mesh.N, 3, 2)
    cellcentertocellcenter = Array{Float64}(undef, mesh.N, 3, 2)
    for (cid, cell) in enumerate(mesh.cells)  
        neighbours[cid, 1:cell.num_neighbours] = cell.neighbour_ids
        centers[cid, :] =  cell.center[1:3]

        for nid in 1:cell.num_neighbours
            T11[cid, nid] = cell.neighbours[nid].transformation[1, 1]
            T12[cid, nid] = cell.neighbours[nid].transformation[1, 2]
            T21[cid, nid] = cell.neighbours[nid].transformation[2, 1]
            T22[cid, nid] = cell.neighbours[nid].transformation[2, 2]
            cellfacearea[cid, nid] = cell.neighbours[nid].face_area
            cellfacenormal[cid, nid, :] = cell.neighbours[nid].face_normal
            cellcentertocellcenter[cid, nid, :] = cell.neighbours[nid].toCenter
        end
        cellvolume[cid] = cell.volume
    end
    # write data to structured format
    h5open(filename, "w") do fid
        mesh = create_group(fid, GROUP_MESH)

        aux = create_group(mesh, "aux")
        write_dataset(aux, "cellvolume", cellvolume)
        write_dataset(aux, "T11", T11)
        write_dataset(aux, "T12", T12)
        write_dataset(aux, "T21", T21)
        write_dataset(aux, "T22", T22)
        write_dataset(aux, "cellcenters", centers)
        write_dataset(aux, "cellcentertocellcenter", cellcentertocellcenter)
        write_dataset(aux, "cellfacearea", cellfacearea)
        write_dataset(aux, "cellfacenormal", cellfacenormal)
        write_dataset(aux, "cellneighboursarray", neighbours)



    end
end

"""
    save_plottable_mesh(mesh::LcmMesh, filename::String)::Nothing

    Saves the information needed to plot a mesh in hdf-format.
"""
function save_plottable_mesh(mesh::LcmMesh, filename::String)::Nothing
        cells = Matrix{Int}(undef, mesh.N, 3)

        # properties that could be of interest to plot
        type = Vector{Int}(undef, mesh.N)
        part_id= Vector{Int}(undef, mesh.N)
        thickness = Vector{Float64}(undef, mesh.N)
        permeability = Vector{Float64}(undef, mesh.N)
        porosity = Vector{Float64}(undef, mesh.N)
        volume = Vector{Float64}(undef, mesh.N)

        for (cid, cell) in enumerate(mesh.cells)  
            cells[cid, :] .= cell.vertex_ids
            type[cid] = Integer(cell.type)
            part_id[cid] = cell.part_id
            thickness[cid] = cell.thickness
            permeability[cid] = cell.permeability
            porosity[cid] = cell.porosity
            volume[cid] = cell.volume
        end

        M = length(mesh.vertices)
        vertices = Matrix{Float64}(undef, M, 3)
        for (vid, vertex) in enumerate(mesh.vertices)
            vertices[vid, :] = vertex
        end

        # write data to structured format
        h5open(filename, "w") do fid
            mesh = create_group(fid, "mesh")
            write_dataset(mesh, "vertices", vertices)
            write_dataset(mesh, "cells", cells)
    
            props = create_group(fid, "properties")
            write_dataset(props, "volume", volume)
            write_dataset(props, "permeability", permeability)
            write_dataset(props, "porosity", porosity)
            write_dataset(props, "thickness", thickness)
            write_dataset(props, "type", type)
            write_dataset(props, "part_id", part_id)
        end
end

"""
    save_state(
        state::State,
        file::String,
    )::Nothing

    Requires an existing hdf5 file and a state struct.
    Creates a group named ("state%09i", iter) at meshfile["/"] and
    writes state attributes/ datasets to it.

    Example: iter = 1 -> "state000000001"
"""
function save_state(
    state::State,
    file::String,
)::Nothing
    h5open(file, "r+") do fid
        statestring = @sprintf("state%09i", state.iter)    
        state_group = create_group(fid, statestring)

        write_attributes(
            state_group,
            [
                (HDF_T, state.t),
                (HDF_ITER, state.iter), 
                (HDF_DELTAT, state.deltat)
            ]
        )
        write_datasets(
            state_group, 
            [
                (HDF_P, state.p),
                (HDF_RHO, state.rho),
                (HDF_U, state.u),
                (HDF_V, state.v),
                (HDF_GAMMA, state.gamma),
                (HDF_VISCOSITY, state.viscosity),
                (HDF_CELLPOROSITYTIMESCELLPOROSITY_FACTOR, state.porosity_times_porosity)
            ]
        )
    end
end

"""
    check_path(path::String)::Tuple{String, String}

    Checks if the given path exists and returns the path to the hdf5 and jld2 file.
"""
function check_path(path::String)::Tuple{String, String}
    # assert that path exists
    @assert isdir(path) "The given path does not exist."

    # check if path contains trailing slash
    if path[end] == '/'
        return path * "data.h5", path * "data.jld2"
    else
        return path * "/data.h5", path * "/data.jld2"
    end
end

"""
    load_case(path::String)::LcmCase

    Loads a LcmCase object from a jld2 file.
"""
function load_case(path::String)::LcmCase
    # assert that path exists
    @assert isfile(path), "The given path does not exist."

    # load the jld2 file
    jld2file = JLD2.load(path)

    # extract the LcmCase object
    return jld2file["LcmCase"]
end

"""
    save_case(case::LcmCase, path::String)::Nothing

    Saves a LcmCase object to a jld2 file.
"""
function save_case(case::LcmCase, path::String)::Nothing
    # assert that path exists
    @assert isdir(path) "The given path does not exist."

    # save the LcmCase object
    JLD2.save(path * "/data.jld2", "LcmCase", case)
end

# funtion to log license and version
function log_license()
    @info """
    LCMsim_v2 version 1.0
    LCMsim_v2 is Julia code which simulates the mold filling in Liquid Composite Molding (LCM) 
    manufacturing process. 
    Copyright (C) 2023 Christof Obertscheider / University of Applied Sciences Wiener Neustadt (FHWN)

    This program is free software; you can redistribute it and/or modify it under the terms of the 
    GNU General Public License as published by the Free Software Foundation; either version 2 of the 
    License, or (at your option) any later version. This program is distributed in the hope that it 
    will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
    FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License along with this program. If not, 
    see http://www.gnu.org/licenses/. 
    
    This software is free of charge and may be used for commercial and academic purposes. Please mention 
    the use of this software at an appropriate place in your work.

    Submit bug reports to christof.obertscheider@fhwn.ac.at
    """
end
