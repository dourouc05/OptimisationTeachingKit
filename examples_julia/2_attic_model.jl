# include("2_attic_data_hard.jl")
include("2_attic_data_soft.jl")

using JuMP
using Gurobi

ideal = sum(values, 2) / size(values, 1)

m = Model(solver=GurobiSolver())

@variable(m, x[1:n_objects], Bin)
@variable(m, s[1:n_criteria])
@variable(m, z[1:n_criteria] >= 0)

@objective(m, Min, sum(z))

for j in 1:n_criteria
  @constraint(m, dot(x, vec(values[j, :])) + s[j] == ideal[j])
  @constraint(m, z[j] >= s[j])
  @constraint(m, z[j] >= - s[j])
end

print(m)
solve(m)