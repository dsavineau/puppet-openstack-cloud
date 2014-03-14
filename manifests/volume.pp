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
#
# == Class: cloud::volume
#
# Common class for volume nodes
#
# === Parameters:
#
# [*cinder_db_host*]
#   (optional) Cinder database host
#   Default value in params
#
# [*cinder_db_user*]
#   (optional) Cinder database user
#   Default value in params
#
# [*cinder_db_password*]
#   (optional) Cinder database password
#   Default value in params
#
# [*rabbit_hosts*]
#   (optional) List of RabbitMQ servers. Should be an array.
#   Default value in params
#
# [*rabbit_password*]
#   (optional) Password to connect to cinder queues.
#   Default value in params
#
# [*ks_keystone_internal_host*]
#   (optional) Keystone host (authentication)
#   Default value in params
#
# [*ks_cinder_password*]
#   (optional) Keystone password for cinder user.
#   Default value in params
#
# [*verbose*]
#   (optional) Set log output to verbose output
#   Default value in params
#
# [*debug*]
#   (optional) Set log output to debug output
#   Default value in params
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults value in params
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults value in params
#
class cloud::volume(
  $cinder_db_host             = '127.0.0.1',
  $cinder_db_user             = 'cinder',
  $cinder_db_password         = 'cinderpassword',
  $rabbit_hosts               = ['127.0.0.1:5672'],
  $rabbit_password            = 'rabbitpassword',
  $ks_keystone_internal_host  = '127.0.0.1',
  $ks_cinder_password         = 'cinderpassword',
  $verbose                    = true,
  $debug                      = true,
  $log_facility               = 'LOG_LOCAL0',
  $use_syslog                 = true
) {

  # Disable twice logging if syslog is enabled
  if $use_syslog {
    $log_dir = false
  } else {
    $log_dir = '/var/log/cinder'
  }

  $encoded_user = uriescape($cinder_db_user)
  $encoded_password = uriescape($cinder_db_password)


  class { 'cinder':
    sql_connection      => "mysql://${encoded_user}:${encoded_password}@${cinder_db_host}/cinder?charset=utf8",
    rabbit_userid       => 'cinder',
    rabbit_hosts        => $rabbit_hosts,
    rabbit_password     => $rabbit_password,
    rabbit_virtual_host => '/',
    verbose             => $verbose,
    debug               => $debug,
    log_dir             => $log_dir,
    log_facility        => $log_facility,
    use_syslog          => $use_syslog
  }

  class { 'cinder::ceilometer': }

  # Note(EmilienM):
  # We check if DB tables are created, if not we populate Cinder DB.
  # It's a hack to fit with our setup where we run MySQL/Galera
  # TODO(Gonéri)
  # We have to do this only on the primary node of the galera cluster to avoid race condition
  # https://github.com/enovance/puppet-cloud/issues/156
  exec {'cinder_db_sync':
    command => '/usr/bin/cinder-manage db sync',
    unless  => "/usr/bin/mysql cinder -h ${cinder_db_host} -u ${encoded_user} -p${encoded_password} -e \"show tables\" | /bin/grep Tables"
  }

}
