" Vimscript Setup: {{{1
let s:save_cpo = &cpo
set cpo&vim

let s:BinaryOk = 0
let s:pwd = ""

" Private Functions: {{{1
function! s:CheckBinary() abort
  if executable(g:git_appraise_binary)
    return 1
  else
    if g:git_appraise_binary == ""
      throw "git-appraise: git_appraise_binary not set"
    endif
    throw "git-appraise: git_appraise_binary not executable"
  endif
endfunction

function! s:SummaryBinds() abort

endfunction

function! s:SummaryBuffer(list) abort
  if !bufexists('git-appraise')
    badd git-appraise 
    call setbufvar('git-appraise', '&bufhidden', 'hide')
    call setbufvar('git-appraise', '&buflisted', 0)
    call setbufvar('git-appraise', '&buflisted', 0)
    call setbufvar('git-appraise', '&buftype', 'nofile')
  endif
  buffer git-appraise
  call setbufvar('git-appraise', '&readonly', 0)
  norm! gg"_dG
  for l:item in a:list
    call append('$', '[' . l:item[0] . '] ' . l:item[1] . ' ' . l:item[2])
  endfor
  norm! gg"_dd
  call setbufvar('git-appraise', '&readonly', 1)
endfunction

function! s:SwapCwd() abort
  let s:pwd = getcwd()
  cd %:p:h
endfunction

function! s:UnSwapCwd() abort
  execute "cd" s:pwd
  let s:pwd = ""
endfunction

function! s:SortList(i1, i2) abort
  return a:i1[0] == a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunction

function! s:GetList() abort
  let l:cmd = g:git_appraise_binary . " list"
  let l:output = system(l:cmd)
  let l:list_raw = split(l:output, '\s*\n\s*')
  let l:list = []
  let l:current = []
  for l:item in l:list_raw[1:]
    if len(l:current) == 0
      let l:details = matchlist(l:item, '\[\([a-z]\+\)\] \([a-z0-9]\+\)') 
      call add(l:current, l:details[1])
      call add(l:current, l:details[2])
    else 
      call add(l:current, l:item)
      call add(l:list, l:current)
      let l:current = []
    endif
  endfor

  return sort(l:list, "s:SortList")
endfunction

" Library Interface: {{{1
function! gitappraise#some_function() abort
  echo "Hello world!"
endfunction

" Teardown:{{{1
let &cpo = s:save_cpo

" Misc: {{{1
" vim: set ft=vim ts=2 sw=2 tw=78 et fdm=marker:
