local M = {}

M.setup = function()
    
    -- ====================================================
    -- PART 1: Auto-Rename Pane 0 (Your existing logic)
    -- ====================================================
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

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })

    -- ====================================================
    -- PART 2: Run Python in Pane 2 (New Logic)
    -- ====================================================
    vim.api.nvim_create_user_command("FTmuxRun", function()
        -- 1. Check: Are we in Tmux?
        if not vim.env.TMUX then 
            print("❌ Error: Not in Tmux")
            return 
        end

        -- 2. Check: Is this a Python file?
        if vim.fn.expand("%:e") ~= "py" then
            print("❌ Error: Not a Python file")
            return
        end

        -- 3. Prepare Command
        local filename = vim.fn.expand("%:t") -- Gets "script.py"
        local command = "python3 " .. filename

        -- 4. Execute in Pane 2
        -- Focus Pane 2
        vim.fn.system({"tmux", "select-pane", "-t", "2"})
        
        -- Send keys AND hit Enter ("C-m" stands for Carriage Return/Enter)
        vim.fn.system({"tmux", "send-keys", "-t", "2", command, "C-m"})
        
        print("🚀 Running: " .. command .. " in Pane 2")
    end, {})
end

return M
