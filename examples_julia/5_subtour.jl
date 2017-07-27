# This file is a slight modification of https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/tsp.jl. 
# (It implements the cut-set formulation, not the subtour elimination.)

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

using JuMP
using Gurobi

n = 10
c = rand(n, n) * 50 

# Extracts a tour, with the cities in the right order. (See comments in findSubtour, just below.)
function extractTour(sol)
    # Start at city 1. 
    tour = [1]  
    cur_city = 1
    
    while true
        # Look for first edge out of current city. 
        for j in 1:n
            if sol[cur_city,j] >= 1 - 1e-6
                push!(tour, j)
                
                # Never use this edge again. 
                sol[cur_city, j] = 0.0
                sol[j, cur_city] = 0.0
                
                # Move to next city. 
                cur_city = j
                break
            end
        end
        
        # If back to 1, stop: made a full loop! 
        if cur_city == 1
            break
        end
    end
    return tour
end

# Finds a subtour (possibly of length n). 
function findSubtour(sol)
    subtour = fill(false, n) # Initialize to no subtour
    
    # Always start looking at city 1 (arbitrary). Due to the structure of the problem, this city will always be connected to at least one other city. 
    cur_city = 1 
    subtour[cur_city] = true
    
    while true
        # Find next node that we haven't yet visited
        found_city = false
        for j in 1:n
            if ! subtour[j] # Edge to unvisited city? Follow it
                if sol[cur_city, j] >= 1 - 1e-6 # ... if it's in the solution (close to 1 in the sol matrix)
                    cur_city = j
                    subtour[j] = true
                    found_city = true
                    break # Move on to next city in subtour. 
                end
            end
        end
        
        if ! found_city # Done: no linked city to 1. 
            break
        end
    end
    return subtour, sum(subtour)
end

# Base model. 
m = Model(solver=GurobiSolver(LazyConstraints=1))
@variable(m, x[i in 1:n, j in 1:n], Bin)
@objective(m, Min, sum{c[i, j] * x[i, j], i in 1:n, j in i:n})
for i in 1:n
    @constraint(m, x[i, i] == 0) # No edge from a node to itself. 
    for j in (i + 1):n
        @constraint(m, x[i, j] == x[j, i]) # Symmetric matrix (undirected problem). 
    end
    @constraint(m, sum{x[i, j], j in 1:n} == 2) # What goes in must go out. 
end

# Separation function. 
function subtour(cb) 
    println("------\nInside subtour callback")

    # Find any set of cities in a subtour. 
    subtour, subtour_length = findSubtour(getvalue(x)) # Note: this x is the same as that of the model! Take care of scoping issues! 
    println("-- Found a subtour: ", find(subtour .== true))

    if subtour_length == n
        # This "subtour" is actually all cities, so we are done: no lazy constraint to add 
        println("-- Solution visits all cities")
        println("------")
        return
    end

    # Build the constraint to eliminate the subtour (term by term). 
    edges_from_subtour = zero(AffExpr)
    for i in 1:n
        if ! subtour[i] # If this city isn't in subtour, skip it
            continue
        end
        
        # Include all edges between this city and another one in the subtour. 
        # Generate each each only once, hence j > i. 
        for j in (i + 1):n
            if subtour[j] # j in the same subtour
                edges_from_subtour += x[i, j]
            else # j is not in the subtour
                continue
            end
        end
    end

    # Finally, add the constraint to the formulation.
    println("-- Adding subtour elimination cut: ", edges_from_subtour, " >= ", subtour_length - 1)
    println("-------")
    @lazyconstraint(cb, edges_from_subtour >= subtour_length - 1)
end 

# Solve the problem with the lazy cuts. 
addlazycallback(m, subtour)
solve(m)

# Print the solution and check whether there is any remaining subtour. 
println()
subtour_bool, subtour_length = findSubtour(getvalue(x))
if subtour_length != n
    println("!! Remaining subtour! ", find(subtour_bool .== true))
else
    println(">> Final solution has no subtour, it goes through all cities: ", find(subtour_bool .== true))
    println(extractTour(getvalue(x)))
end