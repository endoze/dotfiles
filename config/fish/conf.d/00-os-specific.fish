if is_macos
  fish_add_path -a /opt/homebrew/bin

  alias dnsflush "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder;"
  alias pubkey 'pbcopy < ~/.ssh/id_rsa.pub'
end

if is_linux
  if command -v xclip >/dev/null 2>&1
    alias pbcopy 'xclip -selection clipboard'
    alias pbpaste 'xclip -selection clipboard -o'
    alias pubkey 'xclip -selection clipboard < ~/.ssh/id_rsa.pub'
  else if command -v xsel >/dev/null 2>&1
    alias pbcopy 'xsel --clipboard --input'
    alias pbpaste 'xsel --clipboard --output'
    alias pubkey 'xsel --clipboard --input < ~/.ssh/id_rsa.pub'
  end

  if command -v systemd-resolve >/dev/null 2>&1
    alias dnsflush "sudo systemd-resolve --flush-caches"
  else if command -v resolvectl >/dev/null 2>&1
    alias dnsflush "sudo resolvectl flush-caches"
  else if test -f /etc/init.d/nscd
    alias dnsflush "sudo /etc/init.d/nscd restart"
  end

  if test -d /home/linuxbrew/.linuxbrew
    fish_add_path -a /home/linuxbrew/.linuxbrew/bin
  end
end
