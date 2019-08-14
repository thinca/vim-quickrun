let s:V = g:quickrun#V


function quickrun#session#new(config) abort
  let session = copy(s:Session)
  call session.initialize(a:config)
  return session
endfunction

function quickrun#session#get(key) abort
  return get(s:sessions, a:key, {})
endfunction

function quickrun#session#call(key, func, ...) abort
  let session = quickrun#session#get(a:key)
  if !empty(session)
    return call(session[a:func], a:000, session)
  endif
endfunction

function quickrun#session#sweep() abort
  call map(keys(s:sessions), 's:dispose_session(v:val)')
endfunction

function quickrun#session#exists() abort
  return !empty(s:sessions)
endfunction


let s:sessions = {}  " Store for sessions.

function s:save_session(session) abort
  let key = has('reltime') ? reltimestr(reltime()) : string(localtime())
  let s:sessions[key] = a:session
  return key
endfunction

function s:dispose_session(key) abort
  if has_key(s:sessions, a:key)
    let session = remove(s:sessions, a:key)
    call session.sweep()
  endif
endfunction


let s:Session = {}  " {{{1
" Initialize of instance.
function s:Session.initialize(config) abort
  let self.base_config = a:config
endfunction

" The option is appropriately set referring to default options.
function s:Session.normalize(config) abort
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

      if !&l:binary &&
      \  (!exists('&fixendofline') || &l:fixendofline || &l:endofline)
        let body .= "\n"
      endif
      if &l:fileformat ==# 'mac'
        let body = substitute(body, "\n", "\r", 'g')
      elseif &l:fileformat ==# 'dos'
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

function s:Session.setup() abort
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

function s:Session.make_module(kind, line) abort
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

function s:Session.run() abort
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

function s:Session.continue() abort
  let self._continue_key = s:save_session(self)
  return self._continue_key
endfunction

function s:Session.output(data) abort
  let context = {'data': a:data}
  call self.invoke_hook('output', context)
  if context.data !=# ''
    call self.outputter.output(context.data, self)
  endif
endfunction

function s:Session.finish(...) abort
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
function s:Session.build_command(tmpl) abort
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

function s:Session.tempname(...) abort
  let name = a:0 ? a:1 : tempname()
  if !has_key(self, '_temp_names')
    let self._temp_names = []
  endif
  call add(self._temp_names, name)
  return name
endfunction

" Sweep the session.
function s:Session.sweep() abort
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

function s:Session.invoke_hook(point, ...) abort
  let context = a:0 ? a:1 : {}
  let func = 'on_' . a:point
  let hooks = copy(self.hooks)
  let hooks = map(hooks, '[v:val, s:get_hook_priority(v:val, a:point)]')
  let hooks = s:V.Data.List.sort_by(hooks, 'v:val[1]')
  let hooks = map(hooks, 'v:val[0]')
  for hook in hooks
    if has_key(hook, func) && type(hook[func]) is# v:t_func
      call call(hook[func], [self, context], hook)
    endif
  endfor
endfunction

function s:get_hook_priority(hook, point) abort
  try
    return a:hook.priority(a:point) - 0
  catch
    return 0
  endtry
endfunction

function s:build_module(module, configs) abort
  for config in a:configs
    if type(config) == type({})
      for name in keys(a:module.config)
        for conf in [a:module.kind . '/' . a:module.name . '/' . name,
        \            a:module.name . '/' . name,
        \            a:module.kind . '/' . name,
        \            name]
          if has_key(config, conf)
            let val = config[conf]
            if type(a:module.config[name]) is# v:t_list
              let a:module.config[name] += type(val) is# v:t_list ? val : [val]
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

function s:parse_module_option(module, argline) abort
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
function s:get_region(region) abort
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
