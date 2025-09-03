--D/D Ghoul
local s,id=GetID()
function s.initial_effect(c)
    --1) Attach from GY during Standby if you took effect damage
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.matcon)
    e1:SetTarget(s.mattg)
    e1:SetOperation(s.matop)
    c:RegisterEffect(e1)
    --2) If detached for cost: bounce Spells/Traps
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    -- helper: register if effect damage was taken
    local ge1=Effect.GlobalEffect()
    ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    ge1:SetCode(EVENT_DAMAGE)
    ge1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
        if (r&REASON_EFFECT)~=0 then
            Duel.RegisterFlagEffect(ep,id+100,RESET_PHASE+PHASE_STANDBY,0,1)
        end
    end)
    Duel.RegisterEffect(ge1,0)
end
s.listed_series={0xaf,0x10af}

--=== (1) Attach condition ===--
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id+100)==1 -- mark when effect damage is taken
end
function s.xyzfilter(c)
    return c:IsSetCard(0x10af) and c:IsType(TYPE_XYZ) and c:GetOverlayCount()==0
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        Duel.Overlay(tc,c)
    end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_COST) and c:IsPreviousLocation(LOCATION_OVERLAY)
end
function s.thfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ct=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x10af),tp,LOCATION_MZONE,0,nil):GetClassCount(Card.GetCode)
    if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,ct,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local ct=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x10af),tp,LOCATION_MZONE,0,nil):GetClassCount(Card.GetCode)
    if ct<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end
