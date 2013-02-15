verbose true

VERSION = begin
  data = File.read("VERSION").strip
end
DISTDIR = "rbenv-ruby-install-#{VERSION}"

# Check whether the specified command is in $PATH, and return its
# absolute filename. Returns nil if the command is not found.
#
# This function exists because system('which') doesn't always behave
# correctly, for some weird reason.
def find_command(name)
  ENV['PATH'].split(File::PATH_SEPARATOR).detect do |directory|
    path = File.join(directory, name.to_s)
    if File.executable?(path)
      return path
    end
  end
  return nil
end

def download(url)
  if find_command('wget')
    sh "wget", url
  else
    sh "curl", "-O", "-L", url
  end
end

def create_distdir(distdir = DISTDIR)
  sh "rm -rf #{distdir}"
  sh "mkdir #{distdir}"

  sh "cp install installer.rb platform_info.rb dependencies.rb optparse.rb VERSION #{distdir}/"
  sh "cp -r runtime #{distdir}/"
  File.open("#{distdir}/.rbenv-version", "w") do |f|
    f.write("#{VERSION}")
  end
end

# Returns the disk usage of the given directory, in KB.
def disk_usage(dir)
  if RUBY_PLATFORM =~ /linux/
    options = "-a -k --apparent-size --max-depth=0"
  else
    options = "-k -d 0"
  end
  return `du #{options} \"#{dir}\"`.strip.to_i
end

def create_fakeroot
  distdir = "/tmp/rbenvrubyinstall-test"
  create_distdir(distdir)
  sh "rm -rf fakeroot"
  sh "mkdir fakeroot"
  fakeroot = File.expand_path("fakeroot")

  sh "#{distdir}/install --destdir='#{fakeroot}'"
  puts "*** rbenv ruby has been installed to #{fakeroot}"
end

desc "Create a distribution directory"
task :distdir do
  create_distdir
end

desc "Create a distribution package"
task :package do
  create_distdir
  ENV['GZIP'] = '--best'
  sh "tar -czf #{DISTDIR}.tar.gz #{DISTDIR}"
  sh "rm -rf #{DISTDIR}"
end

desc "Test the installer script. Pass extra arguments to the installer with ARGS."
task :test_installer do
  distdir = "/tmp/rbenvrubyinstall-test"
  create_distdir(distdir)
  sh "ln -sf `pwd`/installer.rb #{distdir}/installer.rb"
  command = "#{distdir}/installer #{ENV['ARGS']}"
  sh command
end
