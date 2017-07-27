n_objects = 8000
n_criteria = 5
max_values = rand(1:500, n_criteria)
values = Float64[rand() * max_values[c] for c in 1:n_criteria, o in 1:n_objects]
;