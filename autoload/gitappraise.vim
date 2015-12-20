" Vimscript Setup: {{{1
let s:save_cpo = &cpo
set cpo&vim

" Vital!
let s:V = vital#of('gitappraise')
let s:JSON = s:V.import('Web.JSON')

let s:BinaryOk = 0
let s:pwd = ""

" Private Functions: {{{1
" Utils: {{{2
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

function! s:SwapCwd() abort
  let s:pwd = getcwd()
  cd %:p:h
endfunction

function! s:UnSwapCwd() abort
  execute "cd" s:pwd
  let s:pwd = ""
endfunction

" List: {{{2
function! s:ListSyntax() abort
  syntax clear
  syn keyword GitAppraisePending pending contained
  syn keyword GitAppraiseAccepted accepted contained
  syn keyword GitAppraiseRejected rejected contained

  syn match GitAppraiseHash /\s\+[a-z0-9]\+ / contained

  syn match GitAppraiseSummaryStatus /^\[[a-z]\+\]/ contained contains=GitAppraisePending,GitAppraiseAccepted,GitAppraiseRejected
  syn match GitAppraiseSummaryDetails /^\[[a-z]\+\]\s\+[a-z0-9]\+ / contained contains=GitAppraiseSummaryStatus,GitAppraiseHash
  syn match GitAppraiseSummaryLine '^\[[a-z]\+\]\s\+[a-z0-9]\+ .*$' contains=GitAppraiseSummaryDetails

  hi GitAppraiseSummaryStatus term=bold cterm=bold gui=bold 
  hi GitAppraisePending term=bold cterm=bold gui=bold ctermfg=11 guifg=#f0c674
  hi GitAppraiseAccepted term=bold cterm=bold gui=bold ctermfg=193 guifg=#d7ffaf
  hi GitAppraiseRejected term=bold cterm=bold gui=bold ctermfg=9 guifg=#cc6666
  hi GitAppraiseHash ctermfg=13 guifg=#b294bb
endfunction

function! s:ListRequestHash() abort
  let l:line = getline('.')
  let l:hash = matchlist(l:line, '^\s*\[.*\]\s\+\([a-z0-9]*\)')[1]
  return l:hash
endfunction

function! s:ListBinds() abort
  nnoremap <buffer> <silent> <space> :call gitappraise#show(<SID>ListRequestHash())<CR>
  nnoremap <buffer> <silent> <CR> :call gitappraise#show(<SID>ListRequestHash())<CR>
  nnoremap <buffer> <silent> q :call bw!<CR>
  nnoremap <buffer> <silent> <ESC> :call bw!<CR>
endfunction

function! s:ListBuffer(list) abort
  if !bufexists('git-appraise')
    badd git-appraise 
  endif
  let l:summary_buffer = bufnr('git-appraise')
  call setbufvar(l:summary_buffer, '&bufhidden', 'hide')
  call setbufvar(l:summary_buffer, '&buflisted', 0)
  call setbufvar(l:summary_buffer, '&buftype', 'nofile')
  call setbufvar(l:summary_buffer, '&ft', 'gitappraise')
  execute 'silent keepa keepjump buffer' l:summary_buffer
  call setbufvar(l:summary_buffer, '&readonly', 0)
  norm! gg"_dG
  for l:item in a:list
    call append('$', '[' . l:item[0] . "]\t" . l:item[1] . ' ' . l:item[2])
  endfor
  norm! gg"_dd
  call setbufvar(l:summary_buffer, '&readonly', 1)
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
" Show: {{{2

function! s:Show(hash) abort
  let l:cmd = g:git_appraise_binary . " show -json " . a:hash
  let l:output = system(l:cmd)
  let l:show = s:JSON.decode(l:output)
  return l:show
endfunction

function! s:ShowDiff(hash) abort
  let l:cmd = g:git_appraise_binary . " show -diff " . a:hash
  let l:output = system(l:cmd)
  return l:output
endfunction

" Comment: {{{2
" Accept: {{{2
" Reject: {{{2
" Push: {{{2
" Pull: {{{2

" Library Interface: {{{1
function! gitappraise#show(hash) abort
  echo a:hash
endfunction

function! gitappraise#list() abort
  call s:SwapCwd()
  let l:list = s:GetList()
  call s:ListBuffer(l:list)
  call s:ListBinds()
  call s:ListSyntax()
  call s:UnSwapCwd()
endfunction

" Teardown:{{{1
let &cpo = s:save_cpo

" Misc: {{{1
" vim: set ft=vim ts=2 sw=2 tw=78 et fdm=marker:
