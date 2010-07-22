require 'stringio'

$time_limit = 5 # Time limit for execution

def out_to_string(stdout=StringIO.new)
  old_stdout = $stdout.to_i
  begin
    $stdout = stdout
    yield
 ensure
    $stdout = IO.new(old_stdout)
  end
  stdout.string
end

module Sicuro
  class Base
    attr_reader :error
    def initialize(executable=nil, *executable_args)
      @executable = executable
      @executable_args = executable_args

      if Dir.exist?(File.dirname(__FILE__))
        @chroot = File.join(File.dirname(__FILE__), "chroot")
        Dir.mkdir(@chroot) if !File.directory?(@chroot)
      end
    end

    def self.eval(code)
      c = Kernel
      parts = self.name.split('::')
      parts.each do |part|
        c = c.const_get(part)
      end
      c.new.run code
    end

    def eval(code)
      # Stub, should be defined in each language-specific class
    end

    def run(code, filename=nil)
      filename ||= "#{@executable}_#{Time.now.to_i}_#{rand}.rb"
      filename.gsub!('/', '')
      filename.gsub!('\\', '')
      filename = File.join(@chroot, filename)
      save_file(code, filename)
      run_file(filename)
    end

    def run_file(filename)
      random = nil
      output = ''

      begin
        thread = Thread.new do
          random = rand
          output = `sudo #{@executable} #{@interpeter_args} #{filename.inspect} #{random}`
        end
      rescue Exception => e
        error = e
      ensure
        $stdout = STDOUT
      end

      1.upto($time_limit+1).each do |i|
        id = 0
        id_parts = `ps aux | grep -v grep | grep -i #{@executable} | grep -i nobody | grep -i "#{random}"`.split(' ')
        id = id_parts[1].to_i unless id_parts.include?("<defunct>")

        if thread.alive? && i > $time_limit && id != 0
          puts id
          `sudo kill -9 #{id}`
          thread.kill
          error = "Execution took longer than #{$time_limit} seconds, exiting."
          break
        elsif i > $time_limit || !thread.alive?
          break
        end
        sleep 1
      end

      if !error.nil?
        error
      elsif !output.inspect.empty? && (!output.inspect == '""' && !thread.value.inspect.empty?)
        output
      else
        thread.value
      end
    end

    def save_file(code, filename)
      File.open(filename, "w") do |f|
        f.write(generate_script(code))
      end
    end

    def generate_script(code)
      file = File.join(File.dirname(__FILE__), "template.rb")
      text = open(file).read

      changes = {
                  time: Time.now.to_i,
                  file: __FILE__.inspect,
                  chroot: @chroot.inspect,
                  code: code.inspect,
                  class: self.class.name
                }

      changes.each do |k,v|
        text.gsub!("%#{k.to_s}%", v.to_s)
      end

      text
    end
  end
end

directory = File.join(File.dirname(__FILE__), 'lang/*')
Dir[directory].each do |file|
  load file
end
