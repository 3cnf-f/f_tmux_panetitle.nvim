local M = {}

M.setup = function()
    
    -- [PART 1] Auto-Rename Pane 0 (Keep as is)
    local function update_pane_0()
        if not vim.env.TMUX then return end
        local extension = vim.fn.expand("%:e")
        local filename = vim.fn.expand("%:t")
        local new_title = (extension == "py") and ("f_tmux:" .. filename) or "not_py"
        -- vim.fn.system({"tmux", "select-pane", "-t", "0", "-T", new_title})
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })

    -- [PART 2] Run -> Wait -> Unzoom -> Return
    vim.api.nvim_create_user_command("FTmuxRun", function()
        -- 1. Checks
        if not vim.env.TMUX then print("❌ Not in Tmux") return end
        if vim.fn.expand("%:e") ~= "py" then print("❌ Not a Python file") return end

        -- CHANGE 1: Get the full absolute path for execution
        local full_path = vim.fn.expand("%:p")
        -- Keep just the filename for the pretty print message at the end
        local filename = vim.fn.expand("%:t")

        -- 2. Construct the Bash Chain
        -- CHANGE 2: Use full_path and wrap it in single quotes to handle spaces in folder names
        local bash_chain = "python3 '" .. full_path .. "'" .. 
                           "; echo ''; read -p 'Press Enter to return...' dummy" .. 
                           "; tmux resize-pane -Z -t 2" .. 
                           "; tmux select-pane -t 0"

        -- 3. The Initial Tmux Sequence (From Neovim)
        
        -- A. Focus Pane 2
        vim.fn.system({"tmux", "select-pane", "-t", "2"})

        -- B. Zoom Pane 2 (Make it full screen)
        vim.fn.system({"tmux", "resize-pane", "-Z", "-t", "2"})

        -- C. Clean the terminal (Ctrl+l clear screen, Ctrl+u clear line)
        vim.fn.system({"tmux", "send-keys", "-t", "2", "C-l", "C-u"})

        -- D. Send the Chain and Hit Enter
        vim.fn.system({"tmux", "send-keys", "-t", "2", bash_chain, "C-m"})
        
        print("🚀 Running " .. filename .. " (Zoomed)")
    end, {})
end

return M
