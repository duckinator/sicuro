$TRUSTED_CONSTANTS = [
  :BasicObject, :Object, :Module, :Class, :Kernel, # Absolutely required
  :NilClass, :NIL,
  :Data,
  :TrueClass, :TRUE, :FalseClass, :FALSE, # Booleans
  :Encoding, :Comparable, :Enumerable,
  
  # Exceptions/errors
  :Exception, :SystemExit, :SignalException, :Interrupt,
  :StandardError, :TypeError, :ArgumentError, :IndexError, :KeyError, :RangeError,
  :ScriptError, :SyntaxError, :LoadError, :NotImplementedError, :NameError,
  :NoMethodError, :RuntimeError, :SecurityError, :NoMemoryError, :EncodingError,
  :SystemCallError, :ZeroDivisionError, :FloatDomainError, :RegexpError,
  :IOError, :EOFError, :LocalJumpError, :SystemStackError, :TimeoutError,
  :ThreadError, :FiberError,
  
  # Commonly used classes that should be safe
  :String, :Symbol, :Numeric, :Integer, :Fixnum, :Float, :Bignum, :Array, :Hash,
  :Struct, :Regexp, :MatchData, :Marshal, :Range, :Rational, :Complex,
  :Time, :Random, :Signal, :Process, :Proc, :Method, :UnboundMethod,
  :Binding, :Math, :GC, :ObjectSpace, :Enumerator, :StopIteration,
  :Thread, :ThreadGroup, :TOPLEVEL_BINDING, :Mutex, :Fiber,
  #RubyVM?
  
  # Commonly used constants that should be safe
  :STDIN, :STDOUT, :STDERR, 
  :RUBY_VERSION, :RUBY_RELEASE_DATE, :RUBY_PLATFORM, :RUBY_PATCHLEVEL,
  :RUBY_REVISION, :RUBY_DESCRIPTION, :RUBY_COPYRIGHT, :RUBY_ENGINE,
  :ARGV, :JSON,
  
  :Timeout,
  :StringIO,
  :PrettyPrint,
  :PP,
  :TSort,
  :Date,
  
  # Required for file access
  :File,
  :FileUtils,
  :FileTest,
  :Dir,
  
  :Errno,
  :Pathname,
]
