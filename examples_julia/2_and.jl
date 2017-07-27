using JuMP

n = 50
values = rand(Bool, n)

m1 = Model()
@variable(m1, x[1:n], Bin)
@variable(m1, z, Bin) # z = AND_i x_i
for i = 1:n; @constraint(m1, z <= x[i]); end
@constraint(m2, z >= sum(x) - (n - 1)); 
for i = 1:n; @constraint(m1, x[i] == values[i]); end

tic();
solve(m1); 
toc()

m2 = Model()
@variable(m2, x[1:n], Bin)
@variable(m2, z, Bin) # z = AND_i x_i
@constraint(m2, sum(x) - n * z >= 0); 
@constraint(m2, sum(x) - n * z <= n - 1); 
for i = 1:n; @constraint(m1, x[i] == values[i]); end

tic();
solve(m2); 
toc()
