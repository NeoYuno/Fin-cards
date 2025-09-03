--Dark Contract with the Thousand Hands
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--(1) Draw 2, discard 1 when Summoning D/D/D (once per type each turn)
	local summon_types={SUMMON_TYPE_RITUAL,SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,
						SUMMON_TYPE_XYZ,SUMMON_TYPE_PENDULUM,SUMMON_TYPE_LINK}
	for i,stype in ipairs(summon_types) do
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
		e1:SetCode(EVENT_SPSUMMON_SUCCESS)
		e1:SetRange(LOCATION_SZONE)
		e1:SetCountLimit(1,{id,i}) -- once per type
		e1:SetCondition(s.drcon(stype))
		e1:SetTarget(s.drtg)
		e1:SetOperation(s.drop)
		c:RegisterEffect(e1)
	end
	--(2) Burn 1000 during Standby Phase
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetCountLimit(1)
	e2:SetCondition(function(e,tp) return Duel.GetTurnPlayer()==tp end)
	e2:SetOperation(function(e,tp) Duel.Damage(tp,1000,REASON_EFFECT) end)
	c:RegisterEffect(e2)
end
s.listed_series={0xaf,0x10af}

--Condition: D/D/D summoned with specific type
function s.drcon(stype)
	return function(e,tp,eg,ep,ev,re,r,rp)
		return eg:IsExists(function(c) return c:IsSummonType(stype) and c:IsSetCard(0x10af) and c:IsSummonPlayer(tp) end,1,nil)
	end
end

--Target for draw
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

--Operation: Draw 2, then discard 1
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if Duel.Draw(p,d,REASON_EFFECT)==2 then
		Duel.ShuffleHand(p)
		Duel.BreakEffect()
		Duel.DiscardHand(p,nil,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end
