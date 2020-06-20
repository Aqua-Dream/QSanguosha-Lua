``` lua
-- 懂王: 出牌阶段，你可以将一些牌置于武将牌上，称为“懂”。<b>锁定技</b> 其他角色不能使用或打出与“懂”同名的手牌。
-- 口胡:<b>锁定技</b> 你每受到一点伤害，需将一张“懂”收回手牌。其他角色的回合开始前，需抽取你的一张“懂”并将其置入弃牌堆。

dongwangMod = sgs.CreateTriggerSkill{
    name = "#dongwangMod",  
    events = {sgs.CardsMoveOneTime,sgs.EventLoseSkill}, 
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name == "dong" then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if move.to:objectName() == p:objectName() then
                        player = p
                        break
                    end
                end 
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    for _,id in sgs.qlist(move.card_ids) do
                        local cd = sgs.Sanguosha:getCard(id)
                        local name = cd:getClassName()
                        room:setPlayerCardLimitation(p, "use,response", name.."|.|.|hand", false)
                    end
                end
            elseif move and move.from_pile_names then
                local i = 0
                for _,id in sgs.qlist(move.card_ids) do
                    local cd = sgs.Sanguosha:getCard(id)
                    local name = cd:getClassName()
                    i = i + 1
                    if move.from_pile_names[i] == "dong" then
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if not p:hasSkill("dongwang") then
                                room:removePlayerCardLimitation(p, "use,response", name.."|.|.|hand")
                            end
                        end
                    end
                end
            end
        elseif data:toString() == "dongwang" or data:toString() == self:objectName() then -- Lose Skill
            player:clearOnePrivatePile("dong")
        end
    end
}

dongwangCard = sgs.CreateSkillCard{
    name = "dongwang" ,
    will_throw = false ,
    target_fixed = true ,
    on_use = function(self, room, source, targets)
        source:addToPile("dong", self, true)
    end
}

dongwang = sgs.CreateViewAsSkill{
    name = "dongwang",
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local dongwang_card = dongwangCard:clone()
            for _,card in pairs(cards) do
                dongwang_card:addSubcard(card)
            end
            return dongwang_card
        end
    end
}

extension:insertRelatedSkills("dongwang","#dongwangMod") 



kouhu = sgs.CreateTriggerSkill{
    name = "kouhu",  
    events = {sgs.Damaged, sgs.EventPhaseStart}, 
    view_as_skill = kouhuVS,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local tlp = room:findPlayerBySkillName(self:objectName())
        if not tlp or tlp:getPile("dong"):isEmpty() then 
            return false 
        end
        local room = player:getRoom()
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.to and damage.to:hasSkill(self:objectName()) then
                local card_ids = tlp:getPile("dong")
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                if damage.damage >= card_ids:length() then
                    dummy.addSubcards(card_ids)
                else
                    room:fillAG(card_ids)
                    for i=1,damage.damage do
                        local card_id = room:askForAG(tlp, card_ids, false, "kouhu")
                        room:takeAG(tlp, card_id, false)
                        dummy:addSubcard(card_id)
                        card_ids:removeOne(card_id)
                    end
                    room:clearAG()
                end
                tlp:obtainCard(dummy)
                dummy:deleteLater()
            end
        elseif  player:getPhase() == sgs.Player_Start and not player:hasSkill(self:objectName()) then-- Phase start
            local card_ids = tlp:getPile("dong")
            local id = card_ids:at(math.random(0, card_ids:length() - 1))--取随机手牌代替askForCardChosen
            local cd = sgs.Sanguosha:getCard(id)
            --room:writeToConsole(cd:getClassName())
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "kouhu", "")
            room:throwCard(cd, reason, nil)
        end
        return false
    end
} 
```
# 6号武将
男性 4体力 神
## 单身
你可以将两张手牌当一张基本牌使用或打出。
```lua
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

function isStandard()
	return (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"]
end

danshenCard = sgs.CreateSkillCard{
	name = "danshenCard",
	will_throw = false,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local choice={}
		local patterns = {"slash","jink", "peach"}
		if not isStandard() then
			table.insert(patterns, "analeptic")
		end
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if cd=="slash" and not isStandard() then
						table.insert(choice, "normal_slash")
						table.insert(choice, "thunder_slash")
						table.insert(choice, "fire_slash")
					else
						table.insert(choice, cd)
					end
				end
			end
		end
		if #choice>0 then
			pattern=room:askForChoice(source, "@danshen-choose", table.concat(choice, "+"))
		end
		if pattern~="cancel" then
			if pattern=="normal_slash" then _pattern="slash"
			else _pattern=pattern end
			room:setPlayerProperty(source,"danshenPattern",sgs.QVariant(_pattern))
			room:askForUseCard(source, "@@danshen", "@danshen:::"..pattern)	
		end
	end
}

danshenResponse = sgs.CreateSkillCard{
	name = "danshenResponse",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@@danshen" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("danshen")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end		
		local pattern = player:property("danshenPattern"):toString()
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("danshen")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,	
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@@danshen" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = player:property("danshenPattern"):toString()
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@@danshen" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("danshen")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = player:property("danshenPattern"):toString()
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("danshen")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local player=card_use.from
		local room = player:getRoom()
		local pattern=self:getUserString()
		if pattern == "slash" and not isStandard() then
			pattern= "normal_slash+thunder_slash+fire_slash"
		end
		pattern = room:askForChoice(player, "@danshen-choose", pattern)
		if pattern=="normal_slash" then pattern="slash" end
		if pattern=="cancel" then return nil end
		room:setPlayerProperty(player,"danshenPattern",sgs.QVariant(pattern)) 
		local use_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		use_card:setSkillName("danshen")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		room:setEmotion(player, "weapon/spear")
		return use_card
	end,
	on_validate_in_response = function(self, player)
		local room = player:getRoom()
		--room:broadcastSkillInvoke("danshen")
		local pattern=self:getUserString()
		if pattern== "peach+analeptic" and isStandard() then
			pattern="peach"
		elseif pattern == "slash" and not isStandard() then
			pattern= "normal_slash+thunder_slash+fire_slash"
		end
		pattern = room:askForChoice(player, "@danshen-choose", pattern)
		if pattern=="normal_slash" then pattern="slash" end
		if pattern=="cancel" then return nil end
		room:setPlayerProperty(player,"danshenPattern",sgs.QVariant(pattern)) 
		local use_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		use_card:setSkillName("danshen")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		room:setEmotion(player, "weapon/spear")
		return use_card
	end
}
danshen = sgs.CreateViewAsSkill{
	name = "danshen" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		local reason=sgs.Sanguosha:getCurrentCardUseReason()
		return not to_select:isEquipped() and (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
	end ,
	view_as = function(self, cards)
		local reason=sgs.Sanguosha:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@@danshen" then
				local pattern = sgs.Self:property("danshenPattern"):toString()
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
				if c and #cards == 2 then
					c:setSkillName(self:objectName())
					c:addSubcard(cards[1])
					c:addSubcard(cards[2])
					return c
				else
					return nil
				end
			elseif #cards==2 then
				local card = danshenResponse:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				card:addSubcard(cards[1])
				card:addSubcard(cards[2])
				return card
			end
		elseif #cards == 0 then
			return danshenCard:clone()
		end
	end ,
	enabled_at_play = function(self, player)
		if player:getHandcardNum() < 2 then return false end
		local patterns = {"slash","jink", "peach"}
		if not isStandard() then
			table.insert(patterns, "analeptic")
		end
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(player) then
					return true
				end
			end
		end
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		if pattern=="@@danshen" then return player:getHandcardNum() >= 2 end
		return (player:getHandcardNum() >= 2) 
		and (string.find(pattern, "slash") or string.find(pattern, "analeptic") or string.find(pattern, "jink") or string.find(pattern, "peach"))
	end
}
```
## 表白
当其他角色受到伤害后，若伤害来源不为你，你可以交给其一张牌并弃掉所有其他角色的“爱”标记，然后你其各获得一个“爱”标记。
```lua
biaobai = sgs.CreateTriggerSkill{
	name = "biaobai",  
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local mark="@aiMark"
		local syly = room:findPlayerBySkillName(self:objectName())
		if not syly then return end
		if damage.from and damage.from:hasSkill(self:objectName()) then return false end
		if syly:getCardCount(true)>0 and syly:askForSkillInvoke(self:objectName()) then
			card = room:askForExchange(syly, self:objectName(), 1, 1, true, "biaobaiGive::"..player:objectName(),true)
			if card and card:subcardsLength()>0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, syly:objectName(),
												  player:objectName(), self:objectName(), nil)
				reason.m_playerId = player:objectName()
				room:moveCardTo(card, syly, player, sgs.Player_PlaceHand, reason)
				for _, p in sgs.qlist(room:getOtherPlayers(syly)) do
					p:loseAllMarks(mark)
				end
				syly:gainMark(mark)
				player:gainMark(mark)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and not target:hasSkill(self:objectName())
	end
}

	["biaobaiGive"]="请交给 %dest 1 张牌",
```
## 脱单
**觉醒技** 当伤害结算完毕时，若你的“爱”标记不少于3个，你增加一点体力上限并回复一点体力，失去技能“单身”、“表白”并获得技能“相爱”。
```lua
tuodan = sgs.CreateTriggerSkill{
	name = "tuodan",  
	events = {sgs.DamageComplete},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark="@aiMark"
		local syly = room:findPlayerBySkillName(self:objectName())
		if not syly then return end
		if syly:getMark(mark)>=3 and syly:getMark("tuodanWake")==0 then
			room:doSuperLightbox(syly:getGeneralName(),self:objectName())
			room:setPlayerMark(syly,"tuodanWake", 1)
			local n=syly:getGeneralMaxHp()
			syly:loseSkill("danshen")
			syly:loseSkill("biaobai")
			syly:acquireSkill("xiangai")
			local isSecondaryHero = not (sgs.Sanguosha:getGeneral(syly:getGeneralName()):hasSkill(self:objectName()))
			room:changeHero(syly, "spyly", false, true,isSecondaryHero, false)
			syly:setMaxHp(n)
			room:changeMaxHpForAwakenSkill(syly,1)
			room:recover(syly, sgs.RecoverStruct(syly))
			for _, p in sgs.qlist(room:getOtherPlayers(syly)) do
				if p:getMark(mark)>0 then
					sgs.updateIntention(syly, p, -150)
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
```
## 相爱
每当有“爱”标记的角色即将受到伤害时，另一名有“爱”标记的角色可以失去一点体力，然后防止此伤害。
```lua
xiangai = sgs.CreateTriggerSkill{
	name = "xiangai", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted}, 
	priority={0},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local another
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@aiMark")>0 then
				another=p
				break
			end
		end
		local damage=data:toDamage()
		local nature="normal"
		if damage.nature ~= sgs.DamageStruct_Normal then nature="unnormal" end
		local datatable = {"help",player:objectName(),tostring(damage.damage),nature}
		if another and damage and damage.damage>0
		and room:askForSkillInvoke(another,self:objectName(),sgs.QVariant(table.concat(datatable,":"))) then
			room:loseHp(another,1)
			local log2 = sgs.LogMessage()
			log2.type = "#xiangai:log"
			log2.from = player
			room:sendLog(log2)
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@aiMark")>0
	end
}

	["xiangai:help"] = "你可以失去一点体力，然后防止 %src 受到此伤害。",
	["#xiangai:log"] = "%from 受到的伤害被防止。",
```
相关AI：
```lua
local getCmpHp = function(p,self)
	local hp = p:getHp()
	if p:isLord() and self:isWeak(p) then hp = hp - 4 
	elseif self:isWeak(p) then hp = hp-2 end
	if p:hasSkill("qingnang") then hp = hp - 5 end
	if p:hasSkill("buqu") or p:hasSkill("nosbuqu") then hp = hp + 4 end
	if p:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi") and p:getHp() >= 2 then hp = hp + 1 end
	if p:hasSkills("yinghun|nosmiji|miji|ganlu|shangshi|nosshangshi") and not self:isWeak(p) then hp = hp+2 end
	if p:hasSkill("hunzi") and p:getHp()==2 then hp = hp +5 end
	if p:hasSkill("longhun") and p:getHandcardNum()>2 and p:getHp()>1 then hp=hp+6 end
	return hp
end

sgs.ai_skill_invoke["xiangai"] = function(self,data)
	local promptlist = data:toString():split(":")
	local to = findPlayerByObjectName(self.room, promptlist[2])
	--local room = to:getRoom()
	local damage = tonumber(promptlist[3])
	local nature = promptlist[4]
	local n=0
	if not to:isWounded() and nature=="nature" and damage==1 then return false end
	if nature~="nature" and to:isChained() then
		for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
			if aplayer:isChained() then
				if self:isFriend(aplayer) then
					n=n+1
				else
					n=n-1
				end
			end
		end
		damage=damage*n
	elseif not self:isFriend(to) then 
		return false
	end
	if damage<=0 then return false end
	myhp=getCmpHp(self.player,self)+2*(damage-1)
	hishp=getCmpHp(to,self)
	
	return myhp>hishp
end
```



# 3号武将
女性 3体力 神
## 阴谋
每当你将造成伤害或受到伤害时，你可以弃一张牌并选择一名角色，使其成为此伤害的来源。
```lua
yinmouCard = sgs.CreateSkillCard{
	name = "yinmouCard" ,
	filter = function(self, selected, to_select)
		return #selected == 0
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.to:addMark("yinmouFrom")
		local damage = effect.from:getTag("yinmouDamage"):toDamage()
		damage.from = effect.to
		room:damage(damage)
		effect.to:removeMark("yinmouFrom")
	end
}

yinmouVS = sgs.CreateViewAsSkill{
	name = "yinmou" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local ymCard = yinmouCard:clone()
		ymCard:addSubcard(cards[1])
		ymCard:setSkillName(self:objectName())
		return ymCard
	end ,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@yinmou"
	end
}

yinmou = sgs.CreateTriggerSkill{
	name = "yinmou", 
	events = {sgs.DamageCaused,sgs.DamageInflicted}, 
	view_as_skill = yinmouVS, 
	priority={11,11},
	on_trigger = function(self, event, player, data)
		if player:getCardCount(true)>0 then
			local damage = data:toDamage()
			if not damage.from or damage.from:getMark("yinmouFrom") ==0 then
				player:setTag("yinmouDamage", data)
				return player:getRoom():askForUseCard(player, "@@yinmou", "@yinmou-card", -1, sgs.Card_MethodDiscard)
			end
		end
		return false
	end
}
```
## 阳谋
每当你对距离为1以内的角色造成伤害后，你可以摸一张牌，或者弃一张牌并回复1点体力。
```lua
yangmou = sgs.CreateTriggerSkill{
	name = "yangmou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damage, sgs.PreDamageDone},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
			local zzh=damage.from
			zzh:setTag("can_yangmou", sgs.QVariant((zzh:distanceTo(damage.to) <= 1)))
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:hasSkill(self:objectName()) and player:isAlive() then
			local invoke = player:getTag("can_yangmou"):toBool()
			player:setTag("can_yangmou", sgs.QVariant(false))
			if invoke and player:askForSkillInvoke(self:objectName()) then
				local choices = {}
				table.insert(choices, "draw")
				if player:isWounded() and player:getCardCount(true)>0 then
					table.insert(choices, "recover") 
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice=="recover" then
					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				elseif choice=="draw" then
					player:drawCards(1)
				end
			end
			
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

	["yangmou:draw"]="摸一张牌",
	["yangmou:recover"]="弃牌回血",
```
## 对诗
当有角色的牌被弃置时，你可以弃一张点数相同的牌，然后与其各摸一张牌。
```lua
duishi = sgs.CreateTriggerSkill{
	name = "duishi",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not move.from then return false end
		if player:getHp() > 0 and move.from:isAlive() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE then
			for _, card_id in sgs.qlist(move.card_ids) do
				local n=sgs.Sanguosha:getCard(card_id):getNumber()
				local flag=false
				for _, card in sgs.qlist(player:getHandcards()) do 
					if card:getNumber()==n then
						flag=true
						break
					end
				end
				if not flag then
					for _, card in sgs.qlist(player:getEquips()) do 
						if card:getNumber()==n then
							flag=true
							break
						end	
					end	
				end
				if flag and player:askForSkillInvoke(self:objectName(), data) then
					card = room:askForCard(player, string.format(".|.|%d", n), "@duishi-discard:" .. move.from:objectName())
					if card and card:getNumber()==n then
						speakSkill(room,self:objectName(),math.random(1,2),100)
						player:drawCards(1)
						local from = room:findPlayer(move.from:getGeneralName())
						from:drawCards(1) --必须要这么纠结才能摸到牌。。。
					end
				end
			end
				
		end
		return false
	end
}

["@duishi-discard"]="请弃置相同点数的牌，然后你与 %src 各摸一张牌",
```


# 7号武将
3体力 女性 神
## 专权
出牌阶段，你可以将一些牌置于武将牌上，称为“權”。**锁定技** 你的回合内，其他角色不能使用或打出与“權”同名的手牌。
(为了不与钟会的技能冲突，将“权”写成繁体字以示区分)
```lua
zhuanquanMod = sgs.CreateTriggerSkill{
	name = "#zhuanquanMod",  
	events = {sgs.EventPhaseChanging,sgs.EventLoseSkill}, 
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Start and player:getPile("quanMod"):length()>0 then
				room:sendCompulsoryTriggerLog(player, "zhuanquan")
				local zhuan = player:getPile("quanMod")
				for _,id in sgs.qlist(zhuan) do
					local cd = sgs.Sanguosha:getCard(id)
					local name = cardName(cd)
					if not player:hasFlag("zhuanquan:"..name) then
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:setPlayerCardLimitation(p, "use,response", name.."|.|.|hand", false)
						end
						room:setPlayerFlag(player,"zhuanquan:"..name)
					end
				end
			elseif change.to == sgs.Player_NotActive then
				local flags = player:getFlags()
				local flagtable = flags:split("|")
				for _, flag in ipairs(flagtable) do
					local t = flag:split(":")
					if t[1] == "zhuanquan" then
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:removePlayerCardLimitation(p, "use,response", t[2].."|.|.|hand$0")
						end
					end
				end
			end
		elseif data:toString() == "zhuanquan" then
			local flags = player:getFlags()
			local flagtable = flags:split("|")
			for _, flag in ipairs(flagtable) do
				local t = flag:split(":")
				if t[1] == "zhuanquan" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:removePlayerCardLimitation(p, "use,response", t[2].."|.|.|hand$0")
					end
				end
			end
		end
		return false
	end
}
zhuanquanCard = sgs.CreateSkillCard{
	name = "zhuanquan" ,
	will_throw = false ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		source:addToPile("quanMod", self, true)
		local zhuan = source:getPile("quanMod")
		for _,id in sgs.qlist(zhuan) do
			local cd = sgs.Sanguosha:getCard(id)
			local name = cardName(cd)
			if not source:hasFlag("zhuanquan:"..name) then
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do
					room:setPlayerCardLimitation(p, "use,response", name.."|.|.|hand", false)
				end
				room:setPlayerFlag(source,"zhuanquan:"..name)
			end
		end
		room:sendCompulsoryTriggerLog(source, "zhuanquan")
	end
}

zhuanquan = sgs.CreateViewAsSkill{
	name = "zhuanquan",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhuanquan_card = zhuanquanCard:clone()
			for _,card in pairs(cards) do
				zhuanquan_card:addSubcard(card)
			end
			return zhuanquan_card
		end
	end
}
```
## 谋利
**锁定技** 弃牌阶段结束时，若你武将牌上有“權”，你须进行一次判定，然后弃掉所有与判定牌同类型的“權”并摸X张牌（X为弃置的“權”的数量且至多为2）。
```lua
mouli = sgs.CreateTriggerSkill{
	name = "mouli",  
	events = {sgs.EventPhaseChanging}, 
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getPile("quanMod"):length()>0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good=true
				judge.reason=self:objectName()
				judge.who=player
				room:judge(judge)
				local zhuan = player:getPile("quanMod")
				local n = 0
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _,id in sgs.qlist(zhuan) do
					cd = sgs.Sanguosha:getCard(id)
					if cd:getTypeId() == judge.card:getTypeId() then
						dummy:addSubcard(cd)
						n=n+1
					end
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(),"")
				if n>0 then
					room:throwCard(dummy, reason, nil)
					if n>2 then n=2 end
					player:drawCards(n)
				end
				dummy:deleteLater()
			end
		end
		return false
	end
}
```


# 8号武将
4体力 男性 神
## 剑道
**锁定技** 你每使用或打出一张基本牌或锦囊牌时，获得一个“易”标记；你与其他角色计算相互的距离-X（X为“易”的数量的一半，向下取整）。
``` lua
jiandao = sgs.CreateTriggerSkill{
	name = "jiandao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardResponded,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = "@yiMark"
		local flag = "lianjiFlag"
		local card
		if event==sgs.CardResponded then
			card = data:toCardResponse().m_card
		elseif event==sgs.CardUsed then
			card = data:toCardUse().card
		end
		if card then
			if player:hasFlag(flag) then
				player:setFlags("-"..flag)
			elseif (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
				player:gainMark(mark)
			end
		end
		return false
	end
}
jiandaoDist = sgs.CreateDistanceSkill{
	name = "#jiandaoDist" ,
	correct_func = function(self, from, to)
		return -math.floor((from:getMark("@yiMark")+to:getMark("@yiMark"))/2)
	end
}

extension:insertRelatedSkills("jiandao","#jiandaoDist") 

["@yiMark"]="易",
```

## 连击
**锁定技** 你每次使用【杀】或除【无懈可击】之外的非延时锦囊结算完后，若你的“易”标记不少于你的体力上限，你弃掉所有标记，然后此牌进行一次额外的合法结算。
``` lua
function canUse(use)
	local card = use.card
	for _, p in sgs.qlist(use.to) do
		if not p:isAlive() or (use.card:isKindOf("Collateral") and not p:getWeapon())
			or ((use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and p:getCardCount(true,true)==0)
			or	(use.card:isKindOf("FireAttack") and p:getCardCount(false)==0) then
			use.to:removeOne(p)
		end
	end
	return not use.to:isEmpty()
end

luaLianji = sgs.CreateTriggerSkill{
	name = "luaLianji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished,sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mark = "@yiMark"
		local flag = "lianjiFlag"
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if player:getMark(mark)>=player:getMaxHp() and (card:isKindOf("Slash") or (card:isNDTrick() and not card:isKindOf("Nullification"))) then
				room:getThread():delay()
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:loseAllMarks(mark)
				player:setFlags(flag)
				if canUse(use) then
					if use.card:isKindOf("Slash") then
						player:setFlags("lianjiSlash")
					end
					room:useCard(use)
				end
			end
		else
			local effect = data:toSlashEffect()
			if effect.from:hasFlag("lianjiSlash") then
				effect.drank=0
				data:setValue(effect)
				effect.from:setFlags("-lianjiSlash")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
```

## α突袭
**觉醒技** 准备阶段开始时，若你计算与所有其他角色距离为1，你失去1点体力上限，然后摸X张牌并弃掉所有“易”标记（X为“易”的数量且至多为2）。
``` lua
function isAllAdjacent(from)
    for _, p in sgs.qlist(from:getAliveSiblings()) do
        if from:distanceTo(p) ~= 1 then
            return false
        end
    end
    return true
end

alphatuxi = sgs.CreateTriggerSkill{
	name = "alphatuxi",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start and player:getMark("yiWake")==0 and isAllAdjacent(player) 
		and room:changeMaxHpForAwakenSkill(player) then
			room:doSuperLightbox(player:objectName(),self:objectName())
			if player:getMark("@yiMark")>0 then
				room:getThread():delay()
				player:drawCards(math.min(player:getMark("@yiMark"), 2))
				player:loseAllMarks("@yiMark")
			end
			room:setPlayerMark(player,"yiWake", 1)
		end
		return false
	end
}
```
