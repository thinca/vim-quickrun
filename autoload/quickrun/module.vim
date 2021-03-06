" Module system for quickrun.vim.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

" Templates.  {{{1
let s:templates = {}
" Template of module.  {{{2
let s:module = {'config': {}, 'config_order': []}
function s:module.available() abort
  try
    call self.validate()
  catch
    return 0
  endtry
  return 1
endfunction
function s:module.validate() abort
endfunction
function s:module.init(session) abort
endfunction
function s:module.sweep() abort
endfunction

" Template of runner.  {{{2
let s:templates.runner = deepcopy(s:module)
function s:templates.runner.run(commands, input, session) abort
  throw 'quickrun: A runner must implement run()'
endfunction
function s:templates.runner.shellescape(str) abort
  return shellescape(a:str)
endfunction

" Template of outputter.  {{{2
let s:templates.outputter = deepcopy(s:module)
function s:templates.outputter.start(session) abort
endfunction
function s:templates.outputter.output(data, session) abort
  throw 'quickrun: An outputter must implement output()'
endfunction
function s:templates.outputter.finish(session) abort
endfunction

" Template of hook.  {{{2
let s:templates.hook = deepcopy(s:module)
function s:templates.hook.priority(point) abort
  return 0
endfunction
let s:templates.hook.config.enable = 1

let s:modules = map(copy(s:templates), '{}')


" functions.  {{{1
function quickrun#module#build(kind, module) abort
  return s:deepextend(deepcopy(s:templates[a:kind]), a:module)
endfunction

function quickrun#module#register(module, ...) abort
  call s:validate_module(a:module)
  let overwrite = a:0 && a:1
  let kind = a:module.kind
  let name = a:module.name
  if !has_key(s:modules, kind)
    let s:modules[kind] = {}
  endif
  if overwrite || !quickrun#module#exists(kind, name)
    let s:modules[kind][name] = quickrun#module#build(kind, a:module)
  endif
endfunction

function quickrun#module#unregister(...) abort
  if a:0 && type(a:1) == v:t_dict
    let kind = get(a:1, 'kind', '')
    let name = get(a:1, 'name', '')
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

function quickrun#module#exists(kind, name) abort
  return has_key(s:modules, a:kind) && has_key(s:modules[a:kind], a:name)
endfunction

function quickrun#module#get(kind, ...) abort
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

function quickrun#module#get_kinds() abort
  return keys(s:modules)
endfunction

function quickrun#module#load(...) abort
  let overwrite = a:0 && a:1
  for kind in keys(s:templates)
    let pat = 'autoload/quickrun/' . kind . '/*.vim'
    for name in map(split(globpath(&runtimepath, pat), "\n"),
    \               'fnamemodify(v:val, ":t:r")')
      try
        let module = quickrun#{kind}#{name}#new()
        let module.kind = kind
        let module.name = name
        call quickrun#module#register(module, overwrite)
      catch /:E\%(117\|716\):/
      endtry
    endfor
  endfor
endfunction

function s:validate_module(module) abort
  if !has_key(a:module, 'kind')
    throw 'quickrun: A module must have a "kind" attribute.'
  endif
  if !has_key(a:module, 'name')
    throw 'quickrun: A module must have a "name" attribute.'
  endif
endfunction

function s:deepextend(a, b) abort
  let type_a = type(a:a)
  if type_a != type(a:b)
    throw 'deepextend: Different type: ' . string(a:a) . ' : ' . string(a:b)
  endif
  if type_a == v:t_list
    call extend(a:a, a:b)
  elseif type_a == v:t_dict
    for [k, V] in items(a:b)
      let copied = 0
      if has_key(a:a, k)
        let type_k = type(a:a[k])
        if type_k == type(V) &&
        \  (type_k == v:t_list || type_k == v:t_dict)
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
    throw 'deepextend: Unsupported type: ' . string(a:a)
  endif
  return a:a
endfunction
