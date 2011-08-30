" Run commands quickly.
" Version: 0.5.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('quickrun').load('Data.List')
call s:V.import('Data.String', s:V)
unlet! g:quickrun#V
let g:quickrun#V = s:V
lockvar! g:quickrun#V

let s:is_win = s:V.is_windows()

function! s:is_cmd_exe()
  return &shell =~? 'cmd\.exe'
endfunction

" Default config.  " {{{1
unlet! g:quickrun#default_config
let g:quickrun#default_config = {
\ '_': {
\   'shebang': 1,
\   'outputter': 'buffer',
\   'runner': 'system',
\   'cmdopt': '',
\   'args': '',
\   'output_encode': '&fileencoding',
\   'tempfile'  : '%{tempname()}',
\   'exec': '%c %o %s %a',
\   'eval': 0,
\   'eval_template': '%s',
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
\   'tempfile': '%{tempname()}.c',
\ },
\ 'c/gcc': {
\   'command': 'gcc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '%{tempname()}.c',
\ },
\ 'c/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\             '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
\   'tempfile': '%{tempname()}.c',
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
\   'tempfile': '%{tempname()}.cpp',
\ },
\ 'cpp/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\             '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
\   'tempfile': '%{tempname()}.cpp',
\ },
\ 'dosbatch': {
\   'command': '',
\   'exec': 'call %s %a',
\   'tempfile': '%{tempname()}.bat',
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
\   'tempfile': '%{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/386/win': {
\   'exec': ['8g %o -o %s:p:r.8 %s', '8l -o %s:p:r.exe %s:p:r.8',
\            '%s:p:r.exe %a', 'del /F %s:p:r.exe'],
\   'tempfile': '%{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/amd64': {
\   'exec': ['6g %o -o %s:p:r.6 %s', '6l -o %s:p:r %s:p:r.6',
\            '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '%{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'go/arm': {
\   'exec': ['5g %o -o %s:p:r.5 %s', '5l -o %s:p:r %s:p:r.5',
\            '%s:p:r %a', 'rm -f %s:p:r'],
\   'tempfile': '%{tempname()}.go',
\   'output_encode': 'utf-8',
\ },
\ 'groovy': {
\   'cmdopt': '-c %{&fenc==#""?&enc:&fenc}'
\ },
\ 'haskell': {
\   'command': 'runghc',
\   'tempfile': '%{tempname()}.hs',
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
\           executable('phantomjs') ? 'javascript/phantomjs':
\           executable('jrunscript') ? 'javascript/rhino':
\           executable('cscript') ? 'javascript/cscript': '',
\ },
\ 'javascript/cscript': {
\   'command': 'cscript',
\   'exec': '%c //e:jscript %o %s %a',
\   'cmdopt': '//Nologo',
\   'tempfile': '%{tempname()}.js',
\ },
\ 'javascript/rhino': {
\   'command': 'jrunscript',
\   'tempfile': '%{tempname()}.js',
\ },
\ 'javascript/spidermonkey': {
\   'command': 'js',
\   'tempfile': '%{tempname()}.js',
\ },
\ 'javascript/v8': {
\   'command': 'd8',
\   'tempfile': '%{tempname()}.js',
\ },
\ 'javascript/nodejs': {
\   'command': 'node',
\   'tempfile': '%{tempname()}.js',
\ },
\ 'javascript/phantomjs': {
\   'command': 'phantomjs',
\   'tempfile': '%{tempname()}.js',
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
\   'exec': '%C %s',
\   'eval_template': "echo %s",
\   'runner': 'system',
\ },
\ 'wsh': {
\   'command': 'cscript',
\   'cmdopt': '//Nologo',
\ },
\ 'zsh': {},
\}
lockvar! g:quickrun#default_config


" Modules.  {{{1
" Template of module.  {{{2
let s:module = {'config': {}, 'config_order': []}
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
function! s:module.build(configs)
  for config in a:configs
    if type(config) == type({})
      for name in keys(self.config)
        for conf in [self.kind . '/' . self.name . '/' . name,
        \            self.kind . '/' . name,
        \            name]
          if has_key(config, conf)
            let self.config[name] = config[conf]
            break
          endif
        endfor
      endfor
    elseif type(config) == type('') && config !=# ''
      call self.parse_option(config)
    endif
    unlet config
  endfor
endfunction
function! s:module.parse_option(argline)
  let sep = a:argline[0]
  let args = split(a:argline[1:], '\V' . escape(sep, '\'))
  let order = copy(self.config_order)
  for arg in args
    let name = matchstr(arg, '^\w\+\ze=')
    if !empty(name)
      let value = matchstr(arg, '^\w\+=\zs.*')
    elseif len(self.config) == 1
      let [name, value] = [keys(self.config)[0], arg]
    elseif !empty(order)
      let name = remove(order, 0)
      let value = arg
    endif
    if empty(name)
      throw 'could not parse the option: ' . arg
    endif
    if !has_key(self.config, name)
      throw 'unknown option: ' . name
    endif
    if type(self.config[name]) == type([])
      call add(self.config[name], value)
    else
      let self.config[name] = value
    endif
  endfor
endfunction
function! s:module.init(session)
endfunction

" Template of runner.  {{{2
let s:runner = copy(s:module)
function! s:runner.run(commands, input, session)
  throw 'quickrun: A runner should implements run()'
endfunction
function! s:runner.sweep()
endfunction
function! s:runner.shellescape(str)
  if s:is_cmd_exe()
    return '^"' . substitute(substitute(substitute(a:str,
    \             '[&|<>()^"%]', '^\0', 'g'),
    \             '\\\+\ze"', '\=repeat(submatch(0), 2)', 'g'),
    \             '\^"', '\\\0', 'g') . '^"'
  endif
  return shellescape(a:str)
endfunction

" Template of outputter.  {{{2
let s:outputter = copy(s:module)
function! s:outputter.output(data, session)
  throw 'quickrun: An outputter should implements output()'
endfunction
function! s:outputter.finish(session)
endfunction


let s:Session = {}  " {{{1
" Initialize of instance.
function! s:Session.initialize(config)
  let self.config = s:normalize(a:config)
endfunction

function! s:Session.setup()
  try
    if has_key(self, 'exit_code')
      call remove(self, 'exit_code')
    endif
    let self.runner = self.make_module('runner', self.config.runner)
    let self.outputter = self.make_module('outputter', self.config.outputter)

    let source_name = self.get_source_name()
    let exec = get(self.config, 'exec', '')
    let commands = type(exec) == type([]) ? copy(exec) : [exec]
    call filter(map(commands, 'self.build_command(source_name, v:val)'),
    \           'v:val =~# "\\S"')
    let self.commands = commands
  catch /^quickrun:/
    call self.sweep()
    throw v:exception
  catch
    call self.sweep()
    throw join(['quickrun: Error occurred in setup():',
    \           v:exception, v:throwpoint], "\n")
  endtry
endfunction

function! s:Session.make_module(kind, line)
  let name = ''
  if type(a:line) == type([]) && !empty([])
    let [name; args] = a:line
  elseif a:line =~# '^\w'
    let [name, arg] = split(a:line, '^\w\+\zs', 1)
    let args = [arg]
  endif

  if !has_key(s:modules[a:kind], name)
    throw printf('quickrun: Specified %s is not registered: %s',
    \            a:kind, name)
  endif

  let module = deepcopy(s:modules[a:kind][name])

  try
    call module.validate()
  catch
    let exception = matchstr(v:exception, '^\%(quickrun:\s*\)\?\zs.*')
    throw printf('quickrun: Specified %s is not available: %s: %s',
    \            a:kind, name, exception)
  endtry

  try
    call module.build([self.config] + args)
    call map(module.config, 'quickrun#expand(v:val)')
    call module.init(self)
  catch
    let exception = matchstr(v:exception, '^\%(quickrun:\s*\)\?\zs.*')
    throw printf('quickrun: %s/%s: %s',
    \            a:kind, name, exception)
  endtry

  return module
endfunction

function! s:Session.run()
  call self.setup()
  let exit_code = 1
  try
    let exit_code = self.runner.run(self.commands, self.config.input, self)
  finally
    if !has_key(self, '_continue_key')
      call self.finish(exit_code)
    endif
  endtry
endfunction

function! s:Session.continue()
  let self._continue_key = s:save_session(self)
  return self._continue_key
endfunction

function! s:Session.output(data)
  if a:data !=# ''
    let data = a:data
    if get(self.config, 'output_encode', '') !=# ''
      let enc = split(self.config.output_encode, '[^[:alnum:]-_]')
      if len(enc) == 1
        let enc += [&encoding]
      endif
      if len(enc) == 2
        let [from, to] = enc
        let data = s:V.iconv(data, from, to)
      endif
    endif
    call self.outputter.output(data, self)
  endif
endfunction

function! s:Session.finish(...)
  if !has_key(self, 'exit_code')
    let self.exit_code = a:0 ? a:1 : 0
    call self.outputter.finish(self)
    call self.sweep()
  endif
endfunction

" Build a command to execute it from options.
function! s:Session.build_command(source_name, tmpl)
  let config = self.config
  let shebang = config.shebang ? s:detect_shebang(a:source_name) : ''
  let command = shebang !=# '' ? shebang : config.command
  let rule = {
  \  'c': command,
  \  's': a:source_name,
  \  'o': config.cmdopt,
  \  'a': config.args,
  \  '%': '%',
  \}
  let is_file = '[' . (shebang !=# '' ? 's' : 'cs') . ']'
  let rest = a:tmpl
  let result = ''
  while 1
    let pos = match(rest, '%')
    if pos < 0
      let result .= rest
      break
    elseif pos != 0
      let result .= rest[: pos - 1]
      let rest = rest[pos :]
    endif

    let symbol = rest[1]
    let value = get(rule, tolower(symbol), '')

    if symbol ==? 'c' && value ==# ''
      throw 'quickrun: "command" option is empty.'
    endif

    let rest = rest[2 :]
    if symbol =~? is_file
      let mod = matchstr(rest, '^\v\zs%(\:[p8~.htre]|\:g?s(.).{-}\1.{-}\1)*')
      let value = fnamemodify(value, mod)
      if symbol =~# '\U'
        let value = command =~# '^\s*:' ? fnameescape(value)
        \                               : self.runner.shellescape(value)
      endif
      let rest = rest[len(mod) :]
    endif
    let result .= value
  endwhile
  return substitute(quickrun#expand(result), '[\r\n]\+', ' ', 'g')
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

" Sweep the session.
function! s:Session.sweep()
  " Remove temporary files.
  for file in filter(keys(self), 'v:val =~# "^_temp"')
    if filewritable(self[file])
      call delete(self[file])
    endif
    call remove(self, file)
  endfor

  " Restore options.
  for opt in filter(keys(self), 'v:val =~# "^_option_"')
    let optname = matchstr(opt, '^_option_\zs.*')
    if exists('+' . optname)
      execute 'let'  '&' . optname '= self[opt]'
    endif
    call remove(self, opt)
  endfor

  " Delete autocmds.
  for cmd in filter(keys(self), 'v:val =~# "^_autocmd_"')
    execute 'autocmd!' 'plugin-quickrun-' . self[cmd]
    call remove(self, cmd)
  endfor

  " Sweep the execution of vimproc.
  if has_key(self, '_vimproc')
    try
      call self._vimproc.kill(15)
      call self._vimproc.waitpid()
    catch
    endtry
    call remove(self, '_vimproc')
  endif

  if has_key(self, '_continue_key')
    if has_key(s:sessions, self._continue_key)
      call remove(s:sessions, self._continue_key)
    endif
    call remove(self, '_continue_key')
  endif

  if has_key(self, 'runner')
    call self.runner.sweep()
  endif
endfunction


let s:sessions = {}  " Store for sessions.

function! s:save_session(session)
  let key = has('reltime') ? reltimestr(reltime()) : string(localtime())
  let s:sessions[key] = a:session
  return key
endfunction

" Call a function of a session by key.
function! quickrun#session(key, ...)
  let session = get(s:sessions, a:key, {})
  if a:0 && !empty(session)
    return call(session[a:1], a:000[1 :], session)
  endif
  return session
endfunction

function! s:dispose_session(key)
  if has_key(s:sessions, a:key)
    let session = remove(s:sessions, a:key)
    call session.sweep()
  endif
endfunction

function! quickrun#sweep_sessions()
  call map(keys(s:sessions), 's:dispose_session(v:val)')
endfunction


" Interfaces.  {{{1
function! quickrun#new(config)
  let session = copy(s:Session)
  call session.initialize(a:config)
  return session
endfunction

function! quickrun#run(config)
  call quickrun#sweep_sessions()

  let session = quickrun#new(a:config)

  " for debug
  if has_key(session.config, 'debug')
    let g:{matchstr(session.config.debug, '\h\w*')} = session
  endif

  call session.run()
endfunction

" function for |g@|.
function! quickrun#operator(wise)
  call quickrun#run({'mode': 'o', 'visualmode': a:wise})
endfunction

" function for main command.
function! quickrun#command(config, use_range, line1, line2)
  try
    let config = {}
    if a:use_range
      let config.start = a:line1
      let config.end = a:line2
    endif
    call quickrun#run([config, a:config])
  catch /^quickrun:/
    call s:V.print_error(v:exception)
  endtry
endfunction

" completion function for main command.
function! quickrun#complete(lead, cmd, pos)
  let line = split(a:cmd[:a:pos - 1], '', 1)
  let head = line[-1]
  if 2 <= len(line) && line[-2] =~# '^-'
    " a value of option.
    let opt = line[-2][1:]
    if opt !=# 'type'
      let list = []
      if opt ==# 'shebang'
        let list = ['0', '1']
      elseif opt ==# 'mode'
        let list = ['n', 'v', 'o']
      elseif opt ==# 'runner' || opt ==# 'outputter'
        let list = keys(filter(copy(s:modules[opt]),
        \                      'v:val.available()'))
      endif
      return filter(list, 'v:val =~# "^".a:lead')
    endif

  elseif head =~# '^-'
    " a name of option.
    let list = ['type', 'src', 'input', 'runner', 'outputter',
    \ 'command', 'exec', 'cmdopt', 'args', 'tempfile', 'shebang', 'eval',
    \ 'mode', 'output_encode', 'eval_template']
    let mod_options = {}
    for kind in ['runner', 'outputter']
      for module in filter(values(s:modules[kind]), 'v:val.available()')
        for opt in keys(module.config)
          let mod_options[opt] = 1
          let mod_options[kind . '/' . opt] = 1
          let mod_options[kind . '/' . module.name . '/' . opt] = 1
        endfor
      endfor
    endfor
    let list += keys(mod_options)
    call map(list, '"-" . v:val')

  endif
  if !exists('list')
    " no context: types
    let list = keys(extend(exists('g:quickrun_config') ?
    \               copy(g:quickrun_config) : {}, g:quickrun#default_config))
    call filter(list, 'v:val !~# "^[_*]$"')
  endif

  let re = '^\V' . escape(head, '\') . '\v[^/]*/?'
  return s:V.Data.List.uniq(sort(map(list, 'matchstr(v:val, re)')))
endfunction


" Expand the keyword.
" - @register @{register}
" - &option &{option}
" - $ENV_NAME ${ENV_NAME}
" - %{expr}
" Escape by \ if you does not want to expand.
function! quickrun#expand(input)
  if type(a:input) == type([]) || type(a:input) == type({})
    return map(copy(a:input), 'quickrun#expand(v:val)')
  elseif type(a:input) != type('')
    return a:input
  endif
  let i = 0
  let rest = a:input
  let result = ''
  while 1
    let f = match(rest, '\\\?[@&$%\\]')
    if f < 0
      let result .= rest
      break
    endif

    if f != 0
      let result .= rest[: f - 1]
      let rest = rest[f :]
    endif

    if rest[0] ==# '\'
      let result .= rest[1] =~# '[@&$%\\]' ? rest[1] : rest[0 : 1]
      let rest = rest[2 :]
    else
      if rest =~# '^[@&$]{'
        let rest = '%{' . rest[0] . rest[2 :]
      endif
      if rest[0] ==# '@'
        let e = 2
        let expr = rest[0 : 1]
      elseif rest =~# '^[&$]'
        let e = matchend(rest, '.\w\+')
        let expr = rest[: e - 1]
      elseif rest =~# '^%{'
        let e = matchend(rest, '\\\@<!}')
        let expr = substitute(rest[2 : e - 2], '\\}', '}', 'g')
      else
        let e = 1
        let expr = string(rest[0])
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

" Execute commands by expr.  This is used by remote_expr()
function! quickrun#execute(cmd)
  " XXX: Can't get a result if a:cmd contains :redir command.
  let result = ''
  try
    redir => result
    for cmd in type(a:cmd) == type([]) ? a:cmd : [a:cmd]
      silent execute cmd
    endfor
  finally
    redir END
  endtry
  return result
endfunction


" Misc functions.  {{{1
function! s:parse_argline(argline)
  " foo 'bar buz' "hoge \"huga"
  " => ['foo', 'bar buz', 'hoge "huga']
  " TODO: More improve.
  " ex:
  " foo ba'r b'uz "hoge \nhuga"
  " => ['foo, 'bar buz', "hoge \nhuga"]
  let argline = a:argline
  let arglist = []
  while argline !~# '^\s*$'
    let argline = matchstr(argline, '^\s*\zs.*$')
    if argline[0] =~# '[''"]'
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

function! s:build_config_from_arglist(arglist)
  let config = {}
  let option = ''
  for arg in a:arglist
    if option !=# ''
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
    elseif arg[0] ==# '-'
      let option = arg[1:]
    elseif arg[0] ==# '>'
      if arg[1] ==# '>'
        let config.append = 1
        let arg = arg[1:]
      endif
      let config.outputter = arg[1:]
    elseif arg[0] ==# '<'
      let config.input = arg[1:]
    else
      let config.type = arg
    endif
  endfor
  return config
endfunction

" Converts a string as argline or a list of config to config object.
function! s:to_config(config)
  if type(a:config) == type('')
    return s:build_config_from_arglist(s:parse_argline(a:config))
  elseif type(a:config) == type([])
    let config = {}
    for c in a:config
      call extend(config, s:to_config(c))
      unlet c
    endfor
    return config
  endif
  return a:config
endfunction

" The option is appropriately set referring to default options.
function! s:normalize(config)
  let config = s:to_config(a:config)
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
      let config.input = input[0] ==# '=' ? input[1:]
      \                                  : join(readfile(input, 'b'), "\n")
    catch
      throw 'quickrun: Can not treat input: ' . v:exception
    endtry
  else
    let config.input = ''
  endif

  let config.command = get(config, 'command', config.type)

  if has_key(config, 'src')
    if config.eval
      let config.src = printf(config.eval_template, config.src)
    endif
  else
    if !config.eval && config.mode ==# 'n' && filereadable(expand('%:p')) &&
    \   !has_key(config, 'start') &&  !has_key(config, 'end') && !&modified
      " Use file in direct.
      let config.src = bufnr('%')
    else
      let config.start = get(config, 'start', 1)
      let config.end = get(config, 'end', line('$'))
      " Executes on the temporary file.
      let body = s:get_region(config)

      if config.eval
        let body = printf(config.eval_template, body)
      endif

      let body = s:V.iconv(body, &encoding, &fileencoding)

      if &l:fileformat ==# 'mac'
        let body = substitute(body, "\n", "\r", 'g')
      elseif &l:fileformat ==# 'dos'
        if !&l:binary
          let body .= "\n"
        endif
        let body = substitute(body, "\n", "\r\n", 'g')
      endif

      let config.src = body
    endif
  endif

  for opt in ['cmdopt', 'args', 'output_encode']
    let config[opt] = quickrun#expand(config[opt])
  endfor
  return config
endfunction

" Detect the shebang, and return the shebang command if it exists.
function! s:detect_shebang(file)
  let line = get(readfile(a:file, 0, 1), 0, '')
  return line =~# '^#!' ? line[2:] : ''
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
  endif

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



" Module system.  {{{1
let s:modules = {
\   'runner': {},
\   'outputter': {},
\ }

function! quickrun#register_runner(name, runner)
  return quickrun#register_module('runner', a:name, a:runner)
endfunction

function! quickrun#register_outputter(name, outputter)
  return quickrun#register_module('outputter', a:name, a:outputter)
endfunction

function! quickrun#register_module(kind, name, module)
  if !has_key(s:modules, a:kind)
    throw 'quickrun: Unknown kind of module: ' . a:kind
  endif
  if empty(a:module)
    if has_key(s:modules[a:kind], a:name)
      call remove(s:modules[a:kind], a:name)
    endif
    return
  endif
  let module = extend(deepcopy(s:{a:kind}), a:module)
  let module.kind = a:kind
  let module.name = a:name
  let s:modules[a:kind][a:name] = module
endfunction

function! quickrun#get_module(kind, ...)
  if a:0
    return get(get(s:modules, a:kind, {}), a:1, {})
  endif
  return copy(get(s:modules, a:kind, {}))
endfunction


" Register the default modules.  {{{1
function! s:register_defaults(kind)
  let pat = 'autoload/quickrun/' . a:kind . '/*.vim'
  for name in map(split(globpath(&runtimepath, pat), "\n"),
  \               'fnamemodify(v:val, ":t:r")')
    try
      let module = quickrun#{a:kind}#{name}#new()
      call quickrun#register_module(a:kind, name, module)
    catch /:E\%(117\|716\):/
    endtry
  endfor
endfunction

call s:register_defaults('runner')
call s:register_defaults('outputter')


let &cpo = s:save_cpo
