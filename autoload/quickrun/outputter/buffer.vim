" quickrun: outputter/buffer: Outputs to a vim buffer.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'name': '[quickrun output]',
\     'filetype': 'quickrun',
\     'append': 0,
\     'split': '%{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
\     'into': 0,
\     'running_mark': ':-)',
\     'close_on_empty': 0,
\   }
\ }

function! s:outputter.init(session)
  let self._append = self.config.append
  let self._line = 0
endfunction

function! s:outputter.start(session)
  call s:open_result_window(self.config, a:session)
  if !self._append
    silent % delete _
  endif
  call s:set_running_mark(self.config.running_mark)
  call s:back_to_previous_window()
endfunction

function! s:outputter.output(data, session)
  call s:open_result_window(self.config, a:session)
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
  call s:back_to_previous_window()
  redraw
endfunction

function! s:outputter.finish(session)
  call s:open_result_window(self.config, a:session)
  execute self._line
  silent normal! zt
  let closed = self.config.close_on_empty && s:is_empty_buffer()
  if closed
    close
  endif
  call s:back_to_previous_window(!closed && self.config.into)
  redraw
  if closed
    echohl MoreMsg
    echomsg "quickrun: outputter/buffer: Empty output."
    echohl NONE
  endif
endfunction


function! s:open_result_window(config, session)
  let w:quickrun_outputter_buffer_prevwin = 1
  let sp = a:config.split
  let sname = s:escape_file_pattern(a:config.name)
  let opened = 0
  if !bufexists(a:config.name)
    execute sp 'split'
    edit `=a:config.name`
    nnoremap <buffer> q <C-w>c
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
    let opened = 1
  elseif bufwinnr(sname) != -1
    execute bufwinnr(sname) 'wincmd w'
  else
    execute sp 'split'
    execute 'buffer' bufnr(sname)
    let opened = 1
  endif
  if opened
    call a:session.invoke_hook('outputter_buffer_opened')
  endif
  if &l:filetype !=# a:config.filetype
    let &l:filetype = a:config.filetype
  endif
  if exists('b:quickrun_running_mark')
    silent undo
    unlet b:quickrun_running_mark
  endif
endfunction

function! s:back_to_previous_window(...)
  let sweep_only = a:0 && a:1
  for tabnr in range(1, tabpagenr('$'))
    for winnr in range(1, tabpagewinnr(tabnr, '$'))
      let vars = gettabwinvar(tabnr, winnr, '')
      if has_key(vars, 'quickrun_outputter_buffer_prevwin')
        if !sweep_only
          call s:jump_to_window(tabnr, winnr)
        endif
        call remove(vars, 'quickrun_outputter_buffer_prevwin')
        return
      endif
    endfor
  endfor
endfunction

function! s:set_running_mark(mark)
  if a:mark !=# '' && !exists('b:quickrun_running_mark')
    let &undolevels = &undolevels  " split the undo block
    silent $ put =a:mark
    let b:quickrun_running_mark = 1
  endif
endfunction

function! s:is_empty_buffer()
  return line('$') == 1 && getline(1) =~ '^\s*$'
endfunction

function! s:jump_to_window(tabnr, winnr)
  if tabpagenr() != a:tabnr
    execute 'tabnext' a:tabnr
  endif
  if winnr() != a:winnr
    execute a:winnr 'wincmd w'
  endif
endfunction

function! s:escape_file_pattern(pat)
  return join(map(split(a:pat, '\zs'), '"[".v:val."]"'), '')
endfunction


function! quickrun#outputter#buffer#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
