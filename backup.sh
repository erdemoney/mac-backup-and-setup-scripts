#!/bin/zsh

################################################################################
#                                 CONFIGURATION                                #
################################################################################

# These paths will be used for storing/symlinking your files for mackup
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
						"Select .mackup.cfg from files" ) cp "$(select_from_finder)" "${mackup_cfg}"; break;;
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
	cfg_brewfile_path="${brewfile/"$HOME\/"/""}" # string formatted for mackups config files  
	cfg_file_contents="[application]
	name = Brewfile

	[configuration_files]
	$cfg_brewfile_path"

	# create custom configuration file for backing up brew packages
	create_config () {
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		echo -n "$cfg_file_contents" > "$brewfile_cfg"
	}

	if ! test -f "$brewfile_cfg" ; then
		echo "mackup brewfile config created"
		create_config
	fi

	if [[ "$(< "$brewfile_cfg")" != "$cfg_file_contents" ]]; then
		echo "mackup brewfile config updated"
		create_config
	fi

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

backup_pip () {
	pip_requirements_cfg="${HOME}/.mackup/pip_requirements.cfg"
	cfg_requirements_path="${pip_requirements/"$HOME\/"/""}" # string formatted for mackups config files
	cfg_file_contents="[application]
	name = pip requirements.txt

	[configuration_files]
	$cfg_requirements_path"

	# create custom configuration file for backing up pip packages
	create_config () {
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		echo -n "$cfg_file_contents" > "$pip_requirements_cfg"
	}

	if ! test -f "$pip_requirements_cfg" ; then
		echo "Mackup pip requirements.txt config created"
		create_config
	fi

	if [[ "$(< "$pip_requirements_cfg")" != "$cfg_file_contents" ]]; then
		echo "mackup brewfile config updated"
		create_config
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
	cfg_defaults_path="${defaults/"$HOME\/"/""}" # string formatted for mackups config files
	cfg_file_contents="[application]
	name = macOS defaults
	
	[configuration_files]
	$cfg_defaults_path"

	create_config () {
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		echo -n "$cfg_file_contents" > "$defaults_cfg"
	}

	if ! test -f "$pip_requirements_cfg" ; then
		echo "Mackup pip requirements.txt config created"
		create_config
	fi

	if [[ "$(< "$pip_requirements_cfg")" != "$cfg_file_contents" ]]; then
		echo "mackup brewfile config updated"
		create_config
	fi

	if ! test -f "$defaults_cfg"; then
		# create mackup directory if one doesnt exist
		if ! [ -d "${HOME}/.mackup" ]; then
			mkdir "${HOME}/.mackup"
		fi
		echo "$cfg_file_contents" > "$defaults_cfg"
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

run_mackup
