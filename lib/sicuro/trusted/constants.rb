$TRUSTED_CONSTANTS = [
  :BasicObject, :Object, :Module, :Class, :Kernel, # Absolutely required
  :NilClass, :NIL,
  :Data,
  :TrueClass, :TRUE, :FalseClass, :FALSE, # Booleans
  :Encoding, :Comparable, :Enumerable,

  # Exceptions/errors
  :Exception, :SystemExit, :SignalException, :Interrupt,
  :StandardError, :TypeError, :ArgumentError, :IndexError, :KeyError,
  :RangeError, :ScriptError, :SyntaxError, :LoadError, :NotImplementedError,
  :NameError, :NoMethodError, :RuntimeError, :SecurityError, :NoMemoryError,
  :EncodingError, :SystemCallError, :ZeroDivisionError, :FloatDomainError,
  :RegexpError, :IOError, :EOFError, :LocalJumpError, :SystemStackError,
  :TimeoutError,
  :ThreadError, :FiberError,

  # Commonly used classes that should be safe
  :String, :Symbol, :Numeric, :Integer, :Fixnum, :Float, :Bignum, :Array, :Hash,
  :Struct, :Regexp, :MatchData, :Marshal, :Range, :Rational, :Complex,
  :Time, :Random, :Proc, :Method, :UnboundMethod, :Binding, :Math,
  :Enumerator, :StopIteration, :Thread, :ThreadGroup, :TOPLEVEL_BINDING, :Mutex,
  :Fiber,

  # Commonly used constants that should be safe
  :STDIN, :STDOUT, :STDERR,
  :RUBY_VERSION, :RUBY_RELEASE_DATE, :RUBY_PLATFORM, :RUBY_PATCHLEVEL,
  :RUBY_REVISION, :RUBY_DESCRIPTION, :RUBY_COPYRIGHT, :RUBY_ENGINE,
  :JSON,

  :Timeout,
  :StringIO,
  :PrettyPrint,
  :PP,
  :TSort,
  :Date,

  # File access may be re-enabled in the future, but for now all it does is
  # cause the interpreter to segfault. Since I can't test it, I won't enable it.

  # Required for file access
  #:File,
  #:FileUtils,
  #:FileTest,
  #:Dir,
  #:Pathname,
  :Errno,

  # Replaced in runtime/constants.rb
  :ENV, :DummyFS, :File,
]
