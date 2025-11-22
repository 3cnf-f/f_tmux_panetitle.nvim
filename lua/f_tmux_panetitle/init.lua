local M = {}

M.setup = function()
    
    local function update_pane_0()
        -- 1. First Check: Are we in Tmux?
        -- If not, stop immediately. Do NOT set any title.
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
