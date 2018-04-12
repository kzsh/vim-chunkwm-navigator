" Maps <C-h/j/k/l> to switch vim splits in the given direction. If there are
" no more windows in that direction, forwards the operation to chunkwm.

if exists("g:loaded_chunkwm_navigator") || &cp || v:version < 700
  finish
endif
let g:loaded_chunkwm_navigator = 1

let s:direction_map = {
      \ 'h': 'west',
      \ 'j': 'south',
      \ 'k': 'north',
      \ 'l': 'east'
\ }

function! s:ChunkwmExecutable()
  return 'chunkc'
endfunction

function! s:UseChunkwmNavigatorMappings()
  return !get(g:, 'chunkwm_navigator_no_mappings', 0)
endfunction

function! s:InChunkwmSession()
  let l:cmd = 'command -v chunkc'
  let l:_ = system(l:cmd)
  if v:shell_error != 0
    return 0
  endif
  let l:_ = system('chunkc tiling::query --window name')
  if v:shell_error != 0
    return 0
  endif
  return 1
endfunction

function! s:ChunkwmCommand(args)
  let l:cmd = s:ChunkwmExecutable() . ' ' . a:args
  return system(l:cmd)
endfunction

let s:chunkwm_is_last_pane = 0
augroup chunkwm_navigator
  au!
  autocmd WinEnter * let s:chunkwm_is_last_pane = 0
augroup END

" Like `wincmd` but also change chunkwm panes instead of vim windows when needed.
function! s:ChunkwmWinCmd(direction)
  if s:InChunkwmSession()
    call s:ChunkwmAwareNavigate(a:direction)
  else
    call s:VimNavigate(a:direction)
  endif
endfunction

function! s:ShouldForwardNavigationBackToChunkwm(chunkwm_last_pane, at_tab_page_edge)
  return a:chunkwm_last_pane || a:at_tab_page_edge
endfunction

function! s:ChunkwmAwareNavigate(direction)
  let nr = winnr()
  call s:VimNavigate(a:direction)
  let at_tab_page_edge = (nr == winnr())
  " Forward the switch panes command to chunkwm if:
  " a) we're toggling between the last chunkwm pane;
  " b) we tried switching windows in vim but it didn't have effect.
  if at_tab_page_edge
    let args = 'tiling::window --focus ' . get(s:direction_map, a:direction, '')
    silent call s:ChunkwmCommand(args)
    let s:chunkwm_is_last_pane = 1
  else
    let s:chunkwm_is_last_pane = 0
  endif
endfunction

function! s:VimNavigate(direction)
  try
    execute 'wincmd ' . a:direction
  catch
    echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd k' | echohl None
  endtry
endfunction

command! ChunkwmNavigateLeft call s:ChunkwmWinCmd('h')
command! ChunkwmNavigateDown call s:ChunkwmWinCmd('j')
command! ChunkwmNavigateUp call s:ChunkwmWinCmd('k')
command! ChunkwmNavigateRight call s:ChunkwmWinCmd('l')

if s:UseChunkwmNavigatorMappings()
  nnoremap <silent> <c-a-h> :ChunkwmNavigateLeft<cr>
  nnoremap <silent> <c-a-j> :ChunkwmNavigateDown<cr>
  nnoremap <silent> <c-a-k> :ChunkwmNavigateUp<cr>
  nnoremap <silent> <c-a-l> :ChunkwmNavigateRight<cr>
endif
