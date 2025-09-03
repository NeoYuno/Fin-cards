-- D/D/D Boulder King Joeseph
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --(1) Discard this card; set 1 "Dark Contract" from Deck, but take 1000 damage when you activate it
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.e1cost)
    e1:SetTarget(s.e1tg)
    e1:SetOperation(s.e1op)
    c:RegisterEffect(e1)
    --(2) Quick Effect: return 2 cards to hand, including 1 "D/D" or "Dark Contract" you control
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.e2tg)
    e2:SetOperation(s.e2op)
    c:RegisterEffect(e2)
    --(3) Destroy‐replace: if another "D/D/D" you control would be destroyed, destroy this instead
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.reptg)
    e3:SetValue(s.repval)
    e3:SetOperation(s.repop)
    c:RegisterEffect(e3)
    --(4) If this card on the field is destroyed: send 1 "Dark Contract" from Deck to GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOGRAVE)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCondition(s.tgcon)
    e4:SetCountLimit(1,id+2)
    e4:SetTarget(s.tgtg)
    e4:SetOperation(s.tgop)
    c:RegisterEffect(e4)
end
s.listed_series={0xaf,0x10af,0xae}
-- Effect 1: discard this card; set 1 "Dark Contract" from Deck
function s.e1cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.e1filter(c)
    return c:IsSetCard(0xae) and c:IsSSetable()
end
function s.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.e1filter,tp,LOCATION_DECK,0,1,nil) end
end
function s.e1op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.e1filter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SSet(tp,tc)
        -- register damage trigger when that card is activated
        local dmgE=Effect.CreateEffect(e:GetHandler())
        dmgE:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        dmgE:SetCode(EVENT_CHAINING)
        dmgE:SetCondition(function(_,tp,eg,ep,ev,re,r,rp)
            return ep==tp and re:GetHandler()==tc
                and re:IsHasType(EFFECT_TYPE_ACTIVATE)
        end)
        dmgE:SetOperation(function(_,tp) Duel.Damage(tp,1000,REASON_EFFECT) end)
        dmgE:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(dmgE,tp)
    end
end

-- Effect 2: bounce 2 cards, one must be your "D/D" or "Dark Contract"
function s.e2filter(c)
    return (c:IsSetCard(0xaf) or c:IsSetCard(0xae)) and c:IsAbleToHand()
end
function s.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.e2filter,tp,LOCATION_MZONE,0,1,nil)
           and Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,PLAYER_ALL,LOCATION_ONFIELD)
end
function s.e2op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g1=Duel.SelectMatchingCard(tp,s.e2filter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g2=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,g1:GetFirst())
    g1:Merge(g2)
    Duel.SendtoHand(g1,nil,REASON_EFFECT)
end

-- Effect 3: destroy replace for other "D/D/D" monsters
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0x10af) and c:IsControler(tp)
       and (c:IsReason(REASON_BATTLE) or c:IsReason(REASON_EFFECT))
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(s.repfilter,1,e:GetHandler(),tp) and not e:GetHandler():IsStatus(STATUS_DESTROY_CONFIRMED) end
    return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end

-- Effect 4: when destroyed on field, send 1 "Dark Contract" from Deck to GY
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_DECK,0,1,nil,0xae) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_DECK,0,1,1,nil,0xae)
    if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
end
