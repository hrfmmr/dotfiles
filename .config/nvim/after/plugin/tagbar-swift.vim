" Swift support for TagBar
let g:tagbar_type_swift = {
    \ 'ctagstype': 'Swift',
    \ 'kinds': [
        \ 'n:Enums',
        \ 't:Typealiases',
        \ 'p:Protocols', 
        \ 's:Structs',
        \ 'c:Classes',
        \ 'f:Functions',
        \ 'v:Variables',
        \ 'e:Extensions'
    \ ],
    \ 'sro': '.',
    \ 'kind2scope': {
        \ 'c': 'class',
        \ 's': 'struct',
        \ 'e': 'extension',
        \ 'p': 'protocol',
        \ 'n': 'enum'
    \ },
    \ 'scope2kind': {
        \ 'class': 'c',
        \ 'struct': 's',
        \ 'extension': 'e',
        \ 'protocol': 'p',
        \ 'enum': 'n'
    \ },
    \ 'sort': 0
\ }