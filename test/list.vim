let s:suite = themis#suite('list')
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
  call s:assert.equals(l:lines[0], '[pending]	abc123 Some new feature')
  call s:assert.equals(l:lines[1], '[approved]	def456 Fixing some bug')
endfunction

function! s:suite.get_list()
  execute "cd" s:test_git_path
  let l:list = s:gitappraise.GetList()
  let l:item = l:list[0]
  call s:assert.equals(l:item[0],'accepted')
  call s:assert.match(l:item[1],'[a-z0-9]\+')
  call s:assert.equals(l:item[2],'fixing all dem bugs')
  let l:item = l:list[1]
  call s:assert.equals(l:item[0],'pending')
  call s:assert.match(l:item[1], '[a-z0-9]\+')
  call s:assert.equals(l:item[2],'NEW commit!')
endfunction

function! s:suite.list_request_hash()
  new test_buffer
  call append(0, ['[pending] abc123 some new things', '[approved] def456 fixing some shit'])
  call cursor(1, 0)
  let l:hash = s:gitappraise.ListRequestHash()
  call s:assert.equals(l:hash, 'abc123')
  call cursor(2, 0)
  let l:hash = s:gitappraise.ListRequestHash()
  call s:assert.equals(l:hash, 'def456')
endfunction
