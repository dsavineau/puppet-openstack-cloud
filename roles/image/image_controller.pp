#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Authors: Mehdi Abaakouk <mehdi.abaakouk@enovance.com>
#          Emilien Macchi <emilien.macchi@enovance.com>
#          Francois Charlier <francois.charlier@enovance.com>
#          Sebastien Badia <sebastien.badia@enovance.com>
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
# Image controller
#
# Class:: os_image_controller
#

class os_image_controller {
  $encoded_glance_user = uriescape($os_params::glance_db_user)
  $encoded_glance_password = uriescape($os_params::glance_db_password)

  class { ['glance::api', 'glance::registry']:
    sql_connection            => "mysql://${encoded_glance_user}:${encoded_glance_password}@${os_params::glance_db_host}/glance",
    verbose                   => false,
    debug                     => false,
    auth_host                 => $os_params::ks_keystone_internal_host,
    keystone_password         => $os_params::ks_glance_password,
    keystone_tenant           => 'services',
    keystone_user             => 'glance',
  }

  glance_api_config{
    'DEFAULT/syslog_log_facility':               value => 'LOG_LOCAL0';
    'DEFAULT/use_syslog':                        value => 'yes';
    'DEFAULT/idle_timeout':                      value => '60';
  }

  glance_registry_config{
    'DEFAULT/syslog_log_facility':               value => 'LOG_LOCAL0';
    'DEFAULT/use_syslog':                        value => 'yes';
    'DEFAULT/idle_timeout':                      value => '60';
  }

  class { 'glance::notify::rabbitmq':
    rabbit_password => $os_params::rabbit_password,
    rabbit_userid   => 'glance',
    rabbit_host     => $os_params::rabbit_hosts[0],
  }

} # Class:: os_role_glance