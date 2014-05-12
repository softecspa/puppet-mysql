# == define mysql::config::runtime
#
# Set runtime variable
#
# === Params
#
# [*param_value*]
#   param to be set (default: discover from $name)
#
# [*value*]
#   valuet to be set, if ends with kKmMgG convert in bytes
#
# === Examples
#
define mysql::config::runtime (
  $param_name = '',
  $value,
) {

  $real_name = $param_name ? {
    ''      => regsubst($name,'-','_'),
    default => regsubst($param_name,'-','_'),
  }

  if $value =~ /[0-9]+(k|K|m|M|g|G)$/ {
    $real_value = to_bytes($value)
  } else {
    $real_value = $value
  }

  exec {"mysql-runtime-$real_name":
    command => "mysql -e \"SET GLOBAL $real_name = $real_value;\"",
    onlyif  => "test `mysql -e \"SHOW VARIABLES LIKE '$real_name'\\G;\" | grep Value | awk '{print \$2}'` != '$real_value'"
  }
}
