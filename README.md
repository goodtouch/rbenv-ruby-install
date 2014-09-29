# rbenv-ruby-install

This installer will help you install Ruby with rbenv & ruby-build.

It is a port of the famous Ruby Enterprise Edition installer by Phusion (<http://www.phusion.nl>),  
and should work on Linux, FreeBSD & OSX.

You can expect this from the installation process:

0. Guidelines to install common dependencies
1. **rbenv** will be installed in `~/.rbenv`.
2. **ruby-build** will be installed in `~/.rbenv/plugins`.
3. **ruby-2.1.3** will be compiled in `~/.rbenv/versions/2.1.3`.
4. **Rubygems**, **Rake** & **Bundler** will be installed.

## Install

### Automatic Terminal Install

Open a terminal and run this command (review script [here](https://raw.githubusercontent.com/goodtouch/rbenv-ruby-install/master/install-web))

1. `bash <(curl https://raw.githubusercontent.com/goodtouch/rbenv-ruby-install/master/install-web)`

### Manual Install from sources

Open a terminal and run those commands (git required)

1. `git clone https://github.com/goodtouch/rbenv-ruby-install.git`
2. `cd rbenv-ruby-install`
3. `./install`

## Uninstall

1. `rm -rf ~/.rbenv`
2. remove `export PATH="$HOME/.rbenv/bin:$PATH"` and `eval "$(rbenv init -)"` from your `~/.zshenv`, `~/.zshrc` or `~/.bash_profile`

Enjoy !
