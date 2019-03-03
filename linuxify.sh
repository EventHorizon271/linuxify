#! /usr/bin/env bash

set -euo pipefail

check_os() {
  if ! [[ "$OSTYPE" =~ linux-gnu ]]; then
      echo "This is meant to be run on Linux only"
      exit
  fi
}

change_passwords() {
    echo "Changing root password.."
    sudo passwd root

    echo "Changing password for $(whoami).."
    sudo passwd $(whoami)
}

add_sources() {
    echo 'deb http://ftp.debian.org/debian stretch-backports main' | sudo tee /etc/apt/sources.list.d/stretch-backports.list
}

update_os() {
    sudo apt-get update
    sudo apt-get full-upgrade
}

regular_packages=(
    apt-utils
    apt-file
    command-not-found
    zsh
    fonts-powerline
)

backport_packages=(
    tmux
)

all_packages=(
    $regular_packages
    $backport_packages
)

install_oh-my-zsh() {
    mkdir ~/Downloads
    cd ~/Downloads
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

configure_git() {
    git config --global user.email $2
    git config --global user.name $3
    git config --global credential.helper cache
}

install() {
    check_os;
    change_passwords;
    add_sources;
    update_os;

    # Install regular packages
    sudo apt-get install -y ${regular_packages[@]}

    # Install backport packages
    sudo apt-get install -t stretch-backports -y ${backport_packages[@]}

    # Update apt-file and command-not-found
    sudo apt-file update
    sudo update-command-not-found

    # Install Oh-My-Zsh
    install_oh-my-zsh;

    # Modify Configurations
    configure_git;
}

uninstall() {
    check_os;

    sudo apt-get uninstall ${all_packages[@]}
    sudo apt-get autoremove
}

info() {
    check_os;

    for (( i=0; i<${#all_packages[@]}; i++ )); do
        echo "==============================================================================================================================="
        echo
        sudo apt-cache show -a ${all_packages[i]}
    done
}

help() {
  echo "usage: linuxify.sh [-h] [command] [git_email] [git_name]";
  echo ""
  echo "valid commands:"
  echo "  install    install GNU/Linux utilities"
  echo "  uninstall  uninstall GNU/Linux utilities"
  echo "  info       show info on GNU/Linux utilities"
  echo ""
  echo "optional arguments:"
  echo "  -h, --help  show this help message and exit"
}

main() {
    if [ $# -eq 3 ]; then
        case $1 in
            "install") install ;;
            "uninstall") uninstall ;;
            "info") info ;;
            "-h") help ;;
            "--help") help ;;
        esac
    else
        help;
        exit
    fi
}

main "$@"
