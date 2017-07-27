using JuMP

function getLP(solver) # GurobiSolver(), CbcSolver()... 
  value_ = [4, 5, 6, 6, 6, 10, 15]
  weight = [5, 5, 6, 7, 8, 12, 16]
  capacity = 20

  m = Model(solver=solver)
  @defVar(m, 0 <= x[1:7] <= 1) # Not integer: linear relaxation. 
  @addConstraint(m, dot(weight, x) <= capacity)
  @setObjective(m, Max, dot(value_, x))
  
  ### 3. Covers. 
  
  # 19.4375, [0.0,1.0,1.0,0.0,0.0,0.0,0.5625], hence two covers: cannot take (2, 7) or (3, 7) at the same time. 
  @addConstraint(m, x[2] + x[7] <= 1) 
  @addConstraint(m, x[3] + x[7] <= 1)
  
  # 18.666666666666668, [0.0,1.0,1.0,1.0,0.0,0.16666666666666666,0.0]
  @addConstraint(m, x[2] + x[3] + x[6] <= 2)
  
  # 18.655172413793107, [0.0,0.9310344827586208,0.9310344827586207,1.0,0.0,0.13793103448275856,0.06896551724137932]
  @addConstraint(m, x[4] + x[7] <= 1)
  
  # 18.636363636363633, [0.0,0.9090909090909091,0.9090909090909091,0.9090909090909091,0.0,0.18181818181818177,0.09090909090909094]
  
  ### 4. Extending. 
  @addConstraint(m, x[2] + x[3] + x[6] + x[7] <= 2)
  @addConstraint(m, x[2] + x[4] + x[6] + x[7] <= 2)
  @addConstraint(m, x[3] + x[4] + x[6] + x[7] <= 2)
  
  # 18.6, [0.4,1.0,1.0,1.0,0.0,0.0,0.0]
  
  ### 5. Comparing. 
  # @addConstraint(m, x[1] + x[2] + x[3] + x[4] <= 3) # Original cover. 
  # @addConstraint(m, x[1] + x[2] + x[3] + x[4] + x[5] + x[6] + x[7] <= 3) # Extended cover. 
  @addConstraint(m, x[1] + x[2] + x[3] + x[4] + x[5] + 2 * x[6] + 3 * x[7] <= 3) # Lifted cover.
  
  # 17.666666666666664, [0.0,0.3333333333333333,1.0,1.0,0.6666666666666667,0.0,0.0]
  
  ### 5. Finalising. 
  @addConstraint(m, x[3] + x[4] + x[5] <= 2) # Cover. 
  
  # 17.0, [0.0,1.0,1.0,1.0,0.0,0.0,0.0]
  
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
