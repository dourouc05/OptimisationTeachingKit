include("2_groups.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, y[1:people, 1:people], Bin)
@variable(m, x[1:people, 1:groups], Bin)

@objective(m, Min, vecdot(affinity, y))
for i in 1:people
    @constraint(m, sum(x[i, :]) == 1) 
end
for k in 1:groups
    @constraint(m, sum(x[:, k]) == persons_per_group) 
end
for i in 1:people
    for j in 1:people 
        for k in 1:groups
            @constraint(m, y[i, j] >= x[i, k] + x[j, k] - 1) 
        end
    end
end

#print(m)
solve(m)