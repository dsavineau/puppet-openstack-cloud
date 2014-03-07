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
# Unit tests for cloud::image class
#
require 'spec_helper'

describe 'cloud::image::api' do

  let :params do
    { :glance_db_host                   => '10.0.0.1',
      :glance_db_user                   => 'glance',
      :glance_db_password               => 'secrete',
      :ks_keystone_internal_host        => '10.0.0.1',
      :openstack_vip                    => '10.0.0.42',
      :ks_glance_api_internal_port      => '9292',
      :ks_glance_registry_internal_port => '9191',
      :ks_glance_password               => 'secrete',
      :glance_rbd_user                  => 'glance',
      :glance_rbd_pool                  => 'images',
      :debug                            => true,
      :verbose                          => true,
      :use_syslog                       => true,
      :log_facility                     => 'LOG_LOCAL0',
      :api_eth                          => '10.0.0.1'
    }
  end

  shared_examples_for 'openstack image' do

    it 'configure glance-api' do
      should contain_class('glance::api').with(
        :sql_connection        => 'mysql://glance:secrete@10.0.0.1/glance',
        :keystone_password     => 'secrete',
        :registry_host         => '10.0.0.42',
        :registry_port         => '9191',
        :keystone_tenant       => 'services',
        :keystone_user         => 'glance',
        :show_image_direct_url => true,
        :verbose               => true,
        :debug                 => true,
        :auth_host             => '10.0.0.1',
        :log_facility          => 'LOG_LOCAL0',
        :bind_host             => '10.0.0.1',
        :bind_port             => '9292',
        :use_syslog            => true,
        :log_dir               => false,
        :log_file              => false
      )
    end

    it 'configure glance rbd backend' do
      should contain_class('glance::backend::rbd').with(
          :rbd_store_pool => 'images',
          :rbd_store_user => 'glance'
        )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'openstack image'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'openstack image'
  end

end
