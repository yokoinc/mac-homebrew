#!/bin/bash

DEBUG=0
[[ $DEBUG == 1 ]] && echo "DEBUG mode"

SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Change to the script directory
cd "$SCRIPT_DIR" || { echo "Failed to change directory to $SCRIPT_DIR" >&2; exit 1; }
echo "Working directory: $SCRIPT_DIR"

# Source the functions file
source "$SCRIPT_DIR/functions.sh"

# login and cache sudo which creates a sudoers file
func_sudoers

# Check if the script is being run as root
if [[ "$EUID" -eq 0 ]]; then
    echo "This script should not be run as root. Run it as a regular user, although we will need root password in a second..." >&2
    exit 1
fi

# Check prerequisites of this script
error=false

DEBUG=0
[[ $DEBUG == 1 ]] && echo "DEBUG mode"
# Function to display the install menu
read -p "Should we install Homebrew ? (yes) : " answer

# Check user answer
if [ "$answer" = "yes" ]; then
    echo "mac Homebrew install beginning"
else
    echo "End of Homebrew install."
    exit 1
fi

DEBUG=0
[[ $DEBUG == 1 ]] && echo "DEBUG mode"

export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1

# Create a new .profile and add homebrew paths
cat > "$HOME/.profile" <<EOF
# Directories to add to PATH
directories=(
  "/opt/homebrew/lib/ruby/gems/3.3.0/bin"
  "/opt/homebrew/opt/glibc/sbin"
  "/opt/homebrew/opt/glibc/bin"
  "/opt/homebrew/opt/binutils/bin"
  "/opt/homebrew/sbin"
  "/opt/homebrew/bin"
)
# Iterate over each directory in the 'directories' array
for dir in "\${directories[@]}"; do
    # Check if the directory is already in PATH
    if [[ ":\$PATH:" != *":\$dir:"* ]]; then
        # If not found, append it to PATH
        export PATH="\$dir:\$PATH"
    fi
done

# Additional environment variables
export LDFLAGS="-L/opt/homebrew/opt/glibc/lib"
export CPPFLAGS="-I/opt/homebrew/opt/glibc/include"
export XDG_CONFIG_HOME="\$HOME/.config"
export HOMEBREW_GIT_PATH=/opt/homebrew/bin/git

# Keep gcc up to date. Find the latest version of gcc installed and set symbolic links from version 11 onwards
max_version=\$(/bin/ls -d /opt/homebrew/opt/gcc/bin/gcc-* | grep -oE '[0-9]+$' | sort -nr | head -n1)

# Create symbolic link for gcc to latest gcc-*
ln -sf "/opt/homebrew/bin/gcc-\$max_version" "/opt/homebrew/bin/gcc"

# Create symbolic links for gcc-11 to max_version pointing to latest gcc-*
for ((i = 11; i < max_version; i++)); do
    ln -sf "/opt/homebrew/bin/gcc-\$max_version" "/opt/homebrew/bin/gcc-\$i"
done

# fzf-git.sh source git key bindings for fzf-git
[[ -f \$HOME/.scripts/fzf-git.sh ]] && source "\$HOME/.scripts/fzf-git.sh"

# Link Homebrew environment
eval "\$(/opt/homebrew/bin/brew shellenv)"

EOF

# Begin Homebrew install. Remove brew git env if it does not exist
[[ ! -x /opt/homebrew/bin/git ]] && unset HOMEBREW_GIT_PATH
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2> /dev/null
eval "$(/opt/homebrew/bin/brew shellenv)"
ulimit -n 2048
brew install --quiet zsh 2> /dev/null
brew install --quiet glibc gcc clang-build-analyzer make python 2> /dev/null
brew install --quiet python 2> /dev/null
brew install --quiet git gh git-delta 2> /dev/null
brew install --quiet bat 2> /dev/null
brew install --quiet oh-my-posh zoxide fzf eza thefuck 2> /dev/null
brew install --quiet --cask --force font-meslo-lg-nerd-font 2> /dev/null
brew install --quiet tree ripgrep fd tldr tlrc 2> /dev/null
brew install --quiet tree node npm 2> /dev/null
brew install --quiet nano nvim tmux 2> /dev/null
brew install --HEAD utf8proc 2> /dev/null
brew install --quiet jesseduffield/lazygit/lazygit 2> /dev/null
brew upgrade --quiet 2> /dev/null
source ~/.profile

brew postinstall --quiet gcc 2> /dev/null

# Changing config folder permissions before integration
sudo chown -R "$(whoami)" $SCRIPT_DIR/config/
sudo chmod -R 755 $SCRIPT_DIR/config/

# oh-my-posh configuration
OMP_SOURCE="./config/oh-my-posh"
OMP_DESTINATION="$HOME/.config/oh-my-posh"

# Check if config directory is present
if [ -d "$OMP_SOURCE" ]; then
    # Create destination folder if not present
    mkdir -p "$OMP_DESTINATION"
    sudo chown -R "$(whoami)" "$OMP_DESTINATION"
    sudo chmod -R 755 "$OMP_DESTINATION"
    # Copy content to destination
    cp -r "$OMP_SOURCE/"* "$OMP_DESTINATION/"
else
    echo "$OMP_SOURCE doesnt exist"
fi

# bat configuration
BAT_SOURCE="./config/bat"
BAT_DESTINATION="$HOME/.config/bat"

# Check if config directory is present
if [ -d "$BAT_SOURCE" ]; then
    # Create destination folder if not present
    mkdir -p "$BAT_DESTINATION"
    sudo chown -R "$(whoami)" "$BAT_DESTINATION"
    sudo chmod -R 755 "$BAT_DESTINATION"
    # Copy content to destination
    cp -r "$BAT_SOURCE/"* "$BAT_DESTINATION/"
else
    echo "$BAT_SOURCE doesnt exist"
fi

# neovim configuration
echo "neovim configuration"
NVIM_SOURCE="$SCRIPT_DIR/config/nvim"
NVIM_DESTINATION="$HOME/.config/nvim"

# Check if config directory is present
if [ -d "$NVIM_SOURCE" ]; then
    # Create destination folder if not present
    mkdir -p "$NVIM_DESTINATION"
    sudo chown -R "$(whoami)" "$NVIM_DESTINATION"
    sudo chmod -R 755 "$NVIM_DESTINATION"
    # Copy content to destination
    cp -r "$NVIM_SOURCE/"* "$NVIM_DESTINATION/"
else
    echo "$NVIM_SOURCE doesnt exist"
fi

# Check if config directory is present
mkdir -p $HOME/.scripts
sudo chown -R "$(whoami)" "$HOME/.scripts"
sudo chmod -R 755 "$HOME/.scripts"
echo "Cloning fzf-git.sh into ~/.scripts directory"
sudo mkdir -p ~/.scripts && curl -o ~/.scripts/fzf-git.sh https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh

# Prepare and install zinit
# Set the directory we want to store zinit and plugins
[[ -e $HOME/.local/share ]] && rm -rf .local/share
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    sudo mkdir -p $HOME/.local/share
    sudo chown -R "$(whoami)" $HOME/.local/share
    sudo chmod -R 755 $HOME/.local/share
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Create the symlinks
echo "Creating symlinks"

echo "Finished creating symlinks"

## Finalize with zsh configuration
# default zshrc reference file
ZSHRC_REFERENCE="$SCRIPT_DIR/config/zshrc/default_zshrc"

# .zshrc destination
ZSHRC_FILE="$HOME/.zshrc"

# If default zshrc exist
if [ -f "$ZSHRC_REFERENCE" ]; then
    # Copy content in .zshrc
    cp "$ZSHRC_REFERENCE" "$ZSHRC_FILE"
    echo ".zhrc has been createds"
else
    echo "$ZSHRC_REFERENCE is not present."
fi

# Finalize with zsh execution in Mac OS bash ~/.profile
command_to_add='[[ -x /opt/homebrew/bin/zsh ]] && exec /opt/homebrew/bin/zsh'
if ! grep -xF "$command_to_add" ~/.profile; then
    echo "$command_to_add" >> ~/.profile
fi

# Finish script with cleanup and transport
sudo rm -rf "$SUDOERS_FILE"

# Final installation message
# clear
echo "Script completed successfully. You will now be transported to ZSH with oh-my-posh and zinit !!!"
exec zsh --login


