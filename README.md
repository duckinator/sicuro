# Sicuro

Safe execution environment for untrusted ruby code.

[![Build Status](https://travis-ci.org/duckinator/sicuro.png?branch=master)](https://travis-ci.org/duckinator/sicuro)
[![Coverage Status](https://coveralls.io/repos/duckinator/sicuro/badge.png?branch=master)](https://coveralls.io/r/duckinator/sicuro)

# Installation

    gem install sicuro

# Usage

Sicuro safely executes untrusted ruby code without any complex configuration,
unjustifiable permissions (such as passwordless sudo), chroots, or BSD Jails.

## Configuration

If you wish to set the memory or time limits, you will need to manually create a `Sicuro` instance:

```ruby
s = Sicuro.new(memlimit, timelimit)
s.eval(code)
s.eval(more_code)
```

`memlimit` is in megabytes, and `timelimit` is in seconds.
The defaults are 50MB RAM and 5 seconds.

There is no way to alter the strength of the sandbox.

## Running code in the sandbox

`Sicuro.eval(code)` is an alias for `Sicuro.new.eval(code)`, and returns a `Sicuro::Eval` instance.

### Sicuro::Eval

`Sicuro::Eval#code` is the code passed to `Sicuro#eval`.

`Sicuro::Eval#stdout` is anything printed to stdout by the evaluated code (`puts`, `print`, etc).

`Sicuro::Eval#stderr` is anything printed to stderr by the evaluated code (`warn`).

`Sicuro::Eval#return` is the returned value of the last statement.

`Sicuro::Eval#to_s` intelligently returns one of `#stdout`, `#stderr`, or `#return`. If it uses `#return`, it will call `#inspect` on the result. Otherwise, it returns the result directly.

## Examples

Example 1:

```ruby
require 'sicuro'

s = Sicuro.eval('puts "hi!"')
s.code      # returns "puts \"hi!\""
s.stdout    # returns "hi!\n"
s.stderr    # returns ""
s.return    # returns nil, because that's the result of the last statement.
s.to_s      # returns "hi!\n", because it uses #stdout
```

Example 2:

```ruby
require 'sicuro'

s = Sicuro.eval('"hi!"')
s.code      # returns "\"hi!\""
s.stdout    # returns ""
s.stderr    # returns ""
s.return    # returns "\"hi!\"" because that was the result of the last statement.
s.to_s      # returns "\"hi!\"", because it uses #return
```

# eval.so compatibility

Sicuro is now API-compatible with the eval.so gem.

```ruby
require 'sicuro'

p Sicuro.run(:ruby, "puts 'lawl'")

# Example output:
#   #<Sicuro::Eval code="puts 'lawl'" stdout="lawl\n" stderr="" return="nil" wall_time=36>
```

# License

Sicuro is released under the ISC license. See the LICENSE file which should have
been distributed with this for more information.

