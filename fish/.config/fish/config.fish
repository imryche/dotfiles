# aliases
alias va="source .venv/bin/activate.fish"
alias vd="deactivate.fish"

set -x PATH $HOME/.local/bin $PATH

# default editor
set -x EDITOR nvim

# python
set -x PYTHONBREAKPOINT ipdb.set_trace
set -x PYTHONDONTWRITEBYTECODE 1

# lua
set -x PATH $HOME/.config/lsp/lua-language-server/bin $PATH

# golang
set -x PATH $PATH /usr/local/go/bin
set -x GOPATH $HOME/go
set -x PATH $PATH $GOPATH/bin

# nvm
set --universal nvm_default_version lts

# deno
set -x DENO_INSTALL $HOME/.deno
set -x PATH $DENO_INSTALL/bin $PATH

# rust
set -x PATH $HOME/.cargo/bin $PATH

# starship
starship init fish | source

# zellij
eval (zellij setup --generate-auto-start fish | string collect)

# zoxide
zoxide init fish | source

# fzf
fzf --fish | source

# direnv
direnv hook fish | source

# pyenv
set -x PYENV_ROOT $HOME/.pyenv
if test -d $PYENV_ROOT/bin
    set -x PATH $PYENV_ROOT/bin $PATH
end
pyenv init --path | source
pyenv init - | source
