local async = {}

async.countdown = {}
function async.countdown.new(count, cb)
  local called = false
  if count == 0 then
    called = true
    cb()
  end
  return function()
    count = count - 1
    if count == 0 and not called then
      cb()
      called = true
    end
  end
end

function async.await_all(thunks, cb)
  local countdown = async.countdown.new(#thunks, cb)
  for _, thunk in ipairs(thunks) do
    thunk(countdown)
  end
end

return async
