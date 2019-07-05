#! /usr/bin/env bash

set -euo pipefail

main_packages=(
    apt-file
    command-not-found
    fonts-powerline
    locate
    mesa-utils
    zsh
)

backport_packages=(
    tilix
    tmux
)

all_packages=(
    ${main_packages[@]}
    ${backport_packages[@]}
)

main() {
    if [[ $# -ne 1 ]]; then
	    show_usage
    fi

    check_os
    check_root

    case $1 in
        "install") ;&
        "--install") ;&
        "-i")
            configure_git
            change_passwords
            #configure_os
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
            show_packages 
            ;;
        "help") ;&
        "--help") ;&
        "-h")
            show_usage
            ;;
        *)
            printf "Invalid command\n"
            show_usage
            ;;
    esac
}

show_usage() {
    printf "Usage: linuxify.sh [command]\n\n"
    printf "Valid commands:\n"
    printf "    --install      install GNU/Linux utilities\n"
    printf "    --uninstall    uninstall GNU/Linux utilities\n"
    printf "    --packages     show package info on GNU/Linux utilities\n"
    exit 1
}

install_packages() {
    local working_directory="$HOME/tmp"

    # Pre-install configuration
    mkdir "$working_directory"
    cd "$working_directory"

    # Install packages
    sudo apt-get install -y apt-utils
    sudo apt-get install -y ${main_packages[@]}
    sudo apt-get install -t stretch-backports -y ${backport_packages[@]}

    # Update packages
    sudo apt-file update
    sudo update-command-not-found
    sudo updatedb

    # Install packages not found in repositories
    install_discord
    install_firefox
    install_oh-my-zsh
    install_vscode

    # Configure packages
    configure_tilix
    
    # Post-install cleanup
    rm -rf "$working_directory"
}

uninstall_packages() {
    show_message "Uninstalling Packages"
    sudo apt-get uninstall ${all_packages[@]}
    sudo apt-get autoremove
}

show_packages() {
    for (( i=0; i<${#all_packages[@]}; i++ )); do
        show_message "${all_packages[i]}"
        sudo apt-cache show -a ${all_packages[i]}
    done
}

show_message() {
    if [[ $# -ne 1 ]]; then
        printf "Invalid header parameters\n"
        return 1
    fi

    local header="$1"

    printf "%*s\n" "$(( ${#header}+4 ))" | tr ' ' '='
    printf "| %*s |\n" "${#header}"
    printf "| %s |\n" "$header"
    printf "| %*s |\n" "${#header}"
    printf "%*s\n" "$(( ${#header}+4 ))" | tr ' ' '='
}

check_os() {
    if ! [[ "$OSTYPE" =~ linux-gnu ]]; then
        printf "This is meant to be run on Linux only\n"
        exit 1
    fi
}

check_root() {
    if [[ "$(whoami)" == "root" ]]; then
        printf "This should not be run as root\n"
	    exit 1
    fi
}

change_passwords() {
    show_message "Changing Passwords"
    printf "Changing root password..\n"
    sudo passwd root
    printf "\nChanging password for $(whoami)..\n"
    sudo passwd "$(whoami)"
}

configure_git() {
    show_message "Configuring Git"
    while read -r -t 0; do read -r; done
    read -p "Email address: " local email
    read -p "Full name: " local full_name
    git config --global user.email $email
    git config --global user.name $full_name
    git config --global credential.helper cache
}

configure_os() {
    configure_sources
    configure_environment
}

# configure_sources() {
#     #TODO: Add contrib and non-free to repos
# }

# configure_environment() {
#     #TODO: Add aliases to .bashrc and .zshrc
# }

update_os() {
    show_message "Updating OS"
    sudo apt-get update
    sudo apt-get -y full-upgrade
}

download_package() {
    if [[ $# -ne 3 ]] && ([[ -z "${1-}" ]] || [[ -z "${2-}" ]] || [[ -z "${3-}" ]]); then
        printf "Invalid download parameters\n"
        return 1
    fi

    local name="$1"
    local filepath="$2"
    local url="$3"

    show_message "Downloading $name"
    wget --quiet --output-document="$filepath" "$url"
    
    printf "...Done.\n"
}

install_package() {
    if [[ $# -lt 2 ]] || [[ $# -gt 3 ]]; then
        printf "Invalid install parameters\n"
        return 1
    fi

    local name="$1"
    local package="$2"

    if [[ $filepath != *.deb ]] && [[ -n "${3-}" ]]; then
        local filepath="$3"
    fi
    
    show_message "Installing $name"
    case "$package" in
        *.deb) sudo apt-get install -y "$package" ;;
        *.tar.bz2) tar -xjf "$package" -C "$filepath" ;;
        *) printf "Package type not supported\n" ;;
    esac
    
    printf "...Done.\n"
}

create_icon() {
    if [[ $# -lt 1 ]] && [[ $# -gt 7 ]]; then
        printf "Invalid create icon parameters\n"
        return 1
    fi

    local filepath="$1"
    local name="$2"
    local comment="$3"
    local image="$4"
    local exec="$5"
    local type="$6"
    local categories="$7"

    if [[ -f "$filepath" ]]; then
        sudo rm -f "$filepath"
    fi

    printf "[Desktop Entry]\nName=%s\nComment=%s\nIcon=%s\nExec=%s\nType=%s\nCategories=%s\n" "$name" "$comment" "$image" "$exec" "$type" "$categories" | sudo tee "$filepath"
}

configure_tilix() {
    printf '\nif [ $TILIX_ID ] || [ $VTE_VERSION ]; then\n    source /etc/profile.d/vte.sh\nfi\n' | sudo tee -a "$HOME/.bashrc" > /dev/null 2>&1
    printf '\nif [ $TILIX_ID ] || [ $VTE_VERSION ]; then\n    source /etc/profile.d/vte.sh\nfi\n' | sudo tee -a "$HOME/.zshrc" > /dev/null 2>&1
    sudo ln -s /etc/profile.d/vte-2.91.sh /etc/profile.d/vte.sh
}

install_discord() {
    local name="Discord"
    local filepath=./discord.deb
    local url="https://discordapp.com/api/download?platform=linux&format=deb"

    download_package "$name" "$filepath" "$url"
    install_package "$name" "$filepath"
}

install_firefox() {
    local name="Firefox"
    local comment="Browse the World Wide Web"
    local image="/home/$(whoami)/firefox/browser/chrome/icons/default/default128.png"
    local exec="env MOZ_USE_XINPUT2=1 /home/$(whoami)/firefox/firefox %u"
    local type="Application"
    local categories="Network;WebBrowser;"
    local filepath="./firefox.tar.bz2"
    local iconpath="/usr/share/applications/firefox.desktop"
    local url="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"

    download_package "$name" "$filepath" "$url"
    install_package "$name" "$filepath" "$HOME"
    create_icon "$iconpath" "$name" "$comment" "$image" "$exec" "$type" "$categories"
}

install_oh-my-zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

install_vscode() {
    wget --quiet --output-document=./vscode.deb "https://go.microsoft.com/fwlink/?LinkID=760868"
    sudo apt-get install -y ./vscode.deb
}

main "$@"
exit 0
