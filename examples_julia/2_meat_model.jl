include("2_meat.jl");

using JuMP
using Gurobi

m = Model(solver=GurobiSolver())

@variable(m, selected[1:n_trays], Bin)
@variable(m, fat >= 0)
@variable(m, weight >= 0)
@variable(m, fat_delta)
@variable(m, fat_delta_abs >= 0)

@objective(m, Min, fat_delta_abs)
@constraint(m, fat == dot(fats, selected))
@constraint(m, weight == dot(weights, selected))
@constraint(m, 0.95 * weight_target <= weight)
@constraint(m, 1.05 * weight_target >= weight)
@constraint(m, fat_delta == fat - fat_target)
@constraint(m, fat_delta_abs >= fat_delta)
@constraint(m, fat_delta_abs >= - fat_delta)

#print(m)
solve(m)
getvalue(selected)
