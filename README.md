# Universal Lambda
Universal Lambda is a purely functional [esolang](https://en.wikipedia.org/wiki/Esoteric_programming_language) made by Darren "flagitious" Smith in 2008, based on John Tromp's [binary lambda calculus](https://tromp.github.io/cl/Binary_lambda_calculus.html). You can [code golf](https://en.wikipedia.org/wiki/Code_golf) in it on [anarchy golf](http://golf.shinh.org). It is similar to [Lazy-K](https://esolangs.org/wiki/Lazy-K), but more compact.

I'm maintaining the interpreter and tools here now, so that they work with recent versions of Haskell and Ruby. The original site is [here](http://web.archive.org/web/20200707185352/http://www.golfscript.com/lam/).

## Usage
Install [ghc](https://www.haskell.org/ghc/) and [Ruby](https://www.ruby-lang.org/en/). Run `make` to compile the interpreter, `lamb`. Then try:

```bash
./lama examples/perm.lam    # assembler: emits perm.lamb
./lamd examples/perm.lamb   # disassembler: writes to stdout
echo -n "abc" | ./lamb examples/perm.lamb   # run "perm.lamb" with input
```

## Quick language description
Your code (a `.lamb` file) is treated as a bit stream, and parsed as a term in the following grammar:

* `00 (term)` makes a lambda abstraction (_λx.term_).
* `01 (term) (term)` applies two terms.
* `10`, `110`, `1110`… refer to the variable of the _n_-th innermost lambda ([De Bruijn indexing](https://en.wikipedia.org/wiki/De_Bruijn_index)).

So, the lambda term _λf. (λs. s s)(λx. f (x x))_ is encoded as:

    00  01 00 01 10 10  00  01 110 01 10 10
    λf.  ( λs. ( s  s)) λx.  ( f    ( x  x))

In practice, files consist of bytes. If there are leftover bits in the last byte when parsing your program term, they are ignored. For example, the identity program `00 10` is represented by any single-byte program of the form `0010xxxx` (so any byte between `0x20` and `0x2F`).

The contents of STDIN are encoded into a lambda term as described below. Your program term is applied to this term, and the result is decoded back into a byte stream in the same format.

## I/O format

The I/O format is a linked list of Church numerals between 0 and 255, in the following list encoding:

    0 = λf x.x
    1 = λf x.f x
    2 = λf x.f(f x)
    3 = λf x.f(f(f x))
    ...
    cons = λh t f.f h t
    head = λp.p(λh t.h)
    tail = λp.p(λh t.t)
    nil = λa b.b

So, if STDIN contains the string `"abc\n"` then your program is applied to _(cons 97 (cons 98 (cons 99 (cons 10 nil))))_ in this encoding. And if your program is `tail` (i.e. `λp.p(λh t.t)`, i.e. `18 20` in hex) then your output will be `"bc\n"`. See the `unchurch` and `unlist` functions in `lamb.hs`.

## The "data section"

If there are leftover _bytes_ in the program file after parsing your program term, those bytes are prepended to STDIN before your program runs.

So, the program `20` (hex) described earlier is the identity/echo program (`λx.x`), but `20 61 62 63` is a program that prepends `"abc"` to STDIN.

This is useful as a sort of "data section" for your program: you can choose to have a few more ambient Church numbers lying around at the front of the list. Of course, it also makes writing _Hello, world!_ a lot simpler.

## The `.lam` assembler format

See `examples/perm.lam`. Here is a quick overview from the original docs:

    * (M N) = function application, M(N)
    * \a.M = abstraction, λa->M
    * a = argument lookup
    * Application is left associative, so M N O = (M N) O
    * λ expressions go until ), so \a.a b = (\a.M N), and not (\a.M) N
    * Multiple arguments can be specified in the same λ expression,
      which just means to curry them: (\a b c.b a c) = (\a.\b.\c.b a c)
    * # comments out the rest of the line
    * Assignment can be used with the = operator and ended with a newline,
      it can then be used like a bound variable. Keep in mind however that
      this is purely syntactic sugar. For example:

        a=x y z
        a b a

      is converted to:

        (\a.a b a)(x y z)

The last line in the .lam file is not a definition, but your program term. It can end with an unmatched `"` or `'` to provide a data section, like so:

    (\a. a) "Hello, world!\n

Note: I added a feature where you can use e.g. `__2` to directly refer to the raw De Bruijn variable with index 2 (`110`), whatever it may be. Sometimes this is useful for weird code golf byte-saves.