$TRUSTED_METHODS = {
  :Module => [
    :nesting,
  ],
  :Encoding => [
    :list, :name_list, :aliases, :find, :compatible?,
    :_load, :default_external, :default_external=,
    :default_internal, :default_internal=,
    :locale_charmap
  ],
  :Symbol => [
    :all_symbols,
  ],
  :Regexp => [
    :compile, :quote, :escape, :union, :last_match,
  ],
  :StringIO => [
    :reopen, :string, :string=, :lineno, :lineno=, :binmode, :close, :close_read,
    :close_write, :closed?, :closed_read?, :closed_write?, :eof, :eof?, :fcntl,
    :flush, :fsync, :pos, :pos=, :rewind, :seek, :sync, :sync=, :tell, :each,
    :each_line, :lines, :each_byte, :bytes, :each_char, :chars, :each_codepoint,
    :codepoints, :getc, :ungetc, :ungetbyte, :readchar, :getbyte, :readbyte,
    :gets, :readline, :readlines, :read, :sysread, :readpartial, :read_nonblock,
    :write, :<<, :print, :printf, :putc, :puts, :syswrite, :write_nonblock,
    :isatty, :tty?, :pid, :fileno, :size, :length, :truncate, :external_encoding,
    :internal_encoding, :set_encoding, :entries, :sort, :sort_by, :grep, :count,
    :find, :detect, :find_index, :find_all, :select, :reject, :collect, :map,
    :flat_map, :collect_concat, :inject, :reduce, :partition, :group_by, :first,
    :all?, :any?, :one?, :none?, :min, :max, :minmax, :min_by, :max_by,
    :minmax_by, :member?, :each_with_index, :reverse_each, :each_entry,
    :each_slice, :each_cons, :each_with_object, :zip, :take, :take_while, :drop,
    :drop_while, :cycle, :chunk, :slice_before, :open,
  ],
  :Time => [
    :localtime, :gmtime, :utc, :getlocal, :getgm, :getutc, :ctime, :asctime, :+,
    :-, :succ, :round, :sec, :min, :hour, :mday, :day, :mon, :month, :year, :wday,
    :yday, :isdst, :dst?, :zone, :gmtoff, :gmt_offset, :utc_offset, :utc?, :gmt?,
    :sunday?, :monday?, :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?,
    :tv_sec, :tv_usec, :usec, :tv_nsec, :nsec, :subsec, :strftime, :_dump,
    :between?, :now, :at, :local, :mktime, :gm, :_load,
  ],
  :Random => [
    :srand, :rand, :new_seed,
  ],
  :Fiber => [
    :yield, :untrust, :trust, :resume,
  ],
  :Thread => [
    :start, :fork, :main, :current, :stop, :kill, :pass, :list,
    :abort_on_exception, :abort_on_exception=, :exclusive, :taint, :untaint,
    :untrust, :trust, :join, :value, :terminate, :run, :wakeup, :[], :[]=,
    :key?, :keys, :priority, :priority=, :status, :alive?, :stop?, :safe_level,
    :group, :backtrace, :set_trace_func, :add_trace_func,
  ],
  :File => [
    :directory?, :exist?, :exists?, :readable?, :readable_real?, :world_readable?,
    :writable?, :writable_real?, :world_writable?, :executable?, :executable_real?,
    :file?, :zero?, :size?, :size, :owned?, :grpowned?, :pipe?, :symlink?, :socket?,
    :blockdev?, :chardev?, :setuid?, :setgid?, :sticky?, :identical?, :stat, :lstat,
    :ftype, :atime, :mtime, :ctime, :utime, :chmod, :chown, :lchmod, :lchown, :link,
    :symlink, :readlink, :unlink, :delete, :rename, :umask, :truncate, :expand_path,
    :absolute_path, :realpath, :realdirpath, :basename, :dirname, :extname, :path,
    :split, :join, :fnmatch, :fnmatch?, :open, :sysopen, :for_fd, :popen, :foreach,
    :readlines, :read, :binread, :write, :binwrite, :select, :pipe, :copy_stream,
    :taint, :untaint, :untrust, :trust, :flock, :to_path, :reopen, :each, :each_line,
    :each_byte, :each_char, :each_codepoint, :lines, :bytes, :chars, :codepoints,
    :syswrite, :sysread, :fileno, :fsync, :fdatasync, :sync, :sync=,
    :lineno, :lineno=, :read_nonblock, :write_nonblock, :readpartial, :gets,
    :readline, :getc, :getbyte, :readchar, :readbyte, :ungetbyte, :ungetc, :<<,
    :flush, :tell, :seek, :rewind, :pos, :pos=, :eof, :eof?, :close_on_exec?,
    :close_on_exec=, :close, :closed?, :close_read, :close_write, :isatty, :tty?,
    :binmode, :binmode?, :sysseek, :advise, :ioctl, :fcntl, :pid, :external_encoding,
    :internal_encoding, :set_encoding, :autoclose?, :autoclose=, :entries, :sort,
    :sort_by, :grep, :count, :find, :detect, :find_index, :find_all, :reject,
    :collect, :map, :flat_map, :collect_concat, :inject, :reduce, :partition,
    :group_by, :first, :all?, :any?, :one?, :none?, :min, :max, :minmax, :min_by,
    :max_by, :minmax_by, :member?, :each_with_index, :reverse_each, :each_entry,
    :each_slice, :each_cons, :each_with_object, :zip, :take, :take_while, :drop,
    :drop_while, :cycle, :chunk, :slice_before,
  ],
  :DummyFS => [
    :fs, :setup, :activate!, :has_file?, :find_file, :add_file, :add_real_file,
    :add_directory, :get_file,
  ],
}

$TRUSTED_METHODS[:Class] = $TRUSTED_METHODS[:Module]

$TRUSTED_METHODS_ALL = [
  :sprintf, :format,
  
  # Classes/Modules
  :Integer, :Float, :String, :Array, :Rational, :Complex,
  :warn, :raise, :fail,
  :global_variables, :__method__, :__callee__,
  :eval, :local_variables, :iterator?, :block_given?,
  :catch, :throw, :loop, :caller,

  # Printing    
  :printf, :print, :putc, :puts, :p,

  # Random numbers.
  :srand, :rand,

  # Exiting
  :exit!, :exit, :sleep, :abort,
  
  :proc, :lambda, :binding,
  
  # Comparison
  :===, :==, :<=>, :<, :<=, :>, :>=, :nil?, :=~, :!~, :eql?,
  
  # Conversion
  :to_i, :to_s, :to_a, :to_f, :to_r, :to_c, :to_enum,
  
  # Common operators
  :&, :|, :^,
  
  :included_modules, :include?, :name, :ancestors,
  :instance_methods, :public_instance_methods, :protected_instance_methods,
  :private_instance_methods, :constants, :const_get, :const_set,
  :const_defined?, :const_missing, :class_variables, :remove_class_variable,
  :class_variable_get, :class_variable_set, :class_variable_defined?,
  :public_constant, :private_constant,
  
  :module_exec, :class_exec, :module_eval, :class_eval,
  
  :method_defined?, :public_method_defined?, :private_method_defined?,
  :protected_method_defined?, :public_class_method, :private_class_method,
  :instance_method, :public_instance_method,
  :hash, :class, :singleton_class, :clone, :dup, :initialize_dup,
  :initialize_clone, :tainted?, :untrusted?, :frozen?, :inspect, :methods,
  :singleton_methods, :protected_methods, :private_methods, :public_methods,
  :instance_variables, :instance_variable_get, :instance_variable_set,
  :instance_variable_defined?, :instance_of?, :kind_of?, :is_a?,
  :tap, :send, :public_send, :respond_to?,
  :respond_to_missing?, :extend, :display, :method, :public_method,
  :define_singleton_method, :object_id, :enum_for, :equal?, :!, :!=,
  :instance_eval, :instance_exec, :__send__, :__id__,

  # Pretty-printing
  :pretty_print, :pretty_print_cycle,
  :pretty_print_inspect, :pretty_print_instance_variables,

  # Require/load functions. Redefined in sicuro/runtime/methods.
  :require, :require_relative, :load,

  :inherited, :initialize, :initialize_copy, :included, :extended,
  
  :method_added, :method_removed, :method_undefined,
  
  :inherited, :initialize, :initialize_copy, :included, :extended,
  
  :method_added, :method_removed, :method_undefined,
  :attr, :attr_reader, :attr_writer, :attr_accessor,
  
  
  :remove_const, :include, :remove_method, :undef_method, :alias_method,
  
  :public, :protected, :private,
  
  :define_method,
  
  :remove_instance_variable,
  
  :__method__, :__callee__,

  :allocate, :new, :superclass, :freeze, :frozen?,
  :autoload, :autoload?,

  :try_convert,

  :exception,

  :[],
]
