#! /usr/bin/env bash

set -euo pipefail

packages_main=(
    apt-file
    command-not-found
    cros-adapta
    fonts-powerline
    gimp
    htop
    kodi
    locate
    lxappearance
    mesa-utils
    neovim
    smbnetfs
    zsh

    # Build Dependencies
    cmake
    pkg-config
    libfreetype6-dev
    libfontconfig1-dev
    libxcb-xfixes0-dev
)

packages_backports=(
    remmina
    tmux
)

packages_uninstall=(
    vim
)

packages_all=(
    ${packages_main[@]}
    ${packages_backports[@]}
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
        "debug") ;&
        "--debug") ;&
        "-d")
            configure_git
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
    sudo apt-get remove -y ${packages_uninstall[@]}
    sudo apt-get autoremove
    sudo apt-get install -y ${packages_main[@]}
    sudo apt-get install -t stretch-backports -y ${packages_backports[@]}

    # Install Developer packages
    install_azuredatastudio
    install_dotnetcore
    install_golang
    install_miniconda
    install_rust

    # Install packages not found in repositories
    install_alacritty
    install_ddgr
    install_discord
    install_firefox
    install_googler
    install_gotop
    install_nomachine
    install_oh-my-zsh
    install_slack
    install_tldr
    install_vscode

    # Update packages
    sudo apt-file update
    sudo update-command-not-found
    sudo updatedb
    
    # Post-install cleanup
    rm -rf "$working_directory"
}

uninstall_packages() {
    show_message "Uninstalling Packages"
    sudo apt-get uninstall ${packages_all[@]}
    sudo apt-get autoremove
}

show_packages() {
    local IFS=$'\n'
    local packages_sorted=($(sort <<<"${packages_all[*]}")); 
    for (( i=0; i<${#packages_sorted[@]}; i++ )); do
	show_message "${packages_sorted[i]}"
	sudo apt-cache show ${packages_sorted[i]}
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
    local IFS=
    local email=
    local full_name=
    local timeout="1440"
    show_message "Configuring Git"
    #while read -r -t 0; do read -r; done
    read -r -p "Email address: " email
    read -r -p "Full name: " full_name
    git config --global user.email "$email"
    git config --global user.name "$full_name"
    git config --global credential.helper "cache --timeout $timeout"
}

#configure_os() {
#    configure_sources
#    configure_environment
#}

#configure_sources() {
#    #TODO: Add contrib and non-free to repos
#}

#configure_environment() {
#    #TODO: Add aliases to .bashrc and .zshrc
#}

update_os() {
    show_message "Updating OS"
    sudo apt-get update
    sudo apt-get -y full-upgrade
}

download_package() {
    if [[ $# -ne 3 ]]; then
        printf "Invalid download parameters\n"
        return 1
    fi

    local name="$1"
    local package="$2"
    local url="$3"

    printf "Downloading $name...\n"
    wget --output-document="$package" "$url"
}

download_source() {
    if [[ $# -lt 2 ]] || [[ $# -gt 3 ]]; then
        printf "Invalid download source parameters\n"
    fi

    local name="$1"
    local url="$2"
    local depth="1"
    if [[ -n "${3-}" ]]; then
        depth="$3"
    fi

    printf "Downloading $name...\n"
    git clone --depth "$depth" "$url"
    printf "...Done.\n"
}

install_package() {
    if [[ $# -lt 3 ]] || [[ $# -gt 4 ]]; then
        printf "Invalid install parameters\n"
        return 1
    fi

    local name="$1"
    local package="$2"
    local url="$3"
    if [[ -n "${4-}" ]]; then
        local directory="$4"
    fi

    show_message "Installing $name"
    download_package "$name" "$package" "$url"
    case "$package" in
        *.deb) sudo apt-get install -y "$package" ;;
        *.tar.bz2) tar -xjf "$package" -C "$directory" ;;
        *) printf "Package type not supported\n" ;;
    esac
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

install_azuredatastudio() {
    local name="Azure Data Studio"
    local package="azuredatastudio.deb"
    local url="https://go.microsoft.com/fwlink/?linkid=2100672"

    install_package "$name" "./$package" "$url"
}

install_dotnetcore() {
    local name=".Net Core"
    local version="2.2"
    local package="dotnet-sdk-$version"

    show_message "Installing $name"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
    sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
    wget -q https://packages.microsoft.com/config/debian/9/prod.list
    sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
    sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
    sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list
    sudo apt-get install apt-transport-https
    sudo apt-get update
    sudo apt-get install "$package"
}

install_rust() {
    local name="Rust"
    local url="https://sh.rustup.rs"
    local filepath="$HOME/.cargo/env"

    show_message "Installing $name"
    curl -sSf "$url" | sh
    source "$filepath"
}

install_go() {
    local name="Go"
    local version=1.12.9
    local package="go.$version.tar.gz"
    local url="https://dl.google.com/go/go$version.linux-amd64.tar.gz"
    local directory="/usr/local"
    local filepath="$HOME/.profile"
    local shell_export='\n# Go\nexport PATH=$PATH:/usr/local/go/bin\n'

    show_message "Installing $name"
    download_package "$name" "./$package" "$url"
    tar -C "$directory" -xzf "./$package"
    printf $shell_export | sudo tee -a "$HOME/.bashrc" > /dev/null 2>&1
    printf $shell_export | sudo tee -a "$HOME/.zshrc" > /dev/null 2>&1
    source "$filepath"
}

install_miniconda() {
    local name="Miniconda"
    local url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

    show_message "Installing $name"
    curl -sSf "$url" | sh
}

install_gotop() {
    local name="GoTop"
    local package="gotop"
    local installer="./download.sh"
    local url="https://github.com/cjbassi/gotop"
    local directory="/usr/local/bin"
    local depth="1"

    show_message "Installing $name"
    download_source "$name" "$url" "$depth"
    cd "$package"
    sh "$installer"
    mv "./$package" "$directory"
    cd ..
}

install_alacritty() {
    local name="Alacritty"
    local package="alacritty"
    local url="https://github.com/jwilm/alacritty.git"
    local directory="/usr/local/bin"

    show_message "Installing $name"
    download_source "$name" "$url"
    cd "$package"
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/alacritty.desktop
    sudo update-desktop-database
    sed -i 's/^Exec=alacritty$/Exec=env WAYLAND_DISPLAY= alacritty/g' /usr/share/applications/alacritty.desktop
    cd ..
}

install_ddgr() {
    local name="DuckDuckGo (ddgr)"
    local version="1.7"
    local package="ddgr"
    local url="https://raw.githubusercontent.com/jarun/$package/v$version/$package"
    local install_directory="/usr/local/bin"
    local config_directory="$HOME/.smb"
    local home_config="$config_directory/smbnetfs.conf"
    local source_config="/usr/share/doc/smbnetfs-0.6.0/smbnetfs.conf.bz2"

    sudo curl -o "$install_directory" "$url"
    sudo chmod +x "$install_directory/$package"
    mkdir "$config_directory"
    bunzip2 -c "$source_config" > "$home_config"
}

install_googler() {
    local name="Googler"
    local version="3.9"
    local package="googler"
    local url="https://raw.githubusercontent.com/jarun/$package/v$version/$package"
    local directory="/usr/local/bin"

    sudo curl -o "$directory" "$url"
    sudo chmod +x "$directory/$package"
}

install_discord() {
    local name="Discord"
    local package="discord.deb"
    local url="https://discordapp.com/api/download?platform=linux&format=deb"

    install_package "$name" "./$package" "$url"
}

install_slack() {
    local name="Slack"
    local package="slack.deb"
    local url="https://downloads.slack-edge.com/linux_releases/slack-desktop-4.0.1-amd64.deb"

    install_package "$name" "./$package" "$url"
}

install_firefox() {
    local name="Firefox"
    local package="firefox.tar.bz2"
    local url="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
    local directory="$HOME"

    local comment="Browse the World Wide Web"
    local image="/home/$(whoami)/firefox/browser/chrome/icons/default/default128.png"
    local exec="env MOZ_USE_XINPUT2=1 /home/$(whoami)/firefox/firefox %u"
    local type="Application"
    local categories="Network;WebBrowser;"
    local iconpath="/usr/share/applications/firefox.desktop"

    install_package "$name" "./$package" "$url" "$directory"
    create_icon "$iconpath" "$name" "$comment" "$image" "$exec" "$type" "$categories"
}

install_oh-my-zsh() {
    local name="Oh-My-ZSH"
    local url="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh"

    show_message "Installing $name"
    sh -c "$(curl -fsSL $url)"
    sed -i 's/^ZSH_THEME="robbyrussel"/ZSH_THEME="agnoster"/g' "$HOME/.zshrc"
}

install_vscode() {
    local name="VSCode"
    local package="vscode.deb"
    local url="https://go.microsoft.com/fwlink/?LinkID=760868"

    install_package "$name" "./$package" "$url"
}

install_nomachine() {
    local name="NoMachine"
    local package="nomachine.deb"
    local url="https://download.nomachine.com/download/6.7/Linux/nomachine_6.7.6_11_amd64.deb"

    install_package "$name" "./$package" "$url"
}

install_tldr() {
    local name="TL;DR"
    local package="tldr"
    local url="https://raw.githubusercontent.com/raylee/tldr/master/tldr"
    local directory="/usr/local/bin"

    show_message "Installing $name"
    curl -o "$directory/$package" "$url"
    chmod +x "$directory/$package"
}

main "$@"
exit 0
