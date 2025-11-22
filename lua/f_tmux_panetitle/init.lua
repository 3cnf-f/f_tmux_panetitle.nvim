local M = {}Glocal M = {}

M.setup = function()
    
    -- 1. Existing Logic: Auto-rename Pane 0
    local function update_pane_0()
        if not vim.env.TMUX then return end
        
        local extension = vim.fn.expand("%:e")
        local filename = vim.fn.expand("%:t")
        local new_title = ""

        if extension == "py" then
            new_title = "f_tmux:" .. filename
        else
            new_title = "not_py"
        end

        vim.fn.system({"tmux", "select-pane", "-t", "0", "-T", new_title})
    end

    -- Auto-command for renaming
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })


    -- 2. NEW Logic: Send "poop" to Pane 2
    vim.api.nvim_create_user_command("FTmuxRun", function()
        -- Check if we are in Tmux
        if not vim.env.TMUX then 
            print("❌ Not in Tmux")
            return 
        end

        -- Step A: Focus Pane 2
        vim.fn.system({"tmux", "select-pane", "-t", "2"})

        -- Step B: Send the keys "poop" (No Enter)
        -- Note: If you wanted Enter, you would add "C-m" at the end
        vim.fn.system({"tmux", "send-keys", "-t", "2", "poop"})
        
        print("✅ Sent 'poop' to Pane 2")
    end, {})
end

return MNOT set any title.
        if not vim.env.TMUX then 
            return 
        end

        -- 2. Get file info
        local filename = vim.fn.expand("%:t")
        local extension = vim.fn.expand("%:e")
        local new_title = ""

        -- 3. Logic: Check for Python
        if extension == "py" then
            new_title = "f_tmux:" .. filename
        else
            -- If in Tmux but NOT a python file
            new_title = "not_py"
        end

        -- 4. Execute Tmux Command on Pane 0
        vim.fn.system({"tmux", "select-pane", "-t", "0", "-T", new_title})
    end

    -- Run automatically on file changes
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })
end

return M
