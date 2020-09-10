# zero-quote echo — introduction

An `:echo`-like command that requires literally **≈ ZERO ≈** quoting of its
arguments — it'll by itself:
- detect any variables and expressions,
- differentiate them from the surrounding, regular text,
- and then expand constructing the final message.

*"But :echom also 'expands' variables… by design…"* — you'll maybe think.
That's true, `ZQEcho` works somewhat in a «*reversed*» way for increased
convenience — it doesn't require to quote regular text (unlike `echom`) ←→ THIS
IS THE CANDY — and from this point it takes actions to elevate variables and
expressions back into their special meaning, so it's the command's main
feature. The result is an ability to freely express your thoughts — your
fingers will feel freed!

Besides the zero-quoting property, `ZQEcho` has some other, interesting
features:
- ·**multi-color**· messages that overcome Vim limitation of only one highlight
per-single message — with a custom message ·**history**·,
- automatic, easy to activate (via the *•bang•* **`!`** appended to the
  command, plus an optional •*count*• ↔ the timeout) ·**asynchroneous**·
  display of the message via a ·*timer-based*· callback,
- ability to ·*pause*· Vim for a specified number of seconds, so that the message
  will not be missed or overwritten by some following message or a status change,
- ability to embed variable-expanding strings in the text, in a form `{g:myvar…}`
  and also an `ex` command output-capture substituting via `{:ex-command(s)…}`.

## examples

#### basic usage

```vim
:ZQEcho Hello World! You can use any Unicode glyph without quoting: ≈ß•°×∞„”
:2ZQEcho Prepend with a count ↔ a message log-level AND also a distinct color
:ZQEcho %1Red %2Green %3Yellow %4Blue %5Magenta %6Cyan %7White %0Error %-Reset
:ZQEcho Above is the short-color format. The long one allows to specify any
      \ hl-group: %Identifier.Hello world!
:ZQEcho Provided are color-named hl-groups, like: %gold. %lblue. etc.
```

#### variable/expression printing

```vim
:ZQEcho To print a variable, simply include it, like: g:my_dict['my_field']
:ZQEcho All data-types will be stringified —→ this works: g:my_dictionary
      \ g:my_list v:argv etc.
:ZQEcho Function-like expressions are auto-evaluated, e.g.: toupper('hello!')
:ZQEcho Include complex expressions by wrapping with parens, e.g.: (rand() % 5)
:ZQEcho You can also print l:local_vars, a:argument_vars, and also — if you
  supply a s:-dict getter-function — s:script_vars. More info below.
```

#### asynchroneous printing

```vim
:ZQEcho! I'll be printed from a timer-•callback• after 10 ms (the default timeout)
:200ZQEcho! Set timeout to 200 ms ↔ •counts• > 25 are custom timeouts, not log-levels
```
