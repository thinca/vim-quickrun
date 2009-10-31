" Run commands quickly.
" Version: 0.2.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_quickrun') || v:version < 702
  finish
endif
let g:loaded_quickrun = 1

let s:save_cpo = &cpo
set cpo&vim

let s:Runner = {}

" ----------------------------------------------------------------------------
" Constructor.
function! s:Runner.new(args) " {{{2
  let obj = extend({}, self)
  call obj.initialize(a:args)
  return obj
endfunction

" ----------------------------------------------------------------------------
" Initialize of instance.
function! s:Runner.initialize(argline) " {{{2
  let arglist = self.parse_argline(a:argline)
  call self.set_options_from_arglist(arglist)
  call self.normalize()
endfunction



function! s:Runner.parse_argline(argline) " {{{2
  " foo 'bar buz' "hoge \"huga"
  " => ['foo', 'bar buz', 'hoge "huga']
  " TODO: More improve.
  " ex:
  " foo ba'r b'uz "hoge \nhuga"
  " => ['foo, 'bar buz', "hoge \nhuga"]
  let argline = a:argline
  let arglist = []
  while argline !~ '^\s*$'
    let argline = matchstr(argline, '^\s*\zs.*$')
    if argline[0] =~ '[''"]'
      let arg = matchstr(argline, '\v([''"])\zs.{-}\ze\\@<!\1')
      let argline = argline[strlen(arg) + 2 :]
    else
      let arg = matchstr(argline, '\S\+')
      let argline = argline[strlen(arg) :]
    endif
    let arg = substitute(arg, '\\\(.\)', '\1', 'g')
    call add(arglist, arg)
  endwhile

  return arglist
endfunction



function! s:Runner.set_options_from_arglist(arglist)
  let option = ''
  for arg in a:arglist
    if option != ''
      if has_key(self, option)
        if type(self[option]) == type([])
          call add(self[option], arg)
        else
          let newarg = [self[option], arg]
          unlet self[option]
          let self[option] = newarg
        endif
      else
        let self[option] = arg
      endif
      let option = ''
    elseif arg[0] == '-'
      let option = arg[1:]
    elseif arg[0] == '>'
      if arg[1] == '>'
        let self.append = 1
        let arg = arg[1:]
      endif
      let self.output = arg[1:]
    elseif arg[0] == '<'
      let self.input = arg[1:]
    else
      let self.type = arg
    endif
  endfor
endfunction

" ----------------------------------------------------------------------------
" The option is appropriately set referring to default options.
function! s:Runner.normalize() " {{{2
  if !has_key(self, 'mode')
    if histget(':') =~ "^'<,'>\\s*Q\\%[uickRun]"
      let self.mode = 'v'
    else
      let self.mode = 'n'
    endif
  endif

  if exists('b:quickrun_config')
    call extend(self, b:quickrun_config, 'keep')
  endif

  let self.type = get(self, 'type', &filetype)

  if has_key(g:quickrun_config, self.type)
    call extend(self, g:quickrun_config[self.type], 'keep')
  endif
  call extend(self, g:quickrun_config['*'], 'keep')

  if has_key(self, 'input')
    let input = self.input
    try
      if input[0] == '='
        let self.input = self.expand(input[1:])
      else
        let self.input = join(readfile(input), "\n")
      endif
    catch
      throw 'quickrun:Can not treat input:' . v:exception
    endtry
  endif

  let self.command = get(self, 'command', self.type)
  let self.start = get(self, 'start', 1)
  let self.end = get(self, 'end', line('$'))
  let self.output = get(self, 'output', '')

  if !exists('self.src')
    if self.mode == 'n' && filereadable(expand('%:p'))
          \ && self.start == 1 && self.end == line('$') && !&modified
      " Use file in direct.
      let self.src = bufnr('%')
    else
      " Executes on the temporary file.
      let body = self.get_region()

      if self.eval
        let body = printf(self.eval_template, body)
      endif

      let conv = iconv(body, &enc, &fenc)
      if conv != ''
        let body = conv
      endif

      if &l:ff == 'mac'
        let body = substitute(body, "\n", "\r", 'g')
      elseif &l:ff == 'dos'
        if !&l:bin
          let body .= "\n"
        endif
        let body = substitute(body, "\n", "\r\n", 'g')
      endif

      let self.src = body
    endif
  end
endfunction

" ----------------------------------------------------------------------------
" Run commands. Return the stdout.
function! s:Runner.run() " {{{2
  let exec = get(self, 'exec', '')
  let result = ''

  try
    for i in type(exec) == type([]) ? exec : [exec]
      let cmd = self.build_command(i)
      let result .= self.execute(cmd)
      if v:shell_error != 0
        break
      endif
    endfor
  finally
    if has_key(self, '_temp') && filereadable(self._temp)
      call delete(self._temp)
      unlet self._temp
    endif
  endtry
  return result
endfunction

" ----------------------------------------------------------------------------
" Execute a single command.
function! s:Runner.execute(cmd) " {{{2
  if a:cmd == ''
    throw 'command build Failed'
    return
  endif

  if a:cmd =~ '^\s*:'
    let result = ''
    redir => result
    silent execute a:cmd
    redir END
    return result
  endif

  let cmd = a:cmd
  if get(self, 'output') is '!'
    let in = get(self, 'input', '')
    if in != ''
      let inputfile = tempname()
      call writefile(split(in, "\n"), inputfile)
      let cmd .= ' <' . shellescape(inputfile)
    endif

    execute printf(self.shellcmd, cmd)

    if exists('inputfile') && filereadable(inputfile)
      call delete(inputfile)
    endif
    return 0
  else
    if has_key(self, 'input') && self.input != ''
      let result = system(cmd, self.input)
    else
      let result = system(cmd)
    endif
    if get(self, 'output_encode', '') != ''
      let enc = split(self.expand(self.output_encode), '[^[:alnum:]-_]')
      if len(enc) == 2
        let [from, to] = enc
        let trans = iconv(result, from, to)
        if trans != ''
          let result = trans
        endif
      endif
    endif
    return result
  endif
endfunction

" ----------------------------------------------------------------------------
" Build a command to execute it from options.
function! s:Runner.build_command(tmpl) " {{{2
  " TODO Add rules.
  let shebang = self.detect_shebang()
  let src = string(self.get_source_name())
  let rule = [
        \ ['c', shebang != '' ? string(shebang) : 'self.command'],
        \ ['s', src], ['S', src],
        \ ['a', 'get(self, "args", "")'],
        \ ['\%', string('%')],
        \ ]
  let file = ['s', 'S']
  let cmd = a:tmpl
  for [key, value] in rule
    if 0 <= index(file, key)
      let value = 'fnamemodify('.value.',submatch(1))'
      if key =~# '\U'
        let value = printf(self.command =~ '^\s*:' ? 'fnameescape(%s)'
          \ : 'shellescape(%s)', value)
      endif
      let key .= '(%(\:[p8~.htre]|\:g?s(.).{-}\2.{-}\2)*)'
    endif
    let cmd = substitute(cmd, '\C\v[^%]?\zs\%' . key, '\=' . value, 'g')
  endfor
  return self.expand(cmd)
endfunction

" ----------------------------------------------------------------------------
" Detect the shebang, and return the shebang command if it exists.
function! s:Runner.detect_shebang()
  if type(self.src) == type('')
    let line = matchstr(self.src, '^.\{-}\ze\(\n\|$\)')
  elseif type(self.src) == type(0)
    let line = getbufline(self.src, 1)[0]
  endif
  if line =~ '^#!' && executable(matchstr(line[2:], '^[^[:space:]]\+'))
    return line[2:]
  endif
  return ''
endfunction

" ----------------------------------------------------------------------------
" Return the source file name.
" Output to a temporary file if self.src is string.
function! s:Runner.get_source_name() " {{{2
  let fname = expand('%')
  if exists('self.src')
    if type(self.src) == type('')
      if has_key(self, '_temp')
        let fname = self._temp
      else
        let fname = self.expand(self.tempfile)
        let self._temp = fname
        call writefile(split(self.src, "\n", 'b'), fname)
      endif
    elseif type(self.src) == type(0)
      let fname = expand('#'.self.src.':p')
    endif
  endif
  return fname
endfunction

" ----------------------------------------------------------------------------
" Get the text of specified region.
function! s:Runner.get_region() " {{{2
  if self.mode == 'n'
    " Normal mode
    return join(getline(self.start, self.end), "\n")

  elseif self.mode == 'o'
    " Operation mode
    let vm = {
        \ 'line': 'V',
        \ 'char': 'v',
        \ 'block': "\<C-v>" }[self.visualmode]
    let [sm, em] = ['[', ']']
    let save_sel = &selection
    set selection=inclusive

  elseif self.mode == 'v'
    " Visual mode
    let [vm, sm, em] = [visualmode(), '<', '>']

  else
    return ''
  end

  let [reg_save, reg_save_type] = [getreg(), getregtype()]
  let [pos_c, pos_s, pos_e] = [getpos('.'), getpos("'<"), getpos("'>")]

  execute 'silent normal! `' . sm . vm . '`' . em . 'y'

  " Restore '< '>
  call setpos('.', pos_s)
  execute 'normal!' vm
  call setpos('.', pos_e)
  execute 'normal!' vm
  call setpos('.', pos_c)

  let selected = @"

  call setreg(v:register, reg_save, reg_save_type)

  if self.mode == 'o'
    let &selection = save_sel
  endif
  return selected
endfunction

" ----------------------------------------------------------------------------
" Expand the keyword.
" - @register @{register}
" - &option &{option}
" - $ENV_NAME ${ENV_NAME}
" - {expr}
" Escape by \ if you does not want to expand.
function! s:Runner.expand(str) " {{{2
  if type(a:str) != type('')
    return ''
  endif
  let i = 0
  let rest = a:str
  let result = ''
  while 1
    let f = match(rest, '\\\?[@&${]')
    if f < 0
      let result .= rest
      break
    endif

    if f != 0
      let result .= rest[: f - 1]
      let rest = rest[f :]
    endif

    if rest[0] == '\'
      let result .= rest[1]
      let rest = rest[2 :]
    else
      if rest =~ '^[@&$]{'
        let rest = rest[1] . rest[0] . rest[2 :]
      endif
      if rest[0] == '@'
        let e = 2
        let expr = rest[0 : 1]
      elseif rest =~ '^[&$]'
        let e = matchend(rest, '.\w\+')
        let expr = rest[: e - 1]
      else  " rest =~ '^{'
        let e = matchend(rest, '\\\@<!}')
        let expr = substitute(rest[1 : e - 2], '\\}', '}', 'g')
      endif
      let result .= eval(expr)
      let rest = rest[e :]
    endif
  endwhile
  return result
endfunction

" ----------------------------------------------------------------------------
" Open the output buffer, and return the buffer number.
function! s:Runner.open_result_window() " {{{2
  if !exists('s:bufnr')
    let s:bufnr = -1 " A number that doesn't exist.
  endif
  if !bufexists(s:bufnr)
    execute self.expand(self.split) 'split'
    edit `='[quickrun Output]'`
    let s:bufnr = bufnr('%')
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
    setlocal filetype=quickrun
  elseif bufwinnr(s:bufnr) != -1
    execute bufwinnr(s:bufnr) 'wincmd w'
  else
    execute 'sbuffer' s:bufnr
  endif
endfunction

function! s:is_win() " {{{2
  return has('win32') || has('win64')
endfunction

" MISC Functions. {{{1
" ----------------------------------------------------------------------------
" function for main command.
function! s:quickrun(args) " {{{2
  try
    let runner = s:Runner.new(a:args)
    " let g:runner = runner " for debug
    let result = runner.run()
    let runner.result = result
  catch
    echoerr v:exception v:throwpoint
    return
  endtry

  let out = get(runner, 'output')
  let append = get(runner, 'append')
  if out is ''
    " Output to the exclusive window.
    call runner.open_result_window()
    if !append
      silent % delete _
    endif

    let cursor = getpos('$')
    call append(line('$') - 1, split(result, "\n", 1))
    call setpos('.', cursor)
    normal! zt
    wincmd p
  elseif out is '!'
    " Do nothing.
  elseif out is ':'
    if append
      for i in split(result, "\n")
        echomsg i
      endfor
    else
      echo result
    endif
  elseif out[0] == '='
    let out = out[1:]
    if out =~ '^\w[^:]'
      let out = 'g:' . out
    endif
    if append && (out[0] =~ '\W' || exists(out))
      execute 'let' out '.= result'
    else
      execute 'let' out '= result'
    endif
  else
    let size = strlen(result)
    if append && filereadable(out)
      let result = join(readfile(out, 'b'), "\n") . result
    endif
    call writefile(split(result, "\n"), out, 'b')
    echo printf('Output to %s: %d bytes', out, size)
  endif
endfunction

" Function for |g@|.
function! QuickRun(mode) " {{{2
  execute 'QuickRun -mode o -visualmode' a:mode
endfunction

function! s:quickrun_complete(lead, cmd, pos) " {{{2
  let line = split(a:cmd[:a:pos], '', 1)
  let head = line[-1]
  if 2 <= len(line) && line[-2] =~ '^-'
    let opt = line[-2][1:]
    if opt ==# 'type'
    elseif opt ==# 'append' || opt ==# 'shebang'
      return ['0', '1']
    elseif opt ==# 'mode'
      return ['n', 'v', 'o']
    else
      return []
    end
  elseif head =~ '^-'
    let options = map(['type', 'src', 'input', 'output', 'append',
      \ 'command', 'exec', 'args', 'tempfile', 'shebang', 'eval',
      \ 'mode', 'split', 'output_encode', 'shellcmd', 'eval_template'],
      \ '"-".v:val')
    return filter(options, 'v:val =~ "^".head')
  end
  return filter(keys(g:quickrun_config), 'v:val != "*" && v:val =~ "^".a:lead')
endfunction

" ----------------------------------------------------------------------------
" Initialize. {{{1
function! s:init()
  if !exists('g:quickrun_config')
    let g:quickrun_config = {}
  endif

  let default_config = {
        \ '*': {
        \   'shebang': 1,
        \   'output_encode': '&fenc:&enc',
        \   'tempfile'  : '{tempname()}',
        \   'exec': '%c %s %a',
        \   'split': '{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
        \   'eval': 0,
        \   'eval_template': '%s',
        \   'shellcmd': s:is_win() ? 'silent !"%s" & pause' : '!%s',
        \ },
        \ 'awk': {
        \   'exec': '%c -f %s %a',
        \ },
        \ 'bash': {},
        \ 'c':
        \   s:is_win() && executable('cl') ? {
        \     'command': 'cl',
        \     'exec': ['%c %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
        \               '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
        \     'tempfile': '{tempname()}.c',
        \   } :
        \   executable('gcc') ? {
        \     'command': 'gcc',
        \     'exec': ['%c %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
        \     'tempfile': '{tempname()}.c',
        \   } : {},
        \ 'cpp':
        \   s:is_win() && executable('cl') ? {
        \     'command': 'cl',
        \     'exec': ['%c %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
        \               '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
        \     'tempfile': '{tempname()}.cpp',
        \   } :
        \   executable('g++') ? {
        \     'command': 'g++',
        \     'exec': ['%c %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
        \     'tempfile': '{tempname()}.cpp',
        \   } : {},
        \ 'eruby': {
        \   'command': 'erb',
        \   'exec': '%c -T - %s %a',
        \ },
        \ 'groovy': {
        \   'exec': '%c -c {&fenc==""?&enc:&fenc} %s %a',
        \ },
        \ 'haskell': {
        \   'command': 'runghc',
        \   'tempfile': '{tempname()}.hs',
        \   'eval_template': 'main = print $ %s',
        \ },
        \ 'java': {
        \   'exec': ['javac %s', '%c %s:t:r', ':call delete("%S:t:r.class")'],
        \ },
        \ 'javascript': {
        \   'command': executable('js') ? 'js':
        \              executable('jrunscript') ? 'jrunscript':
        \              executable('cscript') ? 'cscript': '',
        \   'tempfile': '{tempname()}.js',
        \ },
        \ 'lua': {},
        \ 'dosbatch': {
        \   'command': '',
        \   'exec': 'call %s %a',
        \   'tempfile': '{tempname()}.bat',
        \ },
        \ 'io': {},
        \ 'ocaml': {},
        \ 'perl': {
        \   'eval_template':
        \     'print eval{use Data::Dumper;$Data::Dumper::Terse = 1;$Data::Dumper::Indent = 0;Dumper %s}'
        \ },
        \ 'python': {'eval_template': 'print(%s)'},
        \ 'php': {},
        \ 'r': {
        \   'command': 'R',
        \   'exec': '%c --no-save --slave %a < %s',
        \ },
        \ 'ruby': {'eval_template': " p proc {\n%s\n}.call"},
        \ 'scala': {},
        \ 'scheme': {
        \   'command': 'gosh',
        \   'exec': '%c %s:p %a',
        \   'eval_template': '(display (begin %s))',
        \ },
        \ 'sed': {},
        \ 'sh': {},
        \ 'vim': {
        \   'command': ':source',
        \   'exec': '%c %s',
        \   'eval_template': "echo %s",
        \ },
        \ 'zsh': {},
        \}

  if type(g:quickrun_config) == type({})
    for [key, value] in items(g:quickrun_config)
      if !has_key(default_config, key)
        let default_config[key] = value
      else
        call extend(default_config[key], value)
      endif
    endfor
  endif
  unlet! g:quickrun_config
  let g:quickrun_config = default_config

  " Default key mappings.
  silent! nnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode n ><CR>
  silent! vnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode v ><CR>
  if !exists('g:quickrun_no_default_key_mappings')
  \  || !g:quickrun_no_default_key_mappings
    silent! map <unique> <Leader>r <Plug>(quickrun)
  endif
endfunction

call s:init()

command! -nargs=* -range=% -complete=customlist,s:quickrun_complete QuickRun
\ call s:quickrun('-start <line1> -end <line2> ' . <q-args>)

nnoremap <silent> <Plug>(quickrun-op) :<C-u>set operatorfunc=QuickRun<CR>g@

let &cpo = s:save_cpo
unlet s:save_cpo
