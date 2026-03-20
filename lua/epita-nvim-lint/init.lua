local M = {}

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.INFO,
}

local config_files = { ".epita-style", ".epita-style.toml", "epita-style.toml" }

local function find_project_root(fname)
  local root = vim.fs.find(config_files, {
    path = vim.fn.fnamemodify(fname, ":h"),
    upward = true,
    type = "file",
  })[1]
  if root then
    return vim.fn.fnamemodify(root, ":h")
  end
  return vim.fn.fnamemodify(fname, ":h")
end

function M.setup()
  local ok, lint = pcall(require, "lint")
  if not ok then
    vim.notify("epita-nvim-lint: nvim-lint is required", vim.log.levels.ERROR)
    return
  end

  lint.linters.epita_coding_style = {
    cmd = "epita-coding-style",
    stdin = false,
    append_fname = true,
    args = {},
    stream = "stdout",
    ignore_exitcode = true,
    cwd = function()
      local fname = vim.api.nvim_buf_get_name(0)
      return find_project_root(fname)
    end,
    parser = function(output, bufnr)
      local diagnostics = {}
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname == "" then
        return diagnostics
      end
      local norm_bufname = vim.fs.normalize(bufname)
      for line in output:gmatch("[^\n]+") do
        local file, lnum, col, sev, msg =
          line:match("^(.+):(%d+):(%d+): (%w+): (.+)$")
        if file then
          local norm_file = vim.fs.normalize(file)
          if norm_file == norm_bufname then
            table.insert(diagnostics, {
              lnum = tonumber(lnum) - 1,
              col = tonumber(col) - 1,
              severity = severity_map[sev] or vim.diagnostic.severity.WARN,
              message = msg,
              source = "epita-coding-style",
            })
          end
        end
      end
      return diagnostics
    end,
  }

  lint.linters_by_ft.c = lint.linters_by_ft.c or {}
  table.insert(lint.linters_by_ft.c, "epita_coding_style")

  lint.linters_by_ft.cpp = lint.linters_by_ft.cpp or {}
  table.insert(lint.linters_by_ft.cpp, "epita_coding_style")
end

return M
