-- D/D/D Nightmare King Henri
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- (1) Ignition in hand: discard; add 1 Level 6 or lower D/D from Deck or GY
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(Cost.SelfDiscard)
    e1:SetTarget(s.e1tg)
    e1:SetOperation(s.e1op)
    c:RegisterEffect(e1)
    -- (2) Main Phase: shuffle random cards per 1000 damage taken
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.e2tg)
    e2:SetOperation(s.e2op)
    c:RegisterEffect(e2)
    -- (3b) After damage is prevented, boost ATK
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.damval)
	c:RegisterEffect(e3)
	-- Same for effect damage that recovers LP as cost (optional safeguard)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	c:RegisterEffect(e4)
    -- (Global) Track damage taken this turn
    aux.GlobalCheck(s,function()
		s[0]=0
		s[1]=0
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_DAMAGE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_ADJUST)
		ge2:SetCountLimit(1)
		ge2:SetOperation(s.clear)
		Duel.RegisterEffect(ge2,0)
	end)
end
s.listed_series={0xaf,0x10af,0xae}
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	s[ep]=s[ep]+ev
end
function s.clear(e,tp,eg,ep,ev,re,r,rp)
	s[0]=0
	s[1]=0
end

function s.e1filter(c)
    return c:IsSetCard(0xaf) and c:IsType(TYPE_MONSTER)
       and c:IsLevelBelow(6) and c:IsAbleToHand()
end
function s.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.IsExistingMatchingCard(s.e1filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.e1op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.e1filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- Effect 2: shuffle per 1000 damage taken
function s.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
    local player=tp or 1-tp
    local ct=s[player]
    if chk==0 then return ct>0 end
    local dct=math.floor(ct/1000)
    Duel.SetTargetParam(dct)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,dct,1-tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.e2op(e,tp,eg,ep,ev,re,r,rp)
    local ct = Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
    local pool=Group.CreateGroup()
    pool:Merge(Duel.GetFieldGroup(1-tp,LOCATION_HAND,0))
    pool:Merge(Duel.GetFieldGroup(1-tp,LOCATION_GRAVE,0))
    if #pool>0 then
        local sg=pool:Select(tp,1,ct,nil)
        Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end

-- Condition for damage replacement
function s.damval(e,re,val,r,rp,rc)
	if (r&REASON_EFFECT)~=0 and re and val>0 then
		-- Apply ATK boost to all face-up D/D/D monsters you control
		local g=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsSetCard(0x10af) end,
			e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)
		local boost=math.floor(val/2)
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(boost)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
		return 0 -- no damage happens
	end
	return val
end