-- Whether or not it's enabled
CreateConVar("doorbreach_enabled", 1)

-- Starting health for doors
CreateConVar("doorbreach_health", 100)

-- Damage multiplier for handle shots
CreateConVar("doorbreach_handlemultiplier", 2)

-- Time, in seconds, to wait before resetting the door's health
CreateConVar("doorbreach_respawntime", 30)

-- Max distance from the handle to still count as a handle shot
local maxHandleDistance = 5

-- Classname for doors
local entityType = "prop_door_rotating"

-- Handle door damage
hook.Add("EntityTakeDamage", "DoorBreachDamageDetection", function(ent, dmg)
    if not IsValid(ent) then return end
    if not GetConVar("doorbreach_enabled"):GetBool() then return end

    -- If it's a door that has been damaged
    if ent:GetClass() == entityType then
        -- Initialize door health if not done already
        if not ent.DoorBreachHealth then
            ent.DoorBreachHealth = GetConVar("doorbreach_health"):GetFloat()
        end

        -- If the door hasn't been breached yet
        if not ent.DoorBreachExploded then
            -- Store the base damage
            local dam = dmg:GetDamage()
            local damPos = dmg:GetDamagePosition()

            -- If damage is near the handle, apply multiplier
            local bone = ent:LookupBone("handle")
            if bone then
                local handlePos = ent:GetBonePosition(bone)
                if handlePos:Distance(damPos) <= maxHandleDistance then
                    dam = dam * GetConVar("doorbreach_handlemultiplier"):GetFloat()
                end
            end

            -- Apply damage to the door
            ent.DoorBreachHealth = ent.DoorBreachHealth - dam

            -- If the door's health reaches zero
            if ent.DoorBreachHealth <= 0 then
                ent.DoorBreachExploded = true

                -- Unlock and open the door
                ent:Fire("unlock", "", 0)
                ent:Fire("open", "", 0)

                -- Set a timer to reset only the health of the door
                timer.Simple(GetConVar("doorbreach_respawntime"):GetFloat(), function()
                    if not IsValid(ent) then return end

                    -- Reset the door's health and state
                    ent.DoorBreachExploded = nil
                    ent.DoorBreachHealth = GetConVar("doorbreach_health"):GetFloat()
                end)
            end
        end
    end
end)

-- Handle player use of breached doors
hook.Add("PlayerUse", "DoorBreachSuppressUse", function(ply, ent)
    if not IsValid(ent) then return end

    -- If the door is breached and health has not yet been restored, prevent closing
    if ent.DoorBreachExploded and ent:GetClass() == entityType then
        return false -- Disallow any interaction (like closing)
    end
end)
