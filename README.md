# SiVim

curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash
Usage : curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- [option] [target]

  This is bootstrap script for SiVim.

OPTIONS

 -i, --install            install Sivim for vim or neovim
 -v, --version            Show version information and exit
 -u, --uninstall          Uninstall SiVim
 -c, --checkRequirements  checkRequirements for SiVim

EXAMPLE

    Install SiVim for vim and neovim

        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash

    Install SiVim for vim only or neovim only

        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --install vim
        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --install neovim

    Uninstall SiVim

        curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash -s -- --uninstall


NOTES:
    If you notice strange symbols added when changing modes or with some commands like CtrlP, then you will probably
    need to add the following to your terminal initialization script:
    tcsh: setenv VTE_VERSION "100"
    bash: export VTE_VERSION="100"

    And / Or one of the following to the init.before.vim:
    1. let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0
    2. if !has('gui_running')
          set guicursor=
       endif


   For better colors with Gruvbox add the following to the terminal initialization script:
    - gnome-terminal:
       gconftool-2 --set /apps/gnome-terminal/profiles/Default/palette --type=string "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3"
       gconftool-2 --set /apps/gnome-terminal/profiles/Default/background_color --type=string "#002B36"
       gconftool-2 --set /apps/gnome-terminal/profiles/Default/foreground_color --type=string "#657b83"

    - konsole:
        https://github.com/phiggins/konsole-colors-solarized


