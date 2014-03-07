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
# Volume controller scheduler
#

class cloud::volume::controller::scheduler(
  $ks_glance_internal_host     = $os_params::ks_glance_internal_host,
  $ks_glance_api_internal_port = $os_params::ks_glance_api_internal_port,
  # TODO(EmilienM) Disabled for now: http://git.io/kfTmcA
  # $backup_ceph_pool          = $os_params::cinder_rbd_backup_pool,
  # $backup_ceph_user          = $os_params::cinder_rbd_backup_user
) {

  include 'cloud::volume'

  class { 'cinder::scheduler': }

  class { 'cinder::backup': }

  # TODO(EmilienM) Disabled for now: http://git.io/kfTmcA
  # class { 'cinder::backup::ceph':
  #   backup_ceph_user => $backup_ceph_user,
  #   backup_ceph_pool => $backup_ceph_pool
  # }

  # TODO(EmilienM) Disabled for now: http://git.io/uM5sgg
  # class { 'cinder::glance':
  #   glance_api_servers     => $ks_glance_internal_host,
  #   glance_request_timeout => '10'
  # }
  # Replaced by:
  cinder_config {
    'DEFAULT/glance_api_servers':     value => "${ks_glance_internal_host}:${ks_glance_api_internal_port}";
    'DEFAULT/glance_request_timeout': value => '10';
  }

}
