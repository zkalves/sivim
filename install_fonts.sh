#!/usr/bin/env bash

#=============================================================================
# install.sh --- bootstrap script for SiVim
# Copyright (c) 2018 zkalves
# Author: Ezequiel Alves <    >
# URL:
# License: GPLv3
#=============================================================================

# version {{{
Version='0.1.0'
# }}}

# terminal color template {{{
Color_off=$(tput sgr0)
# Regular Colors
Red=$(tput setaf 1)
Green=$(tput setaf 2)
Yellow=$(tput setaf 3)
Blue=$(tput setaf 4)
# Bold
BWhite="$(tput setaf 7)$(tput bold)"
# }}}

#System name {{{
System="$(uname -s)"
# }}}

# need_cmd {{{
need_cmd () {
  if ! hash "$1" &>/dev/null; then
    error "Need '$1' (command not fount)"
    exit 1
  fi
}
# }}}

# success/info/error/warn {{{
msg() {
  printf '%b\n' "$1" >&2
}

success() {
  msg "${Green}[✔]${Color_off} ${1}${2}"
}

info() {
  msg "${Blue}[➭]${Color_off} ${1}${2}"
}

error() {
  msg "${Red}[✘]${Color_off} ${1}${2}"
  exit 1
}

warn () {
   msg "${Yellow}[⚠]${Color_off} ${1}${2}"
}
# }}}

# download_font {{{
download_font () {
  url="https://raw.githubusercontent.com/zkalves/dotfiles/master/.local/share/fonts/$1"
  path="$HOME/.local/share/fonts/$1"
  if [[ -f "$path" ]]
  then
    success "Skipping $1"
  else
    info "Downloading $1"
    curl -s -o "$path" "$url"
    success "Downloaded $1"
  fi
}

# install_fonts {{{
install_fonts () {
  if [[ ! -d "$HOME/.local/share/fonts" ]]; then
    mkdir -p $HOME/.local/share/fonts
  fi
  download_font "DejaVu Sans Mono Bold Oblique for Powerline.ttf"
  download_font "DejaVu Sans Mono Bold for Powerline.ttf"
  download_font "DejaVu Sans Mono Oblique for Powerline.ttf"
  download_font "DejaVu Sans Mono for Powerline.ttf"
  download_font "DroidSansMonoForPowerlinePlusNerdFileTypesMono.otf"
  download_font "Ubuntu Mono derivative Powerline Nerd Font Complete.ttf"
  download_font "WEBDINGS.TTF"
  download_font "WINGDNG2.ttf"
  download_font "WINGDNG3.ttf"
  download_font "devicons.ttf"
  download_font "mtextra.ttf"
  download_font "symbol.ttf"
  download_font "wingding.ttf"
  info "Updating font cache, please wait ..."
  if [ $System == "Darwin" ];then
    if [ ! -e "$HOME/Library/Fonts" ];then
      mkdir "$HOME/Library/Fonts"
    fi
    cp $HOME/.local/share/fonts/* $HOME/Library/Fonts/
  else
    fc-cache -fv > /dev/null
    mkfontdir "$HOME/.local/share/fonts" > /dev/null
    mkfontscale "$HOME/.local/share/fonts" > /dev/null
  fi
  success "font cache done!"
}

install_fonts

# vim:set foldenable foldmethod=marker:
