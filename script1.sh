#----------------------------------NTP Service---------------------------------- 

apt-get install chrony

# Edit /etc/chrony/chrony.conf file

rm /etc/chrony/chrony.conf
cp files/chrony.conf /etc/chrony/

service chrony restart

chronyc sources

echo "###################################################################"
echo "#################### NTP Completed ################################"
echo "###################################################################"

#-----------------------------Openstack Repositories ---------------------------
sudo apt-get install software-properties-common
add-apt-repository cloud-archive:mitaka


echo "###################################################################"
echo "#################### Openstack Repositories Completed #############"
echo "###################################################################"

sudo apt-get update && apt-get dist-upgrade

echo "###################################################################"
echo "#################### Update and Upgrade Complete ##################"
echo "###################################################################"

