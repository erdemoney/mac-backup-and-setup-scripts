#!/bin/zsh

################################################################################
#                                 CONFIGURATION                                #
################################################################################

# These paths will be used for storing/symlinking your files for mackup
# NOTE: If you change these, you will have to change their locations in 
# 	the restore script for it to find them. Additionally if you change them
# 	after already running the script and generating the config files for
# 	mackup i.e .mackup/brewfile.cfg you will have to manually change the
# 	paths in the .cfg files to your new location for it to backup properly

defaults="${HOME}/.defaults"
brewfile="${HOME}/.Brewfile"
pip_requirements="${HOME}/.requirements.txt"

################################################################################

if ! command -v -- "mackup" > /dev/null 2>&1; then
	echo "Mackup not found. Please install Mackup to use this script"
	exit 1
fi


run_mackup () {
	select_from_finder () {
		echo "$(osascript -l JavaScript -e 'a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFile({withPrompt:"Please select a file to process:"}).toString()')"
	}

	create_default_config () {
		select storage_service in "dropbox" "google_drive" "icloud" "copy"; do
			case $storage_service in
				* ) break;;
			esac
		done
		echo -n "[storage]\nengine = ${storage_service}" > "${HOME}/.mackup.cfg"
	}

	mackup_cfg="${HOME}/.mackup.cfg"


	# create mackup config if one doesnt already exit
	if ! test -f "$mackup_cfg"; then
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
	mackup backup
}

backup_brew () {
	brewfile_cfg="${HOME}/.mackup/brewfile.cfg"
	cfg_brewfile_path="${brewfile/"$HOME\/"/""}"   
	cfg_file_contents="[application]\nname = Brewfile\n\n[configuration_files]\n$cfg_brewfile_path"

	create_config () {
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		echo -n "$cfg_file_contents" > "$brewfile_cfg"
	}

	# create custom configuration file for backing up brew packages
	if ! test -f "$brewfile_cfg"; then
		create_config ()
	fi

	if [ "$cfg_file_contents" != "$(cat "$brewfile_cfg")" ]; then
		echo "no match"
		echo -n "[application]\nname = Brewfile\n\n[configuration_files]\n$brew_path"
		echo 
		echo "$(cat "$brewfile_cfg")"
	else
		echo -n "[application]\nname = Brewfile\n\n[configuration_files]\n$brew_path"
		echo 
		echo "$(cat "$brewfile_cfg")"
	fi
	exit

	# backup brew packages
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

backup_brew
exit

backup_pip () {
	pip_requirements_cfg="${HOME}/.mackup/pip_requirements.cfg"

	# create custom configuration file for backing up pip packages
	if ! test -f "$pip_requirements_cfg"; then
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		pip_path="${pip_requirements/"$HOME\/"/""}"   
		echo -n "[application]\nname = pip requirements.txt\n\n[configuration_files]\n$pip_path" > "$pip_requirements_cfg"
	fi

	# backup pip packages
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
	defaults_cfg="${HOME}/.mackup/defaults.cfg"
	if ! test -f "$defaults_cfg"; then
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
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



