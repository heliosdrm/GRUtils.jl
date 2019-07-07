legend_kinds = [Geometry{k} for k in (:line, :line3d)]

function guide(g::Geometry{:line}, x, y)
    GR.savestate()
    if haskey(g.attributes, :alpha)
        GR.settransparency(g.attributes[:alpha])
    end
    mask = GR.uselinespec(g.spec)
    hasline(mask) && GR.polyline(x .+ [-0.03, 0.03], y .+ [0.0, 0.0])
    hasmarker(mask) && GR.polymarker(x .+ [-0.02, 0.02], y .+ [0.0, 0.0])
    GR.restorestate()
end

struct Legend
    size::Tuple{Float64, Float64}
    cursors::Vector{Tuple{Float64, Float64}}
end

function Legend(geoms::Array{<:Geometry}, maxrows=length(geoms))
    cursors = Tuple{Float64, Float64}[]
    row = 0
    x = 0.08
    y = -0.015
    labelwidth = 0.0
    w = h = 0.0
    scale = Int(GR.inqscale())
    GR.selntran(0)
    GR.setscale(0)
    for g in geoms
        if !isempty(g.label) && typeof(g) ∈ legend_kinds
            row += 1
            # New column if the limit is exceeded
            if row > maxrows
                (-y > h) && (h = -y)
                y = -0.015
                x += labelwidth + 0.08
                labelwidth = 0.0
                row = 1
            end
            sz = stringsize(g.label)
            (sz[1] > labelwidth) && (labelwidth = sz[1])
            dy = max(sz[2] - 0.03, 0.0)
            push!(cursors, (x, y - dy))
            y -= dy + 0.03
        end
    end
    GR.setscale(scale)
    GR.selntran(1)
    if !isempty(cursors)
        # Define width and height
        (-y > h) && (h = -y)
        w = x + labelwidth
    end
    Legend((w, h), cursors)
end

Legend() = Legend(nullpair, Tuple{Float64, Float64}[])

const legend_locations = Dict(
    :left => [2, 3, 6],
    :center_h => [8, 9, 10],
    :right_out => [11, 12, 13],
    :bottom => [3, 4, 8],
    :center_v => [5, 6, 7, 10, 12]
)

function legend_box(frame, (w, h), location)
    if location ∈ legend_locations[:right_out]
        px = frame[2] + 0.01
    elseif location ∈ legend_locations[:center_h]
        px = 0.5 * (frame[1] + frame[2] - w)
    elseif location ∈ legend_locations[:left]
        px = frame[1] + 0.03
    else
        px = frame[2] - 0.03 - w
    end
    if location ∈ legend_locations[:center_v]
        py = 0.5 * (frame[3] + frame[4] + h)
    elseif location == 13
        py = frame[3] + h
    elseif location ∈ legend_locations[:bottom]
        py = frame[3] + h + 0.03
    elseif location == 11
        py = frame[4]
    else
        py = frame[4] - 0.03
    end
    (px, px + w, py - h, py)
end


function draw(lg::Legend, geoms, location=1)
    (lg.size == nullpair || location == 0) && return nothing
    # First draw the frame
    GR.savestate()
    # Viewport and window
    viewport = legend_box(GR.inqviewport(), lg.size, location)
    GR.setviewport(viewport...)
    w, h = lg.size
    window = (0, w, -h, 0)
    GR.setwindow(window...)
    # Fill white rectangle
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    GR.setfillcolorind(0)
    GR.fillrect(window...)
    # Draw border
    GR.setlinetype(GR.LINETYPE_SOLID)
    GR.setlinecolorind(1)
    GR.setlinewidth(1)
    GR.drawrect(window...)
    # Then the geometries
    GR.uselinespec(" ")
    GR.settextalign(GR.TEXT_HALIGN_LEFT, GR.TEXT_VALIGN_HALF)
    c = 1
    for g in geoms
        (c > length(lg.cursors)) && break
        cursor = lg.cursors[c]
        if !isempty(g.label) && typeof(g) ∈ legend_kinds
            guide(g, cursor[1] - 0.04, cursor[2])
            text(cursor[1], cursor[2], g.label, true)
            c += 1
        else
            GR.uselinespec("")
        end
    end
    GR.restorestate()
    return nothing
end
