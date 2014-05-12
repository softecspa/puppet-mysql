class mysql::functions
{
  define database ( $ensure, $dump = NONE )
  {
    case $ensure {
      present: {
        exec { "MySQL: create $name db":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"CREATE DATABASE ${name}\";",
          unless  => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"SHOW DATABASES;\" | grep -x '${name}'",
          require => Class["mysql::install"],
        }
      }

      importdb: {
        exec { "MySQL: import db":
          command   => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"CREATE DATABASE ${name}\";
                /usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf ${name} < ${dump}",
          require   => Class["mysql::install"],
        }
      }

      absent: {
        exec { "MySQL: drop $name db":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"DROP DATABASE ${name}\";",
          onlyif  => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"SHOW DATABASES;\" | grep -x '${name}'",
          require => Class["mysql::install"],
        }
      }

      default: {
        fail "Invalid 'ensure' value '$ensure' for mysql::database"
      }
    }
  }

  define user ($password, $database="*", $host="localhost",
               $ensure='present', $plain_password=false, 
               $grant=false, $privileges=false)
  {
    # TODO: add better doc
    # $plain_password assumes $password is not crypted (i.e. return of pwgen())
    # $grant: if true add WITH GRANT OPTION
    # $privileges: if != nil must be a list of all privileges
    case $ensure {
      present: {
        if $plain_password {
            $identified = "IDENTIFIED BY '${password}'"
        } else {
            $identified = "IDENTIFIED BY PASSWORD '${password}'"
        }

        if $grant {
          $grant_opt = "WITH GRANT OPTION"
        } else {
          $grant_opt = ""
        }

        if $privileges {
          $privileges_str = inline_template("<%= privileges.join(', ') %>")
        } else {
          $privileges_str = "ALL PRIVILEGES"
        }

        exec { "MySQL_create_user_${name}":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"GRANT ${privileges_str} ON ${database}.* TO '${name}'@'${host}' ${identified} ${grant_opt};\";",
          unless  => "mysql --defaults-file=/etc/mysql/debian.cnf --batch --execute=\"SELECT Password FROM mysql.user WHERE User='${name}' AND Host='${host}';\" | grep -q ${password}",
        }

        if $database != "*" {
          $requirements = [Class["mysql::install"], Mysql::Functions::Database["${database}"]]
        } else {
          $requirements = Class["mysql::install"]
        }

        Exec["MySQL_create_user_${name}"] {require +> $requirements}
      }

      absent: {
        exec { "MySQL_drop_user_${name}":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"DROP USER '${name}'@'${host}';\"",
          onlyif => "mysql --defaults-file=/etc/mysql/debian.cnf --batch --execute=\"SELECT User FROM mysql.user WHERE User='${name}' AND Host='${host}';\" | grep -q ${name}"
        }

        if $require {
          Exec["MySQL_drop_user_${name}"] {
            require +> Class["mysql::install"]
          }
        }
      }
    }
  }

  define grant ($ensure="present", $database, $host="localhost", $privileges)
  {
    $privileges_str = inline_template("<%= privileges.join(', ') %>")
    case $ensure {
      present: {
        exec {"grant_privileges_for_${name}_on_${database}":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"GRANT ${privileges_str} ON ${database}.* TO '${name}'@'${host}';\"",
          unless => "mysql --defaults-file=/etc/mysql/debian.cnf --batch --execute=\"SHOW GRANTS FOR '${name}'@'${host}';\" | grep -q ${privileges_str}"
        }
      }
      absent: {
        exec {"revoke_privileges_for_${name}_on_${database}":
          command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf --execute=\"REVOKE ${privileges_str} ON ${database}.* TO '${name}'@'${host}';\"",
          only_if => "mysql --defaults-file=/etc/mysql/debian.cnf --batch --execute=\"SHOW GRANTS FOR '${name}'@'${host}';\" | grep -q ${privileges_str}"
        }
      }
    }
  }

  define conf ( $config = $name, $ensure ) 
  {
    case $ensure {
      present: {
        file { "/etc/mysql/conf.d/${name}.cnf":
          ensure  => present,
          owner   => root,
          group   => root,
          mode  => 600,
          content => template ("mysql/${name}.cnf.erb"),
          require => Class["config"],
        }
      }
      
      absent: {
        file { "/etc/mysql/conf.d/${name}.cnf":
          ensure  => absent,
          require => Class["config"],
        }
      }
    }
  }
}
