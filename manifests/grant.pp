# = Define: mysql::grant
#
# define user to assign grant to a database
#
# == Parameters
#
# [*dbname*]
#   database name to assign grants
#
# [*dbuser*]
#   username to assign grants
#
# [*dbpass*]
#   password
#
# [*privileges*]
#   privileges that this user must have. You can declare more privileges using an array.
#
# [*host*]
#   host to grant privileges.
#
# == Examples
#
#   Create a database with ALL PRIVILEGES FROM a_username@'%'
#   mysql::grant {
#     dbname      => 'database_name',
#     dbuser      => 'john',
#     dbpass      => 'XXXXXX',
#     privileges  => 'ALL PRIVILEGES',
#     host        => '%',
#   }
#
# == Author
#   Felice Pizzurro <felice.pizzurro@softecspa.it>
#
define mysql::grant (
  $dbname,
  $dbuser,
  $pass,
  $privileges,
  $host,
) {

  Exec {
    require => [ Package[$mysql::params::packages], Class['mysql::service'] ]
  }

  if !is_array($privileges) {
    $array_privileges = [ $privileges ]
  }
  else {
    $array_privileges = $privileges
  }

  $check_connection = $mysql::disable_service_restart ? {
    true  =>  '/usr/bin/mysql -e "show databases"',
    false =>  undef
  }

  # Se l'utente non esiste lo crea e gli assegna i giusti privilegi
  exec { "create-user-$dbuser-$dbname":
    command => inline_template("/usr/bin/mysql -e \"GRANT <%= array_privileges.join(',') %> ON $dbname.* TO '$dbuser'@'$host' IDENTIFIED BY '$pass'\""),
    unless  => "/usr/bin/mysql -e \"show grants for '$dbuser'@'$host'\" | grep '$dbname'",
    onlyif  => $check_connection,
  }

  # Se l'utente esiste già, controlla che l'utente abbia i privilegi richiesti.
  # Se non e' cosi' elimina tutti i privilegi e riassegna solo quelli richiesti

  $escaped_dbname = $dbname? {
    '*'     => '\*',
    default => $dbname
  }

  $unless_check = inline_template("/usr/bin/mysql -e \"show grants for '$dbuser'@'$host'\" | egrep -i \"GRANT\\ (<%= array_privileges.join(',?\\ ?|') %>){<%= array_privileges.count %>,<%= array_privileges.count %>},?\\ ?\\ ON\\ .?$escaped_dbname.?\\.\\*\\ TO\\ '$dbuser'@'$host'\"")

  exec {"grant-priv-$dbuser-$dbname":
    command => inline_template("/usr/bin/mysql -e \"REVOKE ALL privileges ON $dbname.* FROM '$dbuser'@'$host'; GRANT <%= array_privileges.join(',') %> ON $dbname.* TO '$dbuser'@'$host' IDENTIFIED BY '$pass'\""),
    unless  => $unless_check,
    onlyif  => $check_connection,
    require => Exec["create-user-$dbuser-$dbname"],
  }

}
