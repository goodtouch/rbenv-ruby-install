require "#{File.dirname(__FILE__)}/platform_info"

# Represents a dependency software that Ruby requires. It's used by the
# installer to check whether all dependencies are available. A Dependency object
# contains full information about a dependency, such as its name, code for
# detecting whether it is installed, and installation instructions for the
# current platform.
class Dependency # :nodoc: all
  [:name, :install_command, :install_instructions, :install_comments,
   :website, :website_comments, :provides].each do |attr_name|
    attr_writer attr_name

    define_method(attr_name) do
      call_init_block
      return instance_variable_get("@#{attr_name}")
    end
  end

  def initialize(&block)
    @included_by = []
    @init_block = block
  end

  def define_checker(&block)
    @checker = block
  end

  def check
    call_init_block
    result = Result.new
    @checker.call(result)
    return result
  end

private
  class Result
    def found(filename_or_boolean = nil)
      if filename_or_boolean.nil?
        @found = true
      else
        @found = filename_or_boolean
      end
    end

    def not_found
      found(false)
    end

    def found?
      return !@found.nil? && @found
    end

    def found_at
      if @found.is_a?(TrueClass) || @found.is_a?(FalseClass)
        return nil
      else
        return @found
      end
    end
  end

  def call_init_block
    if @init_block
      init_block = @init_block
      @init_block = nil
      init_block.call(self)
    end
  end
end

# Namespace which contains the different dependencies that Ruby Enterprise Edition may require.
# See Dependency for more information.
module Dependencies # :nodoc: all
  APPLE_COMPILER_INSTALL_INSTRUCTIONS =
    "Please install OS X GCC-4.2 by running: brew tap homebrew/dupes; brew install apple-gcc42"
  include PlatformInfo

  Git = Dependency.new do |dep|
    dep.name = "Git version control system"
    dep.define_checker do |result|
      git = PlatformInfo.find_command('git')
      if git
        result.found(git)
      else
        result.not_found
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install git-core"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install git-core"
      when :gentoo
        dep.install_command = "emerge -av git"
      end
    elsif RUBY_PLATFORM =~ /darwin/
      dep.install_instructions = "brew install git"
    end
    dep.website = "http://git-scm.com/"
  end

  CC = Dependency.new do |dep|
    dep.name = "Non-broken C compiler"
    dep.define_checker do |result|
      if PlatformInfo::CC.nil?
        result.not_found
      else
        result.found(PlatformInfo::CC)
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install build-essential"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install gcc-c++"
      when :gentoo
        dep.install_command = "emerge -av gcc"
      end
    elsif RUBY_PLATFORM =~ /darwin/
      dep.install_instructions = APPLE_COMPILER_INSTALL_INSTRUCTIONS
    end
    dep.website = "http://gcc.gnu.org/"
  end

  CXX = Dependency.new do |dep|
    dep.name = "Non-broken C++ compiler"
    dep.define_checker do |result|
      if PlatformInfo::CXX.nil?
        result.not_found
      else
        result.found(PlatformInfo::CXX)
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install build-essential"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install gcc-c++"
      when :gentoo
        dep.install_command = "emerge -av gcc"
      end
    elsif RUBY_PLATFORM =~ /darwin/
      dep.install_instructions = APPLE_COMPILER_INSTALL_INSTRUCTIONS
    end
    dep.website = "http://gcc.gnu.org/"
  end

  Make = Dependency.new do |dep|
    dep.name = "The 'make' tool"
    dep.define_checker do |result|
      make = PlatformInfo.find_command('make')
      if make
        result.found(make)
      else
        result.not_found
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install build-essential"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install make"
      end
    elsif RUBY_PLATFORM =~ /darwin/
      dep.install_instructions = "Please install the Apple Development Tools: http://developer.apple.com/tools/"
    end
    dep.website = "http://www.gnu.org/software/make/"
  end

  Patch = Dependency.new do |dep|
    dep.name = "The 'patch' tool"
    dep.define_checker do |result|
      patch = PlatformInfo.find_command('patch')
      if patch
        result.found(patch)
      else
        result.not_found
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install patch"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install patch"
      end
    end
    dep.website = "http://www.gnu.org/software/diffutils/"
  end

  Zlib_Dev = Dependency.new do |dep|
    dep.name = "Zlib development headers"
    dep.define_checker do |result|
      begin
        File.open('/tmp/rbenvrubyinstall-check.c', 'w') do |f|
          f.write("#include <zlib.h>")
        end
        Dir.chdir('/tmp') do
          if system("(#{PlatformInfo::CC || 'gcc'} #{ENV['CFLAGS']} -c rbenvrubyinstall-check.c) >/dev/null 2>/dev/null")
            result.found
          else
            result.not_found
          end
        end
      ensure
        File.unlink('/tmp/rbenvrubyinstall-check.c') rescue nil
        File.unlink('/tmp/rbenvrubyinstall-check.o') rescue nil
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install zlib1g-dev"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install zlib-devel"
      end
    end
    dep.website = "http://www.zlib.net/"
  end

  OpenSSL_Dev = Dependency.new do |dep|
    dep.name = "OpenSSL development headers"
    dep.define_checker do |result|
      begin
        File.open('/tmp/rbenvrubyinstall-check.c', 'w') do |f|
          f.write("#include <openssl/ssl.h>")
        end
        Dir.chdir('/tmp') do
          if system("(#{PlatformInfo::CC || 'gcc'} #{ENV['CFLAGS']} -c rbenvrubyinstall-check.c) >/dev/null 2>/dev/null")
            result.found
          else
            result.not_found
          end
        end
      ensure
        File.unlink('/tmp/rbenvrubyinstall-check.c') rescue nil
        File.unlink('/tmp/rbenvrubyinstall-check.o') rescue nil
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install libssl-dev"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install openssl-devel"
      end
    end
    dep.website = "http://www.openssl.org/"
  end

  Readline_Dev = Dependency.new do |dep|
    dep.name = "GNU Readline development headers"
    dep.define_checker do |result|
      begin
        File.open('/tmp/rbenvrubyinstall-check.c', 'w') do |f|
          # readline.h doesn't work on OS X unless we #include stdio.h
          f.puts("#include <stdio.h>")
          f.puts("#include <readline/readline.h>")
        end
        Dir.chdir('/tmp') do
          if system("(#{PlatformInfo::CC || 'gcc'} #{ENV['CFLAGS']} -c rbenvrubyinstall-check.c) >/dev/null 2>/dev/null")
            result.found
          else
            result.not_found
          end
        end
      ensure
        File.unlink('/tmp/rbenvrubyinstall-check.c') rescue nil
        File.unlink('/tmp/rbenvrubyinstall-check.o') rescue nil
      end
    end
    if RUBY_PLATFORM =~ /linux/
      case LINUX_DISTRO
      when :ubuntu, :debian
        dep.install_command = "apt-get install libreadline5-dev"
      when :rhel, :fedora, :centos
        dep.install_command = "yum install readline-devel"
      end
    end
    dep.website = "http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html"
  end
end
