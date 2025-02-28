console.clear()

AVATARS = {}

local function getFilesInFolder(folder)
    local command
    if package.config:sub(1,1) == "\\" then
        command = 'dir /b "' .. folder .. '"'  -- Windows
    else
        command = 'ls "' .. folder .. '"'      -- Unix/Linux/Mac
    end

    local handle = io.popen(command)
    if not handle then return end

    for file in handle:lines() do
        local name = file:match("(.+)%..+$") or file -- Remove extension
        table.insert(AVATARS, name)  -- Add to table
    end

    handle:close()
end

getFilesInFolder("images/avatar") -- Call function on the "images/avatar" folder

-- Print to verify contents of ENTRIES
--for _, v in ipairs(AVATARS) do
--    print('"' .. v .. '"')
--end
client.SetGameExtraPadding(0,0,0,51)
local socket = require("socket.core")

local twitch_conn = socket.tcp()
twitch_conn:connect("irc.chat.twitch.tv", 6667)

twitch_conn:send("PASS " .. twitch_password .. "\r\n")
twitch_conn:send("NICK " .. twitch_username .. "\r\n")
twitch_conn:send("USER " .. twitch_username .. " 8 * :" .. twitch_username .. "\r\n")
twitch_conn:send("JOIN #" .. channel_name .. "\r\n")

local function sendChatMessage(message)
  twitch_conn:send("PRIVMSG #" .. channel_name .. " :" .. message .. "\r\n")
end

local function handlePing()
  twitch_conn:send("PONG :tmi.twitch.tv\r\n")
end

CHAT_MESSAGES = {}

local MAX_MESSAGES = 6
local CHAT_WIDTH = 200
local CHATBOX_MIN_HEIGHT = 32
local FONT_WIDTH = 5
local FONT_HEIGHT = 8
local SCREEN_HEIGHT = 221
local CHAT_MARGIN = 10  -- Small margin from the bottom
local MESSAGE_SPACING = 3 -- Spacing between messages
local NAME_HEIGHT = FONT_HEIGHT -- Ensure nickname has its own space
local CHAT_X_OFFSET = 32 -- Move chat 32 pixels to the right
local IMAGE_SIZE = 32 -- Profile image size
local USERDATA_FOLDER = "userdata/"

local function isValidEntry(entry, list)
  for _, validItem in ipairs(list) do
    if entry == validItem then
      return true
    end
  end
  return false
end

local function createUserFiles(username)
  local avatarFile = USERDATA_FOLDER .. username .. "-avatar.txt"
  local bgcolorFile = USERDATA_FOLDER .. username .. "-bgcolor.txt"
  local namecolorFile = USERDATA_FOLDER .. username .. "-namecolor.txt"
  
  local function ensureFileExists(filePath, defaultValue)
    local file = io.open(filePath, "r")
    if not file then
      file = io.open(filePath, "w")
      if file then
        file:write(defaultValue)
        file:close()
      end
    else
      file:close()
    end
  end

    ensureFileExists(avatarFile, AVATARS[RNG])

  ensureFileExists(bgcolorFile, "#000000")
  ensureFileExists(namecolorFile, "#FFFFFF")
end

local function getUserImage(username)
  local filePath = USERDATA_FOLDER .. username .. "-avatar.txt"
  local file = io.open(filePath, "r")
  if file then
    local imageName = file:read("*l")
    file:close()
    return "images/avatar/" .. imageName .. ".png"
  end
    return "images/avatar/" .. AVATARS[RNG] .. ".png"
end

local function getUserBgColor(username)
  local filePath = USERDATA_FOLDER .. username .. "-bgcolor.txt"
  local file = io.open(filePath, "r")
  if file then
    local color = file:read("*l")
    file:close()
    return color
  end
  return "#000000"
end

local function getUserNameColor(username)
    local filePath = USERDATA_FOLDER .. username .. "-namecolor.txt"
    local file = io.open(filePath, "r")
    if file then
      local color = file:read("*l")
      file:close()
      return color
    end
    return "#FFFFFF"
  end

local function wrapText(text, maxWidth)
  local lines = {}
  local currentLine = ""
  local currentWidth = 0
  
  for word in text:gmatch("%S+") do
    local wordWidth = #word * FONT_WIDTH
    if wordWidth > maxWidth then
      for i = 1, #word, maxWidth // FONT_WIDTH do
        table.insert(lines, word:sub(i, i + (maxWidth // FONT_WIDTH) - 1))
      end
    elseif currentWidth + wordWidth <= maxWidth then
      if currentLine ~= "" then
        currentLine = currentLine .. " "
        currentWidth = currentWidth + FONT_WIDTH
      end
      currentLine = currentLine .. word
      currentWidth = currentWidth + wordWidth
    else
      table.insert(lines, currentLine)
      currentLine = word
      currentWidth = wordWidth
    end
  end
  
  if currentLine ~= "" then
    table.insert(lines, currentLine)
  end
  
  return lines
end

while true do
  RNG = math.random(2049)
  gui.drawBox(0,0,320,600, "#00ff00", "#00ff00")
  twitch_conn:settimeout(0.001)
  local data, status, partial = twitch_conn:receive("*l")
  if data then
    if data:sub(1, 4) == "PING" then
      handlePing()
      print("got pinged")
    else
      local nick = data:match(":(.-)!")
      local message = data:match("PRIVMSG #" .. channel_name .. " :(.+)")
      if nick and message then
        --print(data)
        print(nick .. ": " .. message)
        
        createUserFiles(nick)
        
        if message:match("^-avatar%s*$") then
          sendChatMessage("Please choose an image for this command")
        elseif message:match("^-avatar%s+(%S+)") then
          local avatarCommand = message:match("^-avatar%s+(%S+)")
          if isValidEntry(avatarCommand, AVATARS) then
            local avatarFile = USERDATA_FOLDER .. nick .. "-avatar.txt"
            local file = io.open(avatarFile, "w")
            if file then
              file:write(avatarCommand)
              file:close()
              sendChatMessage(nick .. " changed their avatar to " .. avatarCommand)
            end
          else
            sendChatMessage("This image does not exist")
          end
        elseif message:match("^-bgcolor%s+#%x%x%x%x%x%x$") then
          local color = message:match("^-bgcolor%s+(#%x%x%x%x%x%x)$")
          local bgcolorFile = USERDATA_FOLDER .. nick .. "-bgcolor.txt"
          local file = io.open(bgcolorFile, "w")
          if file then
            file:write(color)
            file:close()
            sendChatMessage(nick .. " changed their background color to " .. color)
          end
        elseif message:match("^-bgcolor%s*.*") then
          sendChatMessage("Invalid background color format. Use -bgcolor #RRGGBB")
        elseif message:match("^-namecolor%s+#%x%x%x%x%x%x$") then
            local color = message:match("^-namecolor%s+(#%x%x%x%x%x%x)$")
            
            -- Prevent users from using #00FF00
            if color:upper() == "#00FF00" then
                sendChatMessage("Sorry, " .. nick .. ", but #00FF00 is not allowed as a name color.")
            else
                local namecolorFile = USERDATA_FOLDER .. nick .. "-namecolor.txt"
                local file = io.open(namecolorFile, "w")
                if file then
                    file:write(color)
                    file:close()
                    sendChatMessage(nick .. " changed their name color to " .. color)
                end
            end
        
          elseif message:match("^-namecolor%s*.*") then
            sendChatMessage("Invalid background color format. Use -namecolor #RRGGBB")
        else
          local wrappedMessage = wrapText(message, CHAT_WIDTH)
          local chatboxHeight = math.max(CHATBOX_MIN_HEIGHT, #wrappedMessage * FONT_HEIGHT + NAME_HEIGHT)
          
          table.insert(CHAT_MESSAGES, {nick = nick, lines = wrappedMessage, height = chatboxHeight})
          
          while #CHAT_MESSAGES > MAX_MESSAGES do
            table.remove(CHAT_MESSAGES, 1)
          end
        end
      end
    end
  end

  local totalHeight = 0
  for _, chat in ipairs(CHAT_MESSAGES) do
    totalHeight = totalHeight + chat.height + MESSAGE_SPACING
  end
  
  local yOffset = SCREEN_HEIGHT - CHAT_MARGIN - totalHeight
  for _, chat in ipairs(CHAT_MESSAGES) do
    local bgcolor = getUserBgColor(chat.nick)
    local namecolor = getUserNameColor(chat.nick)
    --white profile box
    gui.drawBox(CHAT_X_OFFSET - IMAGE_SIZE + 1, yOffset,CHAT_X_OFFSET - IMAGE_SIZE +33, yOffset+33, "white", "white")
    --bgcolor
    gui.drawBox(CHAT_X_OFFSET+2, yOffset, CHAT_X_OFFSET + CHAT_WIDTH+6, yOffset + chat.height + 1, white, bgcolor)
    --white outline / darken
    --gui.drawBox(CHAT_X_OFFSET+3, yOffset, CHAT_X_OFFSET + CHAT_WIDTH, yOffset + chat.height + 1, "#FFFFFF", 0x80000000)
    --image + image position
    --gui.drawImage(getUserImage(chat.nick), CHAT_X_OFFSET - IMAGE_SIZE+2, yOffset+1)
    gui.drawImageRegion(getUserImage(chat.nick), 0, 0, 40, 40, CHAT_X_OFFSET - IMAGE_SIZE+2, yOffset+1, 32, 32)
    --username text
    gui.pixelText(CHAT_X_OFFSET+3, 1+yOffset, chat.nick .. ":", namecolor)
    yOffset = yOffset + NAME_HEIGHT
    for j, msg in ipairs(chat.lines) do
      --gui.pixelText(CHAT_X_OFFSET+5, yOffset + (j - 1) * FONT_HEIGHT + 1, msg, "white", 0x00000000)
      --gui.drawText(CHAT_X_OFFSET+4, yOffset + (j - 1) * FONT_HEIGHT, msg, nil, nil, 8, "Zepto Regular")
      gui.drawText(CHAT_X_OFFSET+4, yOffset + (j - 1) * FONT_HEIGHT-1, msg, 0x90000000, nil, 8, "Zepto Regular")
      gui.drawText(CHAT_X_OFFSET+3, yOffset + (j - 1) * FONT_HEIGHT-1, msg, 0x60000000, nil, 8, "Zepto Regular")
      gui.drawText(CHAT_X_OFFSET+3, yOffset + (j - 1) * FONT_HEIGHT-2, msg, "#FFFFFF", nil, 8, "Zepto Regular")
      --gui.drawText(CHAT_X_OFFSET+5, yOffset + (j - 1) * FONT_HEIGHT + 1, msg, "white", 0x00000000)
    end
    yOffset = yOffset + chat.height - NAME_HEIGHT + MESSAGE_SPACING
  end

  if CHAT_MESSAGES[6] ~= nil then
    gui.drawLine(0,0,320,0,"#00FF00")
    gui.drawLine(1,1,238,1,"white")
  end

  emu.frameadvance()
end