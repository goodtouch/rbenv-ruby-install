# rbenv-ruby-install

This installer will help you install Ruby with rbenv & ruby-build.

It is a port of the famous Ruby Enterprise Edition installer by Phusion (<http://www.phusion.nl>),  
and should work on Linux, FreeBSD & OSX.

You can expect this from the installation process:

1. **rbenv** will be installed in `~/.rbenv`.
2. **ruby-build** will be installed in `~/.rbenv/plugins`.
3. **ruby-1.9.3-p125** will be compiled in `~/.rbenv/versions/1.9.3-p125`.
4. **Rubygems**, **Rake** & **Bundler** will be installed.

## Install

### Automatic Terminal Install

Open a terminal and run this command (review script [here](https://raw.github.com/goodtouch/rbenv-ruby-install/master/install-web))

1. `curl https://raw.github.com/goodtouch/rbenv-ruby-install/master/install-web | sh`

### Manual

1. `git clone https://github.com/goodtouch/rbenv-ruby-install.git`
2. `cd rbenv-ruby-install`
3. `./install`

Enjoy !
