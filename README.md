# Processor

## For values that are being processed and will be cached when completed

Here is example code of how can it can be used (this does not go over everything, just what is important):

```lua
--------
-- Lets process a key with a work argument

local Processor = ProcessorClass.new()

local SomeKey = 1

Processor:StartProcess(SomeKey, function()
	task.wait(2)
	return "Hello, world!"
end, true) -- last argument is to spawn the work, so it wont yield


--------

print( Processor:HasIndex(SomeKey) ) -- true, the key is in the processor
print( Processor:HasIndexProcessing(SomeKey) ) -- true, the key is being processed
print( Processor:HasIndexProcessed(SomeKey) ) -- false, the key has not been fully processed yet

--------

Processor:CallbackForProcess(SomeKey, function(Value: any) -- This will callback when the key has been processed
	print(Value) -- "Hello, world!"	
	print( Processor:HasIndexProcessed(SomeKey) ) -- true, the key has been processed
end)

--------

local Success = Processor:WaitForProcess(SomeKey) -- Yield the code until it process completes

if Success then -- There's a chance the process was cancelled
	local Value = Processor:GetValue(SomeKey)
	print(Value) -- "Hello, world!"
end

--------
-- Lets try again, but without passing a work argument

local AnotherKey = 2

Processor:StartProcess(AnotherKey)
task.wait(2)
Processor:CancelProcess(AnotherKey)

--------

print( Processor:HasIndex(SomeKey) ) -- false, the key is not in the processor (the process was cancelled)

--------
```
