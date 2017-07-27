include("2_beams.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, production[1:timesteps] >= 0, Int)
@variable(m, stored[1:timesteps] >= 0, Int)
@variable(m, on[1:timesteps], Bin)
@variable(m, start[1:timesteps], Bin)

@objective(m, Min, dot(variable, production) + dot(fixed, on) + dot(storage, stored))
@constraint(m, stored[1] == 0)
for t in 1:(timesteps - 1)
    @constraint(m, stored[t + 1] == stored[t] + production[t] - demand[t]) 
end
M = sum(demand)
for t in 1:timesteps
    @constraint(m, production[t] <= M * on[t]) 
end

for t in 1:(timesteps - 4)
    @constraint(m, sum(on[t:t+4]) <= 4)
end
@constraint(m, start[1] == on[1])
for t in 2:timesteps
    @constraint(m, start[t] >= on[t] - on[t - 1])
end
for t in 1:timesteps
    @constraint(m, on[t] >= start[t])
end
for t in 1:(timesteps - 1)
    @constraint(m, on[t + 1] >= start[t])
end
for t in 1:(timesteps - 2)
    @constraint(m, on[t + 2] >= start[t])
end

print(m)
solve(m)
getvalue(on)
