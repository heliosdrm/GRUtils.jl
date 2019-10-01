# Create example data (continent population in million people)
population = Dict("Africa" => 1216,
                 "America" => 1002,
                 "Asia" => 4436,
                 "Europe" => 739,
                 "Oceania" => 38)
# Plot data in "normal" bars
barplot(keys(population), values(population))
# Plot with respect to 1,000 millions of people
barplot(keys(population), values(population), baseline=1000)
# Horizontal bars
barplot(keys(population), values(population), horizontal=true)
