#!/bin/bash
env_dir=$(awk -F " *= *" '/env_dir/ {print $2}' config.ini)

cwd=`pwd`

mkdir -p $env_dir
cd $env_dir
tar zxvf $cwd/env_files.tar.gz
#apt-get update
#apt-get -y upgrade
apt-get install -y build-essential

#libbgpdump
apt-get install -y libbz2-dev zlib1g-dev
#wget http://www.ris.ripe.net/source/bgpdump/libbgpdump-1.4.99.15.tgz
tar zxvf libbgpdump-1.4.99.15.tgz
cd libbgpdump-1.4.99.15/
./configure
make
make install
cd ../

#scamper
#wget https://www.caida.org/tools/measurement/scamper/code/scamper-cvs-20141211e.tar.gz
tar zxvf scamper-cvs-20141211e.tar.gz
cd scamper-cvs-20141211e/
./configure
make
make install
cd ../

#iffinder
#wget http://www.caida.org/tools/measurement/iffinder/download/iffinder-1.38.tar.gz
tar zxvf iffinder-1.38.tar.gz
cd iffinder-1.38
./configure
make
cd ../

#midar-full(local).
#more reference at: http://www.caida.org/tools/measurement/midar/README.midar
apt-get install -y perl ruby ruby-dev

#wget http://www.caida.org/tools/measurement/mper/downloads/mper-0.4.1.tar.gz
tar zxvf mper-0.4.1.tar.gz
cd mper-0.4.1/
./configure
make
make install
cd ../

#wget http://www.caida.org/tools/measurement/rb-mperio/downloads/rb-mperio-0.3.3.gem
gem install rb-mperio-0.3.3.gem

#wget http://www.caida.org/tools/utilities/arkutil/downloads/arkutil-0.13.5.gem
gem install arkutil-0.13.5.gem

#wget http://www.caida.org/tools/measurement/midar/downloads/midar-0.6.0.tar.gz
tar zxvf midar-0.6.0.tar.gz
cd midar-0.6.0/
./configure
make
cd ../

#back to previous pwd.
cd $pwd
