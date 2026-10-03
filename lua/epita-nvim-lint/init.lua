local M = {}

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
}

local config_files = { ".epita-style", ".epita-style.toml", "epita-style.toml" }

local function project_root(fname)
  local found = vim.fs.find(config_files, {
    path = vim.fs.dirname(fname),
    upward = true,
    type = "file",
  })[1]
  return found and vim.fs.dirname(found) or nil
end

local function setup_linter()
  local ok, lint = pcall(require, "lint")
  if not ok then
    vim.notify("epita-nvim-lint: nvim-lint is required", vim.log.levels.ERROR)
    return nil
  end

  if vim.fn.executable("epita-coding-style") ~= 1 then
    vim.notify(
      "epita-nvim-lint: epita-coding-style not found (pipx install epita-coding-style)",
      vim.log.levels.WARN
    )
    return nil
  end

  lint.linters.epita_coding_style = {
    cmd = "epita-coding-style",
    stdin = false,
    append_fname = true,
    args = {},
    stream = "stdout",
    ignore_exitcode = true,
    parser = function(output, bufnr, linter_cwd)
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
          -- resolve relative paths against the linter cwd
          if not file:match("^/") and linter_cwd then
            file = linter_cwd .. "/" .. file
          end
          if vim.fs.normalize(file) == norm_bufname then
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

  return lint
end

function M.setup()
  local lint
  local linter_initialized = false

  -- Own autocmd, not linters_by_ft: keeps project-root cwd and avoids
  -- double-linting; file-based linter, so on-disk events only. Requiring
  -- nvim-lint is deferred until a project marker is found.
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("epita-nvim-lint", { clear = true }),
    pattern = { "*.c", "*.h", "*.cc", "*.hh", "*.hxx", "*.cpp", "*.hpp" },
    callback = function(ev)
      local fname = vim.api.nvim_buf_get_name(ev.buf)
      if fname == "" then
        return
      end

      local root = project_root(fname)
      if not root then
        return
      end

      if not linter_initialized then
        lint = setup_linter()
        linter_initialized = true
      end
      if lint then
        lint.try_lint("epita_coding_style", { cwd = root })
      end
    end,
  })
end

return M
