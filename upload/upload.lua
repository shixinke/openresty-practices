local upload = require "resty.upload"
local cjson = require "cjson"

local chunk_size = 4096
local form = upload:new(chunk_size)
local conf = {max_size=1000000, allow_exts={'jpg', 'png', 'gif'}}
local file
local file_name

--获取文件扩展名
function get_ext(res)
    local ext = 'jpg'
    if res == 'image/png' then
        ext = 'png'
    elseif res == 'image/jpg' or res == 'image/jpeg' then
        ext = 'jpg'
    elseif res == 'image/gif' then
        ext = 'gif'
    end
    return ext
end

--判断某个值是否在数组中
function in_array(v, tab)
    local i = false
    for _, val in ipairs(tab) do
        if val == v then
            i = true
            break
        end
    end
    return i
end

while true do
    local typ, res, err = form:read() 
    if typ == "header" then
        if res[1] ~= "Content-Disposition" then
        
            local file_id = ngx.md5('upload'..os.time())
            local extension = get_ext(res[2])

            if not extension then
                 ngx.say(cjson.encode({code=501, msg='未获取文件后缀', data=res}))
                 return 
            end

            if not in_array(extension, conf.allow_exts) then
                ngx.say(cjson.encode({code=501, msg='不支持这种文件格式', data=res}))
                return 
            end

            local dir = '/data/www/openrestyproject/upload/'..os.date('%Y')..'/'..os.date('%m')..'/'..os.date('%d')..'/'   
            local status = os.execute('mkdir -p '..dir)
            if status ~= 0 then
                ngx.say(cjson.encode({code=501, msg='创建目录失败'}))
                return
            end  
            file_name = dir..file_id.."."..extension          
            if file_name then
                file = io.open(file_name, "w+")
                if not file then
                    ngx.say(cjson.encode({code=500, msg='failed to open file',imgurl=''}))
                    return
                end
            end
        end
     elseif typ == "body" then
        if type(tonumber(res)) == 'number' and tonumber(res) > conf.max_size then
            ngx.say(cjson.encode({code=501, msg='文件超过规定大小', data=res}))
            return
        end
        if file then
            file:write(res)            
        end
    elseif typ == "part_end" then
        if file then
            file:close()
            file = nil
        end
    elseif typ == "eof" then
        file_name = string.gsub(file_name, '/data/www/openrestyproject/upload/', '')
        ngx.say(cjson.encode({code=200, msg='上传成功！',imgurl= file_name}))
        break
    else
        
    end
end

