function och --description 'OpenCode on homelab'
    set -lx OPENCODE_SERVER_PASSWORD (cat ~/.config/opencode/homelab-password)
    command opencode --server https://debian.tailf52e5b.ts.net:8443 $argv
end
