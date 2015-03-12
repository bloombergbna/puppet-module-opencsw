define opencsw::catalog (
  $mirror = $title
){

  $mangled = regsubst(regsubst($mirror, '(^.*//)', ''), '/', '_', 'G')
  $catalog = "catalog.${mangled}_${::hardwareisa}_${::kernelrelease}"
  exec { "pkgutil-update-${catalog}":
    command => '/opt/csw/bin/pkgutil -U',
    creates => "/var/opt/csw/pkgutil/${catalog}",
    require => File['/etc/opt/csw/pkgutil.conf'],
  }
}