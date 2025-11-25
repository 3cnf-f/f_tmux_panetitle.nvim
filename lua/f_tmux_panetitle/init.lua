local M = {}

M.setup = function()
    -- Create the user command :FTmuxRun
    vim.api.nvim_create_user_command("FTmuxRun", function()
        
        -- 1. VALIDATION
        -- Ensure we are inside Tmux
        if not vim.env.TMUX then 
            print("❌ Not in Tmux") 
            return 
        end
        
        -- Ensure the current buffer is a Python file
        if vim.fn.expand("%:e") ~= "py" then 
            print("❌ Not a Python file") 
            return 
        end

        -- 2. FILE PATHS
        -- Get full absolute path for execution (handles nested folders)
        local full_path = vim.fn.expand("%:p")
        -- Get filename just for the print message
        local filename = vim.fn.expand("%:t")

        -- 3. PANE DISCOVERY
        -- Define the exact titles we are looking for in tmux
        local runner_name = "test_pane"
        local editor_name = "editor_pane"
        
        local runner_id = nil
        local editor_id = nil

        -- Run tmux command to list all panes in the current window.
        -- Format requested: "%32 editor_pane" (ID space Title)
        local panes_output = vim.fn.system({"tmux", "list-panes", "-F", "#{pane_id} #{pane_title}"})

        -- Iterate through each line of output to match names to IDs
        for line in panes_output:gmatch("[^\r\n]+") do
            -- Pattern explanation:
            -- ^(%%%d+)  -> Capture the ID starting with % (e.g., %32)
            -- %s+       -> Match the space separator
            -- (.*)$     -> Capture the rest of the line as the title
            local id, title = line:match("^(%%%d+)%s+(.*)$")
            
            if title == runner_name then
                runner_id = id
            elseif title == editor_name then
                editor_id = id
            end
        end

        -- 4. ERROR HANDLING
        -- If we can't find the 'test_pane', we can't run the code.
        if not runner_id then
            print("❌ Could not find a pane named '" .. runner_name .. "'")
            return
        end

        -- If 'editor_pane' isn't found, fallback to the current pane so we don't get lost.
        if not editor_id then
            print("⚠️ '" .. editor_name .. "' not found. Will return to current pane.")
            -- Get the ID of the pane we are currently standing in
            editor_id = vim.fn.system({"tmux", "display-message", "-p", "#{pane_id}"}):gsub("%s+", "")
        end

        -- 5. BUILD COMMANDS
        -- Construct the bash chain to run in the runner pane.
        -- logic: run python -> wait for enter -> unzoom runner -> switch focus back to editor
        local bash_chain = "python3 '" .. full_path .. "'" .. 
                           "; echo ''; read -p 'Press Enter to return...' dummy" .. 
                           "; tmux resize-pane -Z -t " .. runner_id .. 
                           "; tmux select-pane -t " .. editor_id

        -- 6. EXECUTE TMUX SEQUENCE
        
        -- A. Focus the Runner Pane (using the ID we found, e.g., %33)
        vim.fn.system({"tmux", "select-pane", "-t", runner_id})

        -- B. Zoom the Runner Pane (make it full screen)
        vim.fn.system({"tmux", "resize-pane", "-Z", "-t", runner_id})

        -- C. Clean the terminal (Clear screen and scrollback)
        vim.fn.system({"tmux", "send-keys", "-t", runner_id, "C-l", "C-u"})

        -- D. Send the Bash Chain and execute it (C-m is Enter)
        vim.fn.system({"tmux", "send-keys", "-t", runner_id, bash_chain, "C-m"})
        
        print("🚀 Running " .. filename .. " in " .. runner_name .. " (" .. runner_id .. ")")
    end, {})
end

return M
