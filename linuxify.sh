#! /usr/bin/env bash

set -euo pipefail

linuxify_check_os() {
  if ! [[ "$OSTYPE" =~ linux-gnu ]]; then
      echo "This is meant to be run on Linux only"
      exit
  fi
}

linuxify_update_os() {
    sudo apt update
    sudo apt upgrade
    sudo apt dist-upgrade
}

linuxify_packages=(
    apt-utils
    apt-file
    command-not-found
)

linuxify_install() {
    linuxify_check_os;
    linuxify_update_os;

    # Install all packages
    sudo apt install -y ${linuxify_packages[@]}
}

linuxify_uninstall() {
    linuxify_check_os;

    sudo apt uninstall ${linuxify_packages[@]}
}

linuxify_info() {
    linuxify_check_os;

    for (( i=0; i<${#linuxify_packages[@]}; i++ )); do
        echo "==============================================================================================================================="
        echo
        sudo apt show ${linuxify_packages[i]}
    done
}

linuxify_help() {
  echo "usage: linuxify.sh [-h] [command]";
  echo ""
  echo "valid commands:"
  echo "  install    install GNU/Linux utilities"
  echo "  uninstall  uninstall GNU/Linux utilities"
  echo "  info       show info on GNU/Linux utilities"
  echo ""
  echo "optional arguments:"
  echo "  -h, --help  show this help message and exit"
}

linuxify_main() {
    if [ $# -eq 1 ]; then
        case $1 in
            "install") linuxify_install ;;
            "uninstall") linuxify_uninstall ;;
            "info") linuxify_info ;;
            "-h") linuxify_help ;;
            "--help") linuxify_help ;;
        esac
    else
        linuxify_help;
        exit
    fi
}

linuxify_main "$@"
