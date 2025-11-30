# aliases
alias va="source .venv/bin/activate.fish"
alias vd="deactivate.fish"

set -gx PATH $HOME/.local/bin $PATH

# default editor
set -gx EDITOR hx

# python
set -gx PYTHONBREAKPOINT ipdb.set_trace
set -gx PYTHONDONTWRITEBYTECODE 1
# set -gx OPENSSL_MODULES /usr/lib64/ossl-modules
set -gx UV_ENV_FILE .env

# golang
set -gx PATH $PATH /usr/local/go/bin
set -gx GOPATH $HOME/go
set -gx PATH $PATH $GOPATH/bin

# fzf
set -gx FZF_DEFAULT_OPTS '--layout=reverse --border'
fzf --fish | source

# zoxide
zoxide init fish | source

# mise
mise activate fish | source

alias todo="hx ~/todo.txt"

function ruff-fix-format
    ruff check --fix $argv
    ruff format $argv
end

alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"
alias gm="git merge"
alias gc="git commit -v"
alias gs="git status"

function ga
    git status --short |
        fzf --multi --preview 'git diff --color=always {2}' |
        awk '{print $2}' |
        xargs git add
end

if test -f ~/.config/fish/private.fish
    source ~/.config/fish/private.fish
end
