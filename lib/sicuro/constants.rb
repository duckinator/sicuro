class Sicuro
  NO_SANDBOXED_IMPL = "a sandboxed version of \`%s' has not been implemented yet."

  SandboxError = Class.new(::StandardError)

  # Ruby executable used.
  RUBY_EXE = RbConfig::CONFIG['ruby_install_name'] + RbConfig::CONFIG['EXEEXT']
  RUBY_USED = File.join(RbConfig::CONFIG['bindir'], RUBY_EXE)
end
