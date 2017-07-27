include("2_uc.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, on[1:time_steps, 1:n_machines], Bin)
@variable(m, power[1:time_steps, 1:n_machines] >= 0)
@variable(m, start[1:time_steps, 1:n_machines], Bin)

@objective(m, Min, sum{dot(fixed_costs, vec(on[t, :])) + dot(variable_costs, vec(power[t, :])) + dot(startup_costs, vec(start[t, :])), t in 1:time_steps})
for t in 1:time_steps
    for i in 1:n_machines
        @constraint(m, power[t, i] <= max_power[i] * on[t, i])
    end    
    @constraint(m, sum(power[t, :]) == demands[t])
end
for i in 1:n_machines
    @constraint(m, start[1, i] == on[1, i])
end
for t in 2:time_steps
    for i in 1:n_machines
        @constraint(m, start[t, i] >= on[t, i] - on[t - 1, i])
    end
end
for t in 1:time_steps
    for i in 1:n_machines
        @constraint(m, on[t, i] >= start[t, i])
        if t <= time_steps - 1 
            @constraint(m, on[t + 1, i] >= start[t, i])
        end
        if t <= time_steps - 2
            @constraint(m, on[t + 2, i] >= start[t, i])
        end
    end
end

#print(m)
solve(m)
getvalue(on)
