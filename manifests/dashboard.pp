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
# == Class: cloud::dashboard
#
# Installs the OpenStack Dashboard (Horizon)
#
# === Parameters:
#
# [*ks_keystone_internal_host*]
#   (optional) Internal address for endpoint.
#   Default value in params
#
# [*secret_key*]
#   (optional) Secret key. This is used by Django to provide cryptographic
#   signing, and should be set to a unique, unpredictable value.
#   Default value in params
#
# [*horizon_port*]
#   (optional) Port used to connect to OpenStack Dashboard
#   Default value in params
#
# [*internal_netif_ip*]
#   (optional) Which interface we bind the Horizon server.
#   Default value in params
#
# [*listen_ssl*]
#   (optional) Enable SSL on OpenStack Dashboard vhost
#   It requires SSL files (keys and certificates)
#   Defaults false
#
# [*keystone_proto*]
#   (optional) Protocol (http or https) of keystone endpoint.
#   Defaults to params.
#
# [*keystone_host*]
#   (optional) IP / Host of keystone endpoint.
#   Defaults to params.
#
# [*keystone_port*]
#   (optional) TCP port of keystone endpoint.
#   Defaults to params.
#
# [*debug*]
#   (optional) Enable debug or not.
#   Defaults to params.
#

class cloud::dashboard(
  $ks_keystone_internal_host = $os_params::ks_keystone_internal_host,
  $secret_key                = $os_params::secret_key,
  $horizon_port              = $os_params::horizon_port,
  $internal_netif_ip         = $os_params::internal_netif_ip,
  $listen_ssl                = false,
  $keystone_host             = $os_params::ks_keystone_internal_host,
  $keystone_proto            = $os_params::ks_keystone_internal_proto,
  $keystone_port             = $os_params::ks_keystone_internal_port,
  $debug                     = $os_params::debug
) {

  # We build the param needed for horizon class
  $keystone_url = "${keystone_proto}://${keystone_host}:${keystone_port}/v2.0"

  class {'horizon':
    secret_key          => $secret_key,
    can_set_mount_point => 'False',
    # fqdn can can be ambiguous since we use reverse DNS here,
    # e.g: 127.0.0.1 instead of a public IP address.
    # We force $internal_netif_ip to avoid this situation
    fqdn                => $internal_netif_ip,
    bind_address        => $internal_netif_ip,
    swift               => true,
    keystone_url        => $keystone_url,
    django_debug        => $debug

  }

  if ($::osfamily == 'Debian') {
    # TODO(Gonéri): HACK to ensure Horizon can cache its files
    $horizon_var_dir = ['/var/lib/openstack-dashboard/static/js','/var/lib/openstack-dashboard/static/css']
    file {$horizon_var_dir:
      ensure => directory,
      owner  => 'horizon',
      group  => 'horizon',
    }
  }

  @@haproxy::balancermember{"${::fqdn}-horizon":
    listening_service => 'horizon_cluster',
    server_names      => $::hostname,
    ipaddresses       => $internal_netif_ip,
    ports             => $horizon_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }


}
