# Patch Manager Manual Installation For EzyAdmin Platform

Patch Manager for manual installation

## Compatible

- **Linux operating systems**, such as RedHat 5-8, CentOS 5-8, CloudLinux, Fedora and even virtual software environments like VMWare and Xen.
- Control Panel : cPanel/WHM and DirectAdmin
- CloudLinux
- 3rd Party Installation : CPAN Modules(Perl), PEAR Packages(PHP)

## Installation

### Installation of Patch Manager dependencies

  ```bash
    yum install -y wget curl;
  ```

### Install Patch Manager

  ```bash
    mkdir -p /usr/local/ezyadmin
    cd /usr/local/ezyadmin
    wget https://github.com/ezyadmin/connector_patch_manager/archive/latest.tar.gz
    tar -xzf connector_patch_manager.tar.gz
    cd connector_patch_manager
    chmod 755 install/install.sh
    ./install/install.sh
  ```

#### For linux operating systems

  ```bash
    ezinstall_patch_mgr --linux
  ```

#### For cPanel/WHM

  ```bash
    ezinstall_patch_mgr --cpanel
  ```

#### For Direct Admin

  ```bash
    ezinstall_patch_mgr --da
  ```

#### For CloudLinux

  ```bash
    ezinstall_patch_mgr --cloudLinux
  ```

## Configuration
  
## Testing
  