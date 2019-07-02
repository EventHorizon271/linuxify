#! /usr/bin/env bash

set -euo pipefail

check_os() {
    if ! [[ $OSTYPE =~ linux-gnu ]]; then
        echo "This is meant to be run on Linux only"
        exit 1
    fi
}

check_root() {
    if [[ $(whoami) == "root" ]]; then
        echo "This should not be run as root"
	    exit 1
    fi
}

change_passwords() {
    echo
    echo "Changing root password.."
    sudo passwd root
    echo
    echo "Changing password for $(whoami).."
    sudo passwd $(whoami)
    echo
}

add_sources() {
    echo 'deb http://ftp.debian.org/debian stretch-backports main' | sudo tee /etc/apt/sources.list.d/stretch-backports.list
}

update_os() {
    sudo apt-get update
    sudo apt-get -y full-upgrade
}

main_packages=(
    apt-file
    command-not-found
    zsh
    fonts-powerline
)

backport_packages=(
    tmux
)

all_packages=(
    $main_packages
    $backport_packages
)

install_oh-my-zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

install_vscode() {
    wget --quiet --output-document=./vscode.deb 'https://go.microsoft.com/fwlink/?LinkID=760868'
    sudo apt-get install -y ./vscode.deb
}

configure_git() {
    read -p "Email address: " email
    read -p "Full name: " full_name
    git config --global user.email $email
    git config --global user.name $full_name
    git config --global credential.helper cache
}

install_packages() {
    mkdir ~/tmp
    cd ~/tmp

    # Prerequisites
    sudo apt-get install -y apt-utils

    # Install packages found in main repository
    sudo apt-get install -y ${main_packages[@]}

    # Install packages found in backports repository
    sudo apt-get install -t stretch-backports -y ${backport_packages[@]}

    # Update packages
    sudo apt-file update
    sudo update-command-not-found

    # Install packages not found in repositories
    #install_oh-my-zsh
    install_vscode
    
    cd ~
    rm -rf ~/tmp
}

uninstall_packages() {
    sudo apt-get uninstall ${all_packages[@]}
    sudo apt-get autoremove
}

info() {
    for (( i=0; i<${#all_packages[@]}; i++ )); do
        echo "==============================================================================================================================="
        echo
        sudo apt-cache show -a ${all_packages[i]}
    done
}

help() {
  echo "Usage: linuxify.sh [command]";
  echo ""
  echo "Valid commands:"
  echo "  --install     install GNU/Linux utilities"
  echo "  --uninstall   uninstall GNU/Linux utilities"
  echo "  --packages    show info on GNU/Linux utilities"
  exit 1
}

main() {
    check_os
    check_root

    if [[ $# -ne 1 ]]; then
	    help
    else
        case $1 in
            "install") ;&
            "--install") ;&
            "-i")
                configure_git
                change_passwords
                #add_sources
                update_os
                install_packages
                ;;
            "uninstall") ;&
            "--uninstall") ;&
            "-u") 
                uninstall_packages 
                ;;
            "packages") ;&
            "--packages") ;&
            "-p")
                info 
                ;;
            "help") ;&
            "--help") ;&
            "-h")
                help
                ;;
	        *)
                echo "Invalid command"
                help
                ;;
        esac
    fi
}

main "$@"
exit 0
