# path
fish_add_path -g $HOME/.local/bin

# editor
set -gx EDITOR hx

# python
set -gx PYTHONBREAKPOINT ipdb.set_trace
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx UV_ENV_FILE .env

# go
set -gx GOPATH $HOME/go
fish_add_path -g /usr/local/go/bin
fish_add_path -g $GOPATH/bin

# fzf
set -gx FZF_DEFAULT_OPTS '--layout=reverse --border'
type -q fzf && fzf --fish | source

# tools
type -q zoxide && zoxide init fish | source
type -q mise && mise activate fish | source
type -q direnv && direnv hook fish | source

# aliases
abbr -a va 'source .venv/bin/activate.fish'
abbr -a vd deactivate.fish
abbr -a todo 'hx ~/todo.txt'

# python
function ruff-fix-format
    ruff check --fix $argv
    ruff format $argv
end

# git
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gf 'git fetch'
abbr -a gm 'git merge'
abbr -a gc 'git commit -v'
abbr -a gcm 'git commit -m'
abbr -a gca 'git commit --amend'
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gl 'git log --oneline --graph --decorate -20'
abbr -a gla 'git log --oneline --graph --decorate --all -20'
abbr -a gaa 'git add .'
abbr -a gap 'git add -p'
abbr -a gswc 'git switch -c'
abbr -a gco 'git checkout'

function ga
    set -l paths (
        git status --short |
        fzf --multi --nth=2.. --preview 'git diff --color=always -- {2..}' |
        string sub --start=4
    )
    test (count $paths) -gt 0 && git add -- $paths
    true
end

function gsw
    if test (count $argv) -gt 0
        git switch $argv
        return
    end

    set -l branch (
        git branch --all --format='%(refname:short)' |
        sed 's|^origin/||' |
        sort -u |
        fzf --height 40% --preview 'git log --oneline --graph --decorate -20 {}'
    )
    test -n "$branch" && git switch $branch
    true
end

if test -f ~/.config/fish/private.fish
    source ~/.config/fish/private.fish
end
