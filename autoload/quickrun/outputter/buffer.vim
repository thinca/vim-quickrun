" quickrun: outputter: buffer
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {}

function! s:outputter.init(args, session)
  let config = a:session.config
  let self._split = config.split
  let self._into = config.into
  let self._running_mark = config.running_mark
  let winnr = winnr()
  call s:open_result_window(self._split)
  let self._line = line('$')
  if !config.append
    silent % delete _
  endif
  call s:set_running_mark(self._running_mark)
  execute winnr 'wincmd w'
endfunction

function! s:outputter.output(data, session)
  let winnr = winnr()
  call s:open_result_window(self._split)
  let cursor = getpos('.')
  let oneline = line('$') == 1
  let data = getline('$') . a:data
  silent $ delete _
  if data =~ '\n$'
    " :put command do not insert the last line.
    let data .= "\n"
  endif
  silent $ put = data
  if oneline
    silent 1 delete _
  endif
  call s:set_running_mark(self._running_mark)
  call setpos('.', cursor)
  execute winnr 'wincmd w'
  redraw
endfunction

function! s:outputter.finish(session)
  let winnr = winnr()
  call s:open_result_window(self._split)
  execute self._line
  silent normal! zt
  if !self._into
    execute winnr 'wincmd w'
  endif
  redraw
endfunction


function! s:open_result_window(sp)
  if !exists('s:bufnr')
    let s:bufnr = -1  " A number that doesn't exist.
  endif
  if !bufexists(s:bufnr)
    execute a:sp 'split'
    edit `='[quickrun output]'`
    let s:bufnr = bufnr('%')
    nnoremap <buffer> q <C-w>c
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
    setlocal filetype=quickrun
  elseif bufwinnr(s:bufnr) != -1
    execute bufwinnr(s:bufnr) 'wincmd w'
  else
    execute a:sp 'split'
    execute 'buffer' s:bufnr
  endif
  if exists('b:quickrun_running_mark')
    silent undo
    unlet b:quickrun_running_mark
  endif
endfunction

function! s:set_running_mark(mark)
  if a:mark != '' && !exists('b:quickrun_running_mark')
    let &undolevels = &undolevels  " split the undo block
    silent $ put =a:mark
    let b:quickrun_running_mark = 1
  endif
endfunction


function! quickrun#outputter#buffer#new()
  return copy(s:outputter)
endfunction

let &cpo = s:save_cpo
