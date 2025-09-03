--D/D Shadow Flame
local s,id=GetID()
function s.initial_effect(c)
    --Quick Effect: Discard to boost ATK
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(Cost.SelfDiscard)
    e1:SetTarget(s.atktg)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    --Ritual Summon
    local ritual_params={handler=c,lvtype=RITPROC_GREATER,filter=aux.FilterBoolFunction(Card.IsSetCard,0x10af),location=LOCATION_DECK,forcedselection=function(e,tp,g,sc) return g:IsContains(e:GetHandler()) end,matfilter=aux.FilterBoolFunction(Card.IsLocation,LOCATION_GRAVE),extrafil=s.rextra,extratg=s.extratg}
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(Ritual.Target(ritual_params))
	e2:SetOperation(Ritual.Operation(ritual_params))
	c:RegisterEffect(e2)
end
s.listed_series={0xaf,0x10af}
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.ddfilter,tp,LOCATION_MZONE,0,1,nil) end
end
function s.ddfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xaf)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.SelectMatchingCard(tp,s.ddfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(300)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    tc:RegisterEffect(e1)
end

function s.filter(c)
    return c:HasLevel() and c:IsSetCard(0xaf) and c:IsAbleToRemove()
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
end
function s.rextra(e,tp,eg,ep,ev,re,r,rp,chk)
	if not Duel.IsPlayerAffectedByEffect(tp,CARD_SPIRIT_ELIMINATION) then
		return Duel.GetMatchingGroup(s.filter,tp,LOCATION_GRAVE,0,nil)
	end
end