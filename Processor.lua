
--!strict

-- "Processor" class written by @baseparts
-- For values that will be cached after processing
-- The idea is very similar to Promises

-------------------------------------

local UtilityFolder = script.Parent
local SignalClass = require(UtilityFolder.Signal)

local Processor = {}
Processor.__index = Processor

-------------------------------------

type Work = () -> (any)
type Callback = (any) -> () 

type self = {
	Processing: {[any]: SignalClass.Signal<>},
	Processed: {[any]: any},
}
export type Class = typeof(setmetatable({} :: self, Processor))

-------------------------------------

function Processor.new(): Class
	return setmetatable({
		Processing = {},
		Processed = {}
	} :: self, Processor)
end


function Processor._killProcess<_, T>(self: Class, Index: T)
	if not self:HasIndexProcessing(Index) then
		return
	end
	
	local Signal = self.Processing[Index]
	Signal:Destroy()
	
	self.Processing[Index] = nil
end


function Processor._completeProcess<_, T, V>(self: Class, Index: T, Value: V)
	if not self:HasIndexProcessing(Index) then
		return
	elseif Value == nil then
		self:_killProcess(Index)
	end
	
	
	local Signal = self.Processing[Index]
	
	self.Processed[Index] = Value
	Signal:Fire()
	self:_killProcess(Index)
end


function Processor.HasIndexProcessing<_, T>(self: Class, Index: T): boolean
	return self.Processing[Index] ~= nil
end


function Processor.HasIndexProcessed<_, T>(self: Class, Index: T): boolean
	return self.Processed[Index] ~= nil
end


function Processor.HasIndex<_, T>(self: Class, Index: T): boolean
	return (self:HasIndexProcessed(Index) or self:HasIndexProcessing(Index))
end


function Processor.GetValue<_, T>(self: Class, Index: T): any
	return self.Processed[Index]
end


function Processor.StartProcess<_, T>(self: Class, Index: T, Work: Work?)
	if self:HasIndex(Index) then
		return
	end
	local Signal = SignalClass.new()	
	self.Processing[Index] = Signal	
	
	if Work then -- Otherwise youd have to manually call CompleteProcess, which in some cases is better than wrapping all your code inside the work function
		local Value = Work() -- Can yield

		if (Value == nil) then -- The work returned nil, so kill the process
			self:_killProcess(Index)
			return
		elseif (not self:HasIndexProcessing(Index)) then -- Process was killed from elsewhere
			return
		end

		self:_completeProcess(Index, Value)
	end
end


function Processor.CompleteProcess<_, T, V>(self: Class, Index: T, Value: V)
	self:_completeProcess(Index, Value)
end


function Processor.CancelProcess<_, T>(self: Class, Index: T)
	self:_killProcess(Index)
end


function Processor.WaitForProcess<_, T>(self: Class, Index: T)
	if not self:HasIndexProcessing(Index) then
		return
	end
	
	self.Processing[Index]:Wait()
end


function Processor.CallbackForProcess<_, T>(self: Class, Index: T, Callback: Callback)
	if not self:HasIndexProcessing(Index) then
		Callback(self:GetValue(Index))
		return
	end

	self.Processing[Index]:Once(function()
		Callback(self:GetValue(Index))
		return
	end)
end

-------------------------------------

return Processor
