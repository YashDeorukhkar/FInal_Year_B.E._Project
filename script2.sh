
#-----------------------Installing Python Openstack client----------------------

apt-get install python-openstackclient

echo "###################################################################"
echo "########### Python Openstack Client Download Complete #############"
echo "###################################################################"

#--------------------Mysql-------------------------

apt-get install mysql-server 

cd /etc/mysql/conf.d
cp /files/openstack.cnf /etc/mysql/conf.d/
service mysql restart
mysql_secure_installation

echo "###################################################################"
echo "#################### MYSQL Complete ###############################"
echo "###################################################################"

#----------------------------Data Base Population--------------------

# Creating the database for keystone,galnce, nova, neutron & cinder

sh files/databasePopulation.sh $Controller_Ip
echo "Database Populated"

echo "###################################################################"
echo "#################### Database Populated ###########################"
echo "###################################################################"

#--------------------------------RabbitMQ----------------------------


apt-get install rabbitmq-server

rabbitmqctl add_user openstack rabbit
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

service rabbitmq-server restart

echo "###################################################################"
echo "#################### RabbitMQ #####################################"
echo "###################################################################"

#--------------------------Memcached Installation------------------------

apt-get install memcached python-memcache

rm /etc/memcached.conf 
cp files/memcached.conf /etc/

service memcached restart

echo "###################################################################"
echo "################ Memcached Installation Complete ##################"
echo "###################################################################"

#--------------------Keystone-------------------------

echo "manual" > /etc/init/keystone.override
apt-get install keystone apache2 libapache2-mod-wsgi

rm /etc/keystone/keystone.conf
cp files/keystone.conf /etc/keystone/

su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

echo "################ Apache HTTP Server #####################"

rm /etc/apache2/apache2.conf
cp files/apache2.conf /etc/apache2

cp files/wsgi-keystone.conf /etc/apache2/sites-available/
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

service apache2 restart
rm -f /var/lib/keystone/keystone.db

echo "################ Service Entity and API Endpoints ##################"

export OS_TOKEN=hex_value
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack endpoint create --region RegionOne identity public http://controller:5000/v3

openstack endpoint create --region RegionOne identity internal http://controller:5000/v3

openstack endpoint create --region RegionOne identity admin http://controller:35357/v3

echo "################ Domain Creation ##################"

openstack domain create --description "Default Domain" default

echo "################ Project Creation ##################"

openstack project create --domain default --description "Admin Project" admin

openstack user create --domain default --password-prompt admin

openstack role create admin

openstack role add --project admin --user admin admin

openstack project create --domain default --description "Service Project" service

openstack project create --domain default --description "Demo Project" demo

openstack user create --domain default --password-prompt demo

openstack role create user

openstack role add --project demo --user demo user

echo "################ Verification ##################"

rm /etc/keystone/keystone-paste.ini
cp files/keystone-paste.ini /etc/keystone/
unset OS_TOKEN OS_URL

openstack --os-auth-url http://controller:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue

openstack --os-auth-url http://controller:5000/v3 --os-project-domain-name default --os-user-domain-name default --       os-project-name demo --os-username demo token issue

cp files/admin-openrc.sh /
. admin-openrc
openstack token issue
service keystone start

echo "###################################################################"
echo "################ Keystone Installation Complete ##################"
echo "###################################################################"

#--------------------Glance-------------------------

. admin-openrc
openstack user create --domain default --password-prompt glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

apt-get install glance

sudo rm /etc/glance/glance-api.conf
sudo cp files/glance-api.conf /etc/glance/

sudo rm /etc/glance/glance-registry.conf
sudo cp files/glance-registry.conf /etc/glance/

su -s /bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

#-------Verify operation------

. admin-openrc

wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack image list

echo "###################################################################"
echo "################ Glance Installation Complete #####################"
echo "###################################################################"

read -p "Do you wish to continue ?" yn

#--------------------Nova-------------------------

. admin-openrc

openstack user create --domain default --password-prompt nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s

apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
  
rm /etc/nova/nova.conf
cp files/nova.conf /etc/nova/

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova

sleep 5

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

. admin-openrc

openstack compute service list

sleep 5

echo "###################################################################"
echo "################## Nova Installation Complete #####################"
echo "###################################################################"

#--------------------Neutron-------------------------


sleep 5

. admin-openrc
openstack user create --domain default --password-prompt neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

apt-get install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent   neutron-metadata-agent

rm /etc/neutron/neutron.conf
cp files/neutron.conf /etc/neutron/

rm /etc/neutron/plugins/ml2/ml2_conf.ini
cp files/ml2_conf.ini /etc/neutron/plugins/ml2/

rm /etc/neutron/plugins/ml2/linuxbridge_agent.ini
cp files/linuxbridge-agent.ini /etc/neutron/plugins/ml2/

rm /etc/neutron/l3_agent.ini
cp files/l3_agent.ini /etc/neutron/

rm /etc/neutron/dhcp_agent.ini
cp files/dhcp_agent.ini /etc/neutron/

rm /etc/neutron/metadata_agent.ini
cp files/metadata_agent.ini /etc/neutron/	

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
 
service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

#-------------- Verification ------------------

. admin-openrc
neutron ext-list
neutron agent-list

echo "###################################################################"
echo "#################### Neutron Complete #############################"
echo "###################################################################"

#--------------------Horizon-------------------------

apt-get install openstack-dashboard

rm /etc/openstack-dashboard/local_settings.py
cp files/local_settings.py /etc/openstack-dashboard/

service apache2 reload

echo "###################################################################"
echo "#################### Horizon Complete #############################"
echo "###################################################################"
