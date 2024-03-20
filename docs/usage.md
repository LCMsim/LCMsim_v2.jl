# Programming Interface

The public interface of LCMsim_v2.jl is designed mainly for two purposes:
- solving cases via simple scripts
- being able to embed the solver in bigger programs

The availabe functions and their intended usage are descibed in the following sections.
However, since not every possible usecase could be foreseen and most of the internal functions are
documented, you should be able to adapt the program to your custom needs.


## Data structures and artifacts
When working with LCMsim_v2, you will encounter different in-program data structures and/ or file formats to persistently save simulation results.
Data structures:
- LcmMesh/ LcmCell
- State
- AbstractModel
- LcmCase

Two file formats are used:
- human-readable results (HDF)
- binary dump (JLD2)

### LcmMesh/ LcmCell
```
struct LcmMesh 
    N::Int
    vertices::Vector{Point3{Float64}}
    cells::Vector{LcmCell}
    ...
end
```

```
struct LcmCell
    id::Int
    
    # basic cell geometry
    vertex_ids::Tuple{Int, Int, Int}
    ...

    # cell parameters
    thickness::Float64
    area::Float64
    volume::Float64
    permeability::Float64
    porosity::Float64
    ...
end
```

`LcmMesh` represents a mesh, which mainly consists of a vector of `LcmCell`. Most of the information should not be relevant for most users, so it's not included here (extensive documentation can be found in code).
If you want to visualize the mesh directly from the struct, you will need the `vertices` field of `LcmMesh` for the vertex coordinates and the connectivity information. This can be retrieved by iterating over the cells and retrieving each cell's `vertex_ids`, which defines the three vertices making up this cell.
Some cell wise properties possibly interesting for plots can be retrieved in the same manner, for example the permeabilities, porosities, ...

Disclaimer: It is more convenient to create plots from the HDF-files, so this is usually the way to go.

### State
```
struct State
    t::Float64
    iter::Int
    deltat::Float64
    p::Vector{Float64}
    gamma::Vector{Float64}
    rho::Vector{Float64}
    u::Vector{Float64}
    v::Vector{Float64}
    viscosity::Vector{Float64}
    porosity_times_porosity::Vector{Float64}
end
```
The state struct describes the time varying variables of a simulation case. The vectorial fields can be matched to the cells of the mesh that this state has been created from.

### LcmCase
```
struct LcmCase
    mesh::LcmMesh
    model::AbstractModel
    state::State
end
```
This struct describes the state of a simulation entirely and can be used to start solving. `model` will be a concrete subtype of `AbstractModel` that is determined by the input settings and influences the behaviour of the solver.

### HDF
The module will generate HDF files of the following structure:
- mesh
    - cells
    - vertices
- properties
    - part_id
    - permeability
    - porosity
    - thickness
    - type
    - volume
- state000000001
    - cellporositytimecellporosity
    - gamma
    - p
    - rho
    - u
    - v
    - viscosity
    - Attributes: [deltat, iter, t]
- state...

`mesh/vertices` is a 3 by *M* float field, where *M* is the number of vertices. Each 3-entry line describes the x, y, and z coordinates of the vertex associated with this line's index. Note that, since julia is 1-indexed, we use 1-indexing for the HDF-files too, even though most HDF viewers display 0-based indices.

`mesh/cells` is a 3 by *N* integer field, where *N* is the number of cells. Each 3-entry line indicates which 3 vertices make up this cell.

Depending on the setup of the simulation, a varying number of states will be created. The name of a state indicates the iteration counter.
All datasets in `properties` and `stateXXXXXXXXX` refer to the cells of the mesh.

Currently it is not possible to (re)start the solver directly from a these files, since they are meant solely as a way to output the results.

### JLD2
The binary files created by LCMsim_v2 contain an entire `LcmCase` struct. There are convenience functions to create such a file and start/ continue a simulation directly from the file path.
The results are not human readable but can be retrieved via a Julia script (you'll need to include this module!).
Example for loading:
```
# load the jld2 file
jld2file = JLD2.load(path)

# extract the LcmCase object
case = jld2file["LcmCase"]

# get state from case
state = case.state
```

## Functions

### create
```
create(
    meshfile::String,
    partfile::String,
    simfile::String,
    i_model::ModelType,
)::LcmCase
```
Function for in-program usage. Takes paths to the meshfile, the part description file and the simulation parameter file Returns a LcmCase instance.

```
create(
    meshfile::String,
    partfile::String,
    simfile::String,
    i_model::ModelType,
    save_path::String,
    save_binary::Bool=true,
    save_hdf::Bool=true
)::LcmCase
```
Function to also save the results as `data.h5` / `data.jld2` at the given `save_path`.

### solve
```
solve(
    case::LcmCase,
    t_max::Float64
)::LcmCase
```
Solve the given LcmCase up to the specified end time. If you want to receive simulation results at certain point in time, the usual usage would be to call this function repeatedly while incrementing `t_max` and passing the returned LcmCase back in. If your use case only requires the results at the end, you would invoke the solver only once.

```
solve(
    source_path::String,
    save_path::String,
    t_max::Float64,
    t_step::Float64,
    verbosity=verbose::Verbosity,
    save_binary::Bool=true,
    save_hdf::Bool=true
)::Nothing
```
This is a convenience function to start/ continue a simulation from a previously saved LcmCase. `source_path` needs to point to an appropriate .jld2-file. Then the problem up is solved to the specified `t_max`. Results are saved in hdf5 format every `t_step` seconds. If `t_step <= 0.0` is provided, it is set to t_max, aka the results are only saved at the end. Additionally saves the resulting LcmCase as binary in jld2 format.


### create_and_solve
```
solve(
    source_path::String,
    save_path::String,
    t_max::Float64,
    t_step::Float64,
    verbosity=verbose::Verbosity,
    save_binary::Bool=true,
    save_hdf::Bool=true
)::Nothing
````
Convenience function the behaves like `create` and `solve`.