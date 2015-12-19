let s:suite = themis#suite('buffers')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

let s:original_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')

function! s:suite.before_each()
  let l:current_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  let l:buffers_to_wipe = filter(l:current_buffers, 'index(s:original_buffers, v:val) > -1')
  for l:buffer in l:buffers_to_wipe
    execute 'bw!' . l:buffer
  endfor
endfunction

function! s:suite.list_buffer_creates_new_unlisted_buffer()
  let l:list = []
  call s:gitappraise.ListBuffer(l:list)
  call s:assert.equals(bufexists('git-appraise'), 1)
  call s:assert.equals(getbufvar('git-appraise', '&buflisted'), 0)
endfunction

function! s:suite.list_buffer_creates_new_hidden_buffer()
  let l:list = []
  call s:gitappraise.ListBuffer(l:list)
  call s:assert.equals(bufexists('git-appraise'), 1)
  call s:assert.equals(getbufvar('git-appraise', '&bufhidden'), 'hide')
endfunction

function! s:suite.list_buffer_creates_new_nofile_buffer()
  let l:list = []
  call s:gitappraise.ListBuffer(l:list)
  call s:assert.equals(bufexists('git-appraise'), 1)
  call s:assert.equals(getbufvar('git-appraise', '&buftype'), 'nofile')
endfunction

function! s:suite.list_buffer_creates_new_readonly_buffer()
  let l:list = []
  call s:gitappraise.ListBuffer(l:list)
  call s:assert.equals(bufexists('git-appraise'), 1)
  call s:assert.equals(getbufvar('git-appraise', '&readonly'), 1)
endfunction

function! s:suite.list_buffer_focuses_summary_buffer()
  let l:list = []
  call s:gitappraise.ListBuffer(l:list)
  call s:assert.equals(expand('%'), 'git-appraise')
endfunction

function! s:suite.list_buffer_is_populated_with_list()
  let l:list = [['pending', 'abc123', 'Some new feature'], ['approved', 'def456', 'Fixing some bug']]
  call s:gitappraise.ListBuffer(l:list)
  let l:lines = getbufline('git-appraise', 0, '$')
  call s:assert.equals(l:lines[0], '[pending] abc123 Some new feature')
  call s:assert.equals(l:lines[1], '[approved] def456 Fixing some bug')
endfunction
