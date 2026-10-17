" jactionlint (jdx's actionlint fork) for GitHub workflow files.
"
" ALE's built-in actionlint linter can't drive it: it passes Go-style single-dash
" flags (-no-color, -oneline, -config-file), which jactionlint rejects. Reading
" stdin, jactionlint finds .github/jactionlint.yaml only through
" --stdin-filename, so the buffer's real path goes there (%s would be ALE's temp
" copy). The output matches actionlint's, so its handler is reused.

call ale#Set('yaml_jactionlint_executable', 'jactionlint')
call ale#Set('yaml_jactionlint_options', '')

function! s:GetCommand(buffer) abort
  let l:path = expand('#' . a:buffer . ':p')

  if l:path !~# '\v[/\\]\.github[/\\]workflows[/\\]'
    return ''
  endif

  return '%e --no-color --oneline'
  \   . ale#Pad(ale#Var(a:buffer, 'yaml_jactionlint_options'))
  \   . ' --stdin-filename=' . ale#Escape(l:path) . ' -'
endfunction

call ale#linter#Define('yaml', {
\   'name': 'jactionlint',
\   'executable': {b -> ale#Var(b, 'yaml_jactionlint_executable')},
\   'command': function('s:GetCommand'),
\   'callback': 'ale_linters#yaml#actionlint#Handle',
\})
