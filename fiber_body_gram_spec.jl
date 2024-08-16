using JuMP, SCS, LinearAlgebra, Plots, Distributions, PlotlyJS, FileIO, JLD2
function solve_SDP(f,U) 
       model=Model(SCS.Optimizer)
       set_silent(model)
       @variable(model,X[1:4,1:4],PSD)
       @objective(model,Min,tr(U*X))
       @constraint(model,X[1,1]==f[1,1])
       @constraint(model,X[1,2]==1/2*f[2,1])
       @constraint(model,2*X[1,3]+X[2,2]==f[3,1])
       @constraint(model,2*X[1,4]+2*X[2,3]==f[4,1])
       @constraint(model,2*X[2,4]+X[3,3]==f[5,1])
       @constraint(model,2*X[3,4]==f[6,1])
       @constraint(model,X[4,4]==f[7,1])
    
       optimize!(model)
       status = JuMP.termination_status(model)
       X_sol = JuMP.value.(X)
       obj_value = JuMP.objective_value(model)
       return X_sol
end


R1=[[0,0,1,0] [0,-2,0,0] [1,0,0,0] [0,0,0,0]]
R2=[[0,0,0,1] [0,0,-1,0] [0,-1,0,0] [1,0,0,0]]
R3=[[0,0,0,0] [0,0,0,1] [0,0,-2,0] [0,1,0,0]]

L1=[]
L2=[]
L3=[]

directions=[]


function random_directions(n)
    for i in 1:n
        u=rand(Uniform(-1,1),3,1)
        U=u[1,1]*R1+u[2,1]*R2+u[3,1]*R3
        append!(directions,[U])
    end
end

function random__binary_sextic_sos(n)
    F=[]
    for i in 1:n
        f1=rand(Uniform(-1,1),4,1) 
        f2=rand(Uniform(-1,1),4,1)
        f=[f1[1]^2 + f2[1]^2 2*f1[1]*f1[2] + 2*f2[1]*f2[2] f1[2]^2 + 2*f1[1]*f1[3] + f2[2]^2 + 2*f2[1]*f2[3] 2*f1[2]*f1[3] + 2*f1[1]*f1[4] + 2*f2[2]*f2[3] + 2*f2[1]*f2[4] f1[3]^2 + 2*f1[2]*f1[4] + f2[3]^2 + 2*f2[2]*f2[4] 2*f1[3]*f1[4] + 2*f2[3]*f2[4] f1[4]^2 + f2[4]^2]
        append!(F,[f])
    end
    return F
end

function get_coords(A,H1,H2,H3)
    x1=1/3*(A[1,3]-A[2,2])
    x2=1/2*(A[1,4]-A[2,3])
    x3=1/3*(A[2,4]-A[3,3])
    append!(H1,x1)
    append!(H2,x2)
    append!(H3,x3)
end

function sample_f(f)
    H1=[]
    H2=[]
    H3=[]
    for i in 1:length(directions)
        get_coords(solve_SDP(transpose(f),directions[i]),H1,H2,H3)
    end
    append!(L1,[H1])
    append!(L2,[H2])
    append!(L3,[H3])
end

function sample(n)
    F=random__binary_sextic_sos(n)
    for i in 1:n
        print(i)
        sample_f(F[i])
    end
end

function draw_fb()
    s=length(L1)
    print(s)
    H1=L1[1]
    H2=L2[1]
    H3=L3[1]
    for i in 2:s
        H1=H1+L1[i]
        H2=H2+L2[i]
        H3=H3+L3[i]
    end
    H1=H1/s
    H2=H2/s
    H3=H3/s
    plotlyjs()
    Plots.plot(H1,H2,H3,seriestype=:scatter,ms=0.5,mc=:red,grid=false,axis=nothing, foreground_color=:black, legend=false, camera = (-45,45))
    plot!(size=(800,800))
end

function save_to_file()
    FileIO.save("L1.jld2","L1",L1)
    FileIO.save("L2.jld2","L2",L2)
    FileIO.save("L3.jld2","L3",L3)
    FileIO.save("directions.jld2","directions",directions)
end

function load_from_file()
    L1=FileIO.load("L1.jld2","L1")
    L2=FileIO.load("L2.jld2","L2")
    L3=FileIO.load("L3.jld2","L3")
    directions=FileIO.load("directions.jld2","directions")
    return [L1,L2,L3,directions]
end

