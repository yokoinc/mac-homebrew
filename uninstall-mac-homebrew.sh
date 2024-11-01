#!/bin/bash

# Ensure sudo credentials are cached
sudo -v || { echo "Failed to cache sudo credentials"; exit 1; }

read -rp "This will uninstall homebrew and remove all its folders. Do you want to continue? (yes/no): " response

# Convert the response to lowercase and trim leading/trailing whitespace
response=$(echo "$response" | tr '[:upper:]' '[:lower:]' | xargs)
# Check the response
if [[ $response == "yes" || $response == "y" ]]; then
	echo "Uninstalling Homebrew..."
elif [[ $response == "no" || $response == "n" ]]; then
	exit 0
else
    echo "Invalid response. Please enter 'yes' or 'no'."
	exit 1
fi

if [[ -e /opt/homebrew/bin/brew ]]; then
brew uninstall --quiet --cask --force font-meslo-lg-nerd-font 2> /dev/null
NONINTERACTIVE=1 sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
fi

# Remove Symbolic links

# echo attempting to delete homebrew directory....
sudo rm -rf /opt/homebrew
sudo rm -rf ~/.cache
sudo rm -rf ~/.local
sudo rm -rf ~/.config/homebrew
sudo rm -rf ~/.config/zinit
sudo rm -rf ~/.config/nvim
sudo rm -rf ~/.config/bat
sudo rm -rf ~/.config/oh-my-posh
sudo rm -rf ~/.sources/
sudo rm -rf ~/.dotfiles
sudo rm -rf ~/.scripts
sudo rm -rf ~/.zcompdump
sudo rm -rf ~/.npmrc
sudo rm -rf ~/.npm
sudo rm -rf ~/.bash_history
sudo rm -rf ~/.histfil
sudo rm -rf ~/.profile
sudo rm -rf ~/.wget-hsts
sudo rm -rf ~/.zsh_history
sudo rm -rf ~/.zshrc
sudo rm -rf ~/.histfile

echo "Uninstall complete. Returning to the Mac OS default shell.."
