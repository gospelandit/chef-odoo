#
# Cookbook:: odoo
# Recipe:: web
#
# Copyright:: 2016, Joel Handwell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'nodejs::nodejs_from_binary'

apt_repository 'yarn' do
  uri 'https://dl.yarnpkg.com/debian/'
  distribution 'stable'
  components ['main']
  key 'https://dl.yarnpkg.com/debian/pubkey.gpg'
end

package 'yarn'

execute 'yarn global add less --prefix /usr/local' do
  creates  '/usr/local/bin/lessc'
end

python_runtime '2.7.12'

rq_txt = '/opt/odoo/requirements.txt'

ark 'odoo' do
  path '/opt'
  url 'https://nightly.odoo.com/10.0/nightly/src/odoo_10.0.latest.tar.gz'
  action :put
  owner 'odoo'
  group 'odoo'
  creates rq_txt
  only_if { node['odoo']['install_method'] == 'nightly' }
end

git 'odoo' do
  destination '/opt/odoo'
  repository 'https://github.com/odoo/odoo.git'
  revision '10.0'
  depth 1
  only_if { node['odoo']['install_method'] == 'git' }
end

execute 'chown -R odoo:odoo /opt/odoo' do
  only_if { node['odoo']['install_method'] == 'git' }
  not_if "stat -c \"%U %G\" #{rq_txt} | grep 'odoo odoo'"
end

%w[postgresql-server-dev-all libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev].each do |name|
  package name
end

pip_requirements rq_txt

directory node['odoo']['config']['addon_path'] do
  recursive true
end

bin_file = '/usr/local/bin/odoo'

execute 'python setup.py install' do
  cwd '/opt/odoo'
  creates bin_file
end

conf_path = '/etc/odoo'
conf_file_name = 'odoo.conf'

directory conf_path

template "#{conf_path}/#{conf_file_name}" do
  source 'odoo.conf.erb'
  owner 'odoo'
  group 'odoo'
  mode 00640
end

log_path = '/var/log/odoo'

directory log_path do
  owner 'odoo'
  group 'odoo'
end

systemd_path = '/etc/systemd/system'

directory systemd_path

file "#{systemd_path}/odoo.service" do
  content <<-SYSTEMD
[Unit]
Description=Odoo Open Source ERP and CRM
After=network.target

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=#{bin_file} --config #{conf_path}/#{conf_file_name} --logfile #{log_path}/odoo-server.log
SYSTEMD
  mode 00644
end

service 'odoo' do
  action [ :enable, :start ]
end
