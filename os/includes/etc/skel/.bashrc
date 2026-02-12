# ============================================================================
# CursorOS v3 "Horizon" - Shell Configuration
# ============================================================================

export PATH="/usr/local/bin:$PATH"

# ─── Prompt ───────────────────────────────────────────────────────────────
# Sleek two-line prompt with git branch
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export PS1='\n\[\033[38;5;39m\]  \u\[\033[38;5;245m\]@\[\033[38;5;141m\]cursoros \[\033[38;5;245m\]in \[\033[38;5;222m\]\w\[\033[38;5;114m\]$(parse_git_branch)\[\033[0m\]\n  \[\033[38;5;39m\]❯\[\033[0m\] '

# ─── Aliases ──────────────────────────────────────────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -alFh --color=auto --group-directories-first'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# System
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias sysinfo='neofetch'
alias diskinfo='df -h'
alias meminfo='free -h'
alias ports='sudo ss -tulnp'
alias cpuinfo='lscpu'
alias gpuinfo='lspci | grep -i vga'
alias myip='curl -s ifconfig.me && echo'

# Safety
alias rm='rm -I --preserve-root'
alias mv='mv -i'
alias cp='cp -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shortcuts
alias open='xdg-open'
alias cls='clear'
alias h='history'
alias j='jobs -l'

# ─── Environment ──────────────────────────────────────────────────────────
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R --mouse'
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# ─── Welcome ──────────────────────────────────────────────────────────────
if [ -z "$CURSOROS_WELCOMED" ]; then
    export CURSOROS_WELCOMED=1
    echo ""
    echo -e "  \033[38;5;39m┌──────────────────────────────────────┐\033[0m"
    echo -e "  \033[38;5;39m│\033[0m  Welcome to \033[1;38;5;39mCursorOS\033[0m v3.0 \033[38;5;245m\"Horizon\"\033[0m  \033[38;5;39m│\033[0m"
    echo -e "  \033[38;5;39m└──────────────────────────────────────┘\033[0m"
    echo -e "  Type \033[38;5;222m'cursoros-help'\033[0m for commands"
    echo ""
fi

# ─── Completion ───────────────────────────────────────────────────────────
[ -f /etc/bash_completion ] && . /etc/bash_completion
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
