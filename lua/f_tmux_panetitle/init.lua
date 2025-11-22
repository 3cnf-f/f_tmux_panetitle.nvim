local M = {}

M.setup = function()
    
    -- The core logic function
    local function update_pane_0()
        -- 1. Check for Tmux
        if not vim.env.TMUX then return end

        -- 2. Check for Python extension
        -- We silently return (do nothing) if it's not a py file, 
        -- so we don't spam errors while navigating other files.
        if vim.fn.expand("%:e") ~= "py" then return end

        -- 3. Prepare the title
        local filename = vim.fn.expand("%:t")
        local new_title = "f_tmux:" .. filename

        -- 4. Execute Tmux Command targeting Pane 0
        -- -t 0  : Targets pane 0 specifically
        -- -T    : Sets the title
        vim.fn.system({"tmux", "select-pane", "-t", "0", "-T", new_title})
    end

    -- AUTOCOMMAND: Runs automatically when you enter a buffer
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        pattern = "*", -- Triggers on all files (logic inside handles the .py check)
        callback = update_pane_0,
    })

    -- Manual command (just in case you need to force it)
    vim.api.nvim_create_user_command("FTmuxSet", function()
        update_pane_0()
        print("✅ Forced update of Tmux Pane 0")
    end, {})
end

return M
