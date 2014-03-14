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
# Network L3 node
#

class cloud::network::l3(
  $external_int = 'eth0',
  $debug        = true,
) {

  include 'cloud::network'

  class { 'neutron::agents::l3':
    debug                        => $debug,
  } ->
  vs_bridge{'br-ex':
    external_ids => 'bridge-id=br-ex',
  } ->
  vs_port{$external_int:
    ensure => present,
    bridge => 'br-ex'
  }

  class { 'neutron::agents::metering':
    debug => $debug,
  }

}
