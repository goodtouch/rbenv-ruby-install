#!/usr/bin/env ruby
# encoding: binary
require "#{File.dirname(__FILE__)}/dependencies"

class Installer
  ROOT = File.expand_path(File.dirname(__FILE__))
  REQUIRED_DEPENDENCIES = [
    # Don't forget to update the dependency list in the manual too.
    Dependencies::CC,
    Dependencies::CXX,
    Dependencies::Make,
    Dependencies::Patch,
    Dependencies::Zlib_Dev,
    Dependencies::OpenSSL_Dev,
    Dependencies::Readline_Dev
  ]
  
  def start
    Dir.chdir(ROOT)
    @version = read_file("VERSION")
    @rbenv_destdir = '~/.rbenv'
    @rubybuild_destdir = "#{@rbenv_destdir}/plugins"
    @rbenv_in_path = ENV['PATH'] =~ /#{File.join(ENV['HOME'], '/.rbenv/bin')}/
    @rbenv_shims_in_path = read_file(profile) =~ /eval "\$\(rbenv init -\)"/
  
    show_welcome_screen
    check_dependencies || exit(1)
  
    steps = []
    steps += [
     :install_rbenv,
     :install_ruby_build,
     :install_ruby,
     :install_gems,
    ]
  
    steps.each do |step|
      if !self.send(step)
        exit 1
      end
    end
  
    show_finalization_screen
  ensure
    reset_terminal_colors
  end
  
private
  def show_welcome_screen
    color_puts "<banner>Welcome to the rbenv ruby installer</banner>"
    color_puts "This installer will help you install Ruby #{@version} with rbenv & ruby-build."
    puts
    color_puts "You can expect this from the installation process:"
    puts
    color_puts "  <b>1.</b> rbenv will be installed in #{@rbenv_destdir}."
    color_puts "  <b>2.</b> ruby-build will be installed in #{@rubybuild_destdir}."
    color_puts "  <b>3.</b> ruby-#{@version} will be compiled in #{@rbenv_destdir}/versions/#{@version}."
    color_puts "  <b>4.</b> Rubygems, Rake & Bundler will be installed."
    puts
    color_puts "<b>Press Enter to continue, or Ctrl-C to abort.</b>"
    wait
  end
  
  def check_dependencies
    missing_dependencies = []
    color_puts "<banner>Checking for required software...</banner>"
    puts
    REQUIRED_DEPENDENCIES.each do |dep|
      color_print " * #{dep.name}... "
      result = dep.check
      if result.found?
        if result.found_at
          color_puts "<green>found at #{result.found_at}</green>"
        else
          color_puts "<green>found</green>"
        end
      else
        color_puts "<red>not found</red>"
        missing_dependencies << dep
      end
    end

    if missing_dependencies.empty?
      return true
    else
      puts
      color_puts "<red>Some required software is not installed.</red>"
      color_puts "But don't worry, this installer will tell you how to install them.\n"
      color_puts "<b>Press Enter to continue, or Ctrl-C to abort.</b>"
      wait

      line
      color_puts "<banner>Installation instructions for required software</banner>"
      puts
      missing_dependencies.each do |dep|
        print_dependency_installation_instructions(dep)
        puts
      end
      return false
    end
  end
  
  def print_dependency_installation_instructions(dep)
    color_puts " * To install <yellow>#{dep.name}</yellow>:"
    if !dep.install_command.nil?
      color_puts "   Please run <b>#{dep.install_command}</b> as root."
    elsif !dep.install_instructions.nil?
      color_puts "   " << dep.install_instructions
    elsif !dep.website.nil?
      color_puts "   Please download it from <b>#{dep.website}</b>"
      if !dep.website_comments.nil?
        color_puts "   (#{dep.website_comments})"
      end
    else
      color_puts "   Search Google."
    end
  end
  
  def install_rbenv
    color_print " * rbenv... "
    if File.directory?(File.expand_path(@rbenv_destdir))
      color_puts "<green>found at #{File.expand_path(@rbenv_destdir)}</green>"
      return true
    else
      color_puts "<red>not found</red>"
      color_puts "\n<b>Installing rbenv to #{@rbenv_destdir}...</b>"
      Dir.chdir(File.expand_path(File.dirname(@rbenv_destdir))) do
        if !sh("git clone git://github.com/sstephenson/rbenv.git #{File.basename(@rbenv_destdir)}")
          puts "*** Cannot install rbenv"
          return false
        else
          return true
        end
      end
    end
  end
  
  def install_ruby_build
    color_print " * ruby-build... "
    if File.directory?(File.join(File.expand_path(@rubybuild_destdir), '/ruby-build'))
      color_puts "<green>found at #{File.join(File.expand_path(@rubybuild_destdir), '/ruby-build')}</green>"
      return true
    else
      color_puts "<red>not found</red>"
      color_puts "\n<b>Installing ruby-build to #{@rubybuild_destdir}...</b>"
      Dir.chdir(File.expand_path(@rbenv_destdir)) do
        if !sh("mkdir -p #{File.expand_path(@rubybuild_destdir)}") ||
          !Dir.chdir(File.expand_path(@rubybuild_destdir)){sh("git clone git://github.com/sstephenson/ruby-build.git")}
          puts "*** Cannot install ruby-build"
          return false
        else
          return true
        end
      end
    end
  end
  
  def install_ruby
    color_print " * ruby-#{@version}... "
    if File.exists?(File.join(File.expand_path(@rbenv_destdir), "/versions/#{@version}/bin/ruby"))
      color_puts "<green>found at #{File.join(File.expand_path(@rbenv_destdir), "/versions/#{@version}/bin/ruby")}</green>"
      return true
    else
      color_puts "<red>not found</red>"
      color_puts "\n<b>Installing ruby-#{@version}...</b>"
      if !sh("#{@rbenv_destdir}/bin/rbenv install #{@version}")
        puts "*** Cannot install ruby-#{@version}"
        return false
      else
        return true
      end
    end
  end

  def install_gems
    color_puts "\n<banner>Installing some gems...</banner>"
    puts
    gem_bin = "#{@rbenv_destdir}/versions/#{@version}/bin/ruby #{@rbenv_destdir}/versions/#{@version}/bin/gem"
    source_updated = false

    gem_names = ["rake", "bundler"]
    failed_gems = []

    gem_names.each do |gem_name|
      if (paths = Dir["#{File.expand_path(@rbenv_destdir)}/versions/#{@version}/lib/ruby/gems/*/gems/#{gem_name}-[0-9]*"]).empty?
        color_puts "\n<b>Installing #{gem_name}...</b>"
        source_updated ||= sh("#{gem_bin} sources --update")
        if !source_updated
          failed_gems = gem_names
          break
        end
        if !sh("#{gem_bin} install -r --no-rdoc --no-ri --no-update-sources --backtrace #{gem_name} && #{@rbenv_destdir}/bin/rbenv rehash")
          failed_gems << gem_name
        end
      else
        color_print " * #{gem_name}... "
        color_puts "<green>found at #{paths.last}</green>"
      end
    end

    if !failed_gems.empty?
      line
      color_puts "<banner>Warning: some libraries could not be installed</banner>"
      color_puts "The following gems could not be installed, probably because of an Internet"
      color_puts "connection error:"
      puts
      failed_gems.each do |gem_name|
        color_puts " <b>* #{gem_name}</b>"
      end
      puts
      color_puts "To install the aforementioned gems, please use the following commands:"
      failed_gems.each do |gem_name|
        color_puts "  <yellow>* #{gem_bin} install #{gem_name}</yellow>"
      end
      puts
      color_puts "<b>Press ENTER to show the next screen.</b>"
      wait
    end
  
    return true
    # FIXME: rbenv rehash
  end
  
  def show_finalization_screen
    color_puts "\n<banner>Ruby & rbenv are successfully installed!</banner>"
    color_puts "If you ever want to uninstall Ruby & rbenv, simply remove this"
    color_puts "directories:"
    puts
    color_puts "  <b>#{@rbenv_destdir}</b>"
    if !@rbenv_in_path
      puts
      color_puts "Make sure you don't forget run the following command to add rbenv to your path:"
      color_puts %[echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> #{profile.first}]
      color_puts "exec $SHELL"
    end
    if !@rbenv_shims_in_path
      puts
      color_puts "Make sure you don't forget run the following command to enable rbenv shims and autocompletion:"
      color_puts %[echo 'eval "$(rbenv init -)"' >> #{profile.first}]
      color_puts "exec $SHELL"
    end
    puts
    color_puts "Great thanks to <yellow>Phusion (www.phusion.nl)</yellow> for their REE installer from which this one comes from :-)"
    color_puts "Enjoy Ruby & rbenv !"
  end

private
  DEFAULT_TERMINAL_COLORS = "\e[0m\e[37m\e[40m"

  def color_puts(message)
    puts substitute_color_tags(message)
  end

  def color_print(message)
    print substitute_color_tags(message)
  end
  
  def substitute_color_tags(data)
    data = data.gsub(%r{<b>(.*?)</b>}m, "\e[1m\\1#{DEFAULT_TERMINAL_COLORS}")
    data.gsub!(%r{<red>(.*?)</red>}m, "\e[1m\e[31m\\1#{DEFAULT_TERMINAL_COLORS}")
    data.gsub!(%r{<green>(.*?)</green>}m, "\e[1m\e[32m\\1#{DEFAULT_TERMINAL_COLORS}")
    data.gsub!(%r{<yellow>(.*?)</yellow>}m, "\e[1m\e[33m\\1#{DEFAULT_TERMINAL_COLORS}")
    data.gsub!(%r{<banner>(.*?)</banner>}m, "\e[33m\e[44m\e[1m\\1#{DEFAULT_TERMINAL_COLORS}")
    return data
  end

  def reset_terminal_colors
    STDOUT.write("\e[0m")
    STDOUT.flush
  end

  def line
    puts "--------------------------------------------"
  end

  def wait
    if !@auto_install_prefix
      STDIN.readline
    end
  rescue Interrupt
    exit 2
  end
  
  def read_file(*filenames)
    out = ""
    filenames.to_a.flatten.each do |filename|
      out << File.read(File.expand_path(filename)).strip
    end
    return out
  rescue
    return ""
  end

  def sh(*command)
    puts command.join(' ') unless (command.last == false && !command.pop)
    return system(*command)
  end
  
  def shell
    File.basename(ENV['SHELL'])
  end

  def profile
    case shell
    when 'bash'
      %w(~/.bash_profile)
    when 'zsh'
      if File.exists?(File.expand_path('~/.zshenv'))
        %w(~/.zshenv ~/.zshrc)
      else
        %w(~/.zshrc ~/.zshenv)
      end
    else
      %w(~/.profile)
    end
  end
  
end
Installer.new.start
