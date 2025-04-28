local originalRequire = require

local function mockedRequire(moduleName)
    if moduleName == "ao" then
        -- return originalRequire("spec.mocked-env.ao.ao")

        -- Mock implementation of ao module
        return {
            send = function(message)
                print("Mock ao.send called with:", message.Data)
            end,
            id = "mocked_id",
        }
    end

    if moduleName == "handlers-utils" then
      return originalRequire("spec.mocked-env.ao.handlers-utils")
    end
  
    if moduleName == "handlers" then
      return originalRequire("spec.mocked-env.ao.handlers")
    end
  
    if moduleName == ".bint" then
      return originalRequire("spec.mocked-env.lib.bint")
    end
  
    if moduleName == ".utils" then
      return originalRequire("spec.mocked-env.lib.utils")
    end
  
    if moduleName == "json" then
      return originalRequire("spec.mocked-env.lib.json")
    end
  
    return originalRequire(moduleName)
  end

return function()
    _G.require = mockedRequire
    _G.Handlers = {
      prepend = function() end,
      add = function(name, action, handler)
          _G.RegisteredHandlers = _G.RegisteredHandlers or {}
          _G.RegisteredHandlers[name] = handler
      end,
      utils = {
          hasMatchingTag = function()
              return function() end
          end
      },
      evaluate = function() end
  }
end