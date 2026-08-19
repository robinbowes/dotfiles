" TypeScript 7 language server for ALE.
"
" TypeScript 7 dropped the tsserver binary; the Go-native compiler ships as the
" typescript package's own tsc and speaks LSP directly via `tsc --lsp --stdio`.
" The linter is named tsgo because that is how the server identifies itself
" (serverInfo.name), even though the executable is tsc.
"
" Remove this file if ALE ever ships a linter of its own for the native server.

call ale#Set('typescript_tsgo_executable', 'tsc')
call ale#Set('typescript_tsgo_use_global', get(g:, 'ale_use_global_executables', 0))

function! s:GetProjectRoot(buffer) abort
  let l:tsconfig = ale#path#FindNearestFile(a:buffer, 'tsconfig.json')

  return !empty(l:tsconfig) ? fnamemodify(l:tsconfig, ':h') : ''
endfunction

call ale#linter#Define('typescript', {
\   'name': 'tsgo',
\   'lsp': 'stdio',
\   'executable': {b -> ale#path#FindExecutable(b, 'typescript_tsgo', [
\       'node_modules/.bin/tsc',
\   ])},
\   'command': '%e --lsp --stdio',
\   'project_root': function('s:GetProjectRoot'),
\})
