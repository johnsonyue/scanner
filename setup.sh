cwd=""

cd $cwd

apt-get update
apt-get upgrade

#libbgpdump
apt-get install libbz2-dev zlib1g-dev
wget http://www.ris.ripe.net/source/bgpdump/libbgpdump-1.4.99.15.tgz
tar zxvf libbgpdump-1.4.99.15.tgz
cd libbgpdump-1.4.99.15/
make
make install
cd ../

#scamper
wget https://www.caida.org/tools/measurement/scamper/code/scamper-cvs-20141211e.tar.gz
tar zxvf scamper-cvs-20141211e.tar.gz
cd scamper-cvs-20141211e/
./configure
make
make install
cd ../
