using GeometryBasics

function __parse_gmsh(filename::String)
    ind = Int32(1)
    gridind = Int32(1)
    orig_sets = []
    origgridid = []
    gridx::Vector{Float64} = []
    gridy::Vector{Float64} = []
    gridz::Vector{Float64} = []
    celloriggridid = []
    pid::Vector{Int8} = []
    cellgridid = Matrix{Int32}(undef, 0, 3)

    open(filename, "r") do fid
        line = 1
        while !eof(fid)
            thisline = readline(fid)
            if length(thisline) >= 8
                card = thisline[1:8]
                if cmp(card, "GRID    ") == 0
                    gridindstring = thisline[9:16]
                    origgridid = vcat(origgridid, parse(Int32, gridindstring))
                    txt = thisline[25:32]
                    txt = replace(txt, " " => "")
                    txt = replace(txt, "E" => "")
                    txt = replace(txt, "e" => "")
                    txt1 = replace(txt, "-" => "e-")
                    txt1 = replace(txt1, "+" => "e+")
                    if cmp(txt1[1], 'e') == 0
                        txt2 = txt1[2:end]
                    else
                        txt2 = txt1
                    end
                    val = parse(Float64, txt2)
                    val1 = val
                    txt = thisline[33:40]
                    txt = replace(txt, " " => "")
                    txt = replace(txt, "E" => "")
                    txt = replace(txt, "e" => "")
                    txt1 = replace(txt, "-" => "e-")
                    txt1 = replace(txt1, "+" => "e+")
                    if cmp(txt1[1], 'e') == 0
                        txt2 = txt1[2:end]
                    else
                        txt2 = txt1
                    end
                    val = parse(Float64, txt2)
                    val2 = val
                    txt = thisline[41:48]
                    txt = replace(txt, " " => "")
                    txt = replace(txt, "E" => "")
                    txt = replace(txt, "e" => "")
                    txt1 = replace(txt, "-" => "e-")
                    txt1 = replace(txt1, "+" => "e+")
                    if cmp(txt1[1], 'e') == 0
                        txt2 = txt1[2:end]
                    else
                        txt2 = txt1
                    end
                    val = parse(Float64, txt2)
                    val3 = val
                    gridx = vcat(gridx, Float64(val1))
                    gridy = vcat(gridy, Float64(val2))
                    gridz = vcat(gridz, Float64(val3))
                    gridind = gridind + 1
                elseif cmp(card, "CTRIA3  ") == 0
                    celloriggridid = vcat(celloriggridid, parse(Int32, thisline[9:16]))
                    pid = vcat(pid, parse(Int8, thisline[17:24]))
                    i1val = parse(Int32, thisline[25:32])
                    i1 = findfirst(isequal(i1val), origgridid)
                    i2val = parse(Int32, thisline[33:40])
                    i2 = findfirst(isequal(i2val), origgridid)
                    i3val = parse(Int32, thisline[41:end])
                    i3 = findfirst(isequal(i3val), origgridid)
                    ivec = [i1, i2, i3]
                    idel = findall(isequal(min(ivec[1], ivec[2], ivec[3])), ivec)
                    deleteat!(ivec, idel)
                    idel = findall(isequal(max(ivec[1], ivec[2])), ivec)
                    deleteat!(ivec, idel)
                    cellgridid = vcat(cellgridid, [min(i1, i2, i3) ivec[1] max(i1, i2, i3)])
                    ind = ind + 1
                end
            end
            line += 1
        end
    end
    N = ind - 1  #total number of cells

    # convert indices
    sets = []
    for set in (orig_sets)
        new_set = []
        for i in 1:length(set)
            i1 = findfirst(isequal(orig_sets[i]), celloriggridid)
            new_set = vcat(new_set, i1)
        end
        push!(sets, new_set)
    end

    grid = [gridx gridy gridz]

    cellgridid = Int32.(cellgridid)
    N = Int32(N)

    vertices = [Point3{Float64}(grid[i, :]) for i in 1:size(grid)[1]]

    return Int.(cellgridid), vertices::Vector{Point3{Float64}}, Int.(pid), Int(N)
end

function __parse_HyperMesh(filename::String)

    # TODO clean this up, do logic here
    grid_vec, ctria_vec = parse_HyperMeshNastran(filename)

    pids = Vector{Int}(undef, 0)
    cellgridid = Matrix{Int}(undef, 0, 3)
    for i in 1:size(ctria_vec)[1]
        push!(pids, ctria_vec[i][1])
        cellgridid = vcat(cellgridid, transpose(sort(ctria_vec[i][2:4])))
    end
    grid = Vector{Point3{Float64}}(undef, 0)
    for i in 1:size(grid_vec)[1]
        push!(grid, Point3{Float64}(grid_vec[i]))
    end

    return cellgridid, grid, pids, size(cellgridid)[1]
end

function parse_mesh(meshfile::String)
    # TODO add support for different mesh formats, check better than this
    format = ""
    open(meshfile, "r") do fid
        i = 1
        format = "gmsh"
        while i < 10
            line = readline(fid)
            if !isnothing(match(Regex("HyperMesh"), line))
                format = "HyperMesh"
                break
            end
            i += 1
        end
    end

    cellgridid = Matrix{Int}(undef, 0, 3)
    vertices = Vector{Point3{Float64}}(undef, 0)
    pids = Vector{Int}(undef, 0)
    N = 0

    if format == "gmsh"
        @debug "PARSE GMSH"
        cellgridid, vertices, pids, N = __parse_gmsh(meshfile)
    elseif format == "HyperMesh"
        @debug "PARSE HyperMesh"
        cellgridid, vertices, pids, N = __parse_HyperMesh(meshfile)
    end

    return cellgridid, vertices, pids, N
end