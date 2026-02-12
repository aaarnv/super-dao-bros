-- Super DAO Bros — Beeper Notification Watcher
-- Watches for Beeper Desktop notifications via macOS Notification Center
-- and triggers a Claude agent to handle incoming messages

require("hs.ipc")
local log = hs.logger.new("beeper-watcher", "info")

-- Shell escape helper
local function shescape(s)
    return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

-- Watch for all notifications using hs.distributednotifications
-- macOS posts "com.apple.UserNotificationCenter" events when notifications arrive
local notifWatcher = hs.distributednotifications.new(function(name, object, userInfo)
    -- Log all notification events for debugging
    if name and (string.find(name, "notification") or string.find(name, "Notification")) then
        log.i("Distributed notification: " .. tostring(name) .. " object: " .. tostring(object))
    end
end)
notifWatcher:start()

-- Primary approach: Watch for Beeper window/notification changes
-- When Beeper gets a message, its dock badge updates or a banner appears
local beeperWatcher = nil
local lastTriggerTime = 0
local COOLDOWN_SECONDS = 10  -- Don't re-trigger within 10s of same event

-- Watch for notification banners by monitoring the NotificationCenter process
local function watchNotificationBanners()
    local ncApp = hs.application.find("NotificationCenter")
    if not ncApp then
        log.w("NotificationCenter process not found")
        return
    end

    -- Use AXObserver to watch for new windows (notification banners)
    local axApp = hs.axuielement.applicationElement(ncApp)
    if not axApp then
        log.w("Cannot create AX element for NotificationCenter")
        return
    end

    local observer = hs.axuielement.observer.new(ncApp:pid())
    observer:addWatcher(axApp, "AXWindowCreated")
    observer:addWatcher(axApp, "AXFocusedWindowChanged")
    observer:callback(function(obs, elem, notification, info)
        -- A new notification banner appeared
        -- Try to read its content to check if it's from Beeper
        local now = os.time()
        if now - lastTriggerTime < COOLDOWN_SECONDS then
            return
        end

        -- Try to extract the notification text
        local title = ""
        local body = ""

        pcall(function()
            -- Notification banners have child elements with the text
            local children = elem:attributeValue("AXChildren")
            if children then
                for _, child in ipairs(children) do
                    local role = child:attributeValue("AXRole")
                    local value = child:attributeValue("AXValue") or child:attributeValue("AXTitle") or ""
                    if role == "AXStaticText" then
                        if title == "" then
                            title = value
                        else
                            body = value
                        end
                    end
                    -- Also check nested children
                    local subchildren = child:attributeValue("AXChildren")
                    if subchildren then
                        for _, subchild in ipairs(subchildren) do
                            local sv = subchild:attributeValue("AXValue") or subchild:attributeValue("AXTitle") or ""
                            if sv ~= "" then
                                if title == "" then
                                    title = sv
                                elseif body == "" then
                                    body = sv
                                end
                            end
                        end
                    end
                end
            end
        end)

        log.i("Notification banner detected — title: " .. title .. " body: " .. body)

        -- Check if this is a Beeper notification
        -- Beeper notifications typically have the contact name as title and message as body
        -- We also check the source app of the notification
        local isBeeper = false
        pcall(function()
            local appTitle = elem:attributeValue("AXTitle") or ""
            local desc = elem:attributeValue("AXDescription") or ""
            if string.find(appTitle, "Beeper") or string.find(desc, "Beeper") then
                isBeeper = true
            end
        end)

        -- Fallback: check if Beeper was the frontmost app that changed
        if not isBeeper then
            local beeperApp = hs.application.find("Beeper")
            if beeperApp then
                -- Check Beeper's badge count changed (indicates new message)
                pcall(function()
                    local dockItem = hs.axuielement.applicationElement(hs.application.find("Dock"))
                    -- This is approximate — we're checking if Beeper has activity
                end)
            end
        end

        if isBeeper or (title ~= "" and body ~= "") then
            lastTriggerTime = now
            log.i("Beeper notification detected! Triggering handler...")
            -- Call the nchook_script with Beeper context
            local cmd = string.format(
                '%s/.config/nchook/nchook_script "Beeper Desktop" %s %s %d &',
                os.getenv("HOME"),
                shescape(title),
                shescape(body),
                now
            )
            os.execute(cmd)
        end
    end)
    observer:start()
    log.i("AXObserver started for NotificationCenter (pid: " .. ncApp:pid() .. ")")
    return observer
end

-- Watch Beeper's dock badge — triggers on badge changes AND re-checks stale unreads
local function watchBeeperBadge()
    local lastBadge = ""
    local lastBadgeChangeTime = 0  -- When badge last changed to a non-zero value

    local function triggerHandler(badge)
        local now = os.time()
        if now - lastTriggerTime >= COOLDOWN_SECONDS then
            lastTriggerTime = now
            local cmd = string.format(
                '%s/.config/nchook/nchook_script "Beeper Desktop" "New Message" "Badge: %s" %d &',
                os.getenv("HOME"),
                badge,
                now
            )
            os.execute(cmd)
        end
    end

    local timer = hs.timer.doEvery(5, function()
        local beeperApp = hs.application.find("Beeper")
        if not beeperApp then return end

        pcall(function()
            local dockApp = hs.application.find("Dock")
            if not dockApp then return end

            local axDock = hs.axuielement.applicationElement(dockApp)
            local dockChildren = axDock:attributeValue("AXChildren")
            if not dockChildren then return end

            for _, child in ipairs(dockChildren) do
                local dockItems = child:attributeValue("AXChildren")
                if dockItems then
                    for _, item in ipairs(dockItems) do
                        local itemTitle = item:attributeValue("AXTitle") or ""
                        if string.find(itemTitle, "Beeper") then
                            local badge = item:attributeValue("AXStatusLabel") or ""
                            local now = os.time()

                            if badge ~= "" and badge ~= lastBadge then
                                -- Badge count changed — immediate trigger
                                log.i("Beeper badge changed: " .. lastBadge .. " -> " .. badge)
                                lastBadge = badge
                                lastBadgeChangeTime = now
                                triggerHandler(badge)
                            elseif badge ~= "" and badge == lastBadge then
                                -- Badge unchanged but still has unreads
                                -- Re-trigger every 30s in case a new message arrived
                                -- without changing the badge count (e.g., was already unread)
                                if now - lastTriggerTime >= 30 then
                                    log.i("Beeper badge still " .. badge .. " — re-checking for new messages")
                                    triggerHandler(badge)
                                end
                            elseif badge == "" and lastBadge ~= "" then
                                lastBadge = ""
                                lastBadgeChangeTime = 0
                            end
                        end
                    end
                end
            end
        end)
    end)

    log.i("Beeper badge watcher started (5s interval, 30s stale re-check)")
    return timer
end

-- Start both watchers
local axObserver = watchNotificationBanners()
local badgeTimer = watchBeeperBadge()

-- Reload config shortcut
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
    hs.reload()
end)

log.i("Super DAO Bros — Beeper watcher loaded")
hs.alert.show("Super DAO Bros watcher active")
