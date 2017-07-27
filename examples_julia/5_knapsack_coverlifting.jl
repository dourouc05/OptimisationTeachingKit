using JuMP

function getLP(solver) # GurobiSolver(), CbcSolver()... 
  value = [4, 5, 6, 6, 6, 10, 15]
  weight = [5, 5, 6, 7, 8, 12, 16]
  capacity = 20

  m = Model(solver=solver)
  @defVar(m, 0 <= x[1:7] <= 1) # Not integer: linear relaxation. 
  @addConstraint(m, dot(weight, x) <= capacity)
  @setObjective(m, Max, dot(value, x))
  
  # Add more constraints here. 
  
  return m, x
end

# Adapt the following two lines to the solver of your choice. 
using Gurobi
solver = GurobiSolver()

lp, lp_x = getLP(solver)
solve(lp)
println()
println(getObjectiveValue(lp))
println(getValue(lp_x))
