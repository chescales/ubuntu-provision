#!/bin/bash

# Configuration
DEFAULT_ANSIBLE_PATH=$HOME/.venv/ansible
DEFAULT_GIT_PROJECTS_PATH=$HOME/Projects
PROVISION_REPO_PATH=$DEFAULT_GIT_PROJECTS_PATH/ubuntu-provision

# Helpers
## Find the user profile file
PROFILE_FILE=$HOME/.bash_aliases
# [ -w "$PROFILE_FILE" ] || PROFILE_FILE=$HOME/.profile

## Ensure a specific line is in the profile only once
ensure_line_in_profile()
{
	if ! grep -Fx "$1" $PROFILE_FILE >/dev/null 2>/dev/null
	then
		echo -e "\nAdding line to ${PROFILE_FILE} \"$1\". Run \"source $PROFILE_FILE\" to make the new variables and commands available to your shell."
  		echo >> "$PROFILE_FILE"
		echo "$1" >> "${PROFILE_FILE}"
	fi
}


# Installation process
echo -e "\nProceeding to update the system to allow ansible to run a git repo"
sudo apt-get update

echo -e "\nUpgrade currently installed packages? (recommended: 1)"
select yn in Upgrade Skip
do
	case $yn in
		Upgrade) sudo apt-get upgrade;;
		Skip) :;;
	esac
	break
done

if hash git 2>/dev/null
then
	echo -e "\nGit already installed"
else
	echo -e "\nInstall git?"
	select yn in Install Skip
	do
		case $yn in
			Install)
				sudo apt install software-properties-common
				sudo apt-add-repository ppa:git-core/ppa -y
				sudo apt-get update
				sudo apt-get install git -y
				;;
			Skip) :;;
		esac
		break
	done
fi

if hash python3.7 2>/dev/null
then
	echo -e "\nPython3.7 already installed"
else
	echo -e "\nInstall Python3.7?"
	select yn in Install Skip
	do
		case $yn in
			Install)
				sudo apt install software-properties-common
				sudo add-apt-repository ppa:deadsnakes/ppa -y
				sudo apt-get update
				sudo apt install python3.7 python3.7-dev python3.7-venv command-not-found python3-commandnotfound python3.7-gdbm python3.7-gdbm-dbg sessioninstaller -y
				;;
			Skip) :;;
		esac
		break
	done

	if hash python3.7 2>/dev/null
	then
		# Set up the new python executable to be the last one in priority (trying to set it as the default will break Ubuntu)
		# https://askubuntu.com/questions/880188/gnome-terminal-will-not-start/1127951#1127951
		PYTHON_EXEC="$(readlink -f /usr/bin/python)"
		PYTHON3_EXEC="$(readlink -f /usr/bin/python3)"
		PYTHON37_EXEC="$(readlink -f /usr/bin/python3.7)"
		# Remove all previous python executable alternatives
		sudo update-alternatives --remove-all python 2>/dev/null
		sudo update-alternatives --remove-all python3 2>/dev/null
		if [ $PYTHON_EXEC != $PYTHON3_EXEC ]
		then
			# Python 2 still the default version, set it as the highest priority alternative
			sudo update-alternatives --install /usr/bin/python python $PYTHON_EXEC 3
		fi
		if [ $PYTHON3_EXEC != $PYTHON37_EXEC ]
		then
			# An older version of Python3 is still installed, set it as the first in priority for python3 and second for python
			sudo update-alternatives --install /usr/bin/python python $PYTHON3_EXEC 2
			sudo update-alternatives --install /usr/bin/python3 python3 $PYTHON3_EXEC 2
		fi
		# Finally set the new version as the lowest priority one
		sudo update-alternatives --install /usr/bin/python python $PYTHON37_EXEC 1
		sudo update-alternatives --install /usr/bin/python3 python3 $PYTHON37_EXEC 1
	fi
fi

# Find out if ansible is installed in either a $ANSIBLE_VENV_PATH folder, or in the $DEFAULT_ANSIBLE_PATH, and then ask for installation instructions.
ANSIBLE_INSTALLED=0
if [ -z $ANSIBLE_VENV_PATH ]
then
	if [ -d $DEFAULT_ANSIBLE_PATH ]
	then
		echo -e "\nAnsible already installed in $DEFAULT_ANSIBLE_PATH"
		ANSIBLE_INSTALLED=1
	fi
else
	if [ -d $ANSIBLE_VENV_PATH ]
	then
		echo -e "\nAnsible already installed in $ANSIBLE_VENV_PATH"
		ANSIBLE_INSTALLED=1
	else
		echo -e "\nAnsible venv environment set to $ANSIBLE_VENV_PATH, but not installed yet."
	fi
fi
if [ $ANSIBLE_INSTALLED -eq 0 ]
then
	echo -e "\nInstall Ansible? Requires Python3.7 (You can configure Ansible in the next steps)"
	select yn in Install Skip
	do
		case $yn in
			Install)
				if [ -z $ANSIBLE_VENV_PATH ]
				then
					echo -e "\nAnsible will be installed by default in a venv in $DEFAULT_ANSIBLE_PATH. Type another path if you wish to change it, or just press Enter to keep the default path."
					read ANSIBLE_PATH
					if [ -z $ANSIBLE_PATH ]
					then
						ANSIBLE_PATH=$DEFAULT_ANSIBLE_PATH
					else
						# Save the venv path to bash profile for future executions
						ensure_line_in_profile "export ANSIBLE_VENV_PATH=$ANSIBLE_PATH"
						export ANSIBLE_VENV_PATH=$ANSIBLE_PATH
					fi
				else
					ANSIBLE_PATH=$ANSIBLE_VENV_PATH
				fi
				;;
			Skip) :;;
		esac
		break
	done
	if [ $ANSIBLE_PATH ]
	then
		echo -e "\nInstalling ansible in $ANSIBLE_PATH"
		python3.7 -m venv $ANSIBLE_PATH
		source $ANSIBLE_PATH/bin/activate
		pip install -U pip
		pip install ansible
		deactivate
		ensure_line_in_profile "alias activate_ansible='source $ANSIBLE_PATH/bin/activate'"
		ANSIBLE_INSTALLED=1
	fi
fi

# Create the folder structure for the ansible project which will provision the machine
if [ ! -d $PROVISION_REPO_PATH ]
then
	echo -e "\nDownload ubuntu-provision repository? (https://...)"
	select yn in Download Skip
	do
		case $yn in
			Download)
				mkdir -p $PROVISION_REPO_PATH
				# git clone https:// $PROVISION_REPO_PATH
				echo -e "\nDownload complete in $PROVISION_REPO_PATH"
				;;
			Skip) :;;
		esac
		break
	done
fi

if [[ $ANSIBLE_INSTALLED -eq 1 && -d $PROVISION_REPO_PATH ]]
then
	echo -e "\nRun ubuntu-provision playbook?"
	select yn in Run Skip
	do
		case $yn in
			Run)
				echo -e "Not ready to install yet!"
				;;
			Skip) :;;
		esac
		break
	done
else
	echo -e "\nSkipping local machine provisioning. Ansible needs to be installed and the ubuntu-provision repository downloaded."
fi



