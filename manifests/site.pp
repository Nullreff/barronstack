node 'default' {
  include barronstack::utils
}

node /^bungee\d+.*/ {
  include bungeecord
}

node /^host\d+.*/ {
  mark2::server { 'minecraft': }
}
