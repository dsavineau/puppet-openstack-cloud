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
# Telemetry server nodes
#

class cloud::telemetry::server(
  $ks_keystone_internal_host      = $os_params::ks_keystone_internal_host,
  $ks_keystone_internal_proto     = $os_params::ks_keystone_internal_proto,
  $ks_ceilometer_internal_port    = $os_params::ks_ceilometer_internal_port,
  $ks_ceilometer_password         = $os_params::ks_ceilometer_password,
  $ceilometer_database_connection = $os_params::ceilometer_database_connection,
  $internal_netif_ip              = $os_params::internal_netif_ip,
){

  include 'cloud::telemetry'

  $db_conn = regsubst($ceilometer_database_connection, 'mongodb:\/\/(\.*)', '\2')
  exec {'check_mongodb' :
    command   => "/usr/bin/mongo ${db_conn}",
    logoutput => false,
    tries     => 60,
    try_sleep => 5,
    require   => Service['mongodb'],
  }

  # Install MongoDB database
  class { 'ceilometer::db':
    database_connection => $ceilometer_database_connection,
    require             => Exec['check_mongodb'],
  }

# Install Ceilometer-collector
  class { 'ceilometer::collector': }

# Install Ceilometer-evaluator
  class { 'ceilometer::alarm::evaluator': }

# Install Ceilometer-notifier
  class { 'ceilometer::alarm::notifier': }

# Install Ceilometer-API
  class { 'ceilometer::api':
    keystone_password => $ks_ceilometer_password,
    keystone_host     => $ks_keystone_internal_host,
    keystone_protocol => $ks_keystone_internal_proto,
    host              => $internal_netif_ip
  }

# Configure TTL for samples
# Purge datas older than one month
# Run the script once a day but with a random time to avoid
# issues with MongoDB access
  class { 'ceilometer::expirer':
    time_to_live => '2592000',
    minute       => '0',
    hour         => '0',
  }

  Cron <<| title == 'ceilometer-expirer' |>> { command => "sleep $((\$RANDOM % 86400)) && ${::ceilometer::params::expirer_command}" }

  @@haproxy::balancermember{"${::fqdn}-ceilometer_api":
    listening_service => 'ceilometer_api_cluster',
    server_names      => $::hostname,
    ipaddresses       => $internal_netif_ip,
    ports             => $ks_ceilometer_internal_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

}
