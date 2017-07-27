using JuMP

# Adapt the following two lines to the solver of your choice. 
using Gurobi
function getSolver()
  solver = GurobiSolver(OutputFlag=false)
end

n_cities = 7; 
cost_vector = vec([2 4 1 3 7 1 7]);
distance_matrix = [
  [0 4 3 3 5 2 5]; 
  [4 0 5 3 3 4 7]; 
  [3 5 0 4 6 0 4]; 
  [3 3 4 0 4 4 6]; 
  [5 3 6 4 0 5 8]; 
  [2 4 0 4 5 0 3]; 
  [5 7 4 6 8 3 0] 
] # Check that it is symmetric: distance_matrix' == distance_matrix. 

function showEdges(n_cities, sol)
  println("This solution has the following edges: ")
  for i = 1:n_cities
    for j = (i+1):n_cities
      if sol[i, j] > .99
        println("  ", i, " to ", j)
      end
    end
  end
end

function getPCTSP(n_cities::Int, cost_vector::Array{Int64,1}, matrix::Array{Int64,2})
  m = Model(solver=getSolver())
  
  @variable(m, 0 <= x[i=1:n_cities, j=(i+1):n_cities] <= 1) # Not integer: linear relaxation. Upper triangular, zero diagonal! 
  @variable(m, 0 <= y[1:n_cities] <= 1) # Not integer: linear relaxation. 
  
  @objective(m, Max, dot(cost_vector, y) - sum{distance_matrix[i, j] * x[i, j], i=1:n_cities, j=(i+1):n_cities})
  
  for i in 1:n_cities 
    @constraint(m, sum{x[i, j], j=(i+1):n_cities} + sum{x[j, i], j=1:(i-1)} == 2 * y[i]) # Don't forget the matrix is triangular: from i to all the others, then from all the others to i. 
    for j in (i+1):n_cities 
      # Trivial GSECs. 
      @constraint(m, x[i, j] <= y[i])
      @constraint(m, x[i, j] <= y[j])
    end
  end
  @constraint(m, y[1] == 1)
  
  return m, x, y # Solution ensured to be integer! Except if more constraints... 
end

function getSubtour(n_cities, sol_x, sol_y, k)
  m = Model(solver=getSolver())
  
  @variable(m, w[i=2:n_cities, j=(i+1):n_cities], Bin) # Forget the first city, obliged to be in the tour. 
  @variable(m, z[2:n_cities], Bin) 
  
  @objective(m, Max, sum{sol_x[i, j] * w[i, j], i=2:n_cities, j=(i+1):n_cities} - sum{sol_y[i] * z[i], i=2:n_cities; i != k})
  for i in 2:n_cities 
    for j in (i+1):n_cities 
      @constraint(m, w[i, j] <= z[i])
      @constraint(m, w[i, j] <= z[j])
      @constraint(m, w[i, j] >= z[i] + z[j] - 1)
    end
  end
  @constraint(m, z[k] == 1)
  
  solve(m)
  violation = getObjectiveValue(m)
  
  return violation, getValue(z)
end

function bestSubtour(n_cities, sol_x, sol_y)
  best_k = -1
  best_violation = 0
  best_subtour = []
  
  for k = 2:n_cities
    violation, subtour = getSubtour(n_cities, sol_x, sol_y, k)
    if violation > 0. && violation > best_violation
      best_violation = violation
      best_k = k
      best_subtour = subtour
    end
  end
  
  return best_k, best_subtour
end

# First step. 
m1, m1_x, m1_y = getPCTSP(n_cities, cost_vector, distance_matrix)
solve(m1)
showEdges(n_cities, getValue(m1_x)) # See the two tours: (1, 3, 6, 7, 1) and (2, 4, 5, 2). 

# Second step. 
m1_k, m1_subtour = bestSubtour(n_cities, getValue(m1_x), getValue(m1_y)) # Detects subtour with nodes (2, 4, 5), k=2. 

m2, m2_x, m2_y = getPCTSP(n_cities, cost_vector, distance_matrix)
@constraint(m2, m2_x[2, 4] + m2_x[2, 5] + m2_x[4, 5] <= m2_y[4] + m2_y[5])
solve(m2)
showEdges(n_cities, getValue(m2_x)) # See the two tours: (1, 2, 5, 4, 1) and (3, 6, 7). 

# Third step. 
m2_k, m2_subtour = bestSubtour(n_cities, getValue(m2_x), getValue(m2_y)) # Detects subtour with nodes (3, 6, 7), k=3. 

m3, m3_x, m3_y = getPCTSP(n_cities, cost_vector, distance_matrix)
@constraint(m3, m3_x[2, 4] + m3_x[2, 5] + m3_x[4, 5] <= m3_y[4] + m3_y[5])
@constraint(m3, m3_x[3, 6] + m3_x[3, 7] + m3_x[6, 7] <= m3_y[3] + m3_y[7])
solve(m3)
showEdges(n_cities, getValue(m3_x)) # See the only *integer* tour: (1, 2, 5, 4, 1). Have many other variables which are not integer! See m3_x. (Why?)

# Fourth step. 
m3_k, m3_subtour = bestSubtour(n_cities, getValue(m3_x), getValue(m3_y)) # Detects subtour with nodes (3, 6, 7), k=7. 

m4, m4_x, m4_y = getPCTSP(n_cities, cost_vector, distance_matrix)
@constraint(m4, m4_x[2, 4] + m4_x[2, 5] + m4_x[4, 5] <= m4_y[4] + m4_y[5])
@constraint(m4, m4_x[3, 6] + m4_x[3, 7] + m4_x[6, 7] <= m4_y[3] + m4_y[7])
@constraint(m4, m4_x[3, 6] + m4_x[3, 7] + m4_x[6, 7] <= m4_y[3] + m4_y[6])
solve(m4)
showEdges(n_cities, getValue(m4_x)) # See the only tour: (1, 2, 5, 4, 7, 6, 1). 