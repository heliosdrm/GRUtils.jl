# Create example data (continent population in million people)
continents = ["Africa", "America", "Asia", "Europe", "Oceania"]
population_1960 = [285, 425, 1687, 606, 16]
population_2010 = [1044, 944, 4170, 735, 36]
population_matrix = [population_1960 population_2010]
# Plot with respect to 500 millions of people
barplot(continents, population_matrix, baseline=500)
legend("1960", "2010") # add legend
