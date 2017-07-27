include("2_beams.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, production[1:timesteps] >= 0, Int)
@variable(m, stored[1:timesteps] >= 0, Int)
@variable(m, on[1:timesteps], Bin)

@objective(m, Min, dot(variable, production) + dot(fixed, on) + dot(storage, stored))
@constraint(m, stored[1] == 0)
for t in 1:(timesteps - 1)
    @constraint(m, stored[t + 1] == stored[t] + production[t] - demand[t]) 
end
M = sum(demand)
for t in 1:timesteps
    @constraint(m, production[t] <= M * on[t]) 
end

print(m)
solve(m)
getvalue(on)
