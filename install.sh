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
  msg "${Red}[✘]${Color_off} ${1}${2}"
}
# }}}

# echo_with_color {{{
echo_with_color () {
  printf '%b\n' "$1$2${Color_off}" >&2
}
# }}}

# fetch_repo {{{
fetch_repo () {
  if [[ -d "$HOME/.sivim" ]]; then
    info "Trying to update SiVim"
    cd "$HOME/.sivim"
    git pull
    cd - > /dev/null 2>&1
    success "Successfully update SiVim"
  else
    info "Trying to clone SiVim"
    git clone https://github.com/zkalves/sivim.git "$HOME/.sivim"
    success "Successfully clone SiVim"
  fi
}
# }}}

# install_vim {{{
install_vim () {
  #backup_date=$(date +'%Y%m%d')
  if [[ -f "$HOME/.vimrc" ]]; then
    mv "$HOME/.vimrc" "$HOME/.vimrc_backup_sivim"
    success "Backup $HOME/.vimrc to $HOME/.vimrc_backup_sivim"
  fi

  if [[ -d "$HOME/.vim" ]]; then
    if [[ "$(readlink $HOME/.vim)" =~ \.sivim$ ]]; then
      success "Installed SiVim for vim"
    else
      mv "$HOME/.vim" "$HOME/.vim_backup_sivim"
      success "BackUp $HOME/.vim to $HOME/.vim_backup_sivim"
      ln -s "$HOME/.sivim" "$HOME/.vim"
      success "Installed SiVim for vim"
    fi
  else
    ln -s "$HOME/.sivim" "$HOME/.vim"
    success "Installed SiVim for vim"
  fi
}
# }}}

# install_package_manager {{{
install_package_manager () {
  # dein package manager
  if [[ ! -d "$HOME/.sivim/plugins/repos/github.com/Shougo/dein.vim" ]]; then
    info "Install dein.vim"
    git clone https://github.com/Shougo/dein.vim.git $HOME/.sivim/plugins/repos/github.com/Shougo/dein.vim
    success "dein.vim installation done"
  fi

  ## vim-plug package manager
  #info "Install vim-plug package manager"
  #curl -sfLo ~/.sivim/autoload/plug.vim --create-dirs \
  #  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #success "vim-plug installation done"
}
# }}}

## install_default_colorscheme {{{
#install_default_colorscheme () {
#  # gruvbox color scheme
#  if [[ ! -d "$HOME/.sivim/plugins/gruvbox" ]]; then
#    info "Install gruvbox"
#    mkdir -p $HOME/.sivim/plugins
#    git clone https://github.com/morhetz/gruvbox.git $HOME/.sivim/plugins/gruvbox
#    success "gruvbox installation done"
#  fi
#}
## }}}

# install_neovim {{{
install_neovim () {
  if [[ -d "$HOME/.config/nvim" ]]; then
    if [[ "$(readlink $HOME/.config/nvim)" =~ \.sivim$ ]]; then
      success "Installed SiVim for neovim"
    else
      mv "$HOME/.config/nvim" "$HOME/.config/nvim_backup_sivim"
      success "BackUp $HOME/.config/nvim to $HOME/.config/nvim_backup_sivim"
      ln -s "$HOME/.sivim" "$HOME/.config/nvim"
      success "Installed SiVim for neovim"
    fi
  else
    ln -s "$HOME/.sivim" "$HOME/.config/nvim"
    success "Installed SiVim for neovim"
  fi
}
# }}}

# uninstall_vim {{{
uninstall_vim () {
  if [[ -d "$HOME/.vim" ]]; then
    if [[ "$(readlink $HOME/.vim)" =~ \.sivim$ ]]; then
      rm "$HOME/.vim"
      success "Uninstall SiVim for vim"
      if [[ -d "$HOME/.vim_backup_sivim" ]]; then
        mv "$HOME/.vim_backup_sivim" "$HOME/.vim"
        success "Recover from $HOME/.vim_backup_sivim"
      fi
    fi
  fi
  if [[ -f "$HOME/.vimrc_backup_sivim" ]]; then
    mv "$HOME/.vimrc_backup_sivim" "$HOME/.vimrc"
    success "Recover from $HOME/.vimrc_backup_sivim"
  fi
}
# }}}

# uninstall_neovim {{{
uninstall_neovim () {
  if [[ -d "$HOME/.config/nvim" ]]; then
    if [[ "$(readlink $HOME/.config/nvim)" =~ \.sivim$ ]]; then
      rm "$HOME/.config/nvim"
      success "Uninstall SiVim for neovim"
      if [[ -d "$HOME/.config/nvim_backup_sivim" ]]; then
        mv "$HOME/.config/nvim_backup_sivim" "$HOME/.config/nvim"
        success "Recover from $HOME/.config/nvim_backup_sivim"
      fi
    fi
  fi
}
# }}}

# check_requirements {{{
check_requirements () {
  info "Checking Requirements for SiVim"
  if hash "git" &>/dev/null; then
    git_version=$(git --version)
    success "Check Requirements: ${git_version}"
  else
    warn "Check Requirements : git"
  fi
  if hash "vim" &>/dev/null; then
    is_vim8=$(vim --version | grep "Vi IMproved 8.0")
    is_vim74=$(vim --version | grep "Vi IMproved 7.4")
    if [ -n "$is_vim8" ]; then
      success "Check Requirements: vim 8.0"
    elif [ -n "$is_vim74" ]; then
      success "Check Requirements: vim 7.4"
    else
      if hash "nvim" &>/dev/null; then
        success "Check Requirements: nvim"
      else
        warn "SiVim need vim 7.4 or above"
      fi
    fi
    if hash "nvim" &>/dev/null; then
      success "Check Requirements: nvim"
    fi
  else
    if hash "nvim" &>/dev/null; then
      success "Check Requirements: nvim"
    else
      warn "Check Requirements : vim or nvim"
    fi
  fi
  info "Checking true colors support in terminal:"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/JohnMorales/dotfiles/master/colors/24-bit-color.sh)"
}
# }}}

# usage {{{
usage () {
  echo "SiVim install script : V ${Version}"
  echo ""
  echo "Usage : curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- [option] [target]"
  echo ""
  echo "  This is bootstrap script for SiVim."
  echo ""
  echo "OPTIONS"
  echo ""
  echo " -i, --install            install Sivim for vim or neovim"
  echo " -v, --version            Show version information and exit"
  echo " -u, --uninstall          Uninstall SiVim"
  echo " -c, --checkRequirements  checkRequirements for SiVim"
  echo ""
  echo "EXAMPLE"
  echo ""
  echo "    Install SiVim for vim and neovim"
  echo ""
  echo "        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash"
  echo ""
  echo "    Install SiVim for vim only or neovim only"
  echo ""
  echo "        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --install vim"
  echo "        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --install neovim"
  echo ""
  echo "    Uninstall SiVim"
  echo ""
  echo "        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --uninstall"
}
# }}}

# install_vim_plugins {{{
install_vim_plugins () {
   vim +qall!
}
# }}}

# install_neovim_plugins {{{
install_neovim_plugins () {
   nvim +qall!
}
# }}}

# install_done {{{

install_done () {
  echo_with_color ${Yellow} ""
  echo_with_color ${Yellow} "Almost done!"
  echo_with_color ${Yellow} "=============================================================================="
  echo_with_color ${Yellow} "==    Open Vim or Neovim and it will install the plugins automatically      =="
  echo_with_color ${Yellow} "=============================================================================="
  echo_with_color ${Yellow} ""
  echo_with_color ${Yellow} "That's it. Thanks for installing SiVim. Enjoy!"
  echo_with_color ${Yellow} ""
}

# }}}

# welcome {{{


welcome () {
    echo_with_color ${Yellow} "                                                                                    "
    echo_with_color ${Yellow} "                                                                                    "
    echo_with_color ${Yellow} "   SSSSSSSSSSSSSSS   iiii VVVVVVVV           VVVVVVVV iiii                          "
    echo_with_color ${Yellow} " SS:::::::::::::::S i::::iV::::::V           V::::::Vi::::i                         "
    echo_with_color ${Yellow} "S:::::SSSSSS::::::S  iiii V::::::V           V::::::V iiii                          "
    echo_with_color ${Yellow} "S:::::S     SSSSSSS       V::::::V           V::::::V                               "
    echo_with_color ${Yellow} "S:::::S            iiiiiii V:::::V           V:::::Viiiiiii    mmmmmmm    mmmmmmm   "
    echo_with_color ${Yellow} "S:::::S            i:::::i  V:::::V         V:::::V i:::::i  mm:::::::m  m:::::::mm "
    echo_with_color ${Yellow} " S::::SSSS          i::::i   V:::::V       V:::::V   i::::i m::::::::::mm::::::::::m"
    echo_with_color ${Yellow} "  SS::::::SSSSS     i::::i    V:::::V     V:::::V    i::::i m::::::::::::::::::::::m"
    echo_with_color ${Yellow} "    SSS::::::::SS   i::::i     V:::::V   V:::::V     i::::i m:::::mmm::::::mmm:::::m"
    echo_with_color ${Yellow} "       SSSSSS::::S  i::::i      V:::::V V:::::V      i::::i m::::m   m::::m   m::::m"
    echo_with_color ${Yellow} "            S:::::S i::::i       V:::::V:::::V       i::::i m::::m   m::::m   m::::m"
    echo_with_color ${Yellow} "            S:::::S i::::i        V:::::::::V        i::::i m::::m   m::::m   m::::m"
    echo_with_color ${Yellow} "SSSSSSS     S:::::Si::::::i        V:::::::V        i::::::im::::m   m::::m   m::::m"
    echo_with_color ${Yellow} "S::::::SSSSSS:::::Si::::::i         V:::::V         i::::::im::::m   m::::m   m::::m"
    echo_with_color ${Yellow} "S:::::::::::::::SS i::::::i          V:::V          i::::::im::::m   m::::m   m::::m"
    echo_with_color ${Yellow} " SSSSSSSSSSSSSSS   iiiiiiii           VVV           iiiiiiiimmmmmm   mmmmmm   mmmmmm"
    echo_with_color ${Yellow} "                                                                                    "
    echo_with_color ${Yellow} "                                                                                    "
    echo_with_color ${Yellow} "                      version : 0.1.0           by : zkalves                        "
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

# }}}

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

# }}}

### main {{{
main () {
  if [ $# -gt 0 ]
  then
    case $1 in
      --uninstall|-u)
        info "Trying to uninstall SiVim"
        #uninstall_vim
        uninstall_neovim
        echo_with_color ${BWhite} "Thanks!"
        exit 0
        ;;
      --checkRequirements|-c)
        check_requirements
        exit 0
        ;;
      --install|-i)
        welcome
        need_cmd 'git'
        fetch_repo
        if [ $# -eq 2 ]
        then
          case $2 in
            neovim)
              install_neovim
              #install_default_colorscheme
              install_neovim_plugins
              install_done
              exit 0
            #  ;;
            #vim)
            #  install_vim
            #  install_default_colorscheme
            #  install_vim_plugins
            #  install_done
            #  exit 0
          esac
        fi
        #install_vim
        install_neovim
        #install_default_colorscheme
        # install_vim_plugins
        install_neovim_plugins
        install_done
        exit 0
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --version|-v)
        msg "${Version}"
        exit 0
    esac
  else
    welcome
    need_cmd 'git'
    fetch_repo
    #install_vim
    install_neovim
    install_package_manager
    install_fonts
    #install_default_colorscheme
    # install_vim_plugins
    install_neovim_plugins
    install_done
  fi
}

# }}}

main $@

# vim:set foldenable foldmethod=marker:
