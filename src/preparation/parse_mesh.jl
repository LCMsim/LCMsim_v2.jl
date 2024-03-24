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

function __parse_abaqus(filename::String)
        # Abaqus format: Node block after *Node, Element block after *Element, TYPE=S3, Element sets after *ELSET
        # Only one block with nodes and one block with face elements. Mulitple (<=4) element sets possible.

        ind=Int64(1);
        gridind=Int64(1);
        nodeind=Int64(1);
        elementind=Int64(1);
        setelementind=Int64(1);
        setind=Int64(0);
        isnodedefinition=Int64(0);
        iselementdefinition=Int64(0);
        issetdefinition=Int64(0);
        origgridid=[];
        gridx=[];
        gridy=[];
        gridz=[];
        celloriggridid=[];
        cellgridid=Array{Int64}(undef, 0, 3);

        pids = Vector{Int}(undef, 0)
        
        open(filename, "r") do fid
            line=1;
            while !eof(fid)            
                thisline=readline(fid)
                thisline=replace(thisline," "=> "");

                len_line=length(thisline)

                if isnodedefinition==1
                    if isempty(thisline)==1 || cmp(thisline[1:1],"*")==0
                        isnodedefinition=Int64(0)
                    else
                        txt_vec=split(thisline,",")
                        gridindstring=txt_vec[1]
                        origgridid=vcat(origgridid,parse(Int64,gridindstring));                        
                        txt=txt_vec[2]
                        txt=replace(txt," "=> "");txt=replace(txt,"E" => "");txt=replace(txt,"e" => "");
                        txt1=replace(txt,"-" => "e-");txt1=replace(txt1,"+" => "e+");
                        if cmp(txt1[1],'e')==0;txt2=txt1[2:end];else;txt2=txt1;end;
                        val=parse(Float64,txt2);
                        val1=val;
                        txt=txt_vec[3]
                        txt=replace(txt," "=> "");txt=replace(txt,"E" => "");txt=replace(txt,"e" => "");
                        txt1=replace(txt,"-" => "e-");txt1=replace(txt1,"+" => "e+");
                        if cmp(txt1[1],'e')==0;txt2=txt1[2:end];else;txt2=txt1;end;
                        val=parse(Float64,txt2);
                        val2=val;
                        txt=txt_vec[4]
                        txt=replace(txt," "=> "");txt=replace(txt,"E" => "");txt=replace(txt,"e" => "");
                        txt1=replace(txt,"-" => "e-");txt1=replace(txt1,"+" => "e+");
                        if cmp(txt1[1],'e')==0;txt2=txt1[2:end];else;txt2=txt1;end;
                        val=parse(Float64,txt2);
                        val3=val;
                        gridx=vcat(gridx,Float64(val1));
                        gridy=vcat(gridy,Float64(val2));
                        gridz=vcat(gridz,Float64(val3));
                        gridind=gridind+1;
                    end
                end

                if iselementdefinition == 1 
                    if isempty(thisline) == 1 || cmp(thisline[1:1],"*") == 0
                        iselementdefinition=Int64(0)
                    else
                        txt_vec=split(thisline,",")
                        celloriggridid=vcat(celloriggridid,parse(Int64,txt_vec[1]));
                        i1val=parse(Int64,txt_vec[2]);
                        i1=findfirst(isequal(i1val),origgridid);
                        i2val=parse(Int64,txt_vec[3]);
                        i2=findfirst(isequal(i2val),origgridid);
                        i3val=parse(Int64,txt_vec[4]);
                        i3=findfirst(isequal(i3val),origgridid);
                        ivec=[i1,i2,i3];
                        idel=findall(isequal(min(ivec[1],ivec[2],ivec[3])),ivec);
                        deleteat!(ivec,idel)
                        idel=findall(isequal(max(ivec[1],ivec[2])),ivec);
                        deleteat!(ivec,idel)                        
                        cellgridid=vcat(cellgridid,[min(i1,i2,i3) ivec[1] max(i1,i2,i3)]);
                        ind=ind+1;    
                    end
                end

                if issetdefinition == 1 
                    if isempty(thisline)==1 || cmp(thisline[1:1],"*")==0
                        issetdefinition=Int64(0)
                    elseif isnothing(tryparse(Int64,thisline[1:1]))    #name instead of numbers
                        issetdefinition=Int64(0)
                        setind=setind-1
                    else
                        txt1=thisline
                        txt1=replace(txt1," "=> "")
                        txt2=split(txt1,",")
                        for i in 1:length(txt2)
                            if !isempty(txt2[i])
                                push!(pids, parse(Int64,txt2[i]))
                            end
                        end
                    end
                end

                
                if len_line>=5 &&  (cmp( thisline[1:5],"*Node")==0 || cmp( thisline[1:5],"*NODE")==0 ) #if the first five characters are *Node: isnodedefinition=1; else: isnodedefinition=0
                    isnodedefinition=Int64(1);
                    nodeind=1
                    gridind=1
                end
                if (len_line>=17 &&  (cmp(thisline[1:17],"*Element, TYPE=S3")==0 || cmp(thisline[1:17],"*Element, Type=S3")==0 || cmp(thisline[1:17],"*ELEMENT, TYPE=S3")==0 || cmp(thisline[1:17],"*ELEMENT, Type=S3")==0) ) ||
                    len_line>=16 &&  (cmp(thisline[1:16],"*Element,TYPE=S3")==0 || cmp(thisline[1:16],"*Element,Type=S3")==0 || cmp(thisline[1:16],"*ELEMENT,TYPE=S3")==0 || cmp(thisline[1:16],"*ELEMENT,Type=S3")==0)  #if the first 17 characters are *Element, TYPE=S3                    
                    iselementdefinition=Int64(1);
                    ind=1
                    elementind=1
                end
                if len_line>=6 &&  (cmp( thisline[1:6],"*Elset")==0 || cmp( thisline[1:6],"*ELSET")==0)  #if the first six characters are *ELSET
                    issetdefinition=Int64(1);
                    setelementind=1
                    setind=setind+1
                end

                line+=1
            end
        end
        N=ind-1;  #total number of cells

        grid = [gridx gridy gridz]
        vertices = [Point3{Float64}(grid[i, :]) for i in 1:size(grid)[1]]
           
        return cellgridid, vertices, pids, N
end

function parse_mesh(meshfile::String)

    file_extension = splitext(meshfile)[2]

    cellgridid = Matrix{Int}(undef, 0, 3)
    vertices = Vector{Point3{Float64}}(undef, 0)
    pids = Vector{Int}(undef, 0)
    N = 0

    if file_extension == ".bdf"
        @debug "PARSE GMSH"
        cellgridid, vertices, pids, N = __parse_gmsh(meshfile)
    elseif file_extension == ".dat"
        @debug "PARSE HyperMesh"
        cellgridid, vertices, pids, N = __parse_HyperMesh(meshfile)
    elseif file_extension == ".inp"
        @debug "PARSE Abaqus"
        cellgridid, vertices, pids, N = __parse_abaqus(meshfile)
    else
        @error "File extension not supported."
    end

    return cellgridid, vertices, pids, N
end