# Universal Lambda
Universal Lambda is an [esolang](https://en.wikipedia.org/wiki/Esoteric_programming_language) based on John Tromp's [binary lambda calculus](https://tromp.github.io/cl/Binary_lambda_calculus.html), with some ideas to accomodate I/O. It was made by Darren "flagitious" Smith in 2008, and the original site is [here](http://web.archive.org/web/20200707185352/http://www.golfscript.com/lam/). You can code golf in it on [anarchy golf](https://golf.shinh.org).

I'm maintaining the interpreter and tools on GitHub now, so that they work with recent versions of [ghc](https://www.haskell.org/ghc/) and [Ruby](https://www.ruby-lang.org/en/).

## Quick language description
Your code is treated as a bit stream, and parsed as a term in the following grammar:

* `00 (term)` makes a lambda abstraction (_λx.term_).
* `01 (term) (term)` applies two terms.
* `10`, `110`, `1110`… refer to the variable of the _n_-th innermost lambda ([De Bruijn indexing](https://en.wikipedia.org/wiki/De_Bruijn_index)).

So, the lambda term _λf. (λx. f (x x))(λx. f (x x))_ is encoded as:

    00 01 00 01 110 01 10 10 

If there are leftover bits in the last byte when parsing your program term, they are ignored.

The parsed term is then applied to standard I/O, which is encoded into a lambda term as described below. The result is then decoded back into a character stream in the same format.

## I/O format

The I/O format is a linked list of Church numerals between 0 and 255, in the following list encoding:

    0 = λf x.x
    1 = λf x.fx
    2 = λf x.f(fx)
    3 = λf x.f(f(fx))
    ...
    cons = λh t f.f h t
    head = λp.p(λh t.h)
    tail = λp.p(λh t.t)
    nil = λa b.b
