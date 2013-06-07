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

  # $FILENAME is absurdly magic (`$FILENAME` seems to be replaced with the file
  #   name before any code is executed. This makes the test give a false negative).
  # As far as I know $FILENAME is merely a string obtained through an absurdly
  # magical method, so it should be fine.
  :$FILENAME,
]
