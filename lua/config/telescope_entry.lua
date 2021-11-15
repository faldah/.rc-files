local M = {}

-- local path = require('telescope')
local make_entry = require('telescope.make_entry')
-- local utils = require('telescope.utils')
local devicons = require 'nvim-web-devicons'
local entry_display = require('telescope.pickers.entry_display')

local filter = vim.tbl_filter
local map = vim.tbl_map

function get_path_and_fname(p)
    return p:match("(.*)/([^/]+)")
end

function M.gen_from_buffer(opts)
  opts = opts or {}
  local default_icons, _ = devicons.get_icon('file', '', {default = true})

  local bufnrs = filter(function(b) return 1 == vim.fn.buflisted(b) end,
                        vim.api.nvim_list_bufs())

  local max_bufnr = math.max(unpack(bufnrs))
  local bufnr_width = #tostring(max_bufnr)

  local max_bufname = math.max(unpack(map(
                                          function(bufnr)
        return vim.fn.strdisplaywidth(vim.fn.fnamemodify(
                                          vim.api.nvim_buf_get_name(bufnr),
                                          ':p:t'))
      end, bufnrs)))

  local displayer = entry_display.create {
    separator = " ",
    items = {
      {width = bufnr_width}, {width = 4},
      {width = vim.fn.strwidth(default_icons)}, {width = max_bufname},
      {remaining = true}
    }
  }

  local make_display = function(entry)
    return displayer {
      {entry.bufnr, "TelescopeResultsNumber"},
      {entry.indicator, "TelescopeResultsComment"},
      {entry.devicons, entry.devicons_highlight}, entry.file_name,
      {entry.dir_name, "Comment"}
    }
  end

  return function(entry)
    local bufname = entry.info.name ~= "" and entry.info.name or '[No Name]'
    local hidden = entry.info.hidden == 1 and 'h' or 'a'
    local readonly = vim.api.nvim_buf_get_option(entry.bufnr, 'readonly') and
                         '=' or ' '
    local changed = entry.info.changed == 1 and '+' or ' '
    local indicator = entry.flag .. hidden .. readonly .. changed

    local dir_name = vim.fn.fnamemodify(bufname, ':p:h')
    local file_name = vim.fn.fnamemodify(bufname, ':p:t')

    local icons, highlight = devicons.get_icon(bufname,
                                               string.match(bufname, '%a+$'),
                                               {default = true})

    return {
      valid = true,

      value = bufname,
      ordinal = entry.bufnr .. " : " .. file_name,
      display = make_display,

      bufnr = entry.bufnr,

      lnum = entry.info.lnum ~= 0 and entry.info.lnum or 1,
      indicator = indicator,
      devicons = icons,
      devicons_highlight = highlight,

      file_name = file_name,
      dir_name = dir_name
    }
  end
end

function M.gen_from_file(opts)
  opts = opts or {}

  local cwd = vim.fn.expand(opts.cwd or vim.fn.getcwd())
    -- local display = path.make_relative(entry.value, cwd)

  local displayer = entry_display.create {
    separator = " ",
    items = {
      {width = 2},
      {width = 7},
      {},
      {remaining = true}
    }
  }

  local make_display = function(entry)
    return displayer {
      {entry.icon, entry.icon_highlight},
      {entry.location, "TelescopeResultsNumber"},
      entry.display_path,
      {entry.fname, "DevIconCp"},
    }
  end

  local short_fname = function(fname)
      fname = fname:gsub("/usr/local/google/home/frs/","~")
      fname = fname:gsub("/google/src/cloud/frs/[^/]+/","")
      fname = fname:gsub("google3","g3")
      fname = fname:gsub("/security/crypta/","/s/c/")
      return fname
  end

  local orig = make_entry.gen_from_file(opts)
  return function(entry)
      local e = orig(entry)
      local fname = e.value
      local icon, icon_highlight = devicons.get_icon(fname,
                                               string.match(fname, '%a+$'),
                                               {default = true})
      local loc = string.match(fname, "/google/src/cloud/frs/([^/]+)/")
      if loc then
          loc = ' ' .. loc
      elseif string.match(fname, "/usr/local/google/home") then
         loc =  " home"
      else
         loc = " "
      end

      path, fname = get_path_and_fname(fname)

      e.icon = icon
      e.icon_highlight = icon_highlight
      e.display_path= short_fname(path)
      e.fname = fname
      e.location =  loc
      e.display = make_display
      return e
  end
end

return M
