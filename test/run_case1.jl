include("../src/LCMsim_v2.jl")

mypath=pwd()
savepath = joinpath(mypath,"test")
meshfile = joinpath(mypath,"test","mesh_1.dat")
partfile = joinpath(mypath,"test","part_description_1.csv")
simfile = joinpath(mypath,"test","simulation_params_1.csv")
i_model=3
t_max = 200.

@info "mypath = $mypath"
@info "meshfile = $meshfile"
@info "partfile = $partfile"
@info "simfile = $simfile"

t_step = t_max/16
if i_model == 1
    modeltype = LCMsim_v2.model_1
elseif i_model == 2         
    modeltype = LCMsim_v2.model_2
else
    modeltype = LCMsim_v2.model_3
end  

filename_parts=splitpath(meshfile)
meshfilename_parts=splitpath(meshfile)
meshfilename_parts[end]="_" * meshfilename_parts[end]
writefilename=joinpath(meshfilename_parts)

LCMsim_v2.create_and_solve(savepath,meshfile,partfile,simfile,modeltype,t_max,t_step,LCMsim_v2.verbose,true,true)

include("plot_case1.jl");

