# Create example data
numbers = [10, 15, 35, 20]
# Plot bars with labels on top
barplot(numbers)
annotations(1:4, numbers .+1 , string.(numbers), halign="center")
