describe Sicuro::Runtime::Constants::DummyFS do
  subject { Sicuro::Runtime::Constants::DummyFS }

  # DummyFS.activate! cannot be tested, as far as I know.

  subject.add_file('/x/y', 'z')

  subject.has_file?('/x/y').should == true
  subject.find_file('/x').should   == ['/x/y']

  subject.get_file('/x/y').should == 'z'

  testfile = File.join(File.dirname(__FILE__), 'data', 'dummyfs-test.txt')

  it 'can add a file from disk and read it back' do
    # I am well aware that this is bad, because it combines two functionalities
    # into one test. I'm not sure how to separate it, however.
    subject.add_real_file(testfile)
    subject.get_file(testfile).should == open(testfile).read
  end
end

describe Sicuro::Runtime::Constants::File do
  subject { Sicuro::Runtime::Constants::File }

  # TODO:
  #   .exist?(file)
  #   .open(file, 'w')  # Requires the ability to write files.
  #   .open(file, 'r')  # Probably requires the last file writing test to work.
  #   .file?(file)      # Test on both a file (== true ) and a directory (== false)
  #   .directory?(file) # Test on both a file (== false) and a directory (== true)

  subject.dirname('a/b').should == "a"
  subject.join('a', 'b').should == "a/b"
end
