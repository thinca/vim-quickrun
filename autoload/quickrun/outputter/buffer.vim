" quickrun: outputter: buffer
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'append': 0,
\     'split': '%{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
\     'into': 0,
\     'running_mark': ':-)',
\   }
\ }

function! s:outputter.init(session)
  let self._append = self.config.append
  let self._line = 0
endfunction

function! s:outputter.output(data, session)
  let winnr = winnr()
  call s:open_result_window(self.config.split)
  if !self._append
    silent % delete _
    let self._append = 1
  endif
  if self._line == 0
    let self._line = line('$')
  endif
  let oneline = line('$') == 1
  let data = getline('$') . a:data
  silent $ delete _
  if data =~# '\n$'
    " :put command do not insert the last line.
    let data .= "\n"
  endif

  " XXX 'fileformat' of a new buffer depends on 'fileformats'.
  if &l:fileformat ==# 'dos'
    let data = substitute(data, "\r\n", "\n", 'g')
  endif

  silent $ put = data
  if oneline
    silent 1 delete _
  endif
  call s:set_running_mark(self.config.running_mark)
  execute winnr 'wincmd w'
  redraw
endfunction

function! s:outputter.finish(session)
  let winnr = winnr()

  if self._line == 0  " no output
    " clear the buffer if already opened.
    if exists('s:bufnr') && bufwinnr(s:bufnr) != -1
      execute bufwinnr(s:bufnr) 'wincmd w'
      silent % delete _
      if !self.config.into
        execute winnr 'wincmd w'
      endif
    endif
    return
  endif

  call s:open_result_window(self.config.split)
  execute self._line
  silent normal! zt
  if !self.config.into
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
  if a:mark !=# '' && !exists('b:quickrun_running_mark')
    let &undolevels = &undolevels  " split the undo block
    silent $ put =a:mark
    let b:quickrun_running_mark = 1
  endif
endfunction


function! quickrun#outputter#buffer#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
