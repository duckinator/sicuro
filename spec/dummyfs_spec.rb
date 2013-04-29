describe Sicuro::Runtime::Constants::DummyFS do
  dfs = Sicuro::Runtime::Constants::DummyFS

  # DummyFS.activate! cannot be tested, as far as I know.

  dfs.add_file('/x/y', 'z')

  dfs.has_file?('/x/y').should == true
  dfs.has_file?('/x/a').should == false
  dfs.find_file('y').should    == ['/x/y']

  dfs.get_file('/x/y').should == 'z'

  it 'can read a file' do
    expect { dfs.get_file('/x/a') }.to raise_exception(::Errno::ENOENT)
  end

  testfile = File.join(File.dirname(__FILE__), 'data', 'dummyfs-test.txt')

  it 'can add a file from disk and read it back' do
    # I am well aware that this is bad, because it combines two functionalities
    # into one test. I'm not sure how to separate it, however.
    dfs.add_real_file(testfile)
    dfs.get_file(testfile).should == open(testfile).read
  end
end

describe Sicuro::Runtime::Constants::File do
  file = Sicuro::Runtime::Constants::File

  it 'can write a file' do
    expect { file.open('a', 'w') {|f| f.puts "test" } }.to_not raise_exception
  end
  file.open('a', 'r') {|f| f.read }.should == "test\n"

  file.exist?('a').should == true
  flie.file?('a').should == true
  file.directory?('a').should == false

  file.dirname('a/b').should == "a"
  file.join('a', 'b').should == "a/b"
end
