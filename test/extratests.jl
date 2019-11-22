@testset "Plot attributes" begin
    # Axis and geometry guides (2d)
    x = -2π:0.01:2π
    y = sin.(x .+ [0 0.5π π 1.5π])
    plot(x, y)
    xticks(π/8, 4)
    ylim(-1.15, 1.15)
    grid(false)
    # Pretty format for the tick labels
    xticklabels((x)->Base.Printf.@sprintf("%0.1f\\pi",x/π))
    # Legend with various rows
    legend("\\phi = 0", "\\phi = 0.5\\pi", "\\phi = \\pi", "\\phi = 1.5\\pi",
        maxrows = 2, location="upper center")
    @test true

    # Axis scales
    # Example data
    x = 10rand(100)
    y = exp.(x) .* (1 .+ 0.1randn(100))
    plot(x, y, "o")
    oplot(0:0.01:10, exp)
    ylim(1, 25_000)
    ylog(true)
    yticks(10, 2)
    xflip(true)
    aspectratio(19/6)
    @test true
end
