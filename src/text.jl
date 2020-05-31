function search(s::AbstractString, c::Char)
    result = findfirst(isequal(c), s)
    result != nothing ? result : 0
end

function inqtext(x, y, s, wc=false)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        # to be fixed (https://github.com/jheinen/GR.jl/issues/317)
        # tbx, tby = GR.inqmathtex(x, y, s[2:end-1])
        tbx, tby = GR.inqtext(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        tbx, tby = GR.inqtextext(x, y, s)
    else
        tbx, tby = GR.inqtext(x, y, s)
    end
    if wc
        for i = 1:4
            tbx[i], tby[i] = GR.ndctowc(tbx[i], tby[i])
        end
    end
    tbx, tby
end

function stringsize(s, wc=false)
    tbx, tby = inqtext(0, 0, s, wc)
    w = tbx[2] - tbx[1]
    h = tby[4] - tby[1]
    w, h
end

function text(x, y, s, wc = false)
    if wc
        win = GR.inqwindow()
        vp = GR.inqviewport()
        x = (vp[2] - vp[1]) / (win[2] - win[1]) * x + (vp[1] * win[2] - vp[2] * win[1]) / (win[2] - win[1])
        y = (vp[4] - vp[3]) / (win[4] - win[3]) * y + (vp[3] * win[4] - vp[4] * win[3]) / (win[4] - win[3])
    end
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.mathtex(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        GR.textext(x, y, s)
    else
        GR.text(x, y, s)
    end
end
