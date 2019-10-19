# Create example data
s = LinRange(-4, 4, 50)
v = cos.(s) .+ cos.(s)' .+ cos.(reshape(s,1,1,:))
# Draw the isosurface
isosurface(v, 0.5, skincolor=0x99ffcc)
