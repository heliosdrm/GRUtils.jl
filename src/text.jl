setfont() = GR.settextfontprec(232, 3) # CM Serif Roman

function search(s::AbstractString, c::Char)
    result = findfirst(isequal(c), s)
    result != nothing ? result : 0
end

function inqtext(x, y, s, wc, charheight)
    GR.savestate()
    wc ? GR.selntran(1) : GR.selntran(0)
    setfont() # needed for GR.inqmathtex
    GR.setcharheight(charheight)
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        tbx, tby = GR.inqmathtex(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        tbx, tby = GR.inqtextext(x, y, s)
    else
        tbx, tby = GR.inqtext(x, y, s)
    end
    GR.restorestate()
    tbx, tby
end

function inqtext(x, y, s, wc=false)
    charheight = _tickcharheight()[2]
    inqtext(x, y, s, wc, charheight)
end

function stringsize(s, args...)
    tbx, tby = inqtext(0, 0, s, args...)
    w = tbx[2] - tbx[1]
    h = tby[4] - tby[1]
    w, h
end

function text(x, y, s, wc = false)
    GR.savestate() # to avoid side-effect of GR.mathtex
    if wc
        win = GR.inqwindow()
        vp = GR.inqviewport()
        x = (vp[2] - vp[1]) / (win[2] - win[1]) * x + (vp[1] * win[2] - vp[2] * win[1]) / (win[2] - win[1])
        y = (vp[4] - vp[3]) / (win[4] - win[3]) * y + (vp[3] * win[4] - vp[4] * win[3]) / (win[4] - win[3])
    end
    # setfont() # needed for GR.mathtex
    if length(s) >= 2 && s[1] == '$' && s[end] == '$'
        GR.mathtex(x, y, s[2:end-1])
    elseif search(s, '\\') != 0 || search(s, '_') != 0 || search(s, '^') != 0
        GR.textext(x, y, s)
    else
        GR.text(x, y, s)
    end
    GR.restorestate()
end
