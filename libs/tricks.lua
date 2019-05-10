local tricks = {}

local ffi = require("ffi")

local glheader = [[
typedef unsigned int GLenum;
#define GL_SAMPLE_ALPHA_TO_COVERAGE       0x809E
typedef void (APIENTRYP PFNGLDISABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLENABLEPROC) (GLenum cap);
]]

function load_gl(loadfn)
	local openGL = {
		GL = {},
		gl = {},
		loader = loadfn,
	
		import = function(self)
			rawset(_G, "GL", self.GL)
			rawset(_G, "gl", self.gl)
		end
	}
	
	if ffi.os == "Windows" then
		glheader = glheader:gsub("APIENTRYP", "__stdcall *")
		glheader = glheader:gsub("APIENTRY", "__stdcall")
	else
		glheader = glheader:gsub("APIENTRYP", "*")
		glheader = glheader:gsub("APIENTRY", "")
	end
	
	local type_glenum = ffi.typeof("unsigned int")
	local type_uint64 = ffi.typeof("uint64_t")
	
	local function constant_replace(name, value)
		local ctype = type_glenum
		local GL = openGL.GL
	
		local num = tonumber(value)
		if (not num) then
			if (value:match("ull$")) then
				--Potentially reevaluate this for LuaJIT 2.1
				GL[name] = loadstring("return " .. value)()
			elseif (value:match("u$")) then
				value = value:gsub("u$", "")
				num = tonumber(value)
			end
		end
	
		GL[name] = GL[name] or ctype(num)
	
		return ""
	end
	
	glheader = glheader:gsub("#define GL_(%S+)%s+(%S+)\n", constant_replace)
	
	ffi.cdef(glheader)
	
	--ffi.load(ffi.os == 'OSX' and 'OpenGL.framework/OpenGL' or ffi.os == 'Windows' and 'opengl32' or 'GL')
	if ffi.os == "Windows" then
		ffi.load('opengl32')
	end
	
	local gl_mt = {
		__index = function(self, name)
			local glname = "gl" .. name
			local procname = "PFNGL" .. name:upper() .. "PROC"
			local func = ffi.cast(procname, openGL.loader(glname))
			rawset(self, name, func)
			return func
		end
	}
	
	setmetatable(openGL.gl, gl_mt)

	return openGL
end

local gl, GL

local tricky = false
function tricks.prepare()
	if tricky then
		return
	end
	tricky = true

	local already_loaded = pcall(function() return ffi.C.SDL_GL_GetProcAddress end)
	if not already_loaded then
		ffi.cdef([[
			void *SDL_GL_GetProcAddress(const char *proc);
		]])
	end

	local sdl = ffi.C
	-- Windows needs to use an external SDL
	if love.system.getOS() == "Windows" then
		if not love.filesystem.isFused() and love.filesystem.getInfo("bin/SDL2.dll") then
			sdl = ffi.load("bin/SDL2")
		else
			sdl = ffi.load("SDL2")
		end
	end

	opengl = load_gl(function(fn)
		return sdl.SDL_GL_GetProcAddress(fn)
	end)
	gl = opengl.gl
	GL = opengl.GL
end

function tricks.set_alpha_to_coverage(enabled)
	if enabled then
		gl.Enable(GL.SAMPLE_ALPHA_TO_COVERAGE)
	else
		gl.Disable(GL.SAMPLE_ALPHA_TO_COVERAGE)
	end
end

return tricks
