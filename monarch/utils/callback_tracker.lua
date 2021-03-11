local M = {}


function M.create()
	local instance = {}

	local callback = nil
	local callback_count = 0

	local function is_done()
		return callback_count == 0
	end

	local function invoke_if_done()
		if callback_count == 0 and callback then
			local ok, err = pcall(callback)
			if not ok then print(err) end
		end
	end

	--- Create a callback function and track when it is done
	-- @return Callback function
	function instance.track()
		callback_count = callback_count + 1
		local done = false
		return function()
			if done then
				return false, "The callback has already been invoked once"
			end
			done = true
			callback_count = callback_count - 1
			invoke_if_done()
			return true
		end
	end

	--- Call a function when all callbacks have been triggered
	-- @param cb Function to call when all 
	function instance.when_done(cb)
		callback = cb
		invoke_if_done()
	end

	function instance.yield_until_done()
		local co = coroutine.running()
		callback = function()
			local ok, err = coroutine.resume(co)
			if not ok then
				print(err)
			end
		end
		invoke_if_done()
		if not is_done() then
			coroutine.yield()
		end
	end

	return instance
end


return setmetatable(M, {
	__call = function(_, ...)
		return M.create(...)
	end
})