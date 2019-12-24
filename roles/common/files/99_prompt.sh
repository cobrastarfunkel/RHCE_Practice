if [[ $TERM =~ xterm* ]] || [ $TERM = "screen" ]; then
  # Work around for screen changing vim colors
  alias screen="TERM=xterm-256color screen"
  export PS1="\[\033[0;35m\]\u@\h \[\033[0;34m\]\w \[\033[00m\]> "
else
  # Above makes it hard to read on the proxmox terminal
  export PS1="\[\033[0;35m\]\u@\h \[\033[0;32m\]\w \[\033[00m\]> "
fi
