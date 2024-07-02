export ZSH="$HOME/.oh-my-zsh"
plugins=(git fzf)
source $ZSH/oh-my-zsh.sh

source $HOME/.nvm/nvm.sh

alias vim=nvim
alias vi=nvim
alias va="source .venv/bin/activate"
alias vd="deactivate"
alias ear="bluetoothctl connect 2C:BE:EB:09:13:42"
alias near="bluetoothctl disconnect 2C:BE:EB:09:13:42"
alias ta="tmux attach"
alias tn="tmux new -s"

export EDITOR=nvim

export PATH="$HOME/.config/lsp/lua-language-server/bin:$PATH"

export PATH="$PATH:/usr/local/go/bin"
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PYTHONBREAKPOINT=ipdb.set_trace
export PYTHONDONTWRITEBYTECODE=1

export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"

# bun completions
[ -s "/home/ryche/.bun/_bun" ] && source "/home/ryche/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
. "$HOME/.cargo/env"

# uv
export PATH="$HOME/.cargo/bin:$PATH"

eval "$(zellij setup --generate-auto-start zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
