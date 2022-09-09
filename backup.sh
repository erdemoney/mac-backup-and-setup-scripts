#!/bin/zsh

### CONFIGURATION ###
# these locations are where files will be backed up from or created to before backing up
defaults="${HOME}/.defaults"
brewfile="${HOME}/.Brewfile"
pip_requirements="${HOME}/.requirements.txt"

### PATHS ###
# don't mess with these
brewfile_cfg="${HOME}/.mackup/brewfile.cfg"
pip_requirements_cfg="${HOME}/.mackup/pip_requirements.cfg"
defaults_cfg="${HOME}/.mackup/defaults.cfg"

if ! command -v -- "mackup" > /dev/null 2>&1; then
	echo "Mackup not found. Please install Mackup to use this script"
	exit 1
fi

backup_brew () {
	if ! test -f "$brewfile_cfg"; then
		brew_path="${brewfile/"$HOME\/"/""}"   
		echo -n "[application]\nname = Brewfile\n\n[configuration_files]\n$brew_path" > "$brewfile_cfg"
	fi
	if test -f "$brewfile"; then
		echo "Brewfile already exists. Overwrite? (Y/n)"
		while true; do
			read yn
			case $yn in
				[Yy]* ) 
					mv "$brewfile" "$brewfile".tmp;
					brew bundle dump --file="$brewfile";
					rm "$brewfile".tmp;
					break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	else
		brew bundle dump --file="$brewfile";
	fi
}

backup_pip () {
	if ! test -f "$pip_requirements_cfg"; then
		echo -n "[application]\nname = pip requirements.txt\n\n[configuration_files]\n$pip_requirements" > "$pip_requirements_cfg"
	fi

	if test -f "$pip_requirements"; then
		echo "requirements.txt already exists. Overwrite? (Y/n)"
		while true; do
			read yn
			case $yn in
				[Yy]* ) pip3 freeze > "$pip_requirements"; break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	else
		pip3 freeze > "$pip_requirements"
	fi
}

backup_defaults () {
	if ! test -f "$defaults_cfg"; then
		echo "[application]\nname = macOS defaults\n\n[configuration_files]\n$defaults"> "$defaults_cfg"
	fi
}

if command -v -- "brew" > /dev/null 2>&1; then
	echo "Backup brew packages? (Y/n)"
	while true; do
		read yn
		case $yn in
			[Yy]* ) backup_brew; break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
else
	echo "brew not found."
fi

if command -v -- "pip3" > /dev/null 2>&1; then
	echo "Backup python packages? (Y/n)"
	while true; do
		read yn
		case $yn in
			[Yy]* ) backup_pip; break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
else
	echo "pip3 not found."
fi

if test -f "$defaults"; then
	echo "Backup macOS defaults? (Y/n)"
	while true; do
		read yn
		case $yn in
			[Yy]* ) backup_defaults; break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
fi

mackup backup
