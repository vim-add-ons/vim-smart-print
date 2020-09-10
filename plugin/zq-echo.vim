" ·•« Zero-Quote Echo Vim Plugin »•·   ·•« vim-add-ons/zq-echo »•·
" Copyright (c) 2020 « Sebastian Gniazdowski ».
" License: « Gnu GPL v3 ».
"
" A :ZQEcho command that requires literally °ZERO° quoting of its input — it'll
" by itself detect any variables and expressions, differentiate them from
" regular text and then expand constructing the final message. "But :echom also
" 'expands' variables, by design" you'll maybe think. That's true, ZQEcho works
" somewhat in a «reversed» way — it doesn't require to quote regular text
" (unlike echom) ↔ THIS IS THE CANDY — and it takes actions to elevate variables
" and expressions back into their special meaning.
"
" Also, it supports:
" — «multi-color» messages with a custom-message «history»,
" — automatic, easy to activate (ZQEcho! … — simply append the bang +optional
"   count ↔ the timeout) «asynchroneous» display of the message via a
"   «timer-based» callback,
" - ability to «pause» Vim for a specified number of seconds, so that the
"   message will not be missed or overwritten by some following message or a
"   status change.
"
" Examples:
" ---------
" :ZQEcho Hello World! You can use any Unicode glyph without quoting: „≈ß•°×∞”
" :2ZQEcho Prepend with a count ↔ a message log-level AND also a distinct color,
" :ZQEcho %1Red %2Green %3Yellow %4Blue %5Magenta %6Cyan %7White %0Error
" :ZQEcho Above is the short-color format. The long one allows to specify any
"       \ hl-group: %Identifier.Hello world!
" :ZQEcho Provided are color-named hl-groups, like: %gold. %lblue. etc.
"
" Variable/Expression-Examples:
" -----------------------------
" :ZQEcho To print a variable, simply include it, like: g:my_dict['my_field']
" :ZQEcho All data-types will be stringified, so that this works: g:my_dictionary,
"       \ g:my_list, v:argv, etc.
" :ZQEcho Function-like expressions are auto-evaluated, e.g.: toupper("hello!")
" :ZQEcho Include complex expressions by wrapping with parens, e.g.: (rand() % 5)
"
" Asynchroneous-printing:
" -----------------------
" :ZQEcho! I'll be printed from a timer-callback after 7 ms (default) 
" :200ZQEcho! Set time-out to 200 ms ↔ counts > 25 aren't log-levels, but timeouts

"""""""""""""""""" THE SCRIPT BODY {{{

" Variable initialization {{{
" Initialize globals.
" Retain previous messages ↔ allow reloading the plugin preserving the state.
let g:zq_messages = get(g:, 'zq_messages', [])
" A global, common timer-list for pausing…
let g:timers = get(g:, 'timers', [])

" Session-variables initialization.
" zq_-prefix is being used for easier completing.
let s:zq_MessagesCmd_state = 0
let s:zq_deferredMessagesQueue = get(s:, 'zq_deferredMessagesQueue', [])
let s:zq_timers = g:timers
let s:zq_s_dict_providers = get(s:, 'zq_s_dict_providers', {})
let s:zq_loaded_s_dicts = get(s:, 'zq_loaded_s_dicts', [])
" }}}
" Highlight groups… {{{
hi! zq_norm ctermfg=7
" Blue colors…
hi! zq_blue ctermfg=27
hi! zq_blue2 ctermfg=32
hi! zq_blue3 ctermfg=75
hi! zq_lblue ctermfg=50
hi! zq_lblue2 ctermfg=75
hi! zq_lblue3 ctermfg=153
" Blue colors with bold…
hi! zq_bblue ctermfg=27    cterm=bold
hi! zq_bblue2 ctermfg=32   cterm=bold
hi! zq_bblue3 ctermfg=75   cterm=bold
hi! zq_lbblue ctermfg=50   cterm=bold
hi! zq_lbblue2 ctermfg=75  cterm=bold
hi! zq_lbblue3 ctermfg=153 cterm=bold
" yellow colors
hi! zq_gold ctermfg=220
hi! zq_yellow ctermfg=184
hi! zq_yellow2 ctermfg=226
hi! zq_yellow3 ctermfg=221
hi! zq_yellow4 ctermfg=190
" yellow colors with bold
hi! zq_bgold ctermfg=220    cterm=bold
hi! zq_byellow ctermfg=184  cterm=bold
hi! zq_byellow2 ctermfg=226 cterm=bold
hi! zq_byellow3 ctermfg=221 cterm=bold
hi! zq_byellow4 ctermfg=190 cterm=bold
hi! zq_orange ctermfg=94
hi! zq_orange2 ctermfg=172
" Green colors…
hi! zq_green ctermfg=green
hi! zq_green2 ctermfg=35
hi! zq_green3 ctermfg=40
hi! zq_green4 ctermfg=82
" Green colors + bold…
hi! zq_bgreen ctermfg=green cterm=bold
hi! zq_bgreen2 ctermfg=35   cterm=bold
hi! zq_bgreen3 ctermfg=40   cterm=bold
hi! zq_bgreen4 ctermfg=82   cterm=bold
" Light-green colors…
hi! zq_lgreen ctermfg=lightgreen
hi! zq_lgreen2 ctermfg=118
hi! zq_lgreen3 ctermfg=154
" Light-green colors + bold…
hi! zq_lbgreen ctermfg=lightgreen cterm=bold
hi! zq_lbgreen2 ctermfg=118 cterm=bold
hi! zq_lbgreen3 ctermfg=154 cterm=bold
" Rest of standard colors
hi! zq_magenta ctermfg=magenta
hi! zq_lmagenta ctermfg=lightmagenta
hi! zq_cyan ctermfg=cyan
hi! zq_lcyan ctermfg=lightcyan
hi! zq_white ctermfg=white
hi! zq_gray ctermfg=gray
hi! zq_lgray ctermfg=lightgray
" … + bold…
hi! zq_bmagenta ctermfg=magenta       cterm=bold
hi! zq_lbmagenta ctermfg=lightmagenta cterm=bold
hi! zq_bcyan ctermfg=cyan             cterm=bold
hi! zq_lbcyan ctermfg=lightcyan       cterm=bold
hi! zq_bwhite ctermfg=white           cterm=bold
hi! zq_bgray ctermfg=gray             cterm=bold
hi! zq_lbgray ctermfg=lightgray       cterm=bold
hi! zq_red ctermfg=red
hi! zq_bred ctermfg=red cterm=bold
" bold…
hi! zq_bold cterm=bold

hi! zq_bluemsg ctermfg=123 ctermbg=25 cterm=bold
hi! zq_goldmsg ctermfg=35 ctermbg=220 cterm=bold
" }}}

" FUNCTION: s:ZeroQuote_AddSDictFor(sfile,Ref) {{{
" Remembers the given s:-dict provider-function (a getter) reference in internal
" structures.
function! s:ZeroQuote_AddSDictFor(sfile,Ref)
    let l:the_sid = matchstr(string(a:Ref),'<SNR>\zs\d\+\ze_')
    let l:the_sfile = (a:sfile =~ 'function ') ? "" : a:sfile
    730ZQEcho! lev:6 p:0.5:%8 s:-dict offered %3 °• %4 a:Ref %3 °• %8 In-SID%5\|%2 l:the_sid %3 °• %8 Own-SID%5\|%2 (expand('<SID>')[5:-2])
    let s:zq_s_dict_providers[l:the_sid] = [ a:Ref, l:the_sfile ]
endfunc
" }}}

" User-commands definitions {{{
" :ZQEcho — the main command.
command! -nargs=+ -count=4 -bang -bar -complete=var ZQEcho call s:ZeroQuote_ZQEchoCmdImpl(<count>,<q-bang>,expand("<sflnum>"),
            \ s:ZeroQuote_evalArgs([<f-args>],exists("l:")?(l:):{},exists("a:")?(a:):{}))

" :ZQSetSDictFunc — an API to offer an s:-dict getter function.
command! -nargs=1 ZQSetSDictFunc call s:ZeroQuote_AddSDictFor(expand("<sfile>"),<args>)

" :Messages command.
if exists(":Messages")
    700ZQEcho! lev:7 %1WARNING%-: A command %2 :Messages %- already existed. It has been %1overwritten%-…
endif
command! -nargs=? Messages call Messages(<q-args>)

" Debugging command.
com! -nargs=* -complete=command ZQDebug <args>
" }}}

"""""""""""""""""" THE END OF THE SCRIPT BODY }}}

" FUNCTION: s:ZeroQuote_ZQEcho(hl,...) {{{
" 0 - error         LLEV=0 will show only them
" 1 - warning       LLEV=1
" 2 - info          …
" 3 - notice        …
" 4 - debug         …
" 5 - debug2        …
function! s:ZeroQuote_ZQEcho(hl, ...)
    " Log only warnings and errors by default.
    if a:hl < 7 && a:hl > get(g:,'zqecho_log_level', 1) || a:0 == 0
        return
    endif

    " The input…
    let args = copy(a:000[0])

    " Strip the line-number argument for the user- (count>=7) messages.
    if a:hl >= 7 && type(args[0]) == v:t_string &&
                \ args[0] =~ '\v^\s*(\%([0-9-]+\.=|[a-za-z0-9_-]*\.))=\s*\[\d*\]
                    \\s*(\%([0-9-]+\.=|[a-za-z0-9_-]*\.))=\s*$'
        let args = args[1:]
    endif
    " Normalize higlight/count.
    let hl = a:hl >= 7 ? (a:hl-7) : a:hl

    if !s:zq_MessagesCmd_state
        " Store the message in a custom history, accessible via :Messages
        " command.
        call add(g:zq_messages, extend([a:hl], args))
    endif

    " Finally: detect %…. infixes, select color, output the message bit by bit.
    "           0       1       2          3        4          5         6       7        8         9         10
    let c = ["Error", "red", "green2", "orange2", "blue2", "magenta", "lcyan", "white", "gray", "bluemsg", "goldmsg"]
    let [pause,new_msg_pre,new_msg_post] = s:ZeroQuote_GetPrefixValue('p%[ause]', join(args) )
    let msg = new_msg_pre . new_msg_post

    " Pre-process the message…
    let val = ""
    let [arr_hl,arr_msg] = [ [], [] ]
    while val != v:none
        let [val,new_msg_pre,new_msg_post] = s:ZeroQuote_GetPrefixValue('\%', msg)
        let msg = new_msg_post
        if val != v:none
            call add(arr_msg, new_msg_pre)
            call add(arr_hl, val)
        elseif !empty(new_msg_pre)
            if empty(arr_hl)
                call add(arr_msg, "")
                call add(arr_hl, hl)
            endif
            " The final part of the message.
            call add(arr_msg, new_msg_pre)
        endif
    endwhile

    " Clear the message window…
    echon "\r\r"
    echon ''

    " Post-process ↔ display…
    let idx = 0
    while idx < len(arr_hl)
        " Establish the color.
        let hl = !empty(arr_hl[idx]) ? (arr_hl[idx] =~# '^\d\+$' ?
                    \ c[arr_hl[idx]] : arr_hl[idx]) : c[hl]
        let hl = (hl !~# '\v^(-|\d+|zq_[a-z0-9_]+|WarningMsg|Error)$') ? 'zq_'.hl : hl
        let hl = hl == '-' ? 'None' : hl

        " The message part…
        if !empty(arr_msg[idx])
            echon arr_msg[idx]
        endif

        " The color…
        exe 'echohl ' . hl

        " Advance…
        let idx += 1
    endwhile

    " Final message part…
    if !empty(arr_msg[idx:idx])
        echon arr_msg[idx]
    endif
    echohl None

    " 'Submit' the message so that it cannot be deleted with \r…
    if s:zq_MessagesCmd_state && !empty(filter(arr_msg,'!empty(v:val)'))
        echon "\n"
    endif

    if !s:zq_MessagesCmd_state && !empty(filter(arr_msg,'!empty(v:val)'))
        call s:ZeroQuote_DoPause(pause)
    endif
endfunc
" }}}

"""""""""""""""""" HELPER FUNCTIONS {{{
" FUNCTION: s:ZeroQuote_ZQEchoCmdImpl(hl,...) {{{
function! s:ZeroQuote_ZQEchoCmdImpl(hi, bang, linenum, msg_bits)
    " Presume a cmdline-window invocation and prepend the history-index instead.
    if a:hi < 7 && empty(a:linenum)
        let line = "cmd:" . histnr("cmd")
    else
        let line = a:linenum
    endif

    " Establish log-level, specifically for an asynchroneous message.
    if a:hi == 22 && a:msg_bits[0] =~ '^\d\+$'
        let msg_arr = a:msg_bits[1:]
        let hi = a:msg_bits[0]
    else
        let msg_arr = a:msg_bits
        let hi = a:hi
    endif
    " Log level can be given as the first argument, by e.g.: lev:5…
    if a:hi > 25 && msg_arr[0] =~ '^lev:\d\+$'
        let hi = remove(msg_arr,0)[4:]
    elseif a:hi > 25
        " The standard user message level — in the 4th color.
        let hi = 11
    endif

    " Prepend the line number if required…
    let msg_arr = ((hi<7 && !empty(line) && string(msg_arr[0]) !~# '\v^''\[(cmd:)=\d+\]''$') ?
                \ extend(["%4.[".line."]%".hi."."], msg_arr) : msg_arr)

    " Async-message?
    if(!empty(a:bang))
        call s:ZeroQuote_Deploy_TimerTriggered_Message(extend([hi], msg_arr), 0, a:hi > 25 ? a:hi : 7)
    else
        call s:ZeroQuote_ZQEcho(hi, msg_arr)
    endif
endfunc
" }}}
" FUNCTION: s:ZeroQuote_TryExtendSDict {{{
function! s:ZeroQuote_TryExtendSDict()
    let stack = expand("<stack>")
    for sid in keys(s:zq_s_dict_providers)
        let Ref = s:zq_s_dict_providers[sid][0]
        let script_file = s:zq_s_dict_providers[sid][1]
        if !empty(matchstr(stack,'<SNR>\zs'.sid.'\ze_')) && index(s:zq_loaded_s_dicts, sid) < 0
            call add(s:zq_loaded_s_dicts, sid)
            6ZQEcho %4 Extending s:-dict with dict from: %2 ° %9 fnamemodify(l:script_file.'%2.',':t') °
            let g:sdict_bkp = deepcopy(s:)
            call extend(s:,Ref())
            return [1,sid]
        endif
    endfor
    "echom "NO for ——→" stack
    return [0,0]
endfunc
" }}}
" FUNCTION: s:ZeroQuote_TryRestoreSDict {{{
function! s:ZeroQuote_TryRestoreSDict(is_needed,sid)
    if a:is_needed
        let Ref = s:zq_s_dict_providers[a:sid][0]
        for __key in keys(Ref())
            call remove(s:, __key)
        endfor
        call extend(s:, g:sdict_bkp)
        let g:sdict_bkp = {}
        call filter(s:zq_loaded_s_dicts, 'v:val != a:sid')
    endif
endfunc
" }}}
" FUNCTION: s:ZeroQuote_Deploy_TimerTriggered_Message(the_msg) {{{
function! s:ZeroQuote_Deploy_TimerTriggered_Message(the_msg,...)
    " Force-reset of the already deployed/deferred messages?
    " Done on the double-bang, i.e.: ZQEcho!! …
    if a:0 && a:1 > 0
        let s:zq_deferredMessagesQueue = []
    endif

    if a:0 && a:1 >= 0
        call add(s:zq_deferredMessagesQueue, a:the_msg)
        call add(s:zq_timers, timer_start(a:0 >= 2 ? a:2 : 7, function("s:ZeroQuote_showDeferredMessageCallback")))
    else
        " A non-deploy theoretical-scenario, for niceness of the API.
        if type(a:the_msg) == v:t_list
            7ZQEcho <zq—args>: a:the_msg
        else
            7ZQEcho a:the_msg
        endif
    endif
endfunc
" }}}
" FUNCTION: s:ZeroQuote_showDeferredMessageCallback(timer) {{{
function! s:ZeroQuote_showDeferredMessageCallback(timer)
    call filter( s:zq_timers, 'v:val != a:timer' )
    let msg = remove(s:zq_deferredMessagesQueue, 0)
    call s:ZeroQuote_ZQEchoCmdImpl(22, '', '', l:msg)
    redraw
endfunc
" }}}
" FUNCTION: s:ZeroQuote_DoPause(pause_value) {{{
function! s:ZeroQuote_DoPause(pause_value)
    "echom a:pause_value "← a:pause_value"
    if a:pause_value =~ '\v^-=\d+(\.\d+)=$'
        let s:ZeroQuote_pause_value = float2nr(round(str2float(a:pause_value) * 1000.0))
    else
        return
    endif
    if s:ZeroQuote_pause_value =~ '\v^-=\d+$' && s:ZeroQuote_pause_value > 0
        call s:ZeroQuote_PauseAllTimers(1, s:ZeroQuote_pause_value + 3)
        exe "sleep" s:ZeroQuote_pause_value."m"
    endif
endfunc
" }}}
" FUNCTION: s:ZeroQuote_redraw(timer) {{{
function! s:ZeroQuote_redraw(timer)
    call filter( s:zq_timers, 'v:val != a:timer' )
    redraw
endfunc
" }}}
" FUNCTION: s:ZeroQuote_PauseAllTimers() {{{
function! s:ZeroQuote_PauseAllTimers(pause,time)
    for t in s:zq_timers
        call timer_pause(t,a:pause)
    endfor

    if a:pause && a:time > 0
        " Limit the amount of time of the pause.
        call add(s:zq_timers, timer_start(a:time, function("s:ZeroQuote_UnPauseAllTimersCallback")))
    endif
endfunc
" }}}
" FUNCTION: s:ZeroQuote_UnPauseAllTimersCallback() {{{
function! s:ZeroQuote_UnPauseAllTimersCallback(timer)
    call filter( s:zq_timers, 'v:val != a:timer' )
    for t in s:zq_timers
        call timer_pause(t,0)
    endfor
endfunc
" }}}
" FUNCTION: s:ZeroQuote_evalArgs() {{{
function! s:ZeroQuote_evalArgs(args,l,a)
    "echom "ENTRY —→ dict:l °" a:l "° —→ dict:a °" a:a "°"
    call extend(l:,a:l)
    let [__sdict_extended,__sid] = s:ZeroQuote_TryExtendSDict()
    "echom "EXTENDED:" s:
    if a:args[0] == '<zq—args>:'
        let __args = deepcopy(eval(substitute(a:args[1],"a:","a:a.","")))
    else
        let __args = deepcopy(a:args)
    endif

    let __idx=-1
    let __already_evaluated = []
    for __cur_arg in __args
        let __idx += 1
        " 1 — %firstcolor.
        " 2 — whole expression, possibly (-l:var)
        " 3 — the optional opening paren
        " 4 — the optional closing paren
        " 5 — %endcolor.
        let __mres = matchlist(__cur_arg, '\v^(\%%([0-9-]+\.=|[a-zA-Z0-9_-]*\.))=(([(]=)-=[svbwtgla]:[a-zA-Z0-9._]+%(\[[^]]+\])*([)]=))(\%%([0-9-]+\.=|[a-zA-Z0-9_-]*\.))=$')
        " Not a variable-expression? → return the original string…
        if empty(__mres) || __mres[3].__mres[4] !~ '^\(()\)\=$'
            "echom "Returning «original» for" __cur_arg
            call add(__already_evaluated, 0)
            continue
        endif
        call add(__already_evaluated, 1)

        if __mres[2] =~ '^(\=-\=a:.*'
            let __mres[2] = substitute(__mres[2], 'a:\([a-zA-Z_-][a-zA-Z0-9_-]*\)','a:a.\1','g')
        endif
        " Fetch the __values — any variable-expression…
        if exists(substitute(__mres[2], '\v(^\(=-=|\)=$)', "", "g"))
            "echom "From-eval path ↔" __no_dict_arg "↔" eval(__mres[2])
            " Via-eval path…
            let ValueForFRef = eval(__mres[2])
            if type(ValueForFRef) != v:t_string
                let ValueForFRef = string(ValueForFRef)
            endif
            let __args[__idx] = __mres[1] . ValueForFRef . __mres[5]
        else
            "echom "Doesn't exist" substitute(__mres[2], '\v(^\(=-=|\)=$)', "", "g") "///" __mres[2]
        endif
    endfor

    " Expand any variables and concatenate separated atoms wrapped in parens.
    let __start_idx = -1
    let __new_args = []
    let __new_idx = 0
    for __idx in range(len(__args))
        let Arg__ = __args[__idx]
        " Unclosed paren?
        " Discriminate two special cases: (func() and (func(sub_func())
        if __start_idx == -1
            if type(Arg__) == v:t_string && Arg__ =~# '\v^\(.*([^)]|\([^)]*\)|\([^(]*\([^)]*\)[^)]*\))$'
                let __start_idx = __idx
            endif
        " A free, closing paren?
        elseif __start_idx >= 0
            if type(Arg__) == v:t_string && Arg__ =~# '\v^[^(].*\)$' && Arg__ !~ '\v\([^)]*\)$'
                let __obj = substitute(join(__args[__start_idx:__idx]), 'a:\([a-zA-Z_-][a-zA-Z0-9_-]*\)','a:a.\1','g')
                call add(__new_args,s:ZeroQuote_ExpandVars(eval(__obj),a:l,a:a))
                let __start_idx = -1
                continue
            endif
        endif

        " …no multi-part token is being built…
        if __start_idx == -1
            " Compensate for explicit variable-expansion requests or {:ex commands…}, etc.
            let Arg__ = s:ZeroQuote_ExpandVars(Arg__,a:l,a:a)

            if type(Arg__) == v:t_string && (!__already_evaluated[__idx] || Arg__ =~ '^function([^)]\+)$')
                " A variable?
                if Arg__ =~# '\v^\s*[svwatgbl]:[a-zA-Z_][a-zA-Z0-9._]*%(\[[^]]+\])*\s*$'
                    let Arg__ = eval(substitute(Arg__, 'a:\([a-zA-Z_-][a-zA-Z0-9_-]*\)','a:a.\1','g'))
                " A function call or an expression wrapped in parens?
                elseif Arg__ =~# '\v^\s*(([svwatgbl]:)=[a-zA-Z_][a-zA-Z0-9_-]*)=\s*\(.*\)\s*$'
                    let Arg__ = eval(substitute(Arg__, 'a:\([a-zA-Z_-][a-zA-Z0-9_-]*\)','a:a.\1','g'))
                " A \-quoted atom?
                elseif Arg__[0] == '\'
                    let Arg__ = Arg__[1:]
                endif
            endif

            " Store/save the element, further checking for any {exprs} that need
            " expanding.
            call add(__new_args, s:ZeroQuote_ExpandVars(Arg__,a:l,a:a))
            " Increase the following-index…
            let __new_idx += 1
        endif
    endfor
    let __args = __new_args
    call s:ZeroQuote_TryRestoreSDict(__sdict_extended,__sid)
    return __args
endfunc
" }}}
" FUNCTION: s:ZeroQuote_ExpandVars {{{
" It expands all {:command …'s} and {[sgb]:user_variable's}.
func! s:ZeroQuote_ExpandVars(text_or_texts,l,a)
    call extend(l:,a:l)
    if type(a:text_or_texts) == v:t_list
        " List input.
        let __texts=deepcopy(a:text_or_texts)
        let __idx = 0
        for __t in __texts
            let __texts[__idx] = s:ZeroQuote_ExpandVars(__t,a:l,a:a)
            let __idx += 1
        endfor
        let Res__ = __texts
    elseif type(a:text_or_texts) == v:t_string
        " String input.
        let Res__ = substitute(a:text_or_texts, '\([^a-zA-Z0-9_]\|\<\)a:\([a-zA-Z_-][a-zA-Z0-9_-]*\)','\1a:a.\2','g')
        let Res__ = substitute(Res__, '\v\{(([:=][^}]+|([svwtglba]\:|\&)[a-zA-Z_]
    \[a-zA-Z0-9._]*%(\[[^]]+\])*))\}',
    \ '\=((submatch(1)[0] == ":") ?
        \ ((submatch(1)[1] != ":") ? execute(submatch(1))[1:] : execute(submatch(1))[1:0])
                \ : ( (submatch(1)[0] == "=") ?
                    \ eval(submatch(1)[1:])
                        \ : (exists(submatch(1)) ? eval(submatch(1)) : submatch(1)) ))', 'g')
    else
        let Res__ = a:text_or_texts
    endif
    return Res__
endfunc
" }}}
" FUNCTION: s:ZeroQuote_GetPrefixValue(pfx, msg) {{{
func! s:ZeroQuote_GetPrefixValue(pfx, msg)
    if a:pfx =~ '^[a-zA-Z]'
        let mres = matchlist( (type(a:msg) == 3 ? a:msg[0] : a:msg),'\v^(.{-})'.a:pfx.
                    \ ':([^:]*):(.*)$' )
    else
        let mres = matchlist( (type(a:msg) == 3 ? a:msg[0] : a:msg),'\v^(.{-})'.a:pfx.
                    \ '([0-9-]+[[:space:].]=|[a-zA-Z0-9_-]*[[:space:].])(.*)$' )
    endif
    " Special case → a:msg is a List:
    " It's limited functionality — it doesn't allow to determine the message
    " part that preceded and followed the infix (it is just separated out).
    if type(a:msg) == 3 && !empty(mres)
        let cpy = deepcopy(a:msg)
        let cpy[0] = mres[1].mres[3]
        return [substitute(mres[2],'[[:space:].]$','','g'),cpy,""]
    elseif !empty(mres)
        " Regular case → a:msg is a String
        " It returns the message divided into the part that preceded the infix
        " and that followed it.
        return [ substitute(mres[2],'[[:space:].]$','','g'), mres[1], mres[3] ]
    else
        return [v:none,a:msg,""]
    endif
endfunc
" }}}
"""""""""""""""""" THE END OF THE HELPER FUNCTIONS }}}

"""""""""""""""""" UTILITY FUNCTIONS {{{
" FUNCTION: Messages(arg=v:none) {{{
function! Messages(arg=v:none)
    if a:arg == "clear"
        let g:zq_messages = []
        return
    endif
    let s:zq_MessagesCmd_state = 1
    for msg in g:zq_messages
        call s:ZeroQuote_ZQEcho(msg[0],msg[1:])
    endfor
    let s:zq_MessagesCmd_state = 0
endfunc
" }}}
"""""""""""""""""" THE END OF THE UTILITY FUNCTIONS }}}

" vim:set ft=vim tw=80 foldmethod=marker sw=4 sts=4 et:
