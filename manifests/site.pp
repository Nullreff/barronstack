node 'default' {
  include barronstack::utils
}

node /^bungee\d+.*/ {
  include bungeecord
}
