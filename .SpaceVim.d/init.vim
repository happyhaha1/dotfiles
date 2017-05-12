" Here are some basic customizations,
" please refer to the ~/.SpaceVim.d/init.vim
" file for all possible options:
let g:spacevim_default_indent = 3
let g:spacevim_max_column     = 80

" Change the default directory where all miscellaneous persistent files go.
" By default it is ~/.cache/vimfiles.

" set SpaceVim colorscheme
let g:spacevim_colorscheme = 'jellybeans'

" Set plugin manager, you want to use, default is dein.vim
let g:spacevim_plugin_manager = 'dein'  " neobundle or dein or vim-plug

" use space as `<Leader>`
let mapleader = "\<space>"

" Set windows shortcut leader [Window], default is `s`
let g:spacevim_windows_leader = 's'

" Set unite work flow shortcut leader [Unite], default is `f`
let g:spacevim_unite_leader = 'f'

" By default, language specific plugins are not loaded. This can be changed
" with the following, then the plugins for go development will be loaded.
" call SpaceVim#layers#load('lang#java')

" loaded ui layer
call SpaceVim#layers#load('ui')
set norelativenumber
set confirm
set modifiable
nnoremap <Leader>wq :wq<CR>
nnoremap <Leader>q  :q<CR>
nnoremap <Leader>w  :w<CR>
map << 0     " 定义快捷键到行首 / “)” 页尾
map >> $     " 定义快捷键到行尾
