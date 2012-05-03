# This module autodetects various platform-specific information, and
# provides that information through constants.
module PlatformInfo
private
  def self.env_defined?(name)
    return !ENV[name].nil? && !ENV[name].empty?
  end

  def self.determine_gem_command
    gem_exe_in_path = find_command("gem")
    correct_gem_exe = File.dirname(RUBY) + "/gem"
    if gem_exe_in_path.nil? || gem_exe_in_path == correct_gem_exe
      return "gem"
    else
      return correct_gem_exe
    end
  end

  def self.determine_library_extension
    if RUBY_PLATFORM =~ /darwin/
      return "bundle"
    else
      return "so"
    end
  end

  def self.read_file(filename)
    return File.read(filename)
  rescue
    return ""
  end

  def self.determine_libext
    if RUBY_PLATFORM =~ /darwin/
      return "dylib"
    else
      return "so"
    end
  end

  def self.determine_ruby_libext
    if RUBY_PLATFORM =~ /darwin/
      return "bundle"
    else
      return "so"
    end
  end

  def self.determine_linux_distro
    if RUBY_PLATFORM !~ /linux/
      return nil
    end
    lsb_release = read_file("/etc/lsb-release")
    if lsb_release =~ /Ubuntu/
      return :ubuntu
    elsif File.exist?("/etc/debian_version")
      return :debian
    elsif File.exist?("/etc/redhat-release")
      redhat_release = read_file("/etc/redhat-release")
      if redhat_release =~ /CentOS/
        return :centos
      elsif redhat_release =~ /Fedora/  # is this correct?
        return :fedora
      else
        # On official RHEL distros, the content is in the form of
        # "Red Hat Enterprise Linux Server release 5.1 (Tikanga)"
        return :rhel
      end
    elsif File.exist?("/etc/suse-release")
      return :suse
    elsif File.exist?("/etc/gentoo-release")
      return :gentoo
    else
      return :unknown
    end
    # TODO: Slackware, Mandrake/Mandriva
  end

  def self.determine_c_compiler
    result = ENV['CC'] || find_command('gcc') || find_command('cc')
    if broken_apple_llvm_gcc_compiler?(result)
      result = find_command('gcc-4.2')
    end
    return result
  end

  def self.determine_cxx_compiler
    result = ENV['CXX'] || find_command('g++') || find_command('c++')
    if broken_apple_llvm_gcc_compiler?(result)
      result = find_command('g++-4.2')
    end
    return result
  end

  # Apple ships llvm-gcc as the default gcc since Xcode 4, yet llvm-gcc
  # contains many bugs that could crash Ruby !!
  def self.broken_apple_llvm_gcc_compiler?(path)
    if RUBY_PLATFORM =~ /darwin/ && (path == "/usr/bin/gcc" || path == "/usr/bin/g++")
      return `#{path} --version` =~ /llvm/
    else
      return false
    end
  end

  # Returns true if the Solaris version of ld is in use.
  def self.solaris_ld?
    ld_version = `ld -V 2>&1`
    return !!ld_version.index("Solaris")
  end

public
  # Check whether the specified command is in $PATH, and return its
  # absolute filename. Returns nil if the command is not found.
  #
  # This function exists because system('which') doesn't always behave
  # correctly, for some weird reason.
  def self.find_command(name)
    ENV['PATH'].split(File::PATH_SEPARATOR).detect do |directory|
      path = File.join(directory, name.to_s)
      if File.file?(path) && File.executable?(path)
        return path
      end
    end
    return nil
  end

  CC = determine_c_compiler
  CXX = determine_cxx_compiler
  LIBEXT = determine_libext
  RUBYLIBEXT = determine_ruby_libext

  # An identifier for the current Linux distribution. nil if the operating system is not Linux.
  LINUX_DISTRO = determine_linux_distro
end
