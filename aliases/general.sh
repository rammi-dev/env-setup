# aliases/general.sh
# General shell aliases — migrated and improved from ~/.bashrc

# ─── ls ──────────────────────────────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# LS_COLORS — muted professional palette, no vivid colors
# Directories: bold text only (no color shift) — clean and readable
# ow: other-writable (WSL default) — same as di, suppresses green background
export LS_COLORS="\
di=01:\
fi=00:\
ex=38;5;114:\
ln=38;5;73:\
or=38;5;167:\
mi=38;5;167:\
pi=38;5;179:\
so=38;5;134:\
bd=01;38;5;179:\
cd=01;38;5;179:\
su=38;5;203:\
sg=38;5;179:\
tw=01:\
ow=01:\
*.tar=38;5;167:*.tgz=38;5;167:*.zip=38;5;167:*.gz=38;5;167:*.bz2=38;5;167:*.xz=38;5;167:\
*.jpg=38;5;139:*.jpeg=38;5;139:*.png=38;5;139:*.gif=38;5;139:*.svg=38;5;139:*.mp4=38;5;139:*.mp3=38;5;139:\
*.py=38;5;114:*.sh=38;5;114:*.bash=38;5;114:*.js=38;5;114:*.ts=38;5;114:*.go=38;5;114:*.java=38;5;114:\
*.yaml=38;5;73:*.yml=38;5;73:*.json=38;5;73:*.toml=38;5;73:*.xml=38;5;73:\
*.md=38;5;145:*.txt=38;5;145:\
*.log=38;5;239"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ─── Alert: notify on long-running command completion ────────────────────────
# Usage: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ─── Navigation ──────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

# ─── Safety ──────────────────────────────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
