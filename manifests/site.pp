node 'default' {
  include barronstack::utils
}

node /^bungee\d+.*/ {
  include bungeecord
}

node /^host\d+.*/ {
  include mark2::server
}
