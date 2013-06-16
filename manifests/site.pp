node 'default' {
  include barronstack::utils
}

node /^bungee\d+.*/ {
  include bungeecord
}

node /^dota\d+.*/ {
  class { 'minecraft':
      name   => 'mc-dota',
      config => 'barroncraft/mincraft-dota-config',
  }
}
