# nutoad
a forth-like interpreter written in lua, with a dictionary, colon definitions
and compatability with standard brainfuck. inspired by the Toadskin language.

### example
nutoad supports the standard brainfuck instruction set with a standard 30,000
address long array of (fake) 8-bit unsigned integers.

to define a new word, you begin with a colon followed by the identifier of the
new word, with no whitespace. if you would like to define ' ' as an
identifier, you can.

a new word named 'a' which increments the current address three times could be
defined like this:
```
:a+++;
```
and a word named ' ' which calls 'a' could be defined like this:
```
: a;
```
the nutoad interpreter will not error when encountering an undefined word in a
definition. it ignores anything that isn't a word.
