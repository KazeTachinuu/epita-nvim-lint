local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.INFO,
}

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        c = { "epita_coding_style" },
        cpp = { "epita_coding_style" },
      },
      linters = {
        epita_coding_style = {
          cmd = "epita-coding-style",
          stdin = false,
          append_fname = true,
          args = {},
          stream = "stdout",
          ignore_exitcode = true,
          condition = function()
            return vim.fn.executable("epita-coding-style") == 1
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
        },
      },
    },
  },
}
