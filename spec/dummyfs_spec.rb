describe Sicuro::Runtime::Constants::DummyFS do
  dfs = Sicuro::Runtime::Constants::DummyFS

  # DummyFS.activate! cannot be tested, as far as I know.

  dfs.add_file('/x/y', 'z')

  dfs.has_file?('/x/y').should == true
  dfs.find_file('y').should   == ['/x/y']

  dfs.get_file('/x/y').should == 'z'

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

  # TODO:
  #   .exist?(file)
  #   .open(file, 'w')  # Requires the ability to write files.
  #   .open(file, 'r')  # Probably requires the last file writing test to work.
  #   .file?(file)      # Test on both a file (== true ) and a directory (== false)
  #   .directory?(file) # Test on both a file (== false) and a directory (== true)

  file.dirname('a/b').should == "a"
  file.join('a', 'b').should == "a/b"
end
