# List replaced constants in the following array.
# This doesn't do much, just removes the "already initialized constant" warning.
[:ENV].each do |x|
  Object.instance_eval { remove_const x }
end


ENV = {
  "LANG"    => "en_US.UTF-8",
  "SHLVL"   => "1",
  "PWD"     => "/home/sicuro",
  "USER"    => "sicuro",
  "LOGNAME" => "sicuro",
  "HOME"    => "/home/sicuro",
  "PATH"    => "/bin",
  "SHELL"   => "/bin/bash",
  "TERM"    => "dumb"
}

