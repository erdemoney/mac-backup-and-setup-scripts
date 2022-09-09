#!/bin/zsh

### CONFIGURATION ###
mackup_cfg="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Mackup/.mackup.cfg"
brewfile="${HOME}/.Brewfile"
pip_requirements="${HOME}/.requirements.txt"
defaults=""

DEPENDENCIES=(
	mackup 	# config file backup/restore
	mas 	# install mac apps
	python3 # install python packages
	gh 	# set up github
)

install_brew () {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

select_from_finder () {
	echo "$(osascript -l JavaScript -e 'a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFile({withPrompt:"Please select a file to process:"}).toString()')"
}

restore_from_mackup () {
	create_default_config () {
		select storage_service in "dropbox" "google_drive" "icloud" "copy"; do
			case $storage_service in
				* ) break;;
			esac
		done
		echo -n "[storage]\nengine = ${storage_service}" > "${HOME}/.mackup.cfg"
	}

	# if .mackup.cfg is found at remote location, copy it down
	if test -f "$mackup_cfg"; then
		if test -f "${HOME}/.mackup.cfg"; then
			echo "Mackup config file already exists in home directory. Overwrite? (Y/n)"
			while true; do
				read yn
				case $yn in
					[Yy]* ) cp "$mackup_cfg" "$HOME/.mackup.cfg"; break;;
					[Nn]* ) break;;
					* ) echo "Please answer yes or no.";;
				esac
			done
		else
			echo "Mackup config found at ${mackup_cfg}"
			cp "$mackup_cfg" "$HOME/.mackup.cfg"
		fi
	# if .mackup.cfg is NOT found at remote location, prompt user to generate a default config or manually select file
	else
		if test -f "${HOME}/.mackup.cfg"; then
			echo "Mackup config found at ${HOME}/.mackup.cfg"
		else
			while ! test -f "$mackup_cfg"; do
				echo "No mackup config found. What would you like to do?"
				select option in "Create default config" "Select .mackup.cfg from files" "Skip Mackup"; do
					case $option in
						"Create default config" ) create_default_config(); break;;
						"Select .mackup.cfg from files" ) mackup_cfg=select_from_finder; break;;
						"Skip Mackup" ) break;;
					esac
				done
			done
		fi
	fi

	if test -f "${HOME}/.mackup.cfg"; then
		mackup restore
	fi
}

install_packages () {
	cmd=$1
	file=$2
	
	while ! test -f "$file"; do
		echo "File not found at ${file}. Select manually? (Y/n)"
		while true; do
			read yn
			case $yn in
				[Yy]* ) file="$(select_from_finder)"; break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	done
	if test -f "$file"; then
		eval "$cmd '${file}'"
		echo "$cmd ${file}"
	fi
}

post_install () {
	brew cleanup
	brew analytics off
}


if ! command -v -- "brew" > /dev/null 2>&1; then
	echo "Brew is required for this script to run. Install now? (Y/n)"
	while true; do
		read yn
		case $yn in
			[Yy]* ) install_brew; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
fi

echo "Installing script dependencies"
for package in "${DEPENDENCIES[@]}"; do
	if ! command -v -- "$package" > /dev/null 2>&1; then
		brew install "$package"
	fi
done

echo "Restore config files from Mackup? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) restore_from_mackup; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Reinstall packages from Brewfile? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) install_packages "brew bundle --file" "${brewfile}"; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Reinstall python packages from requirements.txt? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) install_packages "pip3 install -r " "$pip_requirements"; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

gh auth login

post_install

# enable icloud documents sharing
# move over EFI
# connect mouse
# setup monitors
