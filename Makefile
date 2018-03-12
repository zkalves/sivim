# SiVim - install and maintain from a local clone.
#
# install.sh remains the bootstrap for a machine with no clone: it fetches
# the repository first, then does the same work. Every target here acts on
# the checkout the Makefile sits in and never pulls, so a working tree with
# local edits is left alone.

SHELL := /bin/bash
.DEFAULT_GOAL := help

SIVIM_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

XDG_CONFIG_HOME ?= $(HOME)/.config
NVIM_CONFIG     := $(XDG_CONFIG_HOME)/nvim
NVIM_BACKUP     := $(XDG_CONFIG_HOME)/nvim_backup_sivim

NVIM     ?= nvim
PLUG     := $(SIVIM_DIR)/autoload/plug.vim
PLUG_URL := https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Directories init.vim points 'backupdir', 'directory', 'undodir' and
# 'viewdir' at. Each keeps a tracked .gitignore, which clean must not eat.
SCRATCH_DIRS := vimbackup vimswap vimundo vimviews

# Put this checkout on the runtimepath explicitly, so every target works
# before 'make link' has pointed the real configuration directory at it.
NVIM_HEADLESS = $(NVIM) --headless \
	--cmd 'set rtp^=$(SIVIM_DIR)' --cmd 'set rtp+=$(SIVIM_DIR)/after' \
	-u $(SIVIM_DIR)/init.vim

.PHONY: help install link plug plugins update check test clean uninstall \
        check-location

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; \
	      print "SiVim\n\nUsage: make <target>\n\nTargets:"} \
	     /^[a-zA-Z_-]+:.*##/ {printf "  %-14s %s\n", $$1, $$2}' \
	     $(MAKEFILE_LIST)
	@echo
	@printf "  %-14s %s\n" "checkout"  "$(SIVIM_DIR)"
	@printf "  %-14s %s\n" "installs to" "$(NVIM_CONFIG)"

install: check-location link plug plugins ## Link the config, fetch vim-plug, install plugins
	@echo "SiVim installed. Start nvim."

# init.vim hardcodes ~/.sivim for plugged/ and config/, so a checkout
# anywhere else installs but then reads its plugins from the wrong place.
check-location:
	@if [ "$(SIVIM_DIR)" != "$(HOME)/.sivim" ]; then \
	    echo "warning: this checkout is $(SIVIM_DIR), but init.vim hardcodes" >&2; \
	    echo "         ~/.sivim for plugged/ and config/. Move the clone to" >&2; \
	    echo "         ~/.sivim, or expect plugins to load from there." >&2; \
	fi

link: ## Symlink the nvim config directory at this checkout
	@if [ -L "$(NVIM_CONFIG)" ] && \
	    [ "$$(readlink "$(NVIM_CONFIG)")" = "$(SIVIM_DIR)" ]; then \
	    echo "already linked: $(NVIM_CONFIG) -> $(SIVIM_DIR)"; \
	elif [ -e "$(NVIM_CONFIG)" ] || [ -L "$(NVIM_CONFIG)" ]; then \
	    if [ -e "$(NVIM_BACKUP)" ]; then \
	        echo "refusing to overwrite $(NVIM_BACKUP); move it aside first" >&2; \
	        exit 1; \
	    fi; \
	    mv "$(NVIM_CONFIG)" "$(NVIM_BACKUP)"; \
	    echo "backed up $(NVIM_CONFIG) -> $(NVIM_BACKUP)"; \
	    ln -s "$(SIVIM_DIR)" "$(NVIM_CONFIG)"; \
	    echo "linked $(NVIM_CONFIG) -> $(SIVIM_DIR)"; \
	else \
	    mkdir -p "$(XDG_CONFIG_HOME)"; \
	    ln -s "$(SIVIM_DIR)" "$(NVIM_CONFIG)"; \
	    echo "linked $(NVIM_CONFIG) -> $(SIVIM_DIR)"; \
	fi

plug: $(PLUG) ## Fetch the vim-plug plugin manager if it is missing

$(PLUG):
	@echo "fetching vim-plug"
	@curl -sfLo "$@" --create-dirs "$(PLUG_URL)"

# vim-plug reports into a buffer nobody reads when headless, so confirm
# against the filesystem rather than trusting the exit status.
plugins: $(PLUG) ## Install every plugin declared in init.vim
	@$(NVIM_HEADLESS) -c 'PlugInstall --sync' \
	    -c 'let g:sivim_missing = keys(filter(copy(g:plugs), "!isdirectory(v:val.dir)"))' \
	    -c 'if !empty(g:sivim_missing) | call writefile(["FAIL: not installed: " . join(g:sivim_missing, ", ")], "/dev/stderr") | cquit 1 | endif' \
	    -c 'qa!'
	@echo "OK: every declared plugin is present"

update: $(PLUG) ## Update vim-plug and all installed plugins
	@$(NVIM_HEADLESS) -c 'PlugUpgrade' -c 'PlugUpdate --sync' -c 'qa!'

check: ## Report on the tools SiVim expects to find
	@bash "$(SIVIM_DIR)/install.sh" --checkRequirements

# -c runs before VimEnter, so quitting from a VimEnter autocmd lets the
# startup autocmds fire first - that is where the yank ring is bound.
test: ## Load init.vim headless and fail on any error it reports
	@out=$$($(NVIM_HEADLESS) -c 'autocmd VimEnter * qa!' 2>&1); \
	if [ -n "$$out" ]; then \
	    echo "$$out" >&2; \
	    echo "FAIL: nvim reported errors loading init.vim" >&2; \
	    exit 1; \
	fi; \
	echo "OK: init.vim loads cleanly"

clean: ## Delete the swap, backup, undo and view files in this checkout
	@for d in $(SCRATCH_DIRS); do \
	    if [ -d "$(SIVIM_DIR)/$$d" ]; then \
	        n=$$(find "$(SIVIM_DIR)/$$d" -type f ! -name '.gitignore' \
	             -delete -print | wc -l); \
	        echo "$$d: removed $$n file(s)"; \
	    fi; \
	done

uninstall: ## Remove the symlink and restore anything it replaced
	@if [ -L "$(NVIM_CONFIG)" ] && \
	    [ "$$(readlink "$(NVIM_CONFIG)")" = "$(SIVIM_DIR)" ]; then \
	    rm "$(NVIM_CONFIG)"; \
	    echo "removed $(NVIM_CONFIG)"; \
	    if [ -e "$(NVIM_BACKUP)" ]; then \
	        mv "$(NVIM_BACKUP)" "$(NVIM_CONFIG)"; \
	        echo "restored $(NVIM_CONFIG) from $(NVIM_BACKUP)"; \
	    fi; \
	else \
	    echo "$(NVIM_CONFIG) is not a SiVim symlink; nothing to do"; \
	fi
