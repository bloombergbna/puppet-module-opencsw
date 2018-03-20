# Class: opencsw
#
# Manages OpenCSW and pkgutil on Solaris systems
#
class opencsw (
  $package_source  = 'http://get.opencsw.org/now',
  $mirror          = 'http://mirror.opencsw.org/opencsw/stable',
  Boolean $use_gpg = false,
  Boolean $use_md5 = false,
  Optional[String] $proxy_server   = undef,
  Enum['http','https'] $proxy_type = 'http',
  Boolean $noncsw  = false,
  $catalog_update  = 14,
) {

  if $proxy_server {
    $wgetopts = "-nv --execute ${proxy_type}_proxy=${proxy_server}"
  } else {
    $wgetopts = '-nv'
  }

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  archive { 'CSWpkgutil.pkg':
    path         => '/var/sadm/pkg/CSWpkgutil.pkg',
    source       => $package_source,
    proxy_server => $proxy_server,
    proxy_type   => $proxy_type,
    cleanup      => false,
    before       => Package['CSWpkgutil'],
  }

  file { '/var/sadm/install/admin/opencsw-noask':
    ensure => 'file',
    source => 'puppet:///modules/opencsw/opencsw-noask',
    before => Package['CSWpkgutil'],
  }

  package { 'CSWpkgutil':
    ensure    => 'latest',
    provider  => 'sun',
    source    => '/var/sadm/pkg/CSWpkgutil.pkg',
    adminfile => '/var/sadm/install/admin/opencsw-noask',
  }

  # Template uses:
  #   - $mirror (can be array)
  #   - $use_gpg
  #   - $use_md5
  #   - $noncsw (to use non CSW sources)
  #   - $catalog_update
  #   - $wgetopts
  file { '/etc/opt/csw/pkgutil.conf':
    ensure  => 'file',
    content => template("${module_name}/pkgutil.conf.erb"),
    require => Package['CSWpkgutil'],
  }

  file { '/opt/csw/etc/pkgutil.conf':
    ensure  => 'symlink',
    target  => '/etc/opt/csw/pkgutil.conf',
    require => Package['CSWpkgutil'],
  }

  opencsw::catalog { $mirror: }
}
