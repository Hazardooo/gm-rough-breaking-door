-- Создание ConVar для включения/выключения аддона
CreateConVar("doorbreach_enabled", 1)

-- Стартовое количество здоровья для дверей
CreateConVar("doorbreach_health", 100)

-- Множитель урона для выстрелов по ручке
CreateConVar("doorbreach_handlemultiplier", 2)

-- Время до восстановления здоровья двери (в секундах)
CreateConVar("doorbreach_respawntime", 30)

-- Максимальное расстояние от ручки, чтобы считаться выстрелом по ручке
local maxHandleDistance = 5

-- Класс двери
local entityType = "prop_door_rotating"

-- Обработка урона двери
hook.Add("EntityTakeDamage", "DoorBreachDamageDetection", function(ent, dmg)
    if not IsValid(ent) then return end
    if not GetConVar("doorbreach_enabled"):GetBool() then return end

    -- Проверяем, является ли объект дверью
    if ent:GetClass() == entityType then
        -- Инициализация здоровья двери, если оно не установлено
        if not ent.DoorBreachHealth then
            ent.DoorBreachHealth = GetConVar("doorbreach_health"):GetFloat()
        end

        -- Если дверь ещё не разрушена
        if not ent.DoorBreachExploded then
            -- Получаем источник урона (кто или что наносит урон)
            local attacker = dmg:GetAttacker()

            -- Проверяем, если урон наносится игроком и оружие в руках игрока
            if attacker:IsPlayer() and attacker:GetActiveWeapon():IsValid() then
                local weapon = attacker:GetActiveWeapon()

                -- Проверяем тип оружия (например, запрещаем ломать руками)
                if weapon:GetClass() == "weapon_fists" then
                    return -- Отменяем урон, если это удар кулаками (руками)
                end
            end

            -- Если урон не отменён, продолжаем обработку
            local dam = dmg:GetDamage()
            local damPos = dmg:GetDamagePosition()

            -- Проверка урона в районе ручки двери
            local bone = ent:LookupBone("handle")
            if bone then
                local handlePos = ent:GetBonePosition(bone)
                if handlePos:Distance(damPos) <= maxHandleDistance then
                    dam = dam * GetConVar("doorbreach_handlemultiplier"):GetFloat()
                end
            end

            -- Применяем урон к двери
            ent.DoorBreachHealth = ent.DoorBreachHealth - dam

            -- Если здоровье двери достигло нуля, "взрываем" дверь
            if ent.DoorBreachHealth <= 0 then
                ent.DoorBreachExploded = true
                ent:Fire("unlock", "", 0)
                ent:Fire("open", "", 0)

                -- Устанавливаем таймер для восстановления здоровья двери
                timer.Simple(GetConVar("doorbreach_respawntime"):GetFloat(), function()
                    if not IsValid(ent) then return end
                    ent.DoorBreachExploded = nil
                    ent.DoorBreachHealth = GetConVar("doorbreach_health"):GetFloat()
                end)
            end
        end
    end
end)

-- Обработка взаимодействия с дверью игроком
hook.Add("PlayerUse", "DoorBreachSuppressUse", function(ply, ent)
    if not IsValid(ent) then return end

    -- Если дверь разрушена и здоровье ещё не восстановлено
    if ent.DoorBreachExploded and ent:GetClass() == entityType then
        -- Предотвращаем взаимодействие с дверью
        return false
    end
end)
