#!/bin/zsh

################################################################################
#                                 CONFIGURATION                                #
################################################################################

# NOTE: only icloud has been tested. 
# Modifications may need to be made for other services to work.
# options: "icloud", "google_drive", "dropbox", "copy", "file_system"
storage_service="icloud" 

# PATHS
# This is the real (not symlinked) path to your mackup directory
mackup_dir="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Mackup"
mackup_cfg="${mackup_dir}/.mackup.cfg"

# This is the location of the symlinked files that Mackup creates based on
# their original location when '$ mackup backup' is run.
brewfile="${HOME}/.Brewfile"
pip_requirements="${HOME}/.requirements.txt"
defaults="${HOME}/.defaults"

# list of manual actions to be displayed as a checklist
manual_actions=(
	"Enable icloud documents and desktop"
	"Copy over EFI"
	"Connect bluetooth mouse"
	"Setup monitors"
)

# Any custom stuff can go here
run_custom () {
	# https://www.lunarvim.org/
	install_lunarvim () {
		echo "Installing LunarVim"
		if ! command -v -- "lvim" > /dev/null 2>&1; then
			brew install git make node npm rust # install deps
			bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
		else
			echo "LunarVim is already installed"
		fi
	}
	install_lunarvim
	brew cleanup
	brew analytics off
}


###############################################################################

# These will be automatically installed with brew if they are not present
DEPENDENCIES=(
	mackup 	# config file backup/restore
	mas 	# install Mac App Store apps
	python3 # install python packages
	gh 	# set up github
)

install_brew () {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

select_from_finder () {
	echo "$(osascript -l JavaScript -e 'a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFile({withPrompt:"Please select a file to process:"}).toString()')"
}

display_manual_actions () {
	echo "Press any key to check off each item"
	for action in "${manual_actions[@]}"; do
		echo -ne "\r[ ] ${action}"
		read
		echo -en "\033[1A\033[2K"
		echo -ne "\r[x] ${action}\n"
	done
}

restore_from_mackup () {
	download_configs_from_icloud () {
		find "${mackup_dir}" -type f -name "*.icloud" -exec brctl download {} \;
		echo "Waiting for iCloud configs to download"
		while [[ -z 'find "${mackup_dir}" -type f -name "*.icloud")' ]]; do
			:
		done
		echo "Config files downloaded"
	}

	create_default_config () {
		select storage_service in "dropbox" "google_drive" "icloud" "copy"; do
			case $storage_service in
				* ) break;;
			esac
		done
		echo -n "[storage]\nengine = ${storage_service}" > "${HOME}/.mackup.cfg"
	}

	if [ $storage_service = "icloud" ]; then
		download_configs_from_icloud
	fi

	# if .mackup.cfg is found at remote location, copy it down
	if test -f "$mackup_cfg"; then
		if test -f "${HOME}/.mackup.cfg"; then
			echo "Mackup config file already exists in home directory. Enter Y to overwrite or N to use local config file (Y/n)"
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
						"Create default config" ) create_default_config; break;;
						"Select .mackup.cfg from files" ) cp $(select_from_finder) "${mackup_cfg}"; break;;
						"Skip Mackup" ) break;;
					esac
				done
			done
		fi
	fi

	if test -f "${HOME}/.mackup.cfg"; then
		mackup restore
	else
		echo "Files NOT restored from Mackup. Continuing..."
	fi
}

install_packages () {
	cmd="$1"
	file="$2"
	
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
		eval "$cmd" '${file}'
	else
		echo "Packages NOT installed."
	fi
}

run_defaults () {
	while ! test -f "$defaults"; do
		echo "File not found at ${defaults}. Select manually? (Y/n)"
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
		bash '${defaults}'
	else
		echo "Defaults file not executed."
	fi
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

echo "Installing script dependencies..."
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
		[Yy]* ) install_packages "pip3 install -r " "${pip_requirements}"; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Execute defaults file? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) run_defaults; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Configure Github? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) gh auth login; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Run custom actions? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) post_install; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "Show manual actions? (Y/n)"
while true; do
	read yn
	case $yn in
		[Yy]* ) display_manual_actions; break;;
		[Nn]* ) break;;
		* ) echo "Please answer yes or no.";;
	esac
done

exit 0
