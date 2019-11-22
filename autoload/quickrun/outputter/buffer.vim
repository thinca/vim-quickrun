" quickrun: outputter/buffer: Outputs to a vim buffer.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License


let s:outputter = {
\   'config': {
\     'bufname': 'quickrun://output',
\     'filetype': 'quickrun',
\     'append': 0,
\     'opener': '%{winwidth(0) * 2 < winheight(0) * 5 ? "split" : "vsplit"}',
\     'into': 0,
\     'running_mark': 'running...',
\     'close_on_empty': 0,
\   }
\ }

function s:outputter.init(session) abort
  let self._bufnr = 0
  let self._baseline = 0
endfunction

function s:outputter.start(session) abort
  let init = !self.config.append
  let self._bufnr = s:try_open_result_window(self, a:session, init, 0)
  if self._bufnr
    call s:set_running_mark(self._bufnr, self.config.running_mark)
  else
    let self._buffered = ''
  endif
endfunction

function s:outputter.output(data, session) abort
  if self._bufnr
    call s:output(self._bufnr, a:data)
  else
    let init = !self.config.append
    let self._bufnr = s:try_open_result_window(self, a:session, init, 0)
    if self._bufnr
      call s:output(self._bufnr, self._buffered . a:data)
      unlet self._buffered
    else
      let self._buffered .= a:data
    endif
  endif
  if self._bufnr
    call s:set_running_mark(self._bufnr, self.config.running_mark)
    call s:execute_in_result_window(self._bufnr, 'noautocmd normal! G')
  endif
endfunction

function s:outputter.finish(session) abort
  let config = self.config
  let should_close = 0
  if self._bufnr
    call s:remove_running_mark(self._bufnr)
    let should_close = config.close_on_empty && s:is_empty_buffer(self._bufnr)
  endif
  let into = config.into || should_close

  let cur_winid = win_getid()
  let bufnr = s:try_open_result_window(self, a:session, 0, into)

  if !bufnr
    " FIXME: Eventually, the result buffer could not be opened.
    return
  endif

  if self._baseline
    let cmd = printf('normal! %dGzt', self._baseline)
    call s:execute_in_result_window(self._bufnr, cmd)
  endif

  if should_close
    close
    call win_gotoid(cur_winid)
    redraw
    echohl MoreMsg
    echomsg 'quickrun: outputter/buffer: Empty output.'
    echohl NONE
  endif
endfunction

function s:try_open_result_window(outputter, session, clear, into) abort
  let cur_winid = win_getid()
  try
    let bufnr = s:open_result_window(a:outputter, a:session)
    if a:clear
      call s:clear_buffer(bufnr)
      let a:outputter._baseline = 1
    elseif a:outputter._baseline is# 0
      let a:outputter._baseline = line('$')
    endif
    return bufnr
  catch /^Vim([^)]\+):E11:/
    " When the user staying at cmdwin, cursor can not move to other window.
    " This is a common case and should be ignored.
    return 0
  catch
    echohl ErrorMsg
    echomsg v:exception
    echomsg v:throwpoint
    echohl NONE
    return 0
  finally
    if !a:into
      call win_gotoid(cur_winid)
    endif
  endtry
endfunction

function s:open_result_window(outputter, session) abort
  let config = a:outputter.config
  let opened = 0
  if bufexists(config.bufname)
    let bufnr = bufnr(s:escape_file_pattern(config.bufname))
    let wins = win_findbuf(bufnr)
    let tabnr = tabpagenr()
    call filter(map(wins, 'win_id2tabwin(v:val)'), 'v:val[0] is# tabnr')
    if empty(wins)
      execute config.opener fnameescape(config.bufname)
      let opened = 1
    else
      execute wins[0][1] 'wincmd w'
    endif
  else
    execute config.opener fnameescape(config.bufname)
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
    setlocal fileformat=unix
    let bufnr = bufnr('%')
    let opened = 1
  endif

  if opened
    call a:session.invoke_hook('outputter_buffer_opened')
  endif

  if &l:filetype !=# config.filetype
    let &l:filetype = config.filetype
  endif

  return bufnr
endfunction

function s:clear_buffer(bufnr) abort
  call deletebufline(a:bufnr, 1, '$')
  call setbufvar(a:bufnr, '&fileformat', 'unix')
  let ff_info = {'lf': 0, 'crlf': 0, 'cr': 0}
  call setbufvar(a:bufnr, 'quickrun_ff_info', ff_info)
endfunction

function s:escape_file_pattern(pat) abort
  return join(map(split(a:pat, '\zs'), '"[" . v:val . "]"'), '')
endfunction

function s:is_empty_buffer(bufnr) abort
  let lines = getbufline(a:bufnr, 1, 2)
  return len(lines) is# 1 && lines[0] is# ''
endfunction

function s:output(bufnr, data) abort
  call s:remove_running_mark(a:bufnr)
  let lines = s:adjust_fileformat(a:bufnr, a:data)
  let [lastline] = getbufline(a:bufnr, '$')
  let lines[0] = lastline . lines[0]
  call setbufline(a:bufnr, '$', lines)
endfunction

let s:breaks = {
\   'unix': "\n",
\   'dos': "\r\n",
\   'mac': "\r",
\ }
function s:adjust_fileformat(bufnr, data) abort
  let ff = getbufvar(a:bufnr, '&fileformat')
  let ff_info = getbufvar(a:bufnr, 'quickrun_ff_info')

  if a:data =~# "\r\n"
    let ff_info.crlf = 1
  endif
  if a:data =~# "[^\r]\n"
    let ff_info.lf = 1
  endif
  if a:data =~# "\r\\%([^\n]\\|$\\)"
    let ff_info.cr = 1
  endif

  if ff isnot# 'mac' && !ff_info.crlf && !ff_info.lf && ff_info.cr
    let new_ff = 'mac'
  elseif ff isnot# 'dos' && ff_info.crlf && !ff_info.lf && !ff_info.cr
    let new_ff = 'dos'
  elseif ff isnot# 'unix' && ff_info.lf
    let new_ff = 'unix'
    let lines = getbufline(a:bufnr, 1, '$')
    call deletebufline(a:bufnr, 1, '$')
    if ff is# 'mac'
      call setbufline(a:bufnr, 1, split(join(lines, "\r"), "\n", 1))
    elseif ff is# 'dos'
      let lastline = remove(lines, -1)
      call map(lines, 'v:val . "\r"')
      call setbufline(a:bufnr, 1, lines + [lastline])
    endif
  endif

  if exists('new_ff')
    let ff = new_ff
    call setbufvar(a:bufnr, '&fileformat', ff)
  endif

  return split(a:data, s:breaks[ff], 1)
endfunction

function s:set_running_mark(bufnr, mark) abort
  if a:mark is# '' || getbufvar(a:bufnr, 'quickrun_running_mark', 0)
    return
  endif
  call appendbufline(a:bufnr, '$', a:mark)
  call setbufvar(a:bufnr, 'quickrun_running_mark', 1)
endfunction

function s:remove_running_mark(bufnr) abort
  let vars = getbufvar(a:bufnr, '')
  if get(vars, 'quickrun_running_mark', 0)
    call deletebufline(a:bufnr, '$')
    call remove(vars, 'quickrun_running_mark')
  endif
endfunction

function s:execute_in_result_window(bufnr, cmd) abort
  for winid in win_findbuf(a:bufnr)
    call win_execute(winid, a:cmd)
  endfor
endfunction


function quickrun#outputter#buffer#new() abort
  return deepcopy(s:outputter)
endfunction
