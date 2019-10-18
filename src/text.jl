function search(s::AbstractString, c::Char)
    result = findfirst(isequal(c), s)
    result != nothing ? result : 0
end

function inqtext(x, y, s)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.inqmathtex(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        GR.inqtextext(x, y, s)
    else
        GR.inqtext(x, y, s)
    end
end

function stringsize(s)
    tbx, tby = inqtext(0, 0, s)
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
