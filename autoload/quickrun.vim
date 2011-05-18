" Run commands quickly.
" Version: 0.4.7
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:available_vimproc = globpath(&runtimepath, 'autoload/vimproc.vim') != ''
let s:is_win = has('win32') || has('win64')

function! s:is_cmd_exe()
  return &shell =~? 'cmd\.exe'
endfunction

unlet! g:quickrun#default_config  " {{{1
let g:quickrun#default_config = {
\ '_': {
\   'shebang': 1,
\   'output': '',
\   'outputter': 'buffer',
\   'append': 0,
\   'runmode': 'simple',
\   'runner': 'system',
\   'cmdopt': '',
\   'args': '',
\   'output_encode': '&fileencoding',
\   'tempfile'  : '{tempname()}',
\   'exec': '%c %o %s %a',
\   'split': '{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
\   'into': 0,
\   'eval': 0,
\   'eval_template': '%s',
\   'shellcmd': s:is_cmd_exe() ? 'silent !%s & pause ' : '!%s',
\   'running_mark': ':-)',
\ },
\ 'awk': {
\   'exec': '%c %o -f %s %a',
\ },
\ 'bash': {},
\ 'c': {
\   'type':
\     s:is_win && executable('cl') ? 'c/vc'  :
\     executable('gcc')            ? 'c/gcc' :
\     executable('clang')          ? 'c/clang' : '',
\ },
\ 'c/C': {
\   'command': 'C',
\   'exec': '%c %o -m %s',
\ },
\ 'c/clang': {
\   'command': 'clang',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.c',
\ },
\ 'c/gcc': {
\   'command': 'gcc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.c',
\ },
\ 'c/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\             '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
\   'tempfile': '{tempname()}.c',
\ },
\ 'cpp': {
\   'type':
\     s:is_win && executable('cl') ? 'cpp/vc'  :
\     executable('g++')            ? 'cpp/g++' : '',
\ },
\ 'cpp/C': {
\   'command': 'C',
\   'exec': '%c %o -p %s',
\ },
\ 'cpp/g++': {
\   'command': 'g++',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.cpp',
\ },
\ 'cpp/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\             '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
\   'tempfile': '{tempname()}.cpp',
\ },
\ 'dosbatch': {
\   'command': '',
\   'exec': 'call %s %a',
\   'tempfile': '{tempname()}.bat',
\ },
\ 'erlang': {
\   'command': 'escript',
\ },
\ 'eruby': {
\   'command': 'erb',
\   'exec': '%c %o -T - %s %a',
\ },
\ 'go': {
\   'type':
\     $GOARCH ==# '386'   ? (s:is_win ? 'go/386/win' : 'go/386'):
\     $GOARCH ==# 'amd64' ? 'go/amd64':
\     $GOARCH ==# 'arm'   ? 'go/arm': '',
\ },
\ 'go/386': {
\   'exec': ['8g %o -o %s:p:r.8 %s', '8l -o %s:p:r %s:p:r.8',
\            '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/386/win': {
\   'exec': ['8g %o -o %s:p:r.8 %s', '8l -o %s:p:r.exe %s:p:r.8',
\            '%s:p:r.exe %a', 'del /F %s:p:r.exe'],
\   'tempfile': '{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/amd64': {
\   'exec': ['6g %o -o %s:p:r.6 %s', '6l -o %s:p:r %s:p:r.6',
\            '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/arm': {
\   'exec': ['5g %o -o %s:p:r.5 %s', '5l -o %s:p:r %s:p:r.5',
\            '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'groovy': {
\   'cmdopt': '-c {&fenc==""?&enc:&fenc}'
\ },
\ 'haskell': {
\   'command': 'runghc',
\   'tempfile': '{tempname()}.hs',
\   'eval_template': 'main = print $ %s',
\ },
\ 'io': {},
\ 'java': {
\   'exec': ['javac %o %s', '%c %s:t:r %a', ':call delete("%S:t:r.class")'],
\   'output_encode': '&termencoding',
\ },
\ 'javascript': {
\   'type': executable('js') ? 'javascript/spidermonkey':
\           executable('d8') ? 'javascript/v8':
\           executable('node') ? 'javascript/nodejs':
\           executable('jrunscript') ? 'javascript/rhino':
\           executable('cscript') ? 'javascript/cscript': '',
\ },
\ 'javascript/cscript': {
\   'command': 'cscript',
\   'cmdopt': '//Nologo',
\   'tempfile': '{tempname()}.js',
\ },
\ 'javascript/rhino': {
\   'command': 'jrunscript',
\   'tempfile': '{tempname()}.js',
\ },
\ 'javascript/spidermonkey': {
\   'command': 'js',
\   'tempfile': '{tempname()}.js',
\ },
\ 'javascript/v8': {
\   'command': 'd8',
\   'tempfile': '{tempname()}.js',
\ },
\ 'javascript/nodejs': {
\   'command': 'node',
\   'tempfile': '{tempname()}.js',
\ },
\ 'lisp': {
\   'command': 'clisp',
\ },
\ 'llvm': {
\   'command': 'llvm-as %s -o=- | lli - %a',
\ },
\ 'lua': {},
\ 'markdown': {
\   'type': executable('Markdown.pl') ? 'markdown/Markdown.pl':
\           executable('kramdown') ? 'markdown/kramdown':
\           executable('bluecloth') ? 'markdown/bluecloth':
\           executable('pandoc') ? 'markdown/pandoc': '',
\ },
\ 'markdown/Markdown.pl': {
\   'command': 'Markdown.pl',
\ },
\ 'markdown/bluecloth': {
\   'command': 'bluecloth',
\   'cmdopt': '-f',
\ },
\ 'markdown/kramdown': {
\   'command': 'kramdown',
\ },
\ 'markdown/pandoc': {
\   'command': 'pandoc',
\   'cmdopt': '--from=markdown --to=html',
\ },
\ 'ocaml': {},
\ 'perl': {
\   'eval_template': join([
\     'use Data::Dumper',
\     '$Data::Dumper::Terse = 1',
\     '$Data::Dumper::Indent = 0',
\     'print Dumper eval{%s}'], ';')
\ },
\ 'perl6': {'eval_template': '{%s}().perl.print'},
\ 'python': {'eval_template': 'print(%s)'},
\ 'php': {},
\ 'r': {
\   'command': 'R',
\   'exec': '%c %o --no-save --slave %a < %s',
\ },
\ 'ruby': {'eval_template': " p proc {\n%s\n}.call"},
\ 'scala': {
\   'output_encode': '&termencoding',
\ },
\ 'scheme': {
\   'type': executable('gosh')     ? 'scheme/gauche':
\           executable('mzscheme') ? 'scheme/mzscheme': '',
\ },
\ 'scheme/gauche': {
\   'command': 'gosh',
\   'exec': '%c %o %s:p %a',
\   'eval_template': '(display (begin %s))',
\ },
\ 'scheme/mzscheme': {
\   'command': 'mzscheme',
\   'exec': '%c %o -f %s %a',
\ },
\ 'sed': {},
\ 'sh': {},
\ 'vim': {
\   'command': ':source',
\   'exec': '%c %s',
\   'eval_template': "echo %s",
\   'runmode': 'simple',
\   'runner': 'system',
\ },
\ 'wsh': {
\   'command': 'cscript',
\   'cmdopt': '//Nologo',
\ },
\ 'zsh': {},
\}
lockvar! g:quickrun#default_config


" Template of module.
let s:module = {}
function! s:module.available()
  try
    call self.validate()
  catch
    return 0
  endtry
  return 1
endfunction
function! s:module.validate()
endfunction
function! s:module.init(args, session)
endfunction
" Template of runner.
let s:runner = copy(s:module)
function! s:runner.run(commands, session)
  throw 'quickrun: A runner should implements run()'
endfunction
function! s:runner.sweep()
endfunction
function! s:runner.shellescape(str)
  if s:is_cmd_exe()
    return '^"' . substitute(substitute(substitute(a:str,
    \             '[&|<>()^"%]', '^\0', 'g'),
    \             '\\\+\ze"', '\=repeat(submatch(0), 2)', 'g'),
    \             '\ze\^"', '\', 'g') . '^"'
  endif
  return shellescape(a:str)
endfunction

" Template of outputter.
let s:outputter = copy(s:module)
function! s:outputter.output(data, session)
  throw 'quickrun: An outputter should implements output()'
endfunction
function! s:outputter.finish(session)
endfunction


" ----------------------------------------------------------------------------
let s:Session = {}  " {{{1
" Constructor.
function! s:Session.new(args)
  let obj = copy(self)
  call obj.initialize(a:args)
  return obj
endfunction

" Initialize of instance.
function! s:Session.initialize(config)
  let self.config = s:normalize(a:config)
  call self.setup()
endfunction

function! s:parse_argline(argline)
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

function! s:set_options_from_arglist(arglist)
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

" The option is appropriately set referring to default options.
function! s:normalize(config)
  let config = a:config
  if !has_key(config, 'mode')
    let config.mode = histget(':') =~# "^'<,'>\\s*Q\\%[uickRun]" ? 'v' : 'n'
  endif

  let type = {"type": &filetype}
  for c in [
  \ 'b:quickrun_config',
  \ 'type',
  \ 'g:quickrun_config[config.type]',
  \ 'g:quickrun#default_config[config.type]',
  \ 'g:quickrun_config["_"]',
  \ 'g:quickrun_config["*"]',
  \ 'g:quickrun#default_config["_"]',
  \ ]
    if exists(c)
      let new_config = eval(c)
      if 0 <= stridx(c, 'config.type')
        let config_type = ''
        while has_key(config, 'type')
        \   && has_key(new_config, 'type')
        \   && config.type !=# ''
        \   && config.type !=# config_type
          let config_type = config.type
          call extend(config, new_config, 'keep')
          let config.type = new_config.type
          let new_config = exists(c) ? eval(c) : {}
        endwhile
      endif
      call extend(config, new_config, 'keep')
    endif
  endfor

  if has_key(config, 'input')
    let input = quickrun#expand(config.input)
    try
      let config.input = input[0] == '=' ? input[1:]
      \                                  : join(readfile(input, 'b'), "\n")
    catch
      throw 'quickrun: Can not treat input: ' . v:exception
    endtry
  else
    let config.input = ''
  endif

  let config.command = get(config, 'command', config.type)
  let config.start = get(config, 'start', 1)
  let config.end = get(config, 'end', line('$'))

  let config.output = quickrun#expand(config.output)
  if config.output == '!'
    let config.runmode = 'simple'
  endif

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
      let body = s:get_region(config)

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

  for opt in ['cmdopt', 'args', 'split', 'running_mark', 'output_encode']
    let config[opt] = quickrun#expand(config[opt])
  endfor
  return config
endfunction

function! s:Session.setup()
  let self.runner = self.make_module('runner', self.config.runner)
  let self.outputter = self.make_module('outputter', self.config.outputter)

  let source_name = self.get_source_name()
  let exec = get(self.config, 'exec', '')
  let commands = type(exec) == type([]) ? copy(exec) : [exec]
  call filter(map(commands, 'self.build_command(source_name, v:val)'),
  \           'v:val =~ "\\S"')
  let self.commands = commands
endfunction

function! s:Session.make_module(kind, line)
  let [name; args] = split(a:line, ':', 1)
  if !has_key(s:registered_{a:kind}s, name)
    throw printf('quickrun: Specified %s is not registered: %s',
    \            a:kind, name)
  endif
  let module = deepcopy(s:registered_{a:kind}s[name])
  try
    call module.validate()
  catch
    throw printf("quickrun: Specified %s is not available: %s: %s",
    \            a:kind, name, v:exception)
  endtry
  call module.init(args, self)
  return module
endfunction

" Run commands.
function! s:Session.run()
  call self.runner.run(self.commands, self)
  if !has_key(self, '_continue_key')
    call self.finish()
  endif
endfunction

function! s:Session.continue()
  let self._continue_key = s:save_session(self)
  return self._continue_key
endfunction

function! s:Session.output(data)
  if a:data != ''
    let data = a:data
    if get(self.config, 'output_encode', '') != ''
      let enc = split(self.config.output_encode, '[^[:alnum:]-_]')
      if len(enc) == 1
        let enc += [&encoding]
      endif
      if len(enc) == 2
        let [from, to] = enc
        let data = s:iconv(data, from, to)
      endif
    endif
    call self.outputter.output(data, self)
  endif
endfunction

function! s:Session.finish()
  call self.outputter.finish(self)
  call quickrun#sweep(self)
endfunction

" Build a command to execute it from options.
function! s:Session.build_command(source_name, tmpl)
  " FIXME: Possibility to be multiple expanded.
  let config = self.config
  let shebang = config.shebang ? self.detect_shebang() : ''
  let src = string(a:source_name)
  let command = shebang != '' ? string(shebang) : 'config.command'
  let rule = [
  \  ['c', command], ['C', command],
  \  ['s', src], ['S', src],
  \  ['o', 'config.cmdopt'],
  \  ['a', 'config.args'],
  \  ['\%', string('%')],
  \]
  let is_file = '[' . (shebang != '' ? 's' : 'cs') . ']'
  let cmd = a:tmpl
  for [key, value] in rule
    if key =~? is_file
      let value = 'fnamemodify('.value.',submatch(1))'
      if key =~# '\U'
        let value = printf(config.command =~ '^\s*:' ? 'fnameescape(%s)'
          \ : 'self.runner.shellescape(%s)', value)
      endif
      let key .= '(%(\:[p8~.htre]|\:g?s(.).{-}\2.{-}\2)*)'
    endif
    let cmd = substitute(cmd, '\C\v[^%]?\zs\%' . key, '\=' . value, 'g')
  endfor
  return substitute(quickrun#expand(cmd), '[\r\n]\+', ' ', 'g')
endfunction

" Detect the shebang, and return the shebang command if it exists.
function! s:Session.detect_shebang()
  let src = self.config.src
  let line = type(src) == type('') ? matchstr(src, '^.\{-}\ze\(\n\|$\)'):
  \          type(src) == type(0)  ? getbufline(src, 1)[0]:
  \                                  ''
  return line =~ '^#!' ? line[2:] : ''
endfunction

" Return the source file name.
" Output to a temporary file if self.config.src is string.
function! s:Session.get_source_name()
  let fname = expand('%')
  if exists('self.config.src')
    let src = self.config.src
    if type(src) == type('')
      if has_key(self, '_temp_source')
        let fname = self._temp_source
      else
        let fname = quickrun#expand(self.config.tempfile)
        let self._temp_source = fname
        call writefile(split(src, "\n", 1), fname, 'b')
      endif
    elseif type(src) == type(0)
      let fname = expand('#'.src.':p')
    endif
  endif
  return fname
endfunction

" Get the text of specified region.
function! s:get_region(config)
  let mode = a:config.mode
  if mode ==# 'n'
    " Normal mode
    return join(getline(a:config.start, a:config.end), "\n")

  elseif mode ==# 'o'
    " Operation mode
    let vm = {
        \ 'line': 'V',
        \ 'char': 'v',
        \ 'block': "\<C-v>" }[a:config.visualmode]
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

" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from ==# a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

" ----------------------------------------------------------------------------
let s:registered_runners = {}
let s:registered_outputters = {}

function! quickrun#register_runner(name, runner)
  return s:register_module(a:name, 'runner', a:runner)
endfunction

function! quickrun#register_outputter(name, outputter)
  return s:register_module(a:name, 'outputter', a:outputter)
endfunction

function! s:register_module(name, kind, module)
  " TODO: validate
  let module = extend(deepcopy(s:{a:kind}), a:module)
  let module.name = a:name
  let s:registered_{a:kind}s[a:name] = module
endfunction

" ----------------------------------------------------------------------------
" Interfaces.  {{{1
" function for main command.
function! quickrun#run(config)
  call s:sweep_sessions()

  let session = s:Session.new(a:config)
  let config = session.config

  if has_key(config, 'debug') && config.debug
    let g:runner = session  " for debug
  endif

  call session.run()
endfunction

" function for main command.
function! quickrun#command(argline)
  try
    let arglist = s:parse_argline(a:argline)
    let config = s:set_options_from_arglist(arglist)
    call quickrun#run(config)
  catch /^quickrun:/
    echohl ErrorMsg
    for line in split(v:exception, "\n")
      echomsg line
    endfor
    echohl None
  endtry
endfunction

function! quickrun#complete(lead, cmd, pos)
  let line = split(a:cmd[:a:pos - 1], '', 1)
  let head = line[-1]
  if 2 <= len(line) && line[-2] =~ '^-'
    let opt = line[-2][1:]
    if opt !=# 'type'
      let list = []
      if opt ==# 'append' || opt ==# 'shebang' || opt ==# 'into'
        let list = ['0', '1']
      elseif opt ==# 'mode'
        let list = ['n', 'v', 'o']
      elseif opt ==# 'runner'
        let list = keys(s:registered_runners)
      elseif opt ==# 'outputter'
        let list = keys(s:registered_outputters)
      end
      return filter(list, 'v:val =~ "^".a:lead')
    endif
  elseif head =~ '^-'
    let options = map(['type', 'src', 'input', 'outputter', 'append', 'command',
      \ 'exec', 'cmdopt', 'args', 'tempfile', 'shebang', 'eval', 'mode',
      \ 'runner', 'split', 'into', 'output_encode', 'shellcmd',
      \ 'running_mark', 'eval_template'], '"-".v:val')
    return filter(options, 'v:val =~ "^".head')
  end
  let types = keys(extend(exists('g:quickrun_config') ?
  \                copy(g:quickrun_config) : {}, g:quickrun#default_config))
  return filter(types, 'v:val !~ "^[_*]$" && v:val =~ "^".a:lead')
endfunction


let s:sessions = {}  " Store for sessions.

function! s:save_session(session)
  let key = has('reltime') ? reltimestr(reltime()) : string(localtime())
  let s:sessions[key] = a:session
  return key
endfunction

function! quickrun#get_session(key)
  return get(s:sessions, a:key, {})
endfunction

function! s:dispose_session(key)
  if has_key(s:sessions, a:key)
    call quickrun#sweep(remove(s:sessions, a:key))
  endif
endfunction

function! s:sweep_sessions()
  call map(keys(s:sessions), 's:dispose_session(v:val)')
endfunction


" Expand the keyword.
" - @register @{register}
" - &option &{option}
" - $ENV_NAME ${ENV_NAME}
" - {expr}
" Escape by \ if you does not want to expand.
function! quickrun#expand(str)
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
      if e < 0
        break
      endif
      try
        let result .= eval(expr)
      catch
      endtry
      let rest = rest[e :]
    endif
  endwhile
  return result
endfunction

" Sweep the session.
function! quickrun#sweep(session)
  " Remove temporary files.
  for file in filter(keys(a:session), 'v:val =~# "^_temp"')
    if filewritable(a:session[file])
      call delete(a:session[file])
    endif
    call remove(a:session, file)
  endfor

  " Restore options.
  for opt in filter(keys(a:session), 'v:val =~# "^_option_"')
    let optname = matchstr(opt, '^_option_\zs.*')
    if exists('+' . optname)
      execute 'let'  '&' . optname '= a:session[opt]'
    endif
    call remove(a:session, opt)
  endfor

  " Delete autocmds.
  for cmd in filter(keys(a:session), 'v:val =~# "^_autocmd_"')
    execute 'autocmd!' 'plugin-quickrun-' . a:session[cmd]
    call remove(a:session, cmd)
  endfor

  " Sweep the execution of vimproc.
  if has_key(a:session, '_vimproc')
    try
      call a:session._vimproc.kill(15)
      call a:session._vimproc.waitpid()
    catch
    endtry
    call remove(a:session, '_vimproc')
  endif

  if has_key(a:session, '_continue_key')
    if has_key(s:sessions, a:session._continue_key)
      call remove(s:sessions, a:session._continue_key)
    endif
    call remove(a:session, '_continue_key')
  endif

  call a:session.runner.sweep()
endfunction

" Execute commands by expr.  This is used by remote_expr()
function! quickrun#execute(...)
  " XXX: Can't get a result if a:cmd contains :redir command.
  let result = ''
  try
    redir => result
    for cmd in a:000
      silent execute cmd
    endfor
  finally
    redir END
  endtry
  return result
endfunction

function! s:register_defaults(kind)
  let pat = 'autoload/quickrun/' . a:kind . '/*.vim'
  for name in map(split(globpath(&runtimepath, pat), "\n"),
  \               'fnamemodify(v:val, ":t:r")')
    try
      call s:register_module(name, a:kind, quickrun#{a:kind}#{name}#new())
    catch /:E\%(117\|716\):/
    endtry
  endfor
endfunction

call s:register_defaults('runner')
call s:register_defaults('outputter')


let &cpo = s:save_cpo
