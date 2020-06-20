module("extensions.fmyl", package.seeall)  

extension = sgs.Package("fmyl")

-- sgs.General(package, name, kingdom, max_hp=4, male=true, hidden=false, never_shown=false)
--以下为王义磊
wyl=sgs.General(extension, "wyl", "god",3, true) 


shenmou = sgs.CreateTriggerSkill{
    name = "shenmou", 
    events = {sgs.TrickCardCanceling},
    can_trigger = function(self, target) return target end,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local effect = data:toCardEffect()
        return effect.from and effect.from:hasSkill(self:objectName()) and effect.from:isAlive()
    end
}

yuanlvCard = sgs.CreateSkillCard{
    name = "yuanlv",
    handling_method = sgs.Card_MethodDiscard,
    filter = function(self,targets,to_select)
        local tos = sgs.Self:property("yuanlvUse"):toString():split("+")
        local old_nullified = sgs.Self:property("yuanlvOldNullify"):toString():split("+")
        return table.contains(tos,to_select:objectName()) and #targets < self:getSubcards():length()
        and (not table.contains(old_nullified,to_select:objectName())) 
    end,
    feasible = function(self,targets)
        return #targets == self:getSubcards():length()
    end,
    on_use = function(self,room,source,targets)
        local nullified_list = {}
        for _, target in ipairs(targets) do 
            table.insert(nullified_list,target:objectName())
        end
        room:setPlayerProperty(source,"yuanlvNullify",sgs.QVariant(table.concat(nullified_list,"+")))
    end
}


yuanlvVS = sgs.CreateViewAsSkill{
    name = "yuanlv",
    n = 999,
    response_pattern = "@@yuanlv",
    view_filter = function(self,selected,to_select)
        local tos = sgs.Self:property("yuanlvUse"):toString():split("+")
        return #selected < #tos
    end,
    view_as = function(self,cards)
        if #cards == 0 then return nil end
        local vs_card = yuanlvCard:clone()
        for _, card in ipairs(cards) do 
            vs_card:addSubcard(card)
        end
        return vs_card
    end
}


yuanlv = sgs.CreateTriggerSkill{
    name = "yuanlv",
    view_as_skill = yuanlvVS,
    events = {sgs.TargetSpecified},

    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
        player = room:findPlayerBySkillName(self:objectName())
        local use = data:toCardUse()
        player:setTag("yuanlv",data)    --给AI使用
        if use.to:length() < 2 or not use.card:isNDTrick() then return false end
        local to_table = {}
        for _, to in sgs.qlist(use.to) do 
            table.insert(to_table,to:objectName())
        end
        local nullified_list = use.nullified_list   --获取原来的免疫列表
        room:setPlayerProperty(player,"yuanlvOldNullify",sgs.QVariant(table.concat(nullified_list,"+")))
        room:setPlayerProperty(player,"yuanlvUse",sgs.QVariant(table.concat(to_table,"+"))) --可施加免疫角色列表
        if room:askForUseCard(player,"@@yuanlv","@yuanlv",-1,sgs.Card_MethodDiscard) then 
            local yuanlv_nullified = player:property("yuanlvNullify"):toString():split("+")
            for _, target in ipairs(yuanlv_nullified) do 
                table.insert(nullified_list,target) --把远虑指定的免疫列表加到原来的列表里面
            end
            use.nullified_list = nullified_list
            data:setValue(use)                      --更新值
        end
        
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end
}

function isPrime(card)
    n = card:getNumber()
    return n==2 or n==3 or n==5 or n==7 or n==11 or n==13 
end

tianyou = sgs.CreateTriggerSkill{
    name = "tianyou",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room=player:getRoom()
        local move = data:toMoveOneTime()
        local source = move.from
        if not move.from or source:objectName() ~= player:objectName() then return end
        local reason = move.reason.m_reason
        if move.to_place == sgs.Player_DiscardPile then
            if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
                local count = 0
                for i=0, (move.card_ids:length()-1), 1 do
                    local card_id = move.card_ids:at(i)
                    local card = sgs.Sanguosha:getCard(card_id)
                    if (move.from_places:at(i) == sgs.Player_PlaceHand
                        or move.from_places:at(i) == sgs.Player_PlaceEquip) and isPrime(card) then
                        count = count + 1
                    end
                end
                if count > 0 and player:askForSkillInvoke(self:objectName()) then
                    player:drawCards(count)
                end
            end
        end
        return false
    end
}

wyl:addSkill(shenmou)
wyl:addSkill(yuanlv)
wyl:addSkill(tianyou)
-------------------------------------------------------------------------
--以下为袁镭洋

yly = sgs.General(extension, "yly", "god",3) 

gongshou = sgs.CreateTriggerSkill{
	name = "gongshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		if player then
			room = player:getRoom()
			yly = room:findPlayerBySkillName(self:objectName())
			msg = sgs.LogMessage()
			msg.from=yly
			if player:objectName()==yly:objectName() then
				local result = room:askForChoice(player, self:objectName(), "nan+nv")
				if result == "nan" then
					msg.type = "#tomale"
					player:setGender(sgs.General_Male)
				else
					player:setGender(sgs.General_Female)
					msg.type = "#tofemale"
				end
			else
				if player:isMale() then
					yly:setGender(sgs.General_Female)
					msg.type = "#tofemale"
				elseif player:isFemale() then
					yly:setGender(sgs.General_Male)
					msg.type = "#tomale"
				else
					yly:setGender(sgs.General_Neuter)
					msg.type = "#toneuter"
				end
			end
			room:sendLog(msg)
		end
		return false
	end,
	can_trigger = function(self, target)
		return true
	end
}

jieyi = sgs.CreateViewAsSkill{  --解衣
	name = "jieyi",
	n=1,
	view_filter = function(self, selected, to_select)
		return to_select:getTypeId() == 3 --是装备
	end,
	
	view_as = function(self, cards)
		if #cards == 1 then
			local vs_card=jieyiCard:clone()
			vs_card:addSubcard(cards[1])
			return vs_card
		end
		return false;
	end
}

jieyiCard = sgs.CreateSkillCard{
	name = "jieyiCard", --必须
	target_fixed = true, --必须
	will_throw = true, --必须
	filter = function(self, targets, to_select) --必须
		return true
	end,

	on_use = function(self, room, source, targets) --几乎必须
		room:drawCards(source,1)
		local card=sgs.Sanguosha:getCard(self:getSubcards():first())
	--	local Fangju={63,64,106,110,123,182,184 Armor
		
		if  card:isKindOf("Armor") then
			local theRecover=sgs.RecoverStruct()
			theRecover.recover=1
			theRecover.who=source
			room:recover(source,theRecover)
		end
	end,
}

tiaoqing = sgs.CreateTriggerSkill{--调情
	name = "tiaoqing",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local use = data:toCardUse()
		local card = use.card
		if card:isKindOf("Slash") and use.from:objectName()==player:objectName() then
			for _,p in sgs.qlist(use.to) do
				if p:getGender() ~= use.from:getGender() then
					if player:askForSkillInvoke(self:objectName()) then
						local room = p:getRoom()
						if not p:isKongcheng() then
							if not room:askForDiscard(p,self:objectName(),1,1,true,false,"@tiaoqing:"..use.from:objectName()) then
								use.from:drawCards(1)
							end
						else
							use.from:drawCards(1)
						end
					end
				end
			end
		end
		return false
	end,
}

TiaoqingTargetMod = sgs.CreateTargetModSkill{
	name = "#tiaoqing-target",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		else
			return 0
		end
	end
}

yly:addSkill(gongshou)

yly:addSkill(jieyi)

yly:addSkill(tiaoqing)
yly:addSkill(TiaoqingTargetMod)

-------------------------------------------------------------------------
--以下为罗剑锋

ljf = sgs.General(extension, "ljf", "god",4, true) 

qiuyiCard = sgs.CreateSkillCard{
    name = "qiuyi",
    handling_method = sgs.Card_MethodDiscard,
    target_fixed = false,
    will_throw = true, 
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        card=room:askForCard(targets[1], "jink", "@qiuyi-jink:"..source:objectName(),sgs.QVariant(),sgs.Card_MethodDiscard)
        if not card then
            room:damage(sgs.DamageStruct(self:objectName(),  source,targets[1]))
        end
    end
}

qiuyi = sgs.CreateViewAsSkill{  
    name = "qiuyi",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Slash")
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local vs_card=qiuyiCard:clone()
            vs_card:addSubcard(cards[1])
            return vs_card
        end
        return false
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#qiuyi") and player:getHandcardNum() > 0
    end
}

zimo = sgs.CreateTriggerSkill{
    name = "zimo",
    events = {sgs.EventPhaseEnd}, 
    on_trigger = function(self, event, player, data) 
        local room=player:getRoom()
        local source = room:findPlayerBySkillName(self:objectName())
        if not source or player:getJudgingArea():length()==0 then return false end
        if player:getPhase()==sgs.Player_Start and source:askForSkillInvoke(self:objectName()) then
            local cards = room:getNCards(1)
            room:fillAG(cards, source)
            local card_id = room:askForAG(source, cards, true, "zimo")
            room:clearAG(source)
            if card_id >= 0 then
                local cd = sgs.Sanguosha:getCard(card_id)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), self:objectName(), "")
                room:obtainCard(source, cd, reason, false)
            else
                room:returnToTopDrawPile(cards)
            end
        end
        return false
    end, 
    can_trigger = function(self, target)
        return target and target:isAlive()
    end
}

ljf:addSkill(qiuyi)
ljf:addSkill(zimo)

-------------------------------------------------------------------------
--以下为何思卓

hsz = sgs.General(extension, "hsz", "god",4, true) 

function sendMsg(room,message,from,to,arg)
    local msg = sgs.LogMessage()
    msg.type = message
    if from then msg.from = from end
    if to then msg.to:append(to) end
    if arg then msg.arg = arg end
    room:sendLog(msg)
end

zhengzhuangCard = sgs.CreateSkillCard{
    name = "zhengzhuang",
    target_fixed = false,
    will_throw = true,
    handling_method = sgs.Card_MethodDiscard,
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_use = function(self, room, player, targets)
        target = targets[1]
        --local phase = {sgs.Player_Start,sgs.Player_Judge,sgs.Player_Draw,sgs.Player_Play,sgs.Player_Discard,sgs.Player_Finish}
        choice = room:askForChoice(player, "zhengzhuang", "1+2+3+4+5+6")
        sendMsg(room, "#zhengzhuang", player, target, "zhengzhuang:"..choice)
        choice = tonumber(choice)
        player = target
        player:setPhase(choice)
        room:broadcastProperty(player, "phase")
        local thread = room:getThread()
        if not thread:trigger(sgs.EventPhaseStart, room, player) then
            thread:trigger(sgs.EventPhaseProceeding, room, player)
        end
        thread:trigger(sgs.EventPhaseEnd, room, player)
        room:broadcastProperty(player, "phase")
    end
}

zhengzhuangVS = sgs.CreateViewAsSkill{
    name = "zhengzhuang",
    n = 1,
    view_filter = function(self, selected, to_select)
        return (not to_select:isKindOf("BasicCard")) and (not sgs.Self:isJilei(to_select))
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = zhengzhuangCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@zhengzhuang"
    end
}

zhengzhuang = sgs.CreateTriggerSkill{
    name = "zhengzhuang",  
    events = {sgs.EventPhaseChanging}, 
    view_as_skill = zhengzhuangVS,
    on_trigger = function(self, event, player, data)
        local room=player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive and player:canDiscard(player, "h") then
            local flag
            if player:getEquips():length() > 0 then
                room:askForUseCard(player, "@@zhengzhuang", "@zhengzhuang")
                return false
            end
            
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("TrickCard") or card:isKindOf("EquipCard") then 
                    room:askForUseCard(player, "@@zhengzhuang", "@zhengzhuang")
                    return false
                end
            end
        end
        return false
    end
}

doule = sgs.CreateTriggerSkill{
    name = "doule" ,
    events = {sgs.BeforeCardsMove} ,
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        local cur = room:getCurrent()
        if player:isAlive() and move and move.to_place == sgs.Player_DiscardPile 
        and cur and (cur:getPhase()==sgs.Player_Play or cur:getPhase()==sgs.Player_Discard) then
            local i=0
            local card_ids = sgs.IntList()
            for _, card_id in sgs.qlist(move.card_ids) do
                local card=sgs.Sanguosha:getCard(card_id)
                if card:isKindOf("Indulgence") and player:askForSkillInvoke(self:objectName(),data) then
                    move.from_places:removeAt(i)
                    card_ids:append(card_id)
                else
                    i=i+1
                end
            end
            for _, id in sgs.qlist(card_ids) do
                if move.card_ids:contains(id) then
                    move.card_ids:removeOne(id)
                end
                data:setValue(move)
                room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
                if not player:isAlive() then break end
            end
        end
        return false
    end
}

hsz:addSkill(zhengzhuang)
hsz:addSkill(doule)

-------------------------------------------------------------------------
--以下为剑圣

masteryi = sgs.General(extension, "masteryi", "god",3, true) 

function canLianji(use)
    local card = use.card
    for _, p in sgs.qlist(use.to) do
        if not p:isAlive() or (use.card:isKindOf("Collateral") and not p:getWeapon())
            or ((use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and p:getCardCount(true,true)==0)
            or  (use.card:isKindOf("FireAttack") and p:getCardCount(false)==0) then
            use.to:removeOne(p)
        end
    end
    return not use.to:isEmpty()
end

luaLianji = sgs.CreateTriggerSkill{
    name = "luaLianji",
    events = {sgs.CardResponded,sgs.CardUsed,sgs.CardFinished,sgs.SlashEffected},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event==sgs.CardResponded or event==sgs.CardUsed then
            local card
            if event==sgs.CardResponded then
                card = data:toCardResponse().m_card
            else
                card = data:toCardUse().card
            end
            -- 虽然不是锁定技但没理由不发动，所以就不询问了
            if card and card:isKindOf("BasicCard") and card:getSkillName() ~= "luaLianji" then 
                player:gainMark("@lianjiMark")
            end
        elseif event==sgs.CardFinished and player:getMark("@lianjiMark") >= 3  then 
            local use = data:toCardUse()
            local card = use.card
            if card:getSkillName() ~= "luaLianji" and (card:isKindOf("Slash") or card:isNDTrick()) and not card:isKindOf("Nullification")
                and canLianji(use) and player:askForSkillInvoke("luaLianji") then
                player:loseMark("@lianjiMark", 3)
                local cd = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
                cd:setSkillName(self:objectName())
                use.card = cd
                room:useCard(use)
            end
        end
        return false
    end
}



masteryi:addSkill(luaLianji)
masteryi:addSkill("lianpo")
masteryi:addSkill("shensu")

-------------------------------------------------------------------------
--以下为特朗普

tlp = sgs.General(extension, "tlp$", "god",4, true)

lingruo = sgs.CreateTriggerSkill{
    name = "lingruo",
    events = {sgs.Damage},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        if data:toDamage().to:getHp() < player:getHp() and player:getRoom():askForSkillInvoke(player, self:objectName(), data)  then
                player:drawCards(1)
        end
        return false
    end
}

baquanCard = sgs.CreateSkillCard{
    name = "baquanCard",
    target_fixed = true,
    mute = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if not source:hasLordSkill("shuangbiao") or p:getKingdom() ~= source:getKingdom() then
                for _,id in sgs.qlist(self:getSubcards()) do
                    local cd = sgs.Sanguosha:getCard(id)
                    local name = cd:getClassName()
                    room:setPlayerCardLimitation(p, "use,response", name.."|.|.|hand", true)
                end
            end
        end
    end
}

baquan = sgs.CreateViewAsSkill{
    name = "baquan",
    n = 999,
    view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local bqc = baquanCard:clone()
        for _,c in ipairs(cards) do
            bqc:addSubcard(c)
        end
        bqc:setSkillName(self:objectName())
        return bqc
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "he")
    end,
}

shuangbiaoCard = sgs.CreateSkillCard{
    name = "shuangbiaoCard",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local kingdom = room:askForChoice(source, "shuangbiao", "wei+shu+wu+qun")
        room:setPlayerProperty(source, "kingdom", sgs.QVariant(kingdom))
    end
}

shuangbiao = sgs.CreateZeroCardViewAsSkill{
    name = "shuangbiao$",
    view_as = function() 
        return shuangbiaoCard:clone()
    end, 
    enabled_at_play = function(self, player)
        return player:hasLordSkill(self:objectName()) and not player:hasUsed("#shuangbiaoCard")
    end,
}

tlp:addSkill(lingruo)
tlp:addSkill(baquan)
tlp:addSkill(shuangbiao)

--------------------------------------------------------------------
--以下为字符串表
sgs.LoadTranslationTable{
	["designer:yly"]="风靡义磊",
	["illustrator:yly"]="风靡义磊",
	["fmyl"]="风靡包",

	["yly"]="袁镭洋",
	["gongshou"] = "攻受",
	[":gongshou"] = "锁定技。其他角色回合开始时，你的性别变成与之相反。你的回合开始时，需选择性别。",
	["jieyi"]="解衣",
	[":jieyi"]="出牌阶段，你可以弃掉一张装备牌，然后摸一张牌。你以此法弃掉防具时回复一点体力。",
	["jieyiCard"]="解衣",
	[":gongshou:"] = "请选择性别:",
	["gongshou:nan"] = "男性",
	["gongshou:nv"] = "女性",
	["tiaoqing"]="调情",
    [":tiaoqing"]="你的杀指定异性角色为目标时，可以令其选择一项：弃一张手牌或让你摸一张牌。锁定技。你的杀攻击范围始终加一。",
    ["@tiaoqing"]="%src 发动了技能【调情】，你须弃置一张手牌，或令 %src 摸一张牌",
    ["#tomale"]=  "%from 的性别变成男性。",
    ["#tofemale"]="%from 的性别变成女性。",
    ["#toneuter"]="%from 的性别变成中性。",
    ["#hello"] = "测试用：%from",

    ["wyl"]="王义磊",
    ["#wyl"]="风靡的钢琴家",
	["shenmou"]="深谋",
	[":shenmou"]="你的非延时锦囊不能被“无懈可击”响应",
	["yuanlv"]="远虑",
	["yuanlvCard"]="远虑",
	[":yuanlv"]="当有角色的锦囊指定了至少两个目标时，你可以弃一些牌并指定等量目标角色，使此锦囊对这些角色无效。",
	["@yuanlv"]="使你的锦囊对若干角色无效。",
	["~yuanlv"]="弃掉X张牌并指定X个目标，若点击取消则不发动。",
	["tianyou"]="天佑",
	[":tianyou"]="你的每张点数为素数的牌因弃置而置入弃牌堆时，你可以摸一张牌。",

    ["ljf"]="罗剑锋",
    ["qiuyi"] = "求异",
    [":qiuyi"] = "阶段技。你可以弃一张【杀】并指定一名其他角色，该角色需弃置一张【闪】或受到你的一点伤害。",
    ["zimo"] = "自摸",
    [":zimo"] = "一名角色的准备阶段时，若其判定区有牌，你可以观看牌堆顶的一张牌，然后你可以获得之。",
    ["@qiuyi-jink"] = "弃置一张【闪】，否则受到 %src 对你造成的一点伤害。",

    ["hsz"]="何思卓",
    ["zhengzhuang"]="整装",
    [":zhengzhuang"]="回合结束时，你可以弃一张非基本牌并指定一名角色，该角色开始一个额外的、由你指定的阶段。",
    ["@zhengzhuang"]="你可以弃一张非基本牌并指定一名角色开始一个阶段。",
    ["~zhengzhuang"]="选择基本牌，选择角色，然后选择阶段。",
    ["#zhengzhuang"]="%from 令 %to 开始了一个额外的 %arg。",
    ["zhengzhuang:1"]="准备阶段",
    ["zhengzhuang:2"]="判定阶段",
    ["zhengzhuang:3"]="摸牌阶段",
    ["zhengzhuang:4"]="出牌阶段",
    ["zhengzhuang:5"]="弃牌阶段",
    ["zhengzhuang:6"]="结束阶段",
    ["doule"] = "逗乐",
    [":doule"]="当有【乐不思蜀】即将进入弃牌堆时，若此时为一名角色的出牌阶段或弃牌阶段，你可以获得之。",

    ["masteryi"]="易大师",
    ["#masteryi"]="无极剑圣",
    ["~masteryi"]="啊……",
    ["luaLianji"]="连击",
    [":luaLianji"]="你每次使用或打出一张基本牌时可以获得一个“连击”标记。你使用【杀】或非延时类锦囊牌结算后，你可以弃掉3个标记使其进行一次额外结算。",
    ["$luaLianji1"]="敌人虽众，一击皆斩！",
    ["$luaLianji2"]="一斩千击！",
    ["@lianjiMark"]="连击",

    ["tlp"]="特离谱",
    ["#tlp"]="懂王",
    ["baquan"]="霸权",
    [":baquan"]="出牌阶段，你可以弃置一些牌，使其他角色不能使用或打出与你所弃置的任何牌同名的手牌直到回合结束。",
    ["lingruo"]="凌弱",
    [":lingruo"]="你对一名角色造成伤害后，若其体力值小于你，你可以摸一张牌。",
    ["shuangbiao"]="双标",
    [":shuangbiao"]="主公技。与你相同势力的武将不受“霸权”效果影响。阶段技。你可以重新选择势力。"
}

