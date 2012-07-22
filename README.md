# Sicuro

Safe execution environment for untrusted ruby code.

# Installation

    gem install sicuro

# Usage

Sicuro safely executes untrusted ruby code without any complex configuration,
unjustifiable permissions (such as passwordless sudo), or chroots/BSD Jails.

If you've not ran into any problems, you probably want (the section on Sicuro::Eval)[#sicuro--eval].

## Configuration

You can run `Sicuro#setup(timelimit, memlimit, memlimit_upper_bound)` to configure it.

All arguments are optional.

The defaults are:

`Sicuro#setup(Sicuro::DEFAULT_TIMEOUT, Sicuro::DEFAULT_MEMLIMIT, Sicuro::DEFAULT_MEMLIMIT_UPPER_BOUND)`

Once you run `Sicuro#setup`, the config stays the same unless you run it a second time.

Using `Sicuro#eval` or `Sicuro.eval` (an alias to the former) will call `Sicuro#setup`
if it has not already been called.

There is no way to alter the strength of the sandbox.

## Running code in the sandbox

`Sicuro.eval(code)` returns a `Sicuro::Eval` instance.

### Sicuro::Eval

`Sicuro::Eval#stdin` is the code passed to `Sicuro#eval`.

`Sicuro::Eval#stdout` is anything printed to stdout by the evaluated code (`puts`, `print`, etc).

`Sicuro::Eval#stderr` is anything printed to stderr by the evaluated code (`warn`).

`Sicuro::Eval#return` is the returned value of the last statement.

`Sicuro::Eval#exception` is the value of any exception. There's been some cases where exceptions appear in `#stderr` instead.

`Sicuro::Eval#value` intelligently returns one of `#stdout`, `#stderr`, `#return`, or `#exception`. If it uses `#return`, it will call `#inspect` on the result. Otherwise, it returns the result directly.

## Examples

Example 1:

```ruby
require 'sicuro'

s = Sicuro.eval('puts "hi!"')
s.stdin     # returns "puts \"hi!\""
s.stdout    # returns "hi!\n"
s.stderr    # returns ""
s.return    # returns nil, because that's the result of the last statement.
s.exception # returns nil
s.value     # returns "hi!\n", because it uses #stdout
```

Example 2:

```ruby
require 'sicuro'

s = Sicuro.eval('"hi!"')
s.stdin     # returns "\"hi!\""
s.stdout    # returns ""
s.stderr    # returns ""
s.return    # returns "hi!" because that was the result of the last statement.
s.exception # returns nil
s.value     # returns "hi!\n", because it uses #stdout
```

I may make `#exception` default to an empty string, depending on feedback I get regarding that.

# License

Sicuro is released under the ISC license. See the LICENSE file which should have
been distributed with this for more information.

