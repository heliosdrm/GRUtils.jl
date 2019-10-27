# Age ranges
ages = ["$age0-$(age0+4)" for age0 = 0:5:95]
push!(ages, "100+")
female = [328, 319, 307, 290, 284, 293, 293, 263, 241, 235,
    218, 191, 161, 135, 95, 66, 47, 26, 11.3, 3.1, 0.4]
male = [350, 341, 325, 310, 303, 310, 305, 270, 246, 239,
    218, 187, 153, 124, 83, 53, 34, 16, 5.7, 1.2, 0.1]
# Plot as bars - with negative values for female
barplot(ages, -female, horizontal=true, color=0xff8080)
hold(true)
barplot(ages, male, horizontal=true, color=0x8080ff)
# Change to absolute figures
xticklabels(x -> abs(x))
# Add labels
title("World population by age in 2019 (https://www.populationpyramid.net/)")
xlabel("Million people")
legend("female", "male")
