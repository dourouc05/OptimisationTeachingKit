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

# First step. 
m1, m1_x, m1_y = getPCTSP(n_cities, cost_vector, distance_matrix)
solve(m1)
showEdges(n_cities, getValue(m1_x)) # See the two tours: (1, 3, 6, 7, 1) and (2, 4, 5, 2). 