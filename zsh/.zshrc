export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

alias vim=nvim
alias vi=nvim
alias va="source venv/bin/activate"
alias vd="deactivate"
alias ear="bluetoothctl connect 2C:BE:EB:09:13:42"
alias near="bluetoothctl disconnect 2C:BE:EB:09:13:42"

export PATH="$HOME/.config/lsp/lua-language-server/bin:$PATH"

export PATH="$PATH:/usr/local/go/bin"
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"
