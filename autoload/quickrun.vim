" Run commands quickly.
" Version: 0.6.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('quickrun').load(
\   'Data.List',
\   'System.File',
\   'System.Filepath',
\   'Vim.Message',
\   'Process',
\   'Prelude')
unlet! g:quickrun#V
let g:quickrun#V = s:V
lockvar! g:quickrun#V

let s:is_win = s:V.Prelude.is_windows()

" Default config.  " {{{1
unlet! g:quickrun#default_config
let g:quickrun#default_config = {
\ '_': {
\   'outputter': 'buffer',
\   'runner': 'system',
\   'cmdopt': '',
\   'args': '',
\   'tempfile'  : '%{tempname()}',
\   'exec': '%c %o %s %a',
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
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.c',
\   'hook/sweep/files': '%S:p:r',
\ },
\ 'c/gcc': {
\   'command': 'gcc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.c',
\   'hook/sweep/files': '%S:p:r',
\ },
\ 'c/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\            '%s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.c',
\   'hook/sweep/files': ['%S:p:r.exe', '%S:p:r.obj'],
\ },
\ 'clojure': {
\   'type': executable('jark') ? 'clojure/jark':
\           executable('clj') ? 'clojure/clj':
\           '',
\ },
\ 'clojure/jark': {
\   'command': 'jark',
\   'exec': '%c ns load %s',
\ },
\ 'clojure/clj': {
\   'command': 'clj',
\   'exec': '%c %s %a',
\ },
\ 'clojure/process_manager': {
\   'command': 'clojure-1.6',
\   'cmdopt': '-e ''(clojure.main/repl :prompt #(print "\nquickrun/pm=> "))''',
\   'runner': 'process_manager',
\   'runner/process_manager/load': '(load-file "%S")',
\   'runner/process_manager/prompt': 'quickrun/pm=> ',
\ },
\ 'clojure/concurrent_process': {
\   'command': 'clojure-1.6',
\   'cmdopt': '-e ''(clojure.main/repl :prompt #(print "\nquickrun/cp=> "))''',
\   'runner': 'concurrent_process',
\   'runner/concurrent_process/load': '(load-file "%S")',
\   'runner/concurrent_process/prompt': 'quickrun/cp=> ',
\ },
\ 'coffee': {},
\ 'cpp': {
\   'type':
\     s:is_win && executable('cl') ? 'cpp/vc'  :
\     executable('clang++')        ? 'cpp/clang++'  :
\     executable('g++')            ? 'cpp/g++' : '',
\ },
\ 'cpp/C': {
\   'command': 'C',
\   'exec': '%c %o -p %s',
\ },
\ 'cpp/clang++': {
\   'command': 'clang++',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.cpp',
\   'hook/sweep/files': ['%S:p:r'],
\ },
\ 'cpp/g++': {
\   'command': 'g++',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.cpp',
\   'hook/sweep/files': '%S:p:r',
\ },
\ 'cpp/vc': {
\   'command': 'cl',
\   'exec': ['%c %o %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
\            '%s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cpp',
\   'hook/sweep/files': ['%S:p:r.exe', '%S:p:r.obj'],
\ },
\ 'crystal': {
\   'command': 'crystal',
\   'cmdopt': '--no-color',
\   'exec': '%c run %o %s -- %a',
\   'tempfile': '%{tempname()}.cr',
\ },
\ 'cs': {
\   'type': executable('csc')  ? 'cs/csc'  :
\           executable('dmcs') ? 'cs/dmcs' :
\           executable('smcs') ? 'cs/smcs' :
\           executable('gmcs') ? 'cs/gmcs' :
\           executable('mcs') ? 'cs/mcs' : ''
\ },
\ 'cs/csc': {
\   'command': 'csc',
\   'exec': ['%c /nologo /out:%s:p:r:gs?/?\\?.exe %s:gs?/?\\?', '%s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cs',
\   'hook/output_encode/encoding': '&termencoding',
\   'hook/sweep/files': ['%S:p:r.exe'],
\ },
\ 'cs/mcs': {
\   'command': 'mcs',
\   'exec': ['%c %o -out:%s:p:r.exe %s', 'mono %s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cs',
\   'hook/sweep/files': ['%S:p:r.exe'],
\ },
\ 'cs/gmcs': {
\   'command': 'gmcs',
\   'exec': ['%c %o -out:%s:p:r.exe %s', 'mono %s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cs',
\   'hook/sweep/files': ['%S:p:r.exe'],
\ },
\ 'cs/smcs': {
\   'command': 'smcs',
\   'exec': ['%c %o -out:%s:p:r.exe %s', 'mono %s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cs',
\   'hook/sweep/files': ['%S:p:r.exe'],
\ },
\ 'cs/dmcs': {
\   'command': 'dmcs',
\   'exec': ['%c %o -out:%s:p:r.exe %s', 'mono %s:p:r.exe %a'],
\   'tempfile': '%{tempname()}.cs',
\   'hook/sweep/files': ['%S:p:r.exe'],
\ },
\ 'd': {
\   'type':
\     executable('rdmd')           ? 'd/rdmd' :
\     executable('ldc')            ? 'd/ldc' :
\     executable('gdc')            ? 'd/gdc' : '',
\ },
\ 'd/rdmd': {
\   'command': 'rdmd',
\   'tempfile': '%{tempname()}.d',
\ },
\ 'd/ldc': {
\   'command': 'ldc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.d',
\   'hook/sweep/files': ['%S:p:r'],
\ },
\ 'd/gdc': {
\   'command': 'gdc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.d',
\   'hook/sweep/files': ['%S:p:r'],
\ },
\ 'dosbatch': {
\   'command': 'cmd',
\   'exec': '%c /c "call %s %a"',
\   'hook/output_encode/encoding': 'cp932',
\   'tempfile': '%{tempname()}.bat',
\ },
\ 'dart': {
\   'type':
\     executable('dart') ? 'dart/dart/checked':
\   '',
\ },
\ 'dart/dart/checked': {
\   'command': 'dart',
\   'cmdopt': '--enable-type-checks',
\   'tempfile': '%{tempname()}.dart',
\ },
\ 'dart/dart/production': {
\   'command': 'dart',
\   'tempfile': '%{tempname()}.dart',
\ },
\ 'elixir': {
\   'command': 'elixir',
\ },
\ 'erlang': {
\   'command': 'escript',
\ },
\ 'eruby': {
\   'command': 'erb',
\   'exec': '%c %o -T - %s %a',
\ },
\ 'fish': {
\   'command': 'fish',
\ },
\ 'fortran': {
\   'type': 'fortran/gfortran',
\ },
\ 'fortran/gfortran': {
\   'command': 'gfortran',
\   'exec': ['%c %o -o %s:p:r %s', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.f95',
\   'hook/sweep/files': ['%S:p:r'],
\ },
\ 'fsharp': {
\   'type': executable('fsharpc') ? 'fsharp/mono' :
\           executable('fsc') ? 'fsharp/vs' : '',
\ },
\ 'fsharp/mono': {
\   'exec': ['%c %o --out:%s:p:r.exe %s', 'mono %s:p:r.exe %a'],
\   'command': 'fsharpc',
\   'cmdopt': '--nologo',
\   'hook/sweep/files': '%S:p:r.exe',
\   'tempfile': '%{fnamemodify(tempname(), ":r")}.fs',
\ },
\ 'fsharp/vs': {
\   'exec': ['%c %o --out:%s:p:r.exe %s', '%s:p:r.exe %a'],
\   'command': 'fsc',
\   'cmdopt': '--nologo',
\   'hook/sweep/files': '%S:p:r.exe',
\   'tempfile': '%{fnamemodify(tempname(), ":r")}.fs',
\ },
\ 'go': {
\   'command': 'go',
\   'exec': '%c run %s:p:t %a',
\   'tempfile': '%{tempname()}.go',
\   'hook/output_encode/encoding': 'utf-8',
\   'hook/cd/directory': '%S:p:h',
\ },
\ 'groovy': {
\   'cmdopt': '-c %{&fenc==#""?&enc:&fenc}'
\ },
\ 'haskell': {'type': 'haskell/runghc'},
\ 'haskell/runghc': {
\   'command': 'runghc',
\   'tempfile': '%{tempname()}.hs',
\   'hook/eval/template': 'main = print \$ %s',
\ },
\ 'haskell/ghc': {
\   'command': 'ghc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'cmdopt': '-v0 --make',
\   'tempfile': '%{tempname()}.hs',
\   'hook/sweep/files': ['%S:p:r', '%S:p:r.o', '%S:p:r.hi'],
\ },
\ 'haskell/ghc/core': {
\   'command': 'ghc',
\   'exec': '%c %o -ddump-simpl -dsuppress-coercions %s',
\   'cmdopt': '-v0 --make',
\   'tempfile': '%{tempname()}.hs',
\   'hook/sweep/files': ['%S:p:r', '%S:p:r.o', '%S:p:r.hi'],
\ },
\ 'io': {},
\ 'java': {
\   'exec': ['javac %o -d %s:p:h %s', '%c -cp %s:p:h %s:t:r %a'],
\   'hook/output_encode/encoding': '&termencoding',
\   'hook/sweep/files': '%S:p:r.class',
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
\ 'jsx': {
\   'exec': '%c --run %o %s %a',
\   'hook/eval/template':
\     'class _Main { static function main(args : string[]) :void { %s }}',
\ },
\ 'kotlin': {
\   'exec': [
\     'kotlinc-jvm %s -d %s:p:r.jar',
\     'java -Xbootclasspath/a:%{shellescape(fnamemodify(' .
\       'fnamemodify(g:quickrun#V.System.Filepath.which("kotlinc-jvm"), ":h") . "/../lib/kotlin-runtime.jar", ":p"))}' .
\       ' -jar %s:p:r.jar'
\   ],
\   'tempfile': '%{tempname()}.kt',
\   'hook/sweep/files': ['%S:p:r.jar'],
\ },
\ 'lisp': {
\   'type' : executable('sbcl') ? 'lisp/sbcl':
\            executable('ccl') ? 'lisp/ccl':
\            executable('clisp') ? 'lisp/clisp': '',
\ },
\ 'lisp/sbcl': {
\   'command': 'sbcl',
\   'cmdopt': '--script',
\ },
\ 'lisp/ccl': {
\   'command': 'ccl',
\   'exec': '%c -l %s -e "(ccl:quit)"',
\ },
\ 'lisp/clisp': {
\   'command': 'clisp',
\ },
\ 'llvm': {
\   'exec' : 'llvm-as %s:p -o=- | lli - %a',
\ },
\ 'lua': {},
\ 'lua/vim': {
\   'command': ':luafile',
\   'exec': '%C %s',
\   'runner': 'vimscript',
\ },
\ 'lua/redis': {
\   'command': 'redis-cli',
\   'exec': '%c --eval %s %a',
\   'tempfile': '%{tempname()}.lua'
\ },
\ 'markdown': {
\   'type': executable('Markdown.pl') ? 'markdown/Markdown.pl':
\           executable('kramdown') ? 'markdown/kramdown':
\           executable('bluecloth') ? 'markdown/bluecloth':
\           executable('redcarpet') ? 'markdown/redcarpet':
\           executable('pandoc') ? 'markdown/pandoc':
\           executable('markdown_py') ? 'markdown/markdown_py': '',
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
\   'exec': '%c --from=markdown --to=html %o %s %a',
\ },
\ 'markdown/redcarpet': {
\   'command': 'redcarpet',
\ },
\ 'markdown/markdown_py': {
\   'command': 'markdown_py',
\ },
\ 'nim': {
\   'cmdopt': 'compile --run --verbosity:0',
\   'hook/sweep/files': '%S:p:r',
\   'tempfile': '%{substitute(tempname(), ''/\(\d\+\)$'', ''nim\1'', '''')}.nim'
\ },
\ 'ocaml': {},
\ 'perl': {
\   'hook/eval/template': join([
\     'use Data::Dumper',
\     '\$Data::Dumper::Terse = 1',
\     '\$Data::Dumper::Indent = 0',
\     'print Dumper eval{%s}'], ';')
\ },
\ 'perl6': {'hook/eval/template': '{%s}().perl.print'},
\ 'python': {'hook/eval/template': 'print(%s)'},
\ 'php': {},
\ 'ps1': {
\   'exec': '%c %o -File %s %a',
\   'command': 'powershell.exe',
\   'cmdopt': '-ExecutionPolicy RemoteSigned',
\   'tempfile': '%{tempname()}.ps1',
\   'hook/output_encode/encoding': '&termencoding',
\ },
\ 'xquery': {
\   'command': 'zorba',
\   'exec': '%c %o %s %a',
\ },
\ 'r': {
\   'command': 'R',
\   'exec': '%c %o --no-save --slave %a < %s',
\ },
\ 'ruby': {'hook/eval/template': " p proc {\n%s\n}.call"},
\ 'ruby/irb': {
\   'command': 'irb',
\   'exec': '%c %o --simple-prompt',
\   'runner': 'process_manager',
\   'runner/process_manager/load': "load '%s'",
\   'runner/process_manager/prompt': '>> ',
\ },
\ 'ruby/pry': {
\   'command': 'pry',
\   'exec': '%c %o --no-color --simple-prompt',
\   'runner': 'process_manager',
\   'runner/process_manager/load': "load '%s'",
\   'runner/process_manager/prompt': '>> ',
\ },
\ 'rust': {
\   'command': 'rustc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.rs',
\   'hook/sweep/files': '%S:p:r',
\ },
\ 'rust/cargo': {
\   'command': 'cargo',
\   'exec': '%c run %o',
\ },
\ 'scala': {
\   'hook/output_encode/encoding': '&termencoding',
\ },
\ 'scala/process_manager': {
\   'command': 'scala',
\   'cmdopt': '-nc',
\   'runner': 'process_manager',
\   'runner/process_manager/load': ':load %S',
\   'runner/process_manager/prompt': 'scala> ',
\ },
\ 'scala/concurrent_process': {
\   'command': 'scala',
\   'cmdopt': '-nc',
\   'runner': 'concurrent_process',
\   'runner/concurrent_process/load': ':load %S',
\   'runner/concurrent_process/prompt': 'scala> ',
\ },
\ 'scheme': {
\   'type': executable('gosh')     ? 'scheme/gauche':
\           executable('mzscheme') ? 'scheme/mzscheme': '',
\ },
\ 'scheme/gauche': {
\   'command': 'gosh',
\   'exec': '%c %o %s:p %a',
\   'hook/eval/template': '(display (begin %s))',
\ },
\ 'scheme/mzscheme': {
\   'command': 'mzscheme',
\   'exec': '%c %o -f %s %a',
\ },
\ 'sed': {},
\ 'sh': {},
\ 'sql': {
\   'type': executable('psql') ? 'sql/postgres' :
\           executable('mysql') ? 'sql/mysql' :
\           executable('sqlite3') ? 'sql/sqlite3' : '',
\ },
\ 'sql/postgres': {
\   'command': 'psql',
\   'exec': ['%c %o -f %s'],
\ },
\ 'sql/mysql': {
\   'command': 'mysql',
\   'exec': ['%c %o < %s'],
\ },
\ 'sql/sqlite3': {
\   'command': 'sqlite3',
\   'exec': ['%c %o < %s'],
\ },
\ 'swift': {
\   'type' : executable('xcrun') ? 'swift/apple' : '',
\ },
\ 'swift/apple': {
\   'command': 'xcrun',
\   'exec': ['%c swift %s'],
\ },
\ 'tmux': {
\   'command': 'tmux',
\   'exec': ['%c source-file %s:p'],
\ },
\ 'typescript': {
\   'command': 'tsc',
\   'exec': ['%c --target es5 --module commonjs %o %s', 'node %s:r.js'],
\   'tempfile': '%{tempname()}.ts',
\   'hook/sweep/files': ['%S:p:r.js'],
\ },
\ 'vim': {
\   'command': ':source',
\   'exec': '%C %s',
\   'hook/eval/template': "echo %s",
\   'runner': 'vimscript',
\ },
\ 'wsh': {
\   'command': 'cscript',
\   'cmdopt': '//Nologo',
\   'hook/output_encode/encoding': '&termencoding',
\ },
\ 'zsh': {},
\}
lockvar! g:quickrun#default_config


let s:Session = {}  " {{{1
" Initialize of instance.
function! s:Session.initialize(config) abort
  let self.base_config = s:build_config(a:config)
endfunction

" The option is appropriately set referring to default options.
function! s:Session.normalize(config) abort
  let config = a:config
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

  let exec = get(config, 'exec', '')
  let config.exec = type(exec) == type([]) ? exec : [exec]
  let config.command = get(config, 'command', config.type)

  if has_key(config, 'srcfile')
    let config.srcfile = quickrun#expand(expand(config.srcfile))
  elseif !has_key(config, 'src')
    if filereadable(expand('%:p')) &&
    \  !has_key(config, 'region') && !&modified
      " Use file in direct.
      let config.srcfile = expand('%:p')
    else
      let config.region = get(config, 'region', {
      \   'first': [1, 0, 0],
      \   'last':  [line('$'), 0, 0],
      \   'wise': 'V',
      \ })
      " Executes on the temporary file.
      let body = s:get_region(config.region)

      let body = s:V.Process.iconv(body, &encoding, &fileencoding)

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

  if !has_key(config, 'srcfile')
    let fname = quickrun#expand(config.tempfile)
    call self.tempname(fname)
    call writefile(split(config.src, "\n", 1), fname, 'b')
    let config.srcfile = fname
  endif

  for opt in ['cmdopt', 'args']
    let config[opt] = quickrun#expand(config[opt])
  endfor
  return config
endfunction

function! s:Session.setup() abort
  try
    if has_key(self, 'exit_code')
      call remove(self, 'exit_code')
    endif
    let self.config = deepcopy(self.base_config)

    let self.hooks = map(quickrun#module#get('hook'),
    \                    'self.make_module("hook", v:val.name)')
    call self.invoke_hook('hook_loaded')
    call filter(self.hooks, 'v:val.config.enable')
    let self.config = self.normalize(self.config)
    call self.invoke_hook('normalized')

    let self.runner = self.make_module('runner', self.config.runner)
    let self.outputter = self.make_module('outputter', self.config.outputter)
    call self.invoke_hook('module_loaded')

    let commands = copy(self.config.exec)
    call filter(map(commands, 'self.build_command(quickrun#expand(v:val))'),
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

function! s:Session.make_module(kind, line) abort
  let name = ''
  if type(a:line) == type([]) && !empty([])
    let [name; args] = a:line
  elseif a:line =~# '^\w'
    let [name, arg] = split(a:line, '^\w\+\zs', 1)
    let args = [arg]
  endif

  let module = deepcopy(quickrun#module#get(a:kind, name))

  try
    call module.validate()
  catch
    let exception = matchstr(v:exception, '^\%(quickrun:\s*\)\?\zs.*')
    throw printf('quickrun: Specified %s is not available: %s: %s',
    \            a:kind, name, exception)
  endtry

  try
    call s:build_module(module, [self.config] + args)
    call map(module.config, 'quickrun#expand(v:val)')
    call module.init(self)
  catch
    let exception = matchstr(v:exception, '^\%(quickrun:\s*\)\?\zs.*')
    throw printf('quickrun: %s/%s: %s',
    \            a:kind, name, exception)
  endtry

  return module
endfunction

function! s:Session.run() abort
  if has_key(self, '_running')
    throw 'quickrun: session.run() was called in running.'
  endif
  let self._running = 1
  call self.setup()
  call self.invoke_hook('ready')
  let exit_code = 1
  try
    call self.outputter.start(self)
    let exit_code = self.runner.run(self.commands, self.config.input, self)
  finally
    if !has_key(self, '_continue_key')
      call self.finish(exit_code)
    endif
  endtry
endfunction

function! s:Session.continue() abort
  let self._continue_key = s:save_session(self)
  return self._continue_key
endfunction

function! s:Session.output(data) abort
  let context = {'data': a:data}
  call self.invoke_hook('output', context)
  if context.data !=# ''
    call self.outputter.output(context.data, self)
  endif
endfunction

function! s:Session.finish(...) abort
  if !has_key(self, 'exit_code')
    let self.exit_code = a:0 ? a:1 : 0
    if self.exit_code == 0
      call self.invoke_hook('success')
    else
      call self.invoke_hook('failure', {'exit_code': self.exit_code})
    endif
    call self.invoke_hook('finish')
    call self.outputter.finish(self)
    call self.sweep()
    call self.invoke_hook('exit')
  endif
endfunction

" Build a command to execute it from options.
" XXX: Undocumented yet.  This is used by core modules only.
function! s:Session.build_command(tmpl) abort
  let config = self.config
  let command = config.command
  let rule = {
  \  'c': command,
  \  's': config.srcfile,
  \  'o': config.cmdopt,
  \  'a': config.args,
  \  '%': '%',
  \}
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
    if symbol =~? '^[cs]$'
      if symbol ==# 'c'
        let value_ = s:V.System.Filepath.which(value)
        if value_ !=# ''
          let value = value_
        endif
      endif
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
  return substitute(result, '[\r\n]\+', ' ', 'g')
endfunction

function! s:Session.tempname(...) abort
  let name = a:0 ? a:1 : tempname()
  if !has_key(self, '_temp_names')
    let self._temp_names = []
  endif
  call add(self._temp_names, name)
  return name
endfunction

" Sweep the session.
function! s:Session.sweep() abort
  " Remove temporary files.
  if has_key(self, '_temp_names')
    for name in self._temp_names
      if filewritable(name)
        call delete(name)
      elseif isdirectory(name)
        call s:V.System.File.rmdir(name)
      endif
    endfor
  endif

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
  if has_key(self, 'outputter')
    call self.outputter.sweep()
  endif
  if has_key(self, 'hooks')
    for hook in self.hooks
      call hook.sweep()
    endfor
  endif

  if has_key(self, '_running')
    call remove(self, '_running')
  endif
endfunction

function! s:Session.invoke_hook(point, ...) abort
  let context = a:0 ? a:1 : {}
  let func = 'on_' . a:point
  let hooks = copy(self.hooks)
  let hooks = map(hooks, '[v:val, s:get_hook_priority(v:val, a:point)]')
  let hooks = s:V.Data.List.sort_by(hooks, 'v:val[1]')
  let hooks = map(hooks, 'v:val[0]')
  for hook in hooks
    if has_key(hook, func) && s:V.Prelude.is_funcref(hook[func])
      call call(hook[func], [self, context], hook)
    endif
  endfor
endfunction

function! s:get_hook_priority(hook, point) abort
  try
    return a:hook.priority(a:point) - 0
  catch
    return 0
  endtry
endfunction


let s:sessions = {}  " Store for sessions.

function! s:save_session(session) abort
  let key = has('reltime') ? reltimestr(reltime()) : string(localtime())
  let s:sessions[key] = a:session
  return key
endfunction

" Call a function of a session by key.
function! quickrun#session(key, ...) abort
  let session = get(s:sessions, a:key, {})
  if a:0 && !empty(session)
    return call(session[a:1], a:000[1 :], session)
  endif
  return session
endfunction

function! s:dispose_session(key) abort
  if has_key(s:sessions, a:key)
    let session = remove(s:sessions, a:key)
    call session.sweep()
  endif
endfunction

function! quickrun#sweep_sessions() abort
  call map(keys(s:sessions), 's:dispose_session(v:val)')
endfunction

function! quickrun#is_running() abort
  return !empty(s:sessions)
endfunction


" Interfaces.  {{{1
function! quickrun#new(...) abort
  let session = copy(s:Session)
  call session.initialize(a:0 ? a:1 : {})
  return session
endfunction

function! quickrun#run(...) abort
  call quickrun#sweep_sessions()

  let session = quickrun#new(a:0 ? a:1 : {})

  " for debug
  if has_key(session.base_config, 'debug')
    let g:{matchstr(session.base_config.debug, '\h\w*')} = session
  endif

  call session.run()
endfunction

" function for |g@|.
function! quickrun#operator(wise) abort
  let wise = {
  \ 'line': 'V',
  \ 'char': 'v',
  \ 'block': "\<C-v>" }[a:wise]
  call quickrun#run({'region': {
  \   'first': getpos("'[")[1 :],
  \   'last':  getpos("']")[1 :],
  \   'wise': wise,
  \   'selection': 'inclusive',
  \ }})
endfunction

" function for main command.
function! quickrun#command(config, use_range, line1, line2) abort
  try
    let config = {}
    if a:use_range
      let config.region = {
      \   'first': [a:line1, 0, 0],
      \   'last':  [a:line2, 0, 0],
      \   'wise': 'V',
      \ }
    endif
    call quickrun#run([config, a:config])
  catch /^quickrun:/
    call s:V.Vim.Message.error(v:exception)
  endtry
endfunction

" completion function for main command.
function! quickrun#complete(lead, cmd, pos) abort
  let line = split(a:cmd[:a:pos - 1], '', 1)
  let head = line[-1]
  let kinds = quickrun#module#get_kinds()
  if 2 <= len(line) && line[-2] =~# '^-'
    " a value of option.
    let opt = line[-2][1:]
    if opt !=# 'type'
      let list = []
      if opt ==# 'mode'
        let list = ['n', 'v']
      elseif 0 <= index(kinds, opt)
        let list = map(filter(quickrun#module#get(opt),
        \                     'v:val.available()'), 'v:val.name')
      endif
      return filter(list, 'v:val =~# "^".a:lead')
    endif

  elseif head =~# '^-'
    " a name of option.
    let list = ['type', 'src', 'srcfile', 'input', 'runner', 'outputter',
    \ 'command', 'exec', 'cmdopt', 'args', 'tempfile', 'mode']
    let mod_options = {}
    for kind in kinds
      for module in filter(quickrun#module#get(kind), 'v:val.available()')
        for opt in keys(module.config)
          let mod_options[opt] = 1
          let mod_options[kind . '/' . opt] = 1
          let mod_options[module.name . '/' . opt] = 1
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
function! quickrun#expand(input) abort
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
function! quickrun#execute(cmd) abort
  let result = ''
  let temp = tempname()
  try
    let save_vfile = &verbosefile
    let &verbosefile = temp

    for cmd in type(a:cmd) == type([]) ? a:cmd : [a:cmd]
      silent execute cmd
    endfor
  finally
    if &verbosefile ==# temp
      let &verbosefile = save_vfile
      let result = join(readfile(temp, 'b'), "\n")
    endif
    call delete(temp)
  endtry
  return result
endfunction

" Converts a string as argline or a list of config to config object.
function! quickrun#config(config) abort
  if type(a:config) == type('')
    return s:build_config_from_arglist(s:parse_argline(a:config))
  elseif type(a:config) == type([])
    let config = {}
    for c in a:config
      call extend(config, quickrun#config(c))
      unlet c
    endfor
    return config
  elseif type(a:config) == type({})
    return deepcopy(a:config)
  endif
  throw 'quickrun: Unsupported config type: ' . type(a:config)
endfunction

function! quickrun#trigger_keys() abort
  if mode() =~# '[iR]'
    let input = "\<C-r>\<ESC>"
  else
    let input = "g\<ESC>" . (0 < v:count ? v:count : '')
  endif
  call feedkeys(input, 'n')
endfunction


" Misc functions.  {{{1
function! s:parse_argline(argline) abort
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

function! s:build_config_from_arglist(arglist) abort
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

function! s:build_config(config) abort
  let config = quickrun#config(a:config)
  if !has_key(config, 'mode')
    let config.mode = histget(':') =~# "^'<,'>\\s*Q\\%[uickRun]" ? 'v' : 'n'
  endif
  if config.mode ==# 'v'
    let config.region = {
    \   'first': getpos("'<")[1 :],
    \   'last':  getpos("'>")[1 :],
    \   'wise': visualmode(),
    \ }
  endif

  let type = {'type': &filetype}
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
  return config
endfunction

function! s:build_module(module, configs) abort
  for config in a:configs
    if type(config) == type({})
      for name in keys(a:module.config)
        for conf in [a:module.kind . '/' . a:module.name . '/' . name,
        \            a:module.name . '/' . name,
        \            a:module.kind . '/' . name,
        \            name]
          if has_key(config, conf)
            let val = config[conf]
            if s:V.Prelude.is_list(a:module.config[name])
              let a:module.config[name] += s:V.Prelude.is_list(val) ? val : [val]
            else
              let a:module.config[name] = val
            endif
            unlet val
            break
          endif
        endfor
      endfor
    elseif type(config) == type('') && config !=# ''
      call s:parse_module_option(a:module, config)
    endif
    unlet config
  endfor
endfunction

function! s:parse_module_option(module, argline) abort
  let sep = a:argline[0]
  let args = split(a:argline[1:], '\V' . escape(sep, '\'))
  let order = copy(a:module.config_order)
  for arg in args
    let name = matchstr(arg, '^\w\+\ze=')
    if !empty(name)
      let value = matchstr(arg, '^\w\+=\zs.*')
    elseif len(a:module.config) == 1
      let [name, value] = [keys(a:module.config)[0], arg]
    elseif !empty(order)
      let name = remove(order, 0)
      let value = arg
    endif
    if empty(name)
      throw 'could not parse the option: ' . arg
    endif
    if !has_key(a:module.config, name)
      throw 'unknown option: ' . name
    endif
    if type(a:module.config[name]) == type([])
      call add(a:module.config[name], value)
    else
      let a:module.config[name] = value
    endif
  endfor
endfunction

" Get the text of specified region.
" region = {
"   'first': [line, col, off],
"   'last': [line, col, off],
"   'wise': 'v' / 'V' / "\<C-v>",
"   'selection': 'inclusive' / 'exclusive' / 'old'
" }
function! s:get_region(region) abort
  let wise = get(a:region, 'wise', 'V')
  if wise ==# 'V'
    return join(getline(a:region.first[0], a:region.last[0]), "\n")
  endif

  if has_key(a:region, 'selection')
    let save_sel = &selection
    let &selection = a:region.selection
  endif
  let [reg_save, reg_save_type] = [getreg('"'), getregtype('"')]
  let [pos_c, pos_s, pos_e] = [getpos('.'), getpos("'<"), getpos("'>")]

  call cursor(a:region.first)
  execute 'silent normal!' wise
  call cursor(a:region.last)
  normal! y
  let selected = @"

  " Restore '< '>
  call setpos('.', pos_s)
  execute 'normal!' wise
  call setpos('.', pos_e)
  execute 'normal!' wise
  call setpos('.', pos_c)

  call setreg('"', reg_save, reg_save_type)

  if exists('save_sel')
    let &selection = save_sel
  endif
  return selected
endfunction


" Wrapper functions for compatibility.  {{{1
function! quickrun#register_runner(name, runner) abort
  return quickrun#register_module('runner', a:name, a:runner)
endfunction
function! quickrun#register_outputter(name, outputter) abort
  return quickrun#register_module('outputter', a:name, a:outputter)
endfunction
function! quickrun#register_hook(name, hook) abort
  return quickrun#register_module('hook', a:name, a:hook)
endfunction
function! quickrun#register_module(kind, name, module) abort
  return quickrun#module#register(
  \        extend(a:module, {'kind': a:kind, 'name': a:name}, 'keep'))
endfunction
function! quickrun#get_module(kind, ...) abort
  return call('quickrun#module#get', [a:kind] + a:000)
endfunction


" Register the default modules.  {{{1
call quickrun#module#load()


let &cpo = s:save_cpo
unlet s:save_cpo
