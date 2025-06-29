" Swift support for TagBar
let g:tagbar_type_swift = {
    \ 'ctagsbin': '/usr/local/bin/ctags',
    \ 'ctagsargs': '--options=' . expand('~/.ctags') . ' -f - --format=2 --excmd=pattern --fields=nksSafetE --sort=no --append=no',
    \ 'kinds': [
        \ 'n:Enums',
        \ 't:Typealiases',
        \ 'p:Protocols', 
        \ 's:Structs',
        \ 'c:Classes',
        \ 'a:Actors',
        \ 'f:Functions',
        \ 'v:Variables',
        \ 'e:Extensions'
    \ ],
    \ 'sro': '.',
    \ 'kind2scope': {
        \ 'c': 'class',
        \ 's': 'struct',
        \ 'a': 'actor',
        \ 'e': 'extension',
        \ 'p': 'protocol',
        \ 'n': 'enum'
    \ },
    \ 'scope2kind': {
        \ 'class': 'c',
        \ 'struct': 's',
        \ 'actor': 'a',
        \ 'extension': 'e',
        \ 'protocol': 'p',
        \ 'enum': 'n'
    \ },
    \ 'sort': 0
\ }