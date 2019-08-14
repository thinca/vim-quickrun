" Run commands quickly.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_quickrun')
  finish
endif
let g:loaded_quickrun = 1


command! -nargs=* -range=0 -complete=customlist,quickrun#command#complete
\ QuickRun call quickrun#command#execute(<q-args>, <count>, <line1>, <line2>)


nnoremap <silent> <Plug>(quickrun-op)
\        :<C-u>set operatorfunc=quickrun#operator<CR>g@

nnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode n<CR>
vnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode v<CR>
