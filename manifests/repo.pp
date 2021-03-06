class mysql::repo
{
  include apt

  case $mysql::type{
    'oracle' : { # use standard packages
    }

    'percona': {
      apt::source {'percona':
        location    => 'http://repo.percona.com/apt',
        repos       => 'main',
        key         => 'CD2EFD2A',
        include_src => false,
      }
    }

    'mariadb': {
      apt::source {'mariadb5.3':
        location    => 'http://mirror2.hs-esslingen.de/mariadb/repo/5.3/debian',
        repos       => 'main',
        key         => '1BB943DB',
        include_src => false,
      }
    }
  }
}
