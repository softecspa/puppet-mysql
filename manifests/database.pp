# = Class: mysql::database
#
# define used for database creation
#
# == Parameters
#
# [*ensure*]
#   present: database'll be created if it not exists.
#   absent: database'll be dropped after or not a dump (depending on dump_on_drop parameter)
#
# [*dbname*]
#   database name
#
# [*dbuser*]
#   username for connection
#
# [*dbpass*]
#   password for that user
#
# [*privileges*]
#   privileges that this user must have. You can declare more privileges using an array.
#   Default: ALL PRIVILEGES
#
# [*host*]
#   host to grant privileges.
#
# [*dump_op_drop*]
#   used when ensure is absent. If true, before drop the db a dump is done.
#   Default: true
#
# == Examples
#
#   Create a database with ALL PRIVILEGES FROM a_username@'%'
#   mysql::database {
#     dbname  => 'a_new_db',
#     dbuser  => 'a_username',
#     dbpass  => 'XXXXXXX',
#   }
#
#   Create a database with SELECT,INSERT,UPDATE FROM a_username@'192.168.1.10'
#   mysql::database {
#     dbname  => 'a_new_db',
#     dbuser  => 'a_username',
#     dbpass  => 'XXXXXX',
#     privileges => ['SELECT', 'INSERT', 'UPDATE'],
#     host       => '192.168.1.10'
#   }
#
# == Author
#   Felice Pizzurro <felice.pizzurro@softecspa.it.it/>
#
define mysql::database (
  $ensure = 'present',
  $dbname,
  $dbuser,
  $dbpass,
  $privileges = 'ALL PRIVILEGES',
  $host = '%',
  $dump_on_drop = true,
) {

  include mysql

  Exec {
    require => Package[$mysql::params::packages]
  }

  case $ensure {
    'present': {
      exec {"create-db-$dbname":
        command => "/usr/bin/mysql -e \"CREATE DATABASE IF NOT EXISTS $dbname;\"",
        unless  => "/usr/bin/mysql -e 'use $dbname;'"
      }
    }
    'absent': {
      if $dump_on_drop {
        exec {"dump-db-$dbname":
          command => "/usr/bin/mysqldump ${mysql::params::dump_option} $dbname > ${mysql::params::disabled_db_path}/${dbname}.sql",
          unless  => "/usr/bin/test -f ${mysql::params::disabled_db_path}/${dbname}.sql"
        }
      }
      exec {"drop-db-$dbname":
        command => "/usr/bin/mysql -e DROP DATABASE $dbname;",
        onlyif  => "/usr/bin/mysql -e 'use $dbname;'"
      }
    }
  }

  mysql::grant {"grant-$dbuser-$dbname":
    dbname      => $dbname,
    dbuser      => $dbuser,
    pass        => $dbpass,
    privileges  => $privileges,
    host        => $host,
    require     => Exec["create-db-$dbname"],
  }
}
