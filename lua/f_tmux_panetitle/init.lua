local M = {}

-- This function runs when you require("...").setup()
M.setup = function(opts)
    -- 1. Print a message so you know it loaded immediately
    print("🚀 f_tmux_panetitle is alive!")

    -- 2. Create a user command you can type manually
    -- Usage: :HelloTmux
    vim.api.nvim_create_user_command("HelloTmux", function()
        print("Hello World from your Container!")
    end, {})
end

return M
