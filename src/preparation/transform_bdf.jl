using Printf

function tabToSpace(s::String, n=8)
    i = findfirst("\t", s)
    while !isnothing(i)
        i = i[1]
        m = i % n
        if m == 1
            tab = repeat(" ", n)
        elseif m == 0
            tab = " "
        else
            tab = repeat(" ", n - (i % n) + 1)
        end
        s = s[1:i - 1] * tab * s[i + 1:end] 
        i = findfirst("\t", s)
    end
    return s
end

function parse_HyperMeshNastran(inputfile::String)
    grid = Dict()
    ctria = Dict()
    sets = []
    temp_set = []
    set_parsing_active = false
    dummy_part_id = 1


    lines = readlines(inputfile)

    for line in lines
        if set_parsing_active
            if isnothing(match(Regex("HMSET"), line))
                push!(temp_set, line)
            else
                part_id = parse(Int, match(Regex("[0-9]+\\s="), temp_set[1]).match[1:end-1]) + 1
                ids = []

                for l in temp_set
                    ids_string = match(Regex("([0-9]+,)+[0-9]+"), l).match
                    append!(ids, split(ids_string, ","))
                end

                ids = [parse(Int, id) for id in ids]

                push!(sets, (part_id, ids))
                temp_set = []
                set_parsing_active = false
            end
        elseif !isnothing(match(Regex("GRID\\s*[0-9]+"), line))
            id = parse(Int, match(Regex("\\s[0-9]+\\s"), line).match)
            coords = line[25:end]

            (x, y, z) = parse_coordinate_line(String(coords))

            pos = length(grid) + 1
            grid[id] = (pos, [x, y, z])

        elseif !isnothing(match(Regex("CTRIA3\\s*[0-9]+"), line))
            id = parse(Int, match(Regex("\\s[0-9]+\\s"), line).match)
            verts = match(Regex("(\\s+[0-9]+){3}\$"), line).match
            verts = split(verts, Regex("\\s+"))
            verts = [parse(Int, x) for x in verts[2:end]]

            ctria[id] = (dummy_part_id, verts)

        elseif !isnothing(match(Regex("SET\\s[0-9]+\\s="), line))
            set_parsing_active = true
            push!(temp_set, line)
        end
    end

    ctria_vec = Vector{Any}(nothing, length(ctria))
    grid_vec = Vector{Any}(nothing, length(grid))
    for (part_id, cells) in sets
        for cid in cells
            ctria[cid] = (part_id, ctria[cid][2])
        end
    end

    # rename verts
    for (i, cell) in enumerate(ctria)
        cid = cell[1]
        pid = cell[2][1]
        verts = cell[2][2]
        verts = [grid[gid][1] for gid in verts]
        ctria_vec[cid] = [pid, verts...]
    end


    for vert in grid
        gid = vert[2][1] # gid after renaming
        grid_vec[gid] = vert[2][2]
    end

    return grid_vec, ctria_vec
end

function write_GmshNastran(outputfile::String, grid, ctria)

    open(outputfile, "w") do f

        for (gid, vert) in enumerate(grid)
            x = ""
            y = ""
            if vert[1] == 0.
                x = "0.00E+00"
            else
                if vert[1] < 0.
                    x = @sprintf("%1.5f", vert[1])
                else
                    x = @sprintf("%1.6f", vert[1])
                end
            end
            
            if vert[2] == 0.
                y = "0.00E+00"
            else
                if vert[2] < 0.
                    y = @sprintf("%1.5f", vert[2])
                else
                    y = @sprintf("%1.6f", vert[2])
                end
            end

            l = "GRID    " * string(gid) * "\t0\t" * x * y * "0.00E+00" * "\n"
            write(f, tabToSpace(l))
        end

        for (cid, cell) in enumerate(ctria)
            l = "CTRIA3\t" * string(cid) * "\t" * string(cell[1]) * "\t" * string(cell[2]) * "\t" * string(cell[3]) * "\t" * string(cell[4]) * "\n"
            write(f, tabToSpace(l))
        end

        write(f, "ENDDATA\n")
    end

end


function parse_coordinate_line(line::String)::Tuple{Float64, Float64, Float64}
    txt = line[1:8]
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
    x = parse(Float64, txt2)

    txt = line[9:16]
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
    y = parse(Float64, txt2)

    txt = line[17:end]
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
    z = parse(Float64, txt2)

    return x, y, z
end