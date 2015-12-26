let s:suite = themis#suite('show')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

let s:original_cwd = getcwd()
let s:test_git_path = ""
let s:original_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')

function! s:suite.before()
  let g:git_appraise_binary = 'git-appraise'
  let l:rand = system("echo -n $RANDOM")
  let l:path = "/tmp/vim-git-appraise-test." . l:rand
  call system("mkdir " . l:path)
  execute "cd" l:path
  call system("git init")
  call system("echo 'test text' > test.txt")
  call system("git add --all")
  call system("git commit -m 'first commit!'")
  call system("git checkout -b new-feature")
  call system("echo 'ALL I WANT IS CAKE!' > test.txt")
  call system("git add --all")
  call system("git commit -m 'NEW commit!'")
  call system(g:git_appraise_binary . " request")
  call system("git checkout master")
  call system("git checkout -b bug-fix")
  call system("echo 'I LIKE PIE!' > test.txt")
  call system("git add --all")
  call system("git commit -m 'fixing all dem bugs'")
  call system(g:git_appraise_binary . " request")
  call system(g:git_appraise_binary . " accept")
  execute "cd" s:original_cwd
  let s:test_git_path = l:path
endfunction

function! s:suite.after()
  call system("rm -rf /tmp/vim-git-appraise-test.*")
  execute "cd" s:original_cwd
endfunction

function! s:suite.before_each()
  let l:current_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  let l:buffers_to_wipe = filter(l:current_buffers, 'index(s:original_buffers, v:val) == -1')
  for l:buffer in l:buffers_to_wipe
    execute 'bw!' . l:buffer
  endfor
endfunction

function! s:suite.show_returns_object_with_the_correct_elements()
  execute 'cd' s:test_git_path
  let l:list = system('git appraise list')
  let l:hash = matchlist(l:list, '\s*.*\] \([a-z0-9]\+\)\n\s*fixing all dem bugs')[1]
  let l:show = s:gitappraise.Show(l:hash)
  call s:assert.key_exists(l:show, 'comments')
  call s:assert.key_exists(l:show, 'resolved')
  call s:assert.key_exists(l:show, 'submitted')
  call s:assert.key_exists(l:show, 'request')
  call s:assert.key_exists(l:show, 'revision')
  call s:assert.equals(l:show.revision, l:hash)
  call s:assert.equals(l:show.request.reviewRef, 'refs/heads/bug-fix')
endfunction

function! s:suite.show_diff_gets_request_diff()
  execute 'cd' s:test_git_path
  let l:list = system('git appraise list')
  let l:hash = matchlist(l:list, '\s*.*\] \([a-z0-9]\+\)\n\s*fixing all dem bugs')[1]
  let l:diff = s:gitappraise.ShowDiff(l:hash)
endfunction

function! s:suite.show_buffer_creates_new_unlisted_buffer()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(bufexists('git-appraise://show'), 1)
  call s:assert.equals(getbufvar('git-appraise://show', '&buflisted'), 0)
endfunction

function! s:suite.show_buffer_creates_new_hidden_buffer()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(bufexists('git-appraise://show'), 1)
  call s:assert.equals(getbufvar('git-appraise://show', '&bufhidden'), 'hide')
endfunction

function! s:suite.show_buffer_creates_new_nofile_buffer()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(bufexists('git-appraise://show'), 1)
  call s:assert.equals(getbufvar('git-appraise://show', '&buftype'), 'nofile')
endfunction

function! s:suite.show_buffer_creates_new_readonly_buffer()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(bufexists('git-appraise://show'), 1)
  call s:assert.equals(getbufvar('git-appraise://show', '&readonly'), 1)
endfunction

function! s:suite.show_buffer_creates_new_buffer_with_diff_file_type()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(bufexists('git-appraise://show'), 1)
  call s:assert.equals(getbufvar('git-appraise://show', '&ft'), 'diff')
endfunction

function! s:suite.show_buffer_focuses_summary_buffer()
  call s:gitappraise.ShowBuffer('')
  call s:assert.equals(expand('%'), 'git-appraise://show')
endfunction

function! s:suite.show_buffer_is_populated_with_diff()
  let l:diff = "--- a/test.txt\n+++ b/test.txt"
  call s:gitappraise.ShowBuffer(l:diff)
  let l:lines = getbufline('git-appraise://show', 0, '$')
  call s:assert.equals(l:lines[0], '--- a/test.txt')
  call s:assert.equals(l:lines[1], '+++ b/test.txt')
endfunction
