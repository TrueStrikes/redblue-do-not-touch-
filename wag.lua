-- LocalScript

local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local botToken = "YOUR_BOT_TOKEN_HERE"
local channelId = "YOUR_CHANNEL_ID_HERE"

local processedMessageIds = {}
local openLinks = true
local lastClipboard = ""

local function retrieveLatestMessage()
    local headers = {authorization = botToken}
    local params = {limit = 1}
    local url = string.format("https://discord.com/api/v8/channels/%s/messages", channelId)

    local success, response = pcall(function()
        return HttpService:requestAsync({
            Url = url,
            Method = Enum.HttpRequestType.GET,
            Headers = headers,
            Parameters = params
        })
    end)

    if success then
        local jsonResponse = HttpService:JSONDecode(response.Body)
        return jsonResponse[1]
    else
        print("Error retrieving message:", response)
        return nil
    end
end

local function extractGameId(url)
    local gameIdStart = url:find("https://www.roblox.com/games/") + #("https://www.roblox.com/games/")
    local gameId = url:sub(gameIdStart, gameIdStart + 10):gsub("%D", "")
    return gameId
end

local function updateDisplay(author, content)
    -- Check if author and content are not nil before formatting the string
    author = author or "Unknown"
    content = content or "No content"

    print(string.format("Author: %s\nContent: %s", author, content))
end

local function openRobloxUrl(gameId)
    local url = string.format("roblox://placeID=%s", gameId)
    print("Opening URL:", url)
    GuiService:OpenBrowserWindow(url)
end

while true do
    local latestMessage = retrieveLatestMessage()
    if latestMessage and not processedMessageIds[latestMessage.id] then
        processedMessageIds[latestMessage.id] = true

        local author = string.format("Author: %s#%s", latestMessage.author.username, latestMessage.author.discriminator)
        local content = "Content: " .. tostring(latestMessage.content or "")

        updateDisplay(author, content)

        if openLinks then
            local gameFound = false
            for _, embed in pairs(latestMessage.embeds or {}) do
                for key, value in pairs(embed) do
                    if typeof(value) == "string" then
                        print(string.format("  %s: %s", key, value))
                    elseif key == "fields" then
                        for _, field in pairs(value) do
                            local fieldName = field.name or ""
                            local fieldValue = field.value or ""
                            print(string.format("  Field: %s: %s", fieldName, fieldValue))
                        end
                    end
                end

                local gameId = extractGameId(embed.fields[1].value)
                if gameId then
                    print("  Game ID:", gameId)
                    openRobloxUrl(gameId)
                    gameFound = true
                    break
                end
            end

            if not gameFound then
                local defaultUrl = "roblox://placeID=975820487"
                print("No game mentioned, opening default URL:", defaultUrl)
                openRobloxUrl("975820487")
            end
        end
    end

    local clipboardContent = GuiService:GetClipboard()
    if clipboardContent:lower() ~= lastClipboard then
        if string.find(clipboardContent, "stop") then
            openLinks = false
            print("Script: Roblox links will not be opened")
        elseif string.find(clipboardContent, "start") then
            openLinks = true
            print("Script: Roblox links will be opened")
        end
        lastClipboard = clipboardContent:lower()
    end

    wait(0.5)
end
