#! /usr/bin/env bash

# Default Settings
INSTALL_DIR="/opt"

# Force IPv4
apt-get -o Acquire::ForceIPv4=true update

# Initialization
apt-get -y update
apt-get -y upgrade


# Build Tools
apt-get -y install build-essential # Essential for compiling source (includes GCC compiler, etc).

# Package Management
apt-get -y install python-software-properties # Provides the "add-apt-repository" command.

# Git
apt-get -y install git-core

# Unzip
apt-get -y install unzip

# Ant
apt-get -y install ant

# Java
add-apt-repository -y ppa:openjdk-r/ppa
apt-get -y update
apt-get -y install openjdk-8-jdk
echo '' >> /etc/bash.bashrc
echo 'export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")' >> /etc/bash.bashrc
source /etc/bash.bashrc

# ElasticSearch
cd $INSTALL_DIR
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.1.1.deb
dpkg -i elasticsearch-5.1.1.deb
rm -f elasticsearch-5.1.1.deb
sed -i.bak 's/#cluster.name: my-application/cluster.name: wisearch/g' /etc/elasticsearch/elasticsearch.yml
sed -i.bak 's/#node.name: node-1/node.name: wisearch/g' /etc/elasticsearch/elasticsearch.yml
sed -i.bak 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
sed -i.bak 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch
systemctl restart elasticsearch

# Kibana
cd $INSTALL_DIR
wget https://artifacts.elastic.co/downloads/kibana/kibana-5.1.1-amd64.deb
dpkg -i kibana-5.1.1-amd64.deb
rm -rf kibana-5.1.1-amd64.deb
sed -i.bak 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml
sed -i.bak 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml
systemctl daemon-reload
systemctl enable kibana
systemctl restart kibana

# Mongo
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
apt-get -y update
apt-get -y install mongodb
systemctl daemon-reload
systemctl enable mongodb
service mongodb start

# Apache Nutch
cd $INSTALL_DIR
wget http://apache.spd.co.il/nutch/2.3.1/apache-nutch-2.3.1-src.tar.gz
tar -zxvf apache-nutch-2.3.1-src.tar.gz
mv apache-nutch-2.3.1 nutch
rm -f apache-nutch-2.3.1-src.tar.gz
mkdir -p $INSTALL_DIR/nutch/seed/
touch $INSTALL_DIR/nutch/seed/urls.txt
echo "http://www.weizmann.ac.il/pages/" >> $INSTALL_DIR/nutch/seed/urls.txt
mkdir -p $INSTALL_DIR/nutch/scripts/
touch $INSTALL_DIR/nutch/scripts/cron.sh
chmod +x $INSTALL_DIR/nutch/scripts/cron.sh

# PATCH for working with ES 5.1.1
cd $INSTALL_DIR
git clone https://github.com/mdigiacomi/indexer-elastic.git
cp -a $INSTALL_DIR/indexer-elastic/ivy.xml $INSTALL_DIR/nutch/ivy/
echo '<dependency org="org.apache.gora" name="gora-mongodb" rev="0.6.1" conf="*->default" />' >> $INSTALL_DIR/nutch/ivy/ivy.yml
rm -rf $INSTALL_DIR/nutch/src/plugin/indexer-elastic/
cp -a $INSTALL_DIR/indexer-elastic/indexer-elastic $INSTALL_DIR/nutch/src/plugin/
cp -a $INSTALL_DIR/indexer-elastic/default.properties $INSTALL_DIR/nutch/

# Create cron script for indexing
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch inject file://$INSTALL_DIR/nutch/seed/" >> $INSTALL_DIR/nutch/scripts/cron.sh
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch generate -topN 20" >> $INSTALL_DIR/nutch/scripts/cron.sh
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch fetch -all" >> $INSTALL_DIR/nutch/scripts/cron.sh
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch parse -all" >> $INSTALL_DIR/nutch/scripts/cron.sh
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch updatedb -all" >> $INSTALL_DIR/nutch/scripts/cron.sh
echo "$INSTALL_DIR/nutch/runtime/local/bin/nutch index -all" >> $INSTALL_DIR/nutch/scripts/cron.sh

# Override files
cd $INSTALL_DIR
git clone https://github.com/rhayun/wisearch.git
cp -a $INSTALL_DIR/wisearch/gora.properties $INSTALL_DIR/nutch/conf/
cp -a $INSTALL_DIR/wisearch/nutch-site.xml $INSTALL_DIR/nutch/conf/
cp -a $INSTALL_DIR/wisearch/regex-urlfilter.txt $INSTALL_DIR/nutch/conf/
cp -a $INSTALL_DIR/wisearch/subcollections.xml $INSTALL_DIR/nutch/conf/
rm -rf $INSTALL_DIR/wisearch

# Build Nutch
cd $INSTALL_DIR/nutch
ant clean
ant runtime



