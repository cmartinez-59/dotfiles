-- Neovim's bundled $VIMRUNTIME/ftplugin/json.vim forces sw=2 sts=2 ts=2,
-- overriding our global 4-space settings. That mismatch made jsonls
-- reformat whole files (4-space -> 2-space) on every save. Restore 4-space
-- here so format-on-save matches this repo's committed JSON style.
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4
vim.bo.expandtab = true
