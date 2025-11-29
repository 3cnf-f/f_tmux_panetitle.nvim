local M = {}

-- === HELPER: Find Git Root ===
local function get_git_root()
    -- Ask git for the top-level directory
    local handle = io.popen("git rev-parse --show-toplevel 2> /dev/null")
    if not handle then return nil end
    local result = handle:read("*a")
    handle:close()
    
    if not result or result == "" then return nil end
    return result:gsub("%s+", "") -- Trim whitespace/newlines
end

-- === HELPER: The Main Execution Engine ===
-- Handles finding panes, zooming, running code, and returning.
local function execute_in_tmux(full_path, display_name)
    -- 1. VALIDATION: Tmux Check
    if not vim.env.TMUX then 
        print("❌ Not in Tmux") 
        return 
    end

    -- 2. PANE DISCOVERY
    local runner_name = "test_pane"
    local editor_name = "editor_pane"
    
    local runner_id = nil
    local editor_id = nil

    -- We use the exact format you verified: ID:Title
    local panes_output = vim.fn.system({"tmux", "list-panes", "-a", "-F", "#{pane_id}:#{pane_title}"})

    -- Match IDs to Titles using the colon separator
    for line in panes_output:gmatch("[^\r\n]+") do
        -- Regex: Capture ID (starting with %), then skip colon, then capture Title
        local id, title = line:match("^(%%%d+):(.*)$")
        if title == runner_name then
            runner_id = id
        elseif title == editor_name then
            editor_id = id
        end
    end

    -- 3. ERROR HANDLING
    if not runner_id then
        print("❌ Could not find pane: '" .. runner_name .. "'")
        return
    end

    -- Fallback: If editor_pane isn't found, default to current pane
    if not editor_id then
        editor_id = vim.fn.system({"tmux", "display-message", "-p", "#{pane_id}"}):gsub("%s+", "")
    end

    -- 4. BUILD COMMANDS (Zoom -> Run -> Wait -> Unzoom)
    -- Using ; as separator to chain bash commands
    local bash_chain = "python3 '" .. full_path .. "'" .. 
                       "; echo ''; read -p 'Press Enter to return...' dummy" .. 
                       "; tmux resize-pane -Z -t " .. runner_id .. 
                       "; tmux select-pane -t " .. editor_id

    -- 5. EXECUTE TMUX SEQUENCE
    -- A. Select & Zoom Runner
    vim.fn.system({"tmux", "select-pane", "-t", runner_id})
    vim.fn.system({"tmux", "resize-pane", "-Z", "-t", runner_id})
    
    -- B. Clear Screen (Ctrl+l, Ctrl+u)
    vim.fn.system({"tmux", "send-keys", "-t", runner_id, "C-l", "C-u"})
    
    -- C. Send Command chain + Enter
    vim.fn.system({"tmux", "send-keys", "-t", runner_id, bash_chain, "C-m"})
    
    print("🚀 Running " .. display_name .. " in " .. runner_name)
end


M.setup = function()
    -- === COMMAND 1: Run Current File (:FTmuxRun) ===
    vim.api.nvim_create_user_command("FTmuxRun", function()
        -- Only run if it's a python file
        if vim.fn.expand("%:e") ~= "py" then 
            print("❌ Not a Python file") 
            return 
        end
        
        local full_path = vim.fn.expand("%:p")
        local filename = vim.fn.expand("%:t")
        
        execute_in_tmux(full_path, filename)
    end, {})

    -- === COMMAND 2: Run Git Root Main (:FTmuxRunRoot) ===
    vim.api.nvim_create_user_command("FTmuxRunRoot", function(opts)
        local root = get_git_root()
        if not root then
            print("❌ Not in a git repository")
            return
        end

        -- Use argument if provided, otherwise default to /main.py
        local relative_path = opts.args
        if relative_path == "" then 
            relative_path = "/main.py" 
        end
        
        -- Ensure path starts with /
        if relative_path:sub(1,1) ~= "/" then 
            relative_path = "/" .. relative_path 
        end

        local full_path = root .. relative_path

        -- Verify file exists
        if vim.fn.filereadable(full_path) == 0 then
            print("⚠️ File not found: " .. full_path)
            return
        end

        execute_in_tmux(full_path, "ROOT" .. relative_path)
    end, { nargs = "?" })
end

return M
