local M = {}

M.setup = function()
    -- Command: :FTmuxSet
    vim.api.nvim_create_user_command("FTmuxSet", function()
        -- 1. Check if we are inside Tmux
        -- vim.env.TMUX returns the socket path if active, or nil if not
        if not vim.env.TMUX then
            print("❌ Not in tmux")
            return
        end

        -- 2. Check if the current file is a Python file
        -- "%:e" gets the extension of the current buffer
        if vim.fn.expand("%:e") ~= "py" then
            print("❌ File is not py")
            return
        end

        -- 3. Get the filename (tail only)
        local filename = vim.fn.expand("%:t")
        local new_title = "f_tmux:" .. filename

        -- 4. Execute the tmux command
        -- "select-pane -T" sets the pane title
        vim.fn.system({"tmux", "select-pane", "-T", new_title})

        print("✅ Tmux pane title set to: " .. new_title)
    end, {})
end

return M
