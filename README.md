## Mac Backup and Restore

These scripts work in tandem to make backing up and restoring your Mac's configuration to and from the cloud seamless.
After runnning the "backup" script, simply run the "restore" script on a new install and all of your config files, brew applications (including casks), Mac App Store applications, python packages, and Mac settings will be restored exactly as before. It'll even set up your Github.

- Backup and restore configuration files for a vast number of apps and cli programs via Mackup
- Backup and restore your Mac GUI and command line programs via brew bundle and mas
- Backup and restore your python packages via pip freeze
- Set up your Github ssh keys via github CLI
- Run Mac 'defaults' commands to restore Mac configuration options not restored via icloud or other mechanisms
