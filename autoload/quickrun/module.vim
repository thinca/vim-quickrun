" Module system for quickrun.vim.
" Version: 0.6.0dev
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:modules = {}

" Templates.  {{{1
let s:templates = {}
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
        \            self.name . '/' . name,
        \            self.kind . '/' . name,
        \            name]
          if has_key(config, conf)
            let val = config[conf]
            if s:is_array(self.config[name])
              let self.config[name] += s:is_array(val) ? val : [val]
            else
              let self.config[name] = val
            endif
            unlet val
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
function! s:module.sweep()
endfunction

" Template of runner.  {{{2
let s:templates.runner = deepcopy(s:module)
function! s:templates.runner.run(commands, input, session)
  throw 'quickrun: A runner should implements run()'
endfunction
function! s:templates.runner.shellescape(str)
  if s:is_cmd_exe()
    return '^"' . substitute(substitute(substitute(a:str,
    \             '[&|<>()^"%]', '^\0', 'g'),
    \             '\\\+\ze"', '\=repeat(submatch(0), 2)', 'g'),
    \             '\^"', '\\\0', 'g') . '^"'
  endif
  return shellescape(a:str)
endfunction

" Template of outputter.  {{{2
let s:templates.outputter = deepcopy(s:module)
function! s:templates.outputter.start(session)
endfunction
function! s:templates.outputter.output(data, session)
  throw 'quickrun: An outputter should implements output()'
endfunction
function! s:templates.outputter.finish(session)
endfunction

" Template of hook.  {{{2
let s:templates.hook = deepcopy(s:module)
function! s:templates.hook.priority(point)
  return 0
endfunction
let s:templates.hook.config.enable = 1


" functions.  {{{1
function! quickrun#module#register(module, ...)
  call s:validate_module(a:module)
  let overwrite = a:0 && a:1
  let kind = a:module.kind
  let name = a:module.name
  if !has_key(s:modules, kind)
    let s:modules[kind] = {}
  endif
  if overwrite || !quickrun#module#exists(kind, name)
    let module = s:deepextend(deepcopy(s:templates[kind]), a:module)
    let s:modules[kind][name] = module
  endif
endfunction

function! quickrun#module#unregister(...)
  if a:0 && type(a:1) == type({})
    let kind = get(a:module, 'kind', '')
    let name = get(a:module, 'name', '')
  elseif 2 <= a:0
    let kind = a:1
    let name = a:2
  else
    return 0
  endif

  if quickrun#module#exists(kind, name)
    call remove(s:modules[kind], name)
    return 1
  endif
  return 0
endfunction

function! quickrun#module#exists(kind, name)
  return has_key(s:modules, a:kind) && has_key(s:modules[a:kind], a:name)
endfunction

function! quickrun#module#get(kind, ...)
  if !has_key(s:modules, a:kind)
    throw 'quickrun: Unknown kind of module: ' . a:kind
  endif
  if a:0 == 0
    return values(s:modules[a:kind])
  endif
  let name = a:1
  if !has_key(s:modules[a:kind], name)
    throw 'quickrun: Unregistered module: ' . a:kind . '/' . name
  endif
  return s:modules[a:kind][name]
endfunction

function! quickrun#module#get_kinds()
  return keys(s:modules)
endfunction

function! s:validate_module(module)
  if !has_key(a:module, 'kind')
    throw 'quickrun: A module must have a "kind" attribute.'
  endif
  if !has_key(a:module, 'name')
    throw 'quickrun: A module must have a "name" attribute.'
  endif
endfunction

let s:list_t = type([])
let s:dict_t = type({})
function! s:deepextend(a, b)
  let type_a = type(a:a)
  if type_a != type(a:b)
    throw ''
  endif
  if type_a == s:list_t
    call extend(a:a, a:b)
  elseif type_a == s:dict_t
    for [k, V] in items(a:b)
      let copied = 0
      if has_key(a:a, k)
        let type_k = type(a:a[k])
        if type_k == type(V) &&
        \  (type_k == s:list_t || type_k == s:dict_t)
          call s:deepextend(a:a[k], V)
          let copied = 1
        endif
      endif
      if !copied
        let a:a[k] = deepcopy(V)
      endif
      unlet V
    endfor
  else
    throw ''
  endif
  return a:a
endfunction

function! s:is_cmd_exe()
  return &shell =~? 'cmd\.exe'
endfunction

function! s:is_array(val)
  return type(a:val) == type([])
endfunction


let &cpo = s:save_cpo
