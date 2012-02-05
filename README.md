# Sicuro

Safe execution environment for untrusted ruby code.

# Installation

    gem install sicuro

# Usage

Sicuro safely executes untrusted ruby code without any complex configuration,
unjustifiable permissions (such as passwordless sudo), or chroots/BSD Jails.

It returns both STDOUT and STDERR as a single string. In the future, it may offer
a method that returns [stdout, stderr] instead.


## Run code, default limits

The preferred option is to run code using the default limits. These are being
tweaked so they are (hopefully) sane on any system capable of running ruby.

```ruby
require 'sicuro'

Sicuro.eval('puts "hi!"') # returns "hi!\n"
```

## Run code, custom limits

You may, optionally, specify a timelimit and memory limit.

The following example shows what I would like the defaults to be, but something
seems to like eating RAM when I'm not looking.

```ruby
require 'sicuro'

timelimit = 5
memlimit  = 10

Sicuro.setup(timelimit, memlimit)
Sicuro.eval('puts "hi!"') # returns "hi!\n"
```

# License

Sicuro is released under the ISC license. See the LICENSE file which should have
been distributed with this for more information.

