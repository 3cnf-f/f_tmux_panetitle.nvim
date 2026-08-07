local M = {}

-- === HELPER: Find Git Root ===
local function get_git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2> /dev/null")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  if not result or result == "" then return nil end
  return result:gsub("%s+", "")
end

-- === HELPER: The Main Execution Engine ===
-- Now takes a raw bash command string instead of assuming python
local function execute_in_tmux(bash_cmd, display_name)
  if not vim.env.TMUX then
    print("❌ Not in Tmux")
    return
  end

  local runner_name = "test_pane"
  local editor_name = "editor_pane"

  local runner_id, editor_id

  local panes_output = vim.fn.system({"tmux", "list-panes", "-a", "-F", "#{pane_id}:#{pane_title}"})
  for line in panes_output:gmatch("[^\r\n]+") do
    local id, title = line:match("^(%%%d+):(.*)$")
    if title == runner_name then
      runner_id = id
    elseif title == editor_name then
      editor_id = id
    end
  end

  if not runner_id then
    print("❌ Could not find pane: '" .. runner_name .. "'")
    return
  end

  if not editor_id then
    editor_id = vim.fn.system({"tmux", "display-message", "-p", "#{pane_id}"}):gsub("%s+", "")
  end

  -- Chain: run the command → blank line → wait for Enter → unzoom → go back to editor
  local bash_chain = bash_cmd ..
    "; echo ''; read -p 'Press Enter to return...' dummy" ..
    "; tmux resize-pane -Z -t " .. runner_id ..
    "; tmux select-pane -t " .. editor_id

  vim.fn.system({"tmux", "select-pane", "-t", runner_id})
  vim.fn.system({"tmux", "resize-pane", "-Z", "-t", runner_id})
  vim.fn.system({"tmux", "send-keys", "-t", runner_id, "C-l", "C-u"})
  vim.fn.system({"tmux", "send-keys", "-t", runner_id, bash_chain, "C-m"})

  print("🚀 Running " .. display_name .. " in " .. runner_name)
end

-- Helper to get current line or visual selection (works for both normal & visual)
local function get_code_to_run()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then  -- visual / visual-line / visual-block
    local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
    local lines = vim.fn.getline(csrow, cerow)
    if #lines == 0 then return "" end
    lines[#lines] = string.sub(lines[#lines], 1, cecol)
    lines[1] = string.sub(lines[1], cscol)
    return table.concat(lines, "\n")
  else
    return vim.api.nvim_get_current_line()
  end
end

M.setup = function()
  -- === :FTmuxRun  (leader RT)  – now context-aware ===
  vim.api.nvim_create_user_command("FTmuxRun", function()
    local ft = vim.bo.filetype
    local ext = vim.fn.expand("%:e")

    if ft == "python" or ext == "py" then
      local full_path = vim.fn.expand("%:p")
      local filename = vim.fn.expand("%:t")
      -- Keep the original quoting style you already verified
      execute_in_tmux("python3 '" .. full_path .. "'", filename)

    elseif ft == "sh" or ft == "bash" or ext == "sh" then
      local code = get_code_to_run()
      if code == "" then
        print("❌ Nothing to run")
        return
      end
      -- Proper escaping so quotes, $, etc. survive
      local escaped = vim.fn.shellescape(code)
      execute_in_tmux("bash -c " .. escaped, "shell-line")

    else
      print("❌ FTmuxRun only supports Python (whole file) or Shell (current line / selection)")
    end
  end, { range = true })  -- allows visual ranges

  -- Keep the root variant exactly as it was (still Python-only)
  vim.api.nvim_create_user_command("FTmuxRunRoot", function(opts)
    local root = get_git_root()
    if not root then
      print("❌ Not in a git repository")
      return
    end

    local relative_path = opts.args
    if relative_path == "" then relative_path = "/main.py" end
    if relative_path:sub(1, 1) ~= "/" then relative_path = "/" .. relative_path end

    local full_path = root .. relative_path
    if vim.fn.filereadable(full_path) == 0 then
      print("⚠️ File not found: " .. full_path)
      return
    end

    execute_in_tmux("python3 '" .. full_path .. "'", "ROOT" .. relative_path)
  end, { nargs = "?" })
end

return M
