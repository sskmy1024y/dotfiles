<p align="center">
<img src="https://user-images.githubusercontent.com/16918590/129431439-e3a2f2e9-ebf8-4ef5-a8be-ead0d45d73b0.png" height="164px;" />
<h1 align="center">Dotfiles</h1>
<p align="center">
<img src="https://img.shields.io/badge/works%20on-Ubuntu-DD4814.svg" />
<img src="https://img.shields.io/badge/works%20on-ArchLinux-00AAD4.svg" />
<img src="https://img.shields.io/badge/works%20on-MacOS-lightgrey.svg" />
<a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</p>

## 🤔 What is this

This is a repository with my configuration files, those are verified on Linux / macOS.

Author: sskmy1024y  
Date: 14/Aug/2021 

## 📂 Directory structure

```sh
dotfiles/
 ├── bin/            # Useful command line scripts
 ├── config/         # Dotfiles
 │   ├── git
 │   ├── iterm
 │   ├── tmux
 │   └── zsh
 ├── doc/            # Document files
 ├── etc/
 │   ├── init        # Setup & Install scripts
 │   ├── scripts     # Install scripts for some packages
 │   └── lib         # Library scripts
 └── Makefile
```

## 📦 Setup

Just copy and execute this !!!

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)"
```

If you want to install a [dev-packages](https://github.com/takuzoo3868/dotfiles/tree/master/etc/scripts/install.d), add `init` as an optional argument.

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)" -s init
```

### Setup using Makefile

```bash
$ git clone https://github.com/sskmy1024y/dotfiles.git $HOME/.dotfiles
$ cd $HOME/.dotfiles
$ make install
```

Incidentally, `make install` will perform the following tasks.

*   `make update` Updating dotfiles from this repository
*   `make deploy` Deploying dotfiles to host
*   `make init` Initializing some settings

Other options can be checked with `make help`.

## 💁‍♀️ Recommend

I recommend installing [Nerd fonts](https://github.com/ryanoasis/nerd-fonts) to display graphical icons on terminal. 

A script to automate the installation is placed in `etc/init/deep.d/98_font.sh`.

```bash
$ make deep
```

## References

*   [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles)

*   [takuzoo3868/dotfiles](https://github.com/takuzoo3868/dotfiles)
