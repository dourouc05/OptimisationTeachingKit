include("2_nurses.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, working[1:timesteps] >= 0, Int)
@variable(m, start[1:timesteps] >= 0, Int)
@variable(m, extra[1:timesteps] >= 0, Int)

@objective(m, Min, sum(extra))
@constraint(m, sum(start) <= max_available) 
for t in 1:timesteps
    @constraint(m, working[t] >= required[t]) 
    @constraint(m, extra[t] <= start[t]) 
end
@constraint(m, working[1] == start[1]) 
@constraint(m, working[2] == start[2] + start[1]) 
@constraint(m, working[3] == start[3] + start[2]) 
@constraint(m, working[4] == start[4] + start[3] + start[1]) 
@constraint(m, working[5] == start[5] + start[4] + start[2] + start[1]) 
for t in 6:timesteps
    @constraint(m, working[t] == start[t] + start[t - 1] + start[t - 3] + start[t - 4] + extra[t - 5]) 
end

print(m)
solve(m)
getvalue(extra)
