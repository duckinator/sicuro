$TRUSTED_GLOBALS = [
  :$;, :$-F, :$@, :$!, :$SAFE, :$~, :$&, :$`, :$', :$+, :$=, :$KCODE, :$-K, :$,,
  :$/, :$-0, :$\, :$_, :$stdin, :$stdout, :$stderr, :$>, :$<, :$.,
  :$-i, :$?, :$$, :$:, :$-I, :$",
  :$-v, :$-w, :$-W, :$-d, :$-p, :$-l, :$-a,
  :$LOADED_FEATURES,

  # Possibly $DEBUG? Seems iffy, since it modifies the interpreter's behavior.
  :$VERBOSE, :$fileutils_rb_have_lchmod, :$fileutils_rb_have_lchown,
  :$CGI_ENV, :$_rspec_mocks_extensions_added,
  :$TRUSTED_CONSTANTS, :$TRUSTED_METHODS, :$TRUSTED_METHODS_ALL, :$TRUSTED_GLOBALS,
]
