" Vimscript Setup: {{{1
let s:save_cpo = &cpo
set cpo&vim

let s:BinaryOk = 0
let s:pwd = ""

" Private Functions: {{{1
function! s:CheckBinary()
  if executable(g:git_appraise_binary)
    return 1
  else
    if g:git_appraise_binary == ""
      throw "git-appraise: git_appraise_binary not set"
      return 0
    endif
    throw "git-appraise: git_appraise_binary not executable"
    return 0
  endif
endfunction

function! s:SwapCwd()
  let s:pwd = getcwd()
  cd %:p:h
endfunction

function! s:UnSwapCwd()
  execute "cd" s:pwd
  let s:pwd = ""
endfunction

function! s:SortList(i1, i2) abort
  return a:i1[0] == a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunction

function! s:GetList() abort
  let l:cmd = g:git_appraise_binary . " list"
  let l:list_raw = split(system(l:cmd), '\s*\n\s*')
  let l:list = []
  let l:current = []
  for l:item in l:list_raw[1:]
    if len(l:current) == 0
      call add(l:current, l:item)
    else 
      call add(l:current, l:item)
      call add(l:list, l:current)
      let l:current = []
    endif
  endfor

  return sort(l:list, "s:SortList")
endfunction

" Library Interface: {{{1
function! gitappraise#some_function()
  echo "Hello world!"
endfunction

" Teardown:{{{1
let &cpo = s:save_cpo

" Misc: {{{1
" vim: set ft=vim ts=2 sw=2 tw=78 et fdm=marker:
