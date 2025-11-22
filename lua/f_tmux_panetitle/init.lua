local M = {} -- Make sure this line is exactly "local M = {}"

M.setup = function()
    
    -- 1. Auto-rename logic (Pane 0)
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

    -- Auto-command setup
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })

    -- 2. "Send Poop" Logic (Pane 2)
    vim.api.nvim_create_user_command("FTmuxRun", function()
        if not vim.env.TMUX then 
            print("❌ Not in Tmux")
            return 
        end

        -- Focus Pane 2 and type text
        vim.fn.system({"tmux", "select-pane", "-t", "2"})
        vim.fn.system({"tmux", "send-keys", "-t", "2", "poop"}) -- Add "C-m" here to hit Enter
        
        print("✅ Sent 'poop' to Pane 2")
    end, {})
end

return M
