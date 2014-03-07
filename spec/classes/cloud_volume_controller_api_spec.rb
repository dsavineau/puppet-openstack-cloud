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
# Unit tests for cloud::volume::controller class
#

require 'spec_helper'

describe 'cloud::volume::controller::api' do

  shared_examples_for 'openstack volume controller' do

    let :params do
      { :ks_cinder_password          => 'secrete',
        :ks_cinder_internal_port     => '8776',
        :ks_keystone_internal_host   => '10.0.0.1',
        :api_eth                     => '10.0.0.1' }
    end

    it 'configure cinder api' do
      should contain_class('cinder::api').with(
          :keystone_password  => 'secrete',
          :keystone_auth_host => '10.0.0.1',
          :bind_host          => '10.0.0.1'
        )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'openstack volume controller'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'openstack volume controller'
  end

end
