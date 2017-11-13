# vim-quickrun

> Run a command and show its result quickly.

`quickrun` is Vim plugin to execute whole/part of editing file.
It provides `QuickRun` for it.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug),

```vim
Plug 'thinca/vim-quickrun'
```

## Examples

```vim
" Execute current buffer.
:QuickRun

" Execute current buffer from line 3 to line 6.
:3,6QuickRun

" Execute current buffer as perl program.
:QuickRun perl
```

## License

[zlib license](https://opensource.org/licenses/Zlib)
