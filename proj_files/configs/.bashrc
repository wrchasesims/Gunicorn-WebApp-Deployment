# Allow using ctrl+backspace to delete words
stty werase '^H'

# Export Env Variables
export FILE_MANAGER="ranger"
export EDITOR="vim"

# Configuration Shortcuts
alias bc="vim ~/.bashrc"

# General Shortcuts
alias bat="batcat"
alias r="ranger"
alias c="clear"
alias bs="source ~/.bashrc"

# Package Management
alias apt="sudo apt"
alias apti="sudo apt install"
alias apts="sudo apt search"
alias aptu="sudo apt update && sudo apt upgrade -y"

# Directory Shortcuts
alias l='ls -la --color=auto'
alias ls='ls --color=auto'

## Functions -----------------------------------------
# Function to automatically ls after changing directory
cd() {
	builtin cd "$@" && ls -la
}

# Enable changing directories without typing cd
shopt -s autocd
