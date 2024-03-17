require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'iceberg',
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = { 'tabs', {
      'filename',
      file_status = true,
      path = 1,
    } },
  },
}
