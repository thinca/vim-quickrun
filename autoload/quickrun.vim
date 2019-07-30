" Run commands quickly.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:V = vital#quickrun#new().load(
\   'Data.List',
\   'System.File',
\   'System.Filepath',
\   'Vim.Message',
\   'Process')
unlet! g:quickrun#V
let g:quickrun#V = s:V
lockvar! g:quickrun#V

let s:is_win = has('win32')

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
\   'exec': '%c /c %s %a',
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
\ 'eta': {
\   'command': 'eta',
\   'exec': ['%c %s', 'java -jar %s:h/Run%s:t:r.jar'],
\   'tempfile': '%{tempname()}.hs',
\   'hook/sweep/files': ['%S:p:h/Run%S:t:r.jar', '%S:p:r.jar', '%S:p:r.hi'],
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
\ 'idris': {
\   'command': 'idris',
\   'exec': ['%c %o %s --output %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{tempname()}.idr',
\   'hook/sweep/files': ['%S:p:r', '%S:p:r.ibc'],
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
\ 'julia': {
\   'command': 'julia',
\ },
\ 'kotlin': {
\    'command': 'java',
\    'exec': ['kotlinc %o %s -include-runtime -d %s:p:r.jar', '%c -jar %s:p:r.jar'],
\    'tempfile': '%{tempname()}.kt',
\    'hook/sweep/files': '%S:p:r.jar'
\ },
\ 'kotlin/concurrent_process': {
\   'command': 'kotlinc-jvm',
\   'exec': '%c',
\   'tempfile': '%{tempname()}.kt',
\   'runner': 'concurrent_process',
\   'runner/concurrent_process/load': ':load %S',
\   'runner/concurrent_process/prompt': '>>> ',
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
\           executable('markdown_py') ? 'markdown/markdown_py':
\           executable('markdown') ? 'markdown/discount': '',
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
\ 'markdown/discount': {
\   'command': 'markdown',
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
\ 'pony': {
\   'command': 'ponyc',
\   'exec': ['%c -V 0 %o', '%s:p:h/%s:p:h:t %a'],
\   'tempfile': '%{tempname()}.pony',
\   'hook/sweep/files': ['%S:p:h/%S:p:h:t'],
\   'hook/cd/directory': '%S:p:h',
\ },
\ 'prolog': {
\   'type': executable('swipl') ? 'prolog/swi' :
\           executable('gprolog') ? 'prolog/gnu' : '',
\ },
\ 'prolog/gnu': {
\   'command': 'gprolog',
\   'cmdopt': '--consult-file',
\   'exec': '%c %o %s %a --query-goal halt',
\ },
\ 'prolog/swi': {
\   'command': 'swipl',
\   'cmdopt': '--quiet -s',
\   'exec': '%c %o %s %a -g halt',
\ },
\ 'ps1': {
\   'exec': '%c %o -File %s %a',
\   'command': 'powershell.exe',
\   'cmdopt': '-ExecutionPolicy RemoteSigned',
\   'tempfile': '%{tempname()}.ps1',
\   'hook/output_encode/encoding': '&termencoding',
\ },
\ 'purescript': {
\   'type': executable('pulp') ? 'purescript/pulp' : '',
\ },
\ 'purescript/pulp': {
\   'command': 'pulp',
\   'cmdopt': '--monochrome',
\   'exec': '%c %o run',
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
\   'cmdopt': '--simple-prompt',
\   'runner': 'concurrent_process',
\   'runner/concurrent_process/load': 'load %s',
\   'runner/concurrent_process/prompt': '>> ',
\ },
\ 'ruby/pry': {
\   'command': 'pry',
\   'cmdopt': '--no-color --simple-prompt',
\   'runner': 'concurrent_process',
\   'runner/concurrent_process/load': 'load %s',
\   'runner/concurrent_process/prompt': '>> ',
\ },
\ 'rust': {
\   'command': 'rustc',
\   'exec': ['%c %o %s -o %s:p:r', '%s:p:r %a'],
\   'tempfile': '%{fnamemodify(tempname(), ":r")}.rs',
\   'hook/shebang/enable': 0,
\   'hook/sweep/files': '%S:p:r',
\ },
\ 'rust/cargo': {
\   'command': 'cargo',
\   'exec': '%c run %o',
\   'hook/shebang/enable': 0,
\ },
\ 'scala': {
\   'exec': ['scalac %o -d %s:p:h %s', '%c -cp %s:p:h %s:t:r %a'],
\   'hook/output_encode/encoding': '&termencoding',
\   'hook/sweep/files': '%S:p:r.class',
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
\           executable('sqlite3') ? 'sql/sqlite3' :
\           executable('sqlplus') ? 'sql/oracle' :
\           executable('sqlcmd') ? 'sql/mssql' : '',
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
\ 'sql/oracle': { 
\   'command': 'sqlplus',
\   'exec': ['%c %o \@%s'],
\   'hook/output_encode/enable' : 1,
\   'hook/output_encode/encoding' : '&termencoding',
\ },
\ 'sql/mssql': { 
\   'command': 'sqlcmd',
\   'exec': ['%c %o -i %s'],
\   'hook/output_encode/enable' : 1,
\   'hook/output_encode/encoding' : '&termencoding',
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
\   'type': executable('ts-node') ? 'typescript/ts-node' :
\           executable('tsc') ? 'typescript/tsc' : '',
\ },
\ 'typescript/ts-node': {
\   'command': 'ts-node',
\   'cmdopt': '--compilerOptions ''{"target": "es2015"}''',
\   'exec': '%c %o %s',
\ },
\ 'typescript/tsc': {
\   'command': 'tsc',
\   'exec': ['%c --target es5 --module commonjs %o %s', 'node %s:r.js'],
\   'tempfile': '%{tempname()}.ts',
\   'hook/sweep/files': ['%S:p:r.js'],
\ },
\ 'vim': {
\   'command': ':source',
\   'exec': '%C %s',
\   'hook/eval/template': 'echo %s',
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


" Deprecated functions.  {{{1
function quickrun#new(...) abort
  return call('quickrun#session#new', a:000)
endfunction

function quickrun#session(key, ...) abort
  let session = quickrun#session#get(a:key)
  if a:0 && !empty(session)
    return call(session[a:1], a:000[1 :], session)
  endif
  return session
endfunction

function quickrun#sweep_sessions() abort
  call quickrun#session#sweep()
endfunction

function quickrun#is_running() abort
  return quickrun#session#exists()
endfunction


" Interfaces.  {{{1
function quickrun#run(...) abort
  call quickrun#session#sweep()

  let session = quickrun#new(a:0 ? a:1 : {})

  " for debug
  if has_key(session.base_config, 'debug')
    let g:{matchstr(session.base_config.debug, '\h\w*')} = session
  endif

  call session.run()
endfunction

" function for |g@|.
function quickrun#operator(wise) abort
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
function quickrun#command(config, use_range, line1, line2) abort
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
function quickrun#complete(lead, cmd, pos) abort
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
      return filter(list, 'v:val =~# "^" . a:lead')
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
function quickrun#expand(input) abort
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
function quickrun#execute(cmd) abort
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
function quickrun#config(config) abort
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

function quickrun#trigger_keys() abort
  if mode() =~# '[iR]'
    let input = "\<C-r>\<ESC>"
  else
    let input = "g\<ESC>" . (0 < v:count ? v:count : '')
  endif
  call feedkeys(input, 'n')
endfunction


" Misc functions.  {{{1
function s:parse_argline(argline) abort
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

function s:build_config_from_arglist(arglist) abort
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


" Register the default modules.  {{{1
call quickrun#module#load()
