local _M = {
    _VERSION = '0.0.1'
}

local regex = ngx.re

function _M.pwd()
    return _M.cmd('pwd')
end

function _M.vmstat()
    local tab
    local res = _M.cmd('vmstat', 1)
    if type(res) == 'table' and #res > 0 then
        tab = {}
        ngx.say(res[2])
        local line = res[3]
        ngx.say(line)
        local m = regex.match(line, '(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)')
        if m then
            tab.r = tonumber(m[1])
            tab.b = tonumber(m[2])
            tab.swpd = tonumber(m[3])
            tab.free = tonumber(m[4])
            tab.buff = tonumber(m[5])
            tab.cache = tonumber(m[6])
            tab.si = tonumber(m[7])
            tab.so = tonumber(m[8])
            tab.bi = tonumber(m[9])
            tab.bo = tonumber(m[10])
            tab.ir = tonumber(m[11])
            tab.cs = tonumber(m[12])
            tab.us = tonumber(m[13])
            tab.sy = tonumber(m[14])
            tab.id = tonumber(m[15])
            tab.wa = tonumber(m[16])
            tab.st = tonumber(m[17])
        end
    end
    return tab
end

function _M.cmd(prog, multi_line)
    local pd = io.popen(prog)
    if pd == nil then
        return nil, err
    end
    local res
    if multi_line == 1 then
        res = {}
        for v in pd:lines() do
            res[#res+1] = v
        end
    else
        res = pd:read('*all')
    end
    pd:close()
    return res
end

return _M
