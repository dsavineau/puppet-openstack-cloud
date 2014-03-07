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
# Telemetry server nodes api
#

class cloud::telemetry::server::api(
  $ks_keystone_internal_host      = $os_params::ks_keystone_internal_host,
  $ks_keystone_internal_proto     = $os_params::ks_keystone_internal_proto,
  $ks_ceilometer_internal_port    = $os_params::ks_ceilometer_internal_port,
  $ks_ceilometer_password         = $os_params::ks_ceilometer_password,
  $api_eth                        = $os_params::api_eth,
){

  include 'cloud::telemetry'

# Install Ceilometer-notifier
  class { 'ceilometer::alarm::notifier': }

# Install Ceilometer-API
  class { 'ceilometer::api':
    keystone_password => $ks_ceilometer_password,
    keystone_host     => $ks_keystone_internal_host,
    keystone_protocol => $ks_keystone_internal_proto,
    host              => $api_eth
  }

  @@haproxy::balancermember{"${::fqdn}-ceilometer_api":
    listening_service => 'ceilometer_api_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_ceilometer_internal_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

}
