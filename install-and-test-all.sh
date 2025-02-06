#!/bin/bash

# Check the Linux distribution and install missing dependencies
LSB=$(cat /etc/lsb-release 2>/dev/null)
if [[ "${LSB}" =~ [Uu]buntu ]]; then
  INSTALL_CMD="sudo apt install astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml git pkg-config wget || exit 1"
elif [[ "${LSB}" =~ [Aa]rch ]]; then
  INSTALL_CMD="sudo pacman -S --needed astyle cmake gcc ninja openssl lib32-openssl python-pytest python-pytest-xdist unzip libxslt doxygen graphviz python-yaml git pkgconf wget || exit 1"
elif [[ "${LSB}" =~ [Gg]entoo ]]; then
  INSTALL_CMD="sudo emerge --selective --ask net-misc/wget dev-util/astyle dev-build/cmake sys-devel/gcc dev-build/ninja dev-libs/openssl dev-python/pytest app-arch/unzip dev-libs/libxslt app-text/doxygen dev-python/graphviz dev-python/pyyaml dev-vcs/git dev-util/pkgconf || exit 1"
else
  echo "Unsupported OS. Exiting."
  exit 1
fi

#Download working version of official golang
# TODO: maybe we could add this tar.gz file to our repo as a requirement
wget https://go.dev/dl/go1.22.12.linux-amd64.tar.gz

sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.12.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >>  ~/.profile
echo "export PATH=$PATH:/usr/local/go/bin" >>  ~/.bashrc

GO_STD_DIR=$PWD

# Install Liboqs
  cd ../
  git clone https://github.com/open-quantum-safe/liboqs.git 
  cd liboqs 
  mkdir -p build && cd build
  cmake -GNinja -DBUILD_SHARED_LIBS=ON .. 
  sudo ninja 
  sudo ninja install 
  cd ../..


# Install Liboqs-go
  git clone https://github.com/open-quantum-safe/liboqs-go.git
  export LIBOQS_GO_DIR=$(pwd)/liboqs-go


# Set environment variables
echo -e "Setting environment variables..."
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$LIBOQS_GO_DIR/.config

{
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib"
  echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$LIBOQS_GO_DIR/.config"
} >> ~/.profile
{
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib"
  echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$LIBOQS_GO_DIR/.config"
} >> ~/.bashrc


go get github.com/open-quantum-safe/liboqs-go@latest


cd ${GO_STD_DIR}/src
./make.bash



#overwrites system's go version to our go version
export PATH=${GO_STD_DIR}/bin:$PATH
echo "export PATH=${GO_STD_DIR}/bin:\$PATH" | tee -a ~/.profile ~/.bashrc


#refresh bashrc
source ~/.bashrc


# Ask for test duration
read -p "How many seconds do you want to run the tests? (default is 3): " TEST_DURATION
TEST_DURATION=${TEST_DURATION:-3}

if ! [[ "$TEST_DURATION" =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please enter a positive integer for the test duration. Exiting."; exit 1;
fi

# Run the tests
echo "Running tests for $TEST_DURATION seconds..."
go test -v ./src/crypto/hybrid -duration=${TEST_DURATION}s || {
  echo "Failed to run the tests. Exiting."; exit 1;
}

echo "Tests completed."
