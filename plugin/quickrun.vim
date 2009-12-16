" Run commands quickly.
" Version: 0.3.3
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
function! s:Runner.new(args)  " {{{2
  let obj = copy(self)
  call obj.initialize(a:args)
  return obj
endfunction



" ----------------------------------------------------------------------------
" Initialize of instance.
function! s:Runner.initialize(argline)  " {{{2
  let arglist = self.parse_argline(a:argline)
  let self.config = self.set_options_from_arglist(arglist)
  call self.normalize()
endfunction



function! s:Runner.parse_argline(argline)  " {{{2
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
  let config = {}
  let option = ''
  for arg in a:arglist
    if option != ''
      if has_key(config, option)
        if type(config[option]) == type([])
          call add(config[option], arg)
        else
          let newarg = [config[option], arg]
          unlet config[option]
          let config[option] = newarg
        endif
      else
        let config[option] = arg
      endif
      let option = ''
    elseif arg[0] == '-'
      let option = arg[1:]
    elseif arg[0] == '>'
      if arg[1] == '>'
        let config.append = 1
        let arg = arg[1:]
      endif
      let config.output = arg[1:]
    elseif arg[0] == '<'
      let config.input = arg[1:]
    else
      let config.type = arg
    endif
  endfor
  return config
endfunction



" ----------------------------------------------------------------------------
" The option is appropriately set referring to default options.
function! s:Runner.normalize()  " {{{2
  let config = self.config
  if !has_key(config, 'mode')
    let config.mode = histget(':') =~# "^'<,'>\\s*Q\\%[uickRun]" ? 'v' : 'n'
  endif

  if exists('b:quickrun_config')
    call extend(config, b:quickrun_config, 'keep')
  endif

  let config.type = get(config, 'type', &filetype)

  if has_key(g:quickrun_config, config.type)
    call extend(config, g:quickrun_config[config.type], 'keep')
  endif
  call extend(config, g:quickrun_config['*'], 'keep')

  if has_key(config, 'input')
    let input = config.input
    try
      let config.input = input[0] == '=' ? self.expand(input[1:])
      \                                  : join(readfile(input), "\n")
    catch
      throw 'quickrun: Can not treat input: ' . v:exception
    endtry
  else
    let config.input = ''
  endif

  let config.command = get(config, 'command', config.type)
  let config.start = get(config, 'start', 1)
  let config.end = get(config, 'end', line('$'))

  if has_key(config, 'src')
    if config.eval
      let config.src = printf(config.eval_template, config.src)
    endif
  else
    if !config.eval && config.mode ==# 'n' && filereadable(expand('%:p'))
          \ && config.start == 1 && config.end == line('$') && !&modified
      " Use file in direct.
      let config.src = bufnr('%')
    else
      " Executes on the temporary file.
      let body = self.get_region()

      if config.eval
        let body = printf(config.eval_template, body)
      endif

      let body = s:iconv(body, &enc, &fenc)

      if &l:ff ==# 'mac'
        let body = substitute(body, "\n", "\r", 'g')
      elseif &l:ff ==# 'dos'
        if !&l:bin
          let body .= "\n"
        endif
        let body = substitute(body, "\n", "\r\n", 'g')
      endif

      let config.src = body
    endif
  endif

  let self.source_name = self.get_source_name()
endfunction



" ----------------------------------------------------------------------------
" Run commands. Return the stdout.
function! s:Runner.run()  " {{{2
  let exec = get(self.config, 'exec', '')
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
function! s:Runner.execute(cmd)  " {{{2
  if a:cmd == ''
    throw 'command build Failed'
    return
  endif

  if a:cmd =~ '^\s*:'
    " A vim command.
    " XXX: Can't get a result if a:cmd contains :redir command.
    let result = ''
    redir => result
    silent execute a:cmd
    redir END
    return result
  endif

  let cmd = a:cmd
  let config = self.config
  if get(config, 'output') == '!'
    let in = config.input
    if in != ''
      let inputfile = tempname()
      call writefile(split(in, "\n"), inputfile)
      let cmd .= ' <' . shellescape(inputfile)
    endif

    execute s:iconv(printf(config.shellcmd, cmd), &encoding, &termencoding)

    if exists('inputfile') && filereadable(inputfile)
      call delete(inputfile)
    endif
    return 0
  endif

  let cmd = s:iconv(cmd, &encoding, &termencoding)
  let result = config.input == '' ? system(cmd)
  \                               : system(cmd, config.input)

  if get(config, 'output_encode', '') != ''
    let enc = split(self.expand(config.output_encode), '[^[:alnum:]-_]')
    if len(enc) == 2
      let [from, to] = enc
      let result = s:iconv(result, from, to)
    endif
  endif
  return result
endfunction



" ----------------------------------------------------------------------------
" Build a command to execute it from options.
function! s:Runner.build_command(tmpl)  " {{{2
  " TODO: Add rules.
  " FIXME: Possibility to be multiple expanded.
  let config = self.config
  let shebang = self.detect_shebang()
  let src = string(self.source_name)
  let rule = [
  \  ['c', shebang != '' ? string(shebang) : 'config.command'],
  \  ['s', src], ['S', src],
  \  ['a', 'config.args'],
  \  ['\%', string('%')],
  \]
  let file = ['s', 'S']
  let cmd = a:tmpl
  for [key, value] in rule
    if 0 <= index(file, key)
      let value = 'fnamemodify('.value.',submatch(1))'
      if key =~# '\U'
        let value = printf(config.command =~ '^\s*:' ? 'fnameescape(%s)'
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
  let src = self.config.src
  let line = type(src) == type('') ? matchstr(src, '^.\{-}\ze\(\n\|$\)'):
  \          type(src) == type(0)  ? getbufline(src, 1)[0]:
  \                                  ''
  return line =~ '^#!' ? line[2:] : ''
endfunction



" ----------------------------------------------------------------------------
" Return the source file name.
" Output to a temporary file if self.config.src is string.
function! s:Runner.get_source_name()  " {{{2
  let fname = expand('%')
  if exists('self.config.src')
    let src = self.config.src
    if type(src) == type('')
      if has_key(self, '_temp')
        let fname = self._temp
      else
        let fname = self.expand(self.config.tempfile)
        let self._temp = fname
        call writefile(split(src, "\n", 'b'), fname)
      endif
    elseif type(src) == type(0)
      let fname = expand('#'.src.':p')
    endif
  endif
  return fname
endfunction



" ----------------------------------------------------------------------------
" Get the text of specified region.
function! s:Runner.get_region()  " {{{2
  let mode = self.config.mode
  if mode ==# 'n'
    " Normal mode
    return join(getline(self.config.start, self.config.end), "\n")

  elseif mode ==# 'o'
    " Operation mode
    let vm = {
        \ 'line': 'V',
        \ 'char': 'v',
        \ 'block': "\<C-v>" }[self.config.visualmode]
    let [sm, em] = ['[', ']']
    let save_sel = &selection
    set selection=inclusive

  elseif mode ==# 'v'
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

  if mode ==# 'o'
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
function! s:Runner.expand(str)  " {{{2
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



function! s:Runner.output()
  let config = self.config
  let [out, to] = [config.output[:0], config.output[1:]]
  let append = config.append
  let running_mark = config.running_mark

  let result = self.result
  if out == ''
    " Output to the exclusive window.
    call self.open_result_window()
    if running_mark != ''
      silent undo
    endif
    if !append
      silent % delete _
    endif

    let cursor = getpos('$')
    silent $-1 put =result
    call setpos('.', cursor)
    silent normal! zt
    wincmd p

  elseif out == '!'
    " Do nothing.

  elseif out == ':'
    " Output to messages.
    if append
      for i in split(result, "\n")
        echomsg i
      endfor
    else
      echo result
    endif

  elseif out == '='
    " Output to variable.
    if to =~ '^\w[^:]'
      let to = 'g:' . to
    endif
    let assign = append && (to[0] =~ '\W' || exists(to)) ? '.=' : '='
    execute 'let' to assign 'result'

  else
    " Output to file.
    let size = strlen(result)
    if append && filereadable(out)
      let result = join(readfile(out, 'b'), "\n") . result
    endif
    call writefile(split(result, "\n"), out, 'b')
    echo printf('Output to %s: %d bytes', out, size)
  endif
endfunction




" ----------------------------------------------------------------------------
" Open the output buffer, and return the buffer number.
function! s:Runner.open_result_window()  " {{{2
  if !exists('s:bufnr')
    let s:bufnr = -1  " A number that doesn't exist.
  endif
  if !bufexists(s:bufnr)
    execute self.expand(self.config.split) 'split'
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



" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from ==# a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction



function! s:is_win()  " {{{2
  return has('win32') || has('win64')
endfunction



" MISC Functions. {{{1
" ----------------------------------------------------------------------------
" function for main command.
function! s:quickrun(args)  " {{{2
  try
    let runner = s:Runner.new(a:args)
    let config = runner.config

    if config.running_mark != '' && config.output == ''
      call runner.open_result_window()
      if !config.append
        silent % delete _
      endif
      silent $-1 put =config.running_mark
      normal! zt
      wincmd p
      redraw!
    endif

    if has_key(config, 'debug') && config.debug
      let g:runner = runner  " for debug
    endif

    let runner.result = runner.run()

    call runner.output()
  catch
    echoerr v:exception v:throwpoint
    return
  endtry
endfunction



" Function for |g@|.
function! QuickRun(mode)  " {{{2
  execute 'QuickRun -mode o -visualmode' a:mode
endfunction



function! s:quickrun_complete(lead, cmd, pos)  " {{{2
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
    let options = map(['type', 'src', 'input', 'output', 'append', 'command',
      \ 'exec', 'args', 'tempfile', 'shebang', 'eval', 'mode', 'split',
      \ 'output_encode', 'shellcmd', 'running_mark', 'eval_template'],
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
        \   'output': '',
        \   'append': 0,
        \   'args': '',
        \   'output_encode': '&fenc:&enc',
        \   'tempfile'  : '{tempname()}',
        \   'exec': '%c %s %a',
        \   'split': '{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
        \   'eval': 0,
        \   'eval_template': '%s',
        \   'shellcmd': s:is_win() ? 'silent !"%s" & pause' : '!%s',
        \   'running_mark': ':-)',
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
        \ 'go':
        \   $GOARCH ==# '386' ? {
        \     'exec':
        \       s:is_win() ?
        \         ['8g %s', '8l -o %s:p:r.exe %s:p:r.8', '%s:p:r.exe %a', 'del /F %s:p:r.exe'] :
        \         ['8g %s', '8l -o %s:p:r %s:p:r.8', '%s:p:r %a', 'rm -f %s:p:r']
        \   } :
        \   $GOARCH ==# 'amd64' ? {
        \     'exec': ['6g %s', '6l -o %s:p:r %s:p:r.6', '%s:p:r %a', 'rm -f %s:p:r'],
        \   } :
        \   $GOARCH ==# 'arm' ? {
        \     'exec': ['5g %s', '5l -o %s:p:r %s:p:r.5', '%s:p:r %a', 'rm -f %s:p:r'],
        \   } : {},
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
        \   'output_encode': '&tenc:&enc',
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
        \   'eval_template': join([
        \     'use Data::Dumper',
        \     '$Data::Dumper::Terse = 1',
        \     '$Data::Dumper::Indent = 0',
        \     'print Dumper eval{%s}'], ';')
        \ },
        \ 'python': {'eval_template': 'print(%s)'},
        \ 'php': {},
        \ 'r': {
        \   'command': 'R',
        \   'exec': '%c --no-save --slave %a < %s',
        \ },
        \ 'ruby': {'eval_template': " p proc {\n%s\n}.call"},
        \ 'scala': {
        \   'output_encode': '&tenc:&enc',
        \ },
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
endfunction

call s:init()

command! -nargs=* -range=% -complete=customlist,s:quickrun_complete QuickRun
\ call s:quickrun('-start <line1> -end <line2> ' . <q-args>)


nnoremap <silent> <Plug>(quickrun-op) :<C-u>set operatorfunc=QuickRun<CR>g@

silent! nnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode n<CR>
silent! vnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode v<CR>
" Default key mappings.
if !exists('g:quickrun_no_default_key_mappings')
\  || !g:quickrun_no_default_key_mappings
  silent! map <unique> <Leader>r <Plug>(quickrun)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
