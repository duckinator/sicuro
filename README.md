# Sicuro

Safe execution environment for untrusted ruby code. If you want me to dedicate more time to working on this, please consider [giving a weekly donation](https://gittip.com/duckinator) to me on Gittip!

[![Gittip](http://img.shields.io/gittip/duckinator.svg)](https://gittip.com/duckinator)
[![Build Status](http://img.shields.io/travis/duckinator/sicuro.svg)](https://travis-ci.org/duckinator/sicuro)
[![Code Coverage](http://img.shields.io/coveralls/duckinator/sicuro.svg)](https://coveralls.io/r/duckinator/sicuro)
[![Dependencies](http://img.shields.io/gemnasium/duckinator/sicuro.svg)](https://gemnasium.com/duckinator/sicuro)
[![](http://img.shields.io/gem/v/sicuro.svg)](http://rubygems.org/gems/sicuro)

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

~~`Sicuro::Eval#return` is the returned value of the last statement.~~

`Sicuro::Eval#to_s` intelligently returns one of `#stdout` or `#stderr`.


#### Notes on Sicuro::Eval#return

Previously, Sicuro provided a `#return` method that would give the value returned by the last line of code it evaluated. It existed from v0.0.1 to v0.18.0 (inclusive), and was removed with v0.19.0.
The way this was accomplished was by returning a JSON object from the child (sandboxed) process to the parent (non-sandboxed) process.
However, this approach led to bugs with errors about encoding things to JSON being intermixed with the other results, which gave rather bizarre errors when reaching the parent process.

I plan to eventually either reintroduce this exact functionality in a more robust form, or replace it with a better alternative later on.

## Examples

Example 1:

```ruby
require 'sicuro'

s = Sicuro.eval('puts "hi!"')
s.code      # returns "puts \"hi!\""
s.stdout    # returns "hi!\n"
s.stderr    # returns ""
s.to_s      # returns "hi!\n", because it uses #stdout
```

Example 2:

```ruby
require 'sicuro'

s = Sicuro.eval('"hi!"')
s.code      # returns "\"hi!\""
s.stdout    # returns ""
s.stderr    # returns ""
s.to_s      # returns "\"hi!\"", because it uses #return
```

# eval.so compatibility

Sicuro is now API-compatible with the eval.so gem.

```ruby
require 'sicuro'

p Sicuro.run(:ruby, "puts 'lawl'")

# Example output:
#   #<Sicuro::Eval code="puts 'lawl'" stdout="lawl\n" stderr="" wall_time=36>
```

# License

Sicuro is released under the ISC license. See the LICENSE file which should have
been distributed with this for more information.

