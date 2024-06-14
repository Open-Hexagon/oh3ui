local monkeypatch = {}

local original_functions = {}

function monkeypatch.add(orig_fun, extra_fun)
	local new_fun = function(...)
		extra_fun(...)
		return orig_fun(...)
	end
	original_functions[new_fun] = orig_fun
	return new_fun
end

function monkeypatch.replace(orig_fun, replace_fun)
	local new_fun = replace_fun
	original_functions[new_fun] = orig_fun
	return new_fun
end

function monkeypatch.get_original(new_fun)
	return original_functions[new_fun]
end

return monkeypatch
