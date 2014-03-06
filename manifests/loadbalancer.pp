#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# HAproxy nodes
#
class cloud::loadbalancer(
  $swift_api                        = $os_params::swift,
  $ceilometer_api                   = true,
  $cinder_api                       = true,
  $glance_api                       = true,
  $glance_registry                  = true,
  $neutron_api                      = true,
  $heat_api                         = true,
  $heat_cfn_api                     = true,
  $heat_cloudwatch_api              = true,
  $nova_api                         = true,
  $ec2_api                          = true,
  $metadata_api                     = true,
  $keystone_api_admin               = true,
  $keystone_api                     = true,
  $horizon                          = true,
  $horizon_ssl                      = false,
  $spice                            = true,
  $haproxy_auth                     = $os_params::haproxy_auth,
  $keepalived_state                 = 'BACKUP',
  $keepalived_priority              = 50,
  $keepalived_public_interface      = $os_params::lb_public_netif,
  $keepalived_public_ipvs           = [$os_params::vip_public_ip],
  $keepalived_internal_interface    = $os_params::lb_internal_netif,
  $keepalived_internal_ipvs         = [$os_params::vip_internal_ip],
  $keepalived_localhost_ip          = $os_params::keepalived_localhost_ip,
  $ks_cinder_public_port            = $os_params::ks_cinder_public_port,
  $ks_ceilometer_public_port        = $os_params::ks_ceilometer_public_port,
  $ks_ec2_public_port               = $os_params::ks_ec2_public_port,
  $ks_glance_api_public_port        = $os_params::ks_glance_api_public_port,
  $ks_glance_registry_internal_port = $os_params::ks_glance_registry_internal_port,
  $ks_heat_public_port              = $os_params::ks_heat_public_port,
  $ks_heat_cfn_public_port          = $os_params::ks_heat_cfn_public_port,
  $ks_heat_cloudwatch_public_port   = $os_params::ks_heat_cloudwatch_public_port,
  $ks_keystone_admin_port           = $os_params::ks_keystone_admin_port,
  $ks_keystone_public_port          = $os_params::ks_keystone_public_port,
  $ks_metadata_public_port          = $os_params::ks_metadata_public_port,
  $ks_neutron_public_port           = $os_params::ks_neutron_public_port,
  $ks_nova_public_port              = $os_params::ks_nova_public_port,
  $ks_swift_public_port             = $os_params::ks_swift_public_port,
  $horizon_port                     = $os_params::horizon_port,
  $spice_port                       = $os_params::spice_port,
  $galera_ip                        = $os_params::galera_ip
){


  if $keepalived_public_interface != $keepalived_internal_interface and $keepalived_public_ipvs != $keepalived_internal_ipvs {
    $lb_bind_ip = unique(flatten([$keepalived_public_ipvs, $keepalived_internal_ipvs]))
    $create_internal = true
  } else {
    $create_internal = false
  }

  # Ensure Keepalived is started before HAproxy to avoid binding errors.
  class { 'keepalived': } ->
  class { 'haproxy': }

  keepalived::vrrp_script { 'haproxy':
    name_is_process => true
  }

  keepalived::instance { '1':
    interface     => $keepalived_public_interface,
    virtual_ips   => unique(split(join(flatten([$keepalived_public_ipvs, ['']]), " dev ${keepalived_public_interface},"), ',')),
    state         => $keepalived_state,
    track_script  => ['haproxy'],
    priority      => $keepalived_priority,
    notify_master => '"/etc/init.d/haproxy start"',
    notify_backup => '"/etc/init.d/haproxy stop"',
  }

  if $create_internal {
    keepalived::instance { '2':
      interface     => $keepalived_internal_interface,
      virtual_ips   => unique(split(join(flatten([$keepalived_internal_ipvs, ['']]), " dev ${keepalived_internal_interface},"), ',')),
      state         => $keepalived_state,
      track_script  => ['haproxy'],
      priority      => $keepalived_priority,
      notify_master => '"/etc/init.d/haproxy start"',
      notify_backup => '"/etc/init.d/haproxy stop"',
    }
  }

  file { '/etc/logrotate.d/haproxy':
    ensure  => file,
    source  => 'puppet:///modules/cloud/logrotate/haproxy',
    owner   => root,
    group   => root,
    mode    => '0644';
  }

  haproxy::listen { 'monitor':
    ipaddress => $lb_bind_ip,
    ports     => '9300',
    options   => {
      'mode'        => 'http',
      'monitor-uri' => '/status',
      'stats'       => ['enable','uri     /admin','realm   Haproxy\ Statistics',"auth    ${haproxy_auth}", 'refresh 5s' ],
      ''            => template('cloud/loadbalancer/monitor.erb'),
    }
  }

  if $keystone_api {
    cloud::loadbalancer::listen_http {
      'keystone_api_cluster':
        ports     => $ks_keystone_public_port,
        listen_ip => $lb_bind_ip;
      'keystone_api_admin_cluster':
        ports     => $ks_keystone_admin_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $swift_api {
    cloud::loadbalancer::listen_http{
      'swift_api_cluster':
        ports     => $ks_swift_public_port,
        httpchk   => 'httpchk /healthcheck',
        listen_ip => $lb_bind_ip;
    }
  }
  if $nova_api {
    cloud::loadbalancer::listen_http{
      'nova_api_cluster':
        ports     => $ks_nova_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $ec2_api {
    cloud::loadbalancer::listen_http{
      'ec2_api_cluster':
        ports     => $ks_ec2_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $metadata_api {
    cloud::loadbalancer::listen_http{
      'metadata_api_cluster':
        ports     => $ks_metadata_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $spice {
    cloud::loadbalancer::listen_http{
      'spice_cluster':
        ports     => $spice_port,
        listen_ip => $lb_bind_ip,
        httpchk   => 'httpchk GET /';
    }
  }
  if $glance_api {
    cloud::loadbalancer::listen_http{
      'glance_api_cluster':
        ports     => $ks_glance_api_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $glance_registry {
    cloud::loadbalancer::listen_http{
      'glance_registry_cluster':
        ports     => $ks_glance_registry_internal_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $neutron_api {
    cloud::loadbalancer::listen_http{
      'neutron_api_cluster':
        ports     => $ks_neutron_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $cinder_api {
    cloud::loadbalancer::listen_http{
      'cinder_api_cluster':
        ports     => $ks_cinder_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $ceilometer_api {
    cloud::loadbalancer::listen_http{
      'ceilometer_api_cluster':
        ports     => $ks_ceilometer_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $heat_api {
    cloud::loadbalancer::listen_http{
      'heat_api_cluster':
        ports     => $ks_heat_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $heat_cfn_api {
    cloud::loadbalancer::listen_http{
      'heat_api_cfn_cluster':
        ports     => $ks_heat_cfn_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $heat_cloudwatch_api {
    cloud::loadbalancer::listen_http{
      'heat_api_cloudwatch_cluster':
        ports     => $ks_heat_cloudwatch_public_port,
        listen_ip => $lb_bind_ip;
    }
  }
  if $horizon {
    if $horizon_ssl {
      cloud::loadbalancer::listen_https{
        'horizon_cluster':
          ports     => $horizon_port,
          listen_ip => $vip_public_ip;
      }
    } else {
      cloud::loadbalancer::listen_http{
        'horizon_cluster':
          ports     => $horizon_port,
          listen_ip => $vip_public_ip;
      }
    }
  }

  haproxy::listen { 'galera_cluster':
    ipaddress          => $galera_ip,
    ports              => 3306,
    options            => {
      'mode'           => 'tcp',
      'balance'        => 'roundrobin',
      'option'         => ['tcpka', 'tcplog', 'httpchk'], #httpchk mandatory expect 200 on port 9000
      'timeout client' => '400s',
      'timeout server' => '400s',
    }
  }

}
