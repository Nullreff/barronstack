node 'default' {
  include barronstack::utils
}

node /^bungee\d+\.barronstack\.com$/ {
  include bungeecord
}
