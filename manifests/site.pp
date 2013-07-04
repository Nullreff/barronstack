node /^bungee\d+.*/ {
  include bungeecord
  include barronstack::utils
}

node /^host\d+.*/ {
  mark2::server { 'minecraft': }
  include barronstack::utils
}
