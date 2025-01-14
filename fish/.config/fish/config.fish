# aliases
alias va="source .venv/bin/activate.fish"
alias vd="deactivate.fish"

set -gx PATH $HOME/.local/bin $PATH

# default editor
set -gx EDITOR nvim

# python
set -gx PYTHONBREAKPOINT ipdb.set_trace
set -gx PYTHONDONTWRITEBYTECODE 1

# golang
set -gx PATH $PATH /usr/local/go/bin
set -gx GOPATH $HOME/go
set -gx PATH $PATH $GOPATH/bin

# zellij
eval (zellij setup --generate-auto-start fish | string collect)

mise activate fish | source
