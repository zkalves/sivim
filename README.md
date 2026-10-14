# SiVim

A Neovim configuration for ASIC and FPGA work: SystemVerilog, UVM, VHDL and
the Python that drives them. It expects to live beside the tmux
configuration in the dotfiles repository, which supplies the matching pane
navigation and session handling.

## Install

From a clone, which is the usual case:

```sh
git clone https://github.com/zkalves/sivim.git ~/.sivim
cd ~/.sivim
make install
```

`make install` symlinks the Neovim configuration directory at the checkout,
fetches vim-plug and installs the plugins. Anything already at
`~/.config/nvim` is moved to `~/.config/nvim_backup_sivim` first, and
`make uninstall` puts it back.

Clone to `~/.sivim`. `init.vim` hardcodes that path for `plugged/` and
`config/`, so a checkout elsewhere installs but then reads its plugins from
`~/.sivim` anyway. `make install` warns when it notices.

### Make targets

| Target | What it does |
| --- | --- |
| `make help` | List the targets, the checkout and the install path |
| `make install` | `link` + `plug` + `plugins` |
| `make link` | Symlink the nvim config directory, backing up what is there |
| `make plug` | Fetch vim-plug if missing |
| `make plugins` | Install every plugin declared in `init.vim`, and verify it landed |
| `make update` | Update vim-plug and all installed plugins |
| `make check` | Report on the tools SiVim expects (`install.sh --checkRequirements`) |
| `make test` | Load `init.vim` headless and fail on any error it reports |
| `make clean` | Delete the swap, backup, undo and view files in the checkout |
| `make uninstall` | Remove the symlink and restore anything it replaced |

`make test` is the quick check after editing `init.vim`. It starts Neovim
headless and fails if anything is reported, quitting from a `VimEnter`
autocommand so the startup autocommands run first.

Honours `XDG_CONFIG_HOME`, and `NVIM=/path/to/nvim` to pick an interpreter.

Plugins no longer declared in `init.vim` are left on disk; remove them with
`:PlugClean`.

### Bootstrap on a machine with no clone

`install.sh` does the same work but fetches the repository first:

```sh
curl -sLf https://raw.githubusercontent.com/zkalves/sivim/master/install.sh | bash
```

| Option | |
| --- | --- |
| `-i`, `--install` | Install, optionally for a named target |
| `-u`, `--uninstall` | Uninstall |
| `-c`, `--checkRequirements` | Check for the expected tools |
| `-v`, `--version` | Print the version |

It pulls the repository before installing, so prefer `make` on a checkout
you are editing.

## Local configuration

`config/init.before.vim` is sourced before plugins load and is where
per-site settings belong; `config/init.after.vim` is sourced last. The
options the HDL support reads are listed, commented out, at the bottom of
`init.before.vim`:

| Variable | |
| --- | --- |
| `g:sivim_verilog_linters` | ALE linters for the Verilog filetypes (default `['verible_ls']`) |
| `g:sivim_vhdl_linters` | ALE linters for VHDL (default `['ghdl']`) |
| `g:sivim_verilog_incdirs` | Include and library directories for the elaborating linters, and for `gf` / `:find` |
| `g:sivim_simulator` | Compiler `:SimLog` uses for its errorformat (default `ncverilog`) |
| `g:sivim_verilog_efm_uvm_lst` | UVM severities collected into the quickfix list |
| `g:sivim_verilog_fold_lst` | Syntax fold groups for SystemVerilog |

The general behaviour switches (`g:sivim_leader`, `g:sivim_no_autochdir`,
`g:sivim_no_easyWindows`, and the rest) are documented at their point of use
in `init.vim`.

## HDL support

### Linting

ALE runs the linters above as you edit. `verible-verilog-ls` checks one file
without elaborating it, so it does not resolve modules, packages or includes
that live in other directories; `:VeribleFilelist` builds a
`verible.filelist` at the repository root from `flow/manifests/*.f` so that
it can. With no argument it reads every manifest, otherwise name one:

```vim
:VeribleFilelist pqs_flare_config_7
```

Source `flow/project/conf.sh` first, or the `$VARs` in the manifests will not
resolve. `:ALEFix` reformats through `verible-verilog-format`; it is
deliberately not wired to run on save.

### Simulation logs

`:SimLog` reads a simulation log into the quickfix list, using the
errorformat of the compiler plugin that ships with
`verilog_systemverilog.vim` plus the UVM report patterns, so `:cn` and `:cp`
step from a `UVM_ERROR` to the line that reported it:

```vim
:SimLog sim.log         " uses g:sivim_simulator, default ncverilog
:SimLog vcs sim.log     " name the compiler explicitly
```

Any of `ncverilog`, `vcs`, `msim`, `verilator`, `iverilog`, `spyglass`,
`leda` and `cver` work as the compiler name.

### Navigation

Within a SystemVerilog buffer, with `maplocalleader` at `_`:

| Mapping | |
| --- | --- |
| `_fi` | Follow the instance under the cursor |
| `_fp` | Follow the port under the cursor |
| `_fr` | Return from a followed instance |
| `_gi` | Go to the start of the enclosing instance |

Following an instance needs a tags file built with universal-ctags.
`gf` on an `` `include `` resolves without the extension being typed.

## tmux

The matching half of this configuration lives in the dotfiles repository.
`vim-tmux-navigator` maps `<C-h/j/k/l>` and `<C-\>`; inside tmux those cross
pane borders, outside it they fall back to window switching. `.tmux.conf`
forwards the keys only when the pane is running vim. Set
`g:sivim_no_easyWindows` to keep `<C-k>` for digraphs.

Sessions are tracked with vim-obsession. `:ObsessionHere` starts tracking
the current project, writing to a central store under
`$XDG_DATA_HOME/nvim-sessions` that mirrors the project path, so no
`Session.vim` lands in the project itself. tmux-resurrect reads the same
location through its `central` strategy, which lives in the dotfiles
repository because that is what owns `~/.tmux`.

Files regenerated by a flow step reload when the pane regains focus, via
tmux's `focus-events` and `vim-tmux-focus-events`. On a login node reached
over plain ssh, with no X display, the clipboard registers are routed
through the tmux buffer and out to the local terminal over OSC 52.

## Notes

A patched Powerline or Nerd font is needed for the lightline separators and
the ALE indicators to render; the font belongs to whatever manages `$HOME`.
`make check` reports whether one is installed.

If stray symbols appear when changing modes, export `VTE_VERSION="100"` from
the terminal's initialization script, or set one of the following in
`config/init.before.vim`:

```vim
let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0
" or
if !has('gui_running')
    set guicursor=
endif
```

The colorscheme is solarized. For a terminal palette to match:

- gnome-terminal:

  ```sh
  gconftool-2 --set /apps/gnome-terminal/profiles/Default/palette --type=string "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3"
  gconftool-2 --set /apps/gnome-terminal/profiles/Default/background_color --type=string "#002B36"
  gconftool-2 --set /apps/gnome-terminal/profiles/Default/foreground_color --type=string "#657b83"
  ```

- konsole: https://github.com/phiggins/konsole-colors-solarized
