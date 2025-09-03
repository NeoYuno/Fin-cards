--D/D Dark Flame
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    --Ritual Summon
    local ritual_params={handler=c,lvtype=RITPROC_GREATER,location=LOCATION_HAND,forcedselection=function(e,tp,g,sc) return g:IsContains(e:GetHandler()) end,matfilter=aux.FilterBoolFunction(s.matfilter),extrafil=s.rextra,extratg=s.extratg,extraop=s.extraop}
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(Ritual.Target(ritual_params))
	e2:SetOperation(Ritual.Operation(ritual_params))
	c:RegisterEffect(e2)
end
s.listed_series={0xaf,0x10af}
function s.spfilter(c)
    return c:IsSetCard(0xaf) and c:IsLevelAbove(5) and c:IsAbleToGraveAsCost()
end
function s.ddfilter(c)
    return c:IsFaceup() and c:IsSetCard(0xaf)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.ddfilter,tp,LOCATION_MZONE,0,nil)
    return #g>=2 and g:GetClassCount(Card.GetCode)>=2
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local tg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil)
    Duel.SendtoGrave(tg,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

function s.matfilter(c,e)
    return ((c:IsCode(id)) and c:IsLocation(LOCATION_MZONE)) or (c:IsRace(RACE_FIEND) and c:IsLocation(LOCATION_REMOVED)) and c:IsAbleToDeck()
end
function s.filter(c)
    return c:HasLevel() and c:IsSetCard(0xaf) and c:IsAbleToDeck()
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_REMOVED)
end
function s.rextra(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.filter,tp,LOCATION_REMOVED,0,nil)
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_REMOVED,0,nil)
	g:AddCard(e:GetHandler())
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end