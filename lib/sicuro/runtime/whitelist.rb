BEGIN {
  eigenclass = class << Kernel; self end

  Sicuro::Runtime::Methods.replace_all!
}

