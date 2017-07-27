include("2_hospital.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, open[1:n_hospitals], Bin)
@variable(m, demand[1:n_hospitals, 1:n_demands] >= 0)

@objective(m, Min, dot(fixed_costs, open) + vecdot(variable_costs, demand))
for j in 1:n_demands
    @constraint(m, sum(demand[:, j]) == demands[j]) 
end
for i in 1:n_hospitals
    @constraint(m, sum(demand[i, :]) <= sum(demands) * open[i]) 
end

print(m)
solve(m)
getvalue(open)
