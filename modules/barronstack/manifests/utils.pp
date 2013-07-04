class barronstack::utils {
  package { [
    'vim',
    'htop',
  ]:
    ensure => 'installed',
  }
}
