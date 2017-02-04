local ModDrawableTD = Class.create("ModDrawableTD", Entity)

ModDrawableTD.trackFunctions = {"draw"}

function ModDrawableTD:create()
	self.animations = self.animations or {}
	self.sprites = self.sprites or {}
	self.spritePieceNames = self.spritePieceNames or {}
	self.idleCounter = 0
	-- self.angle = 0
	self.imgX = 64
	self.imgY = 64
	self.initImgH = 64
	self.initImgW = 64

	self.x = self.x or 0
	self.y = self.y or 0
	self.height = self.height or 0


	-- self.lastDir = 0
	self.referenceVel = 0
	self.animationsPending = {}
	self.attachPositions = {}
	self.icons = {}
end

function ModDrawableTD:tick(dt)
	self:updateSprites() 
end

function ModDrawableTD:destroy()
	for key, value in pairs(self.sprites) do
		self:delSpritePiece(key)
	end
	if self.sprite then
		Game.scene:remove(self.sprite)
	end 
end

function ModDrawableTD:changeAnimation(animation,speedMod,spritePieces)
	if not self.advancedSprites then
		return 
	end
	local speed = speedMod or 1
	speed = 1/speed
	local hasAnimation = false
	local goodKey = "none"
	if type(animation) == "table" then
		for i=1,#animation do
			if self.animations[animation[i]] then
				goodKey = animation[i]
				break
			end
		end
	else
		goodKey = animation
	end
	if self.animations[goodKey] then
		hasAnimation = true
		local anim = self.animations[goodKey]
		local sprites = anim.sprites
		if type(sprites) == "table" then
			for key,value in pairs(sprites) do
				if (not spritePieces or util.hasValue(spritePieces,key)) and self.sprites[key] then
					local anim2 = value
					local row = anim2.row
					local range = anim2.range
					local delay = anim2.delay * speed
					local startFrame = anim2.startFrame or 1
					local noLoop = anim2.noLoop
					local mDir = anim2.dir or 1
					if self.dir == 0 then
						range = anim2.upRange or range
						row = anim2.upRow or row
						delay = anim2.upDelay or delay * 2
					elseif self.dir == 2 then
						range = anim2.downRange or range
						delay = anim2.downDelay or delay * 2
						row = anim2.downRow or row
					end
					local priority = (anim2.priority or 1)
					if true then --(#self.animationsPending == 0 and priority >= self.sprites[key].priority) then
						if self.dir == 0 then
							self.sprites[key]:updateAttach(value.attachUp or value.attachMod or {{{x=0,y=0}}})
						elseif self.dir == 2 then
							self.sprites[key]:updateAttach(value.attachDown or value.attachMod or {{{x=0,y=0}}})
						else
							self.sprites[key]:updateAttach(value.attachMod or {{{x=0,y=0}}})
						end
						--self.sprites[key]:updateAttach(value.attachDown)
						if goodKey ~= self.sprites[key].currentAnim or self.sprites[key].currentDir ~= self.dir then
							self.sprites[key]:setIndex(0)
							self.sprites[key]:onUpdate()
							self.sprites[key]:resume()
						end
						self.sprites[key].mDir = mDir
						self.sprites[key].currentDir = self.dir
						self.sprites[key].currentAnim = goodKey
						self.sprites[key].priority = priority
						self:orientSprite(row,range,delay,startFrame, key,noLoop)
						self:orientAllSprites()
					end
				end
			end
		end
	end
	return hasAnimation
end


function ModDrawableTD:updateSprites()
	if self.body then
		self.x,self.y = self.body:getPosition()
	end
	if not self.angle and (self.body and not self.body:isFixedRotation()) then
		self:setSprAngle(self.body:getAngle())
	end
	for i,spriteName in ipairs(self.spritePieceNames) do
		local spr = self.sprites[spriteName]
		if spr.noLoop == false then
			self:changeAnimation(spr.currentAnim )
		end
		Game.scene:move(spr,self.y + (spr.zDiff or 0))
	end
	self:setSprPos(self.x,self.y + 29 + math.floor(self.height/2))
end

function ModDrawableTD:orientAllSprites()
	for key,value in pairs(self.sprites) do
		if self.dir == -1 or self.dir == 1 then
			value:setScale(self.dir * value.mDir,1)
		else
			value:setScale(value.mDir,1)
		end
		value.dir = self.dir
	end
end
function ModDrawableTD:orientSprite(row,range,delay,startFrame, sprite, onLoop)
	local spr = self.sprites[sprite] or self.sprite
	if delay == 0 then delay = 0.1 end
	local md = self.sprites[sprite].mDir
	if self.dir == -1 or self.dir == 1 then
		spr:setScale(self.dir * md,1)
	else
		spr:setScale(md,1)
	end
	spr:setAnimation(range,row,1/delay,onLoop)
	spr.dir = self.dir * md
end

function ModDrawableTD:freezeAnimation(sprite, duration)
	if self.sprites[sprite] then
		self.sprites[sprite]:pause(duration)
	end
end

function ModDrawableTD:resetAnimation(spritePiece)
	if self.sprites[spritePiece] then
		self.sprites[spritePiece]:resetAnimation()
		self.sprites[spritePiece]:onUpdate()
	end
end
function ModDrawableTD:overrideAnimation(spritePiece)
	if self.sprites[spritePiece] then
		self.sprites[spritePiece].priority = 0
	end
end

function ModDrawableTD:normalizeSprSize( speed )
	local s = speed or 8
	self.imgX = math.min( self.imgX + s, self.initImgW )
	self.imgY = math.min( self.imgY + s, self.initImgH)
end

-- function ModDrawableTD:animate()
-- 	-- lume.trace()
-- 	local maxSpeed, maxSpeedY = self.maxSpeed, self.maxSpeedY
-- 	local walkanim = math.abs(4 / self.velX)
-- 	local newVelX = self.velX - self.referenceVel
-- 	walkanim = math.max(walkanim, 0.18)

-- 	if self.inAir then 
-- 		if self.turnTime and self.turnTime > 0 then
-- 				self:changeAnimation({"fallTurn","fall"})
-- 		elseif not self.turnTime and self.velY < 0 or self.jumping then
-- 			self:changeAnimation("jump")
-- 		else
-- 			self:changeAnimation({"fall","jump"})
-- 		end
-- 	elseif self.isCrouching then
-- 		self:changeAnimation({"crouch","stand"})
-- 	elseif self.isMoving then
-- 		self.idleCounter = 0
-- 		if (self.dir == 1 and newVelX < -16) or (self.dir == -1 and newVelX > 16) then
-- 			self:changeAnimation({"slideMore","slide","stand"})
-- 		else
-- 			if self.status == "offense" and self.prepTime > 5 then
-- 				--self:changeAnimation("prep2")
				
-- 				--self:freezeAnimation("body",0.0)
-- 				--self:freezeAnimation("head",0.0)
-- 			end 
-- 			if math.abs(newVelX) >= maxSpeed - 52 then
-- 				self:changeAnimation({"run","walk"})
-- 			else
-- 				self:changeAnimation("walk")
-- 			end
-- 		end
-- 	else
-- 		if math.abs(newVelX) <= 32 then
-- 			self.idleCounter = self.idleCounter + 1
-- 			if self.status == "offense" and self.prepTime > 5 then
-- 			--	self:changeAnimation({"prep","stand"})
-- 			else
-- 				if self.idleCounter >= 60 and self.idleCounter < 89 then
-- 					self:changeAnimation({"idleStart","idle","stand"})
-- 				elseif self.idleCounter > 84 then
-- 					self:changeAnimation({"idle","stand"})
-- 				else
-- 					self:changeAnimation("stand")
-- 				end
-- 			end
-- 			-- if self.idleCounter >= 84 then
-- 			-- 	self.idleCounter = 0
-- 			-- end
-- 		else
-- 			self:changeAnimation({"slide","stand"})
-- 		end
-- 	end
-- 	if self.isHolding then
-- 		self:changeAnimation({"holding","guard"})
-- 	end
-- end

function ModDrawableTD:addSpritePieces( newPieces )
	local depth = self.depth
	for key, piece in pairs(newPieces) do
		self:addSpritePiece(piece ,depth)
		depth = depth + 1
	end
end

function ModDrawableTD:addSprite( piece )
	self.sprite = xl.Sprite(piece.path, piece.width, piece.height)
	self.sprite:setSize((piece.imgX or piece.width/2), (piece.imgY or piece.height/2))
	self.sprite:setOrigin((piece.originX or piece.width/2), (piece.originY or piece.height/2))
	self:changeAnimation(1,1,0, 1)
	Game.scene:insert(self.sprite)
end

function ModDrawableTD:addSpritePiece( piece , d)
	local sprite
	local SpritePiece = require "xl.SpritePiece"
	self.advancedSprites = true
	if not util.hasValue(self.spritePieceNames,piece) then
		table.insert(self.spritePieceNames,piece.name)
	end
	sprite = SpritePiece(piece.path, (piece.width or 128), (piece.height or 128),0,d,piece.name)
	local imgY = (piece.imgY or piece.height/2)
	sprite:setOrigin((piece.originX or piece.width/2), (piece.originY or piece.height/2))
	sprite:setSize((piece.imgX or piece.width/2), imgY)
	sprite.vert = piece.vert or imgY
	if piece.attachPoints then
		for key, point in pairs(piece.attachPoints) do
			self.attachPositions[key] = {x=(point.x -sprite.ox), y =(point.y -sprite.oy)}
			sprite:addPoint(key,(point.x -sprite.ox),(point.y -sprite.oy))
		end
	end
	if piece.connectSprite then
		local connectSprite
		for key, sprite in pairs(self.sprites) do
			if key == piece.connectSprite then
				connectSprite = sprite
				break
			end
		end
		if connectSprite == nil then
			lume.trace('mType: ',self.type, "currentSprite", piece.name,"connectSprite:",piece.connectSprite)
			error('Attempted to connect Sprite to spritePiece that does not exist')
		end
		sprite:addConnectPoint(connectSprite, piece.connectPoint,piece.connectMPoint)
	end
	sprite:setAnimation(1,1,1)
	-- sprite:setDepth(d + (piece.z or 0))
	Game.scene:insert(sprite)
	self.sprites[piece.name] = sprite
	if piece.animations then
		local animations
		if type(piece.animations) == "string" then
			animations = require(piece.animations)
		else
			animations = piece.animations
		end
		for k,v in pairs(animations) do
			if not self.animations[k] then
				self.animations[k] = {}
				self.animations[k]["sprites"] = {}
			end
			self.animations[k]["sprites"][piece.name] = v
		end
	end
end


function ModDrawableTD:delSpritePiece( pieceName )
	if self.sprites[pieceName] then
		Game.scene:remove(self.sprites[pieceName])
		self.sprites[pieceName] = nil
	end
end

function ModDrawableTD:getAttachPos(attachPoint )
	return self.attachPositions[attachPoint]
end

function ModDrawableTD:setSprPos( x , y )
	self.lastY = y
	for i, spriteName in ipairs(self.spritePieceNames) do
		local piece = self.sprites[spriteName]
		local piecesPos = piece:updatePos(x,y - piece.vert/2)
		for k,v in pairs(piecesPos) do
			self.attachPositions[k] = v
		end
	end
	if self.sprite then
		self.sprite:setPosition(x,y)
	end
end


function ModDrawableTD:setSprAngle( angle )
	for key, piece in pairs(self.sprites) do
		piece:setAngle(angle)
	end
	if self.sprite then
		self.sprite:setAngle(angle)
	end
end

function ModDrawableTD:setDepth( depth )
	self.depth = depth
end


function ModDrawableTD:addIcon( newIcon )
	local newPieces
	local newTable = {}
	newIcon = util.deepcopy(newIcon)
	for i,v in ipairs(self.icons) do
		if v.path == newIcon.path then
			return 
		end
	end
	local iconName = "icon" .. #self.icons + 1
	newIcon.name = iconName
	if #self.icons > 0 then
		newIcon.connectSprite = "icon" .. (#self.icons)
	elseif self.sprites["main"] then
		newIcon.connectSprite = "main"
		newIcon.connectPoint = "center"
		newIcon.attachPoints.prevIco = {x=16,y=48}
	elseif self.sprites["legs"] then
		newIcon.connectSprite = "legs"
		newIcon.connectPoint = "center"
		newIcon.attachPoints.prevIco = {x=16,y=48}
	end
	-- lume.trace(newIcon.path)
	-- lume.trace(iconName)
	-- util.print_table(self.icons)
	-- lume.trace(Game:getTicks())

	self:addSpritePiece(newIcon)
	-- lume.trace(self.sprites[newIcon.name].setAngle)
	self.icons[#self.icons + 1] = newIcon
end

function ModDrawableTD:removeIcon( iconPath )
	local pushBack = false
	local deletedInd = 0
	for i,v in pairs(self.icons) do
		if v.path == iconPath then
			pushBack = true
			self:delSpritePiece(v.name)
			deletedInd = i
			-- lume.trace("I is: ",i,"removed: ", v.name, "path: ",iconPath)
		elseif pushBack then
			self:delSpritePiece(v.name)
			v.connectSprite = "icon" .. (i - 2)
			v.name = "icon" .. (i - 1)
			if (i-1) == 1 then
				if self.sprites["main"] then
					v.connectSprite = "main"
				else
					v.connectSprite = "legs"
				end
				v.connectPoint = "center"
				v.attachPoints.prevIco = {x=16,y=48}
			end
			lume.trace("prev was: ", i, "Now is: " , v.name)
			lume.trace("trying to connect to: " , v.connectSprite)
			self:addSpritePiece(v)
		end
	end

	if deletedInd ~= 0 then
		table.remove(self.icons,deletedInd)
	else
		lume.trace("Attempting to remove icon that does not exist.")
	end
end
return ModDrawableTD