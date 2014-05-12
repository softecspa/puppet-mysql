define mysql::config::param (
  $param_name= '',
  $value,
  $filename,
) {

  $real_name = $param_name? {
    ''      => $name,
    default => $param_name,
  }

  if $value != false {
    concat_fragment {"${filename}+002-${name}.tmp":
      content => template('mysql/param.erb')
    }
  }
}
