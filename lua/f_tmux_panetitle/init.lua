local M = {}

M.setup = function()
    
    -- [PART 1] Auto-Rename Pane 0 (Keep this as is)
    local function update_pane_0()
        if not vim.env.TMUX then return end
        local extension = vim.fn.expand("%:e")
        local filename = vim.fn.expand("%:t")
        local new_title = (extension == "py") and ("f_tmux:" .. filename) or "not_py"
        vim.fn.system({"tmux", "select-pane", "-t", "0", "-T", new_title})
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
        pattern = "*",
        callback = update_pane_0,
    })

    -- [PART 2] Run Python with Zoom and Clear
    vim.api.nvim_create_user_command("FTmuxRun", function()
        -- 1. Checks
        if not vim.env.TMUX then print("❌ Not in Tmux") return end
        if vim.fn.expand("%:e") ~= "py" then print("❌ Not a Python file") return end

        local filename = vim.fn.expand("%:t")
        local command = "python3 " .. filename

        -- 2. The Tmux Sequence
        
        -- A. Focus Pane 2
        vim.fn.system({"tmux", "select-pane", "-t", "2"})

        -- B. Toggle Zoom (Equivalent to Prefix + z)
        -- "-Z" tells tmux to zoom/unzoom the target pane
        vim.fn.system({"tmux", "resize-pane", "-Z", "-t", "2"})

        -- C. Clean the terminal
        -- "C-l" = Clear Screen (Ctrl+l)
        -- "C-u" = Clear Line (Ctrl+u) - removes any junk text on the prompt
        vim.fn.system({"tmux", "send-keys", "-t", "2", "C-l", "C-u"})

        -- D. Run the command
        vim.fn.system({"tmux", "send-keys", "-t", "2", command, "C-m"})
        
        print("🚀 Zoomed & Running: " .. filename)
    end, {})
end

return M
