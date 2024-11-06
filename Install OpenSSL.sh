sudo apt-get -y install libssl-dev
sudo apt-get install openssl

sudo apt update
sudo apt install build-essential checkinstall zlib1g-dev -y
yum group install 'Development Tools'
yum install perl-core zlib-devel -y

cd /usr/local/src/
wget https://www.openssl.org/source/openssl-1.0.2o.tar.gz
tar -xf openssl-1.0.2o.tar.gz
cd openssl-1.0.2o
openssl version -a
cd /usr/local/src/openssl-1.0.2o
./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
make
make test
make install






https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux/






