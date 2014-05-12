# = Define: mysql::monitoring::check_mysql_health
#
#   This define create a nrpe_check using check_mysql_healt as plugin and nrpe::check define
#
# == Parameters
#
# [*mysql_hostname*]
#   host where checks are made.
#
# [*mysql_port*]
#   host's port.
#
# [*mysql_user*]
#   database user used to make checks.
#
# [*mysql_password*]
#   user's password used to make checks
#
# [*check_mode*]
#   --mode params passed to check_mysql_healt plugin. If none is specified <name> will be used.
#
# [*warning*]
#   warning threshold to use to
#
# [*critical*]
#   critiacl threshold to use to
#
# == Examples
#
# 1) Push check threads-connected using without threshold.
#   mysql::monitoring::check_mysql_health { 'threads-connected':
#     mysql_hostname  =>'localhost'
#     mysql_port      => '3306',
#     mysql_user      => 'monitoring',
#     mysql_password  => 'xxxxxx',
#   }
#
# 2) push check threads-connected using customized threshold
#   $user_cheks = {
#     'threads-connected' => { 'warning'  => '10', 'critical' => '20' }
#   }
#
#   mysql::monitoring::check_mysql_health { 'threads-connected':
#     mysql_hostname   =>'localhost',
#     mysql_port       => '3306',
#     mysql_user       => 'monitoring',
#     mysql_password   => 'xxxxxx',
#     warning          => '10',
#     critical         => '20'
#   }
#
# == Author
#   Felice Pizzurro <felice.pizzurro@softecspa.it>
#
define mysql::monitoring::check_mysql_health (
  $mysql_hostname,
  $mysql_port,
  $mysql_user,
  $mysql_password,
  $check_mode     = '',
  $warning        = '',
  $critical       = ''
) {

  $warning_params = $warning ? {
    ''      => '',
    default => " --warning $warning",
  }

  $critical_params = $critical ? {
    ''      => '',
    default => " --critical $critical",
  }

  $checkmode = $check_mode ? {
    ''      => $name,
    default => $check_mode,
  }

  nrpe::check { $checkmode:
    contrib     => true,
    source      => 'puppet:///modules/mysql/check_mysql_health',
    binaryname  => 'check_mysql_health',
    checkname   => "mysql_${checkmode}",
    params      => "--hostname ${mysql_hostname} --port ${mysql_port} --username ${mysql_user} --password ${mysql_password} --mode ${checkmode}${warning_params}${critical_params}",
  }
}
