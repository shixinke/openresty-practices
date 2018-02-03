local _M = {
    _VERSION = '0.01'
}

local upload = require "resty.upload"
local chunk_size = 4096
local cjson = require 'cjson.safe'
local os_exec = os.execute
local os_date = os.date
local md5 = ngx.md5
local io_open = io.open
local tonumber = tonumber
local type = type
local gsub = string.gsub
local ngx_var = ngx.var
local ngx_req = ngx.req
local os_time = os.time
local json_encode = cjson.encode



local function get_ext(res)
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

local function file_exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end

local function json_return(code, message, data)
    ngx.say(json_encode({code = code, msg = message, data = {}}))
end

local function uploadfile()
    local file
    local file_name
    local form = upload:new(chunk_size)
    local conf = {max_size = 1000000, allow_exts = {'jpg', 'png', 'gif'} }
    local root_path = ngx_var.document_root
    local file_info = {extension = '', filesize = 0, url = '', mime = '' }
    local content_len = ngx_req.get_headers()['Content-length']
    local body_size = content_len and tonumber(content_len) or 0
    if not form then
        return nil, '没有上传的文件'
    end
    if body_size > 0 and body_size > conf.max_size then
        return nil, '文件过大'
    end
    file_info.filesize = body_size
    while true do
        local typ, res, err = form:read()
        if typ == "header" then
            if res[1] == "Content-Type" then
                file_info.mime = res[2]
            elseif res[1] == "Content-Disposition" then

                local file_id = md5('upload'..os_time())
                local extension = get_ext(res[2])
                file_info.extension = extension

                if not extension then
                    return nil,  '未获取文件后缀'
                end

                if not func.in_array(extension, conf.allow_exts) then
                    return nil,  '不支持该文件格式'
                end

                local dir = root_path..'/uploads/images/'..os_date('%Y')..'/'..os_date('%m')..'/'..os_date('%d')..'/'
                if file_exists(dir) ~= true then
                    local status = os_exec('mkdir -p '..dir)
                    if status ~= true then
                        return nil, '创建目录失败'
                    end
                end
                file_name = dir..file_id.."."..extension
                if file_name then
                    file = io_open(file_name, "w+")
                    if not file then
                        return nil, '打开文件失败'
                    end
                end
            end
        elseif typ == "body" then
            if file then
                file:write(res)
            end
        elseif typ == "part_end" then
            if file then
                file:close()
                file = nil
            end
        elseif typ == "eof" then
            file_name = gsub(file_name, root_path, '')
            file_info.url = file_name
            return file_info
        else

        end
    end
end



local file_info, err = uploadfile()
if file_info then
    json_return(200, '上传成功', {imgurl = file_info.url})
else
    json_return(5003, err)
end


