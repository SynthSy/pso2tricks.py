#!/usr/bin/env bash
# shellcheck disable=SC1090

# Auto installer for the lazy
# Setup the required user dependencies to 
# execute pso2tricks.py

# Downloads the following:
# - virtualenv.pyz python3 web script 
# from https://bootstrap.pypa.io/virtualenv.pyz
# - - Allows the creation of a python virtual environment 
# so we can install the python library requests
 
# This script will automatically create a virutal 
# environment named "myenv" which will be activated 
# afterwards, allowing execution of our custom python
# script "pso2tricks.py".

# If you have suggestions, feel free to let us know.

# pso2tricks.py is licensed under the WTFPL.

# Step 1: Check if the script has write permissions
if [ ! -w . ]; then
  echo "Error: No write permissions in the current directory. Exiting."
  exit 1
fi

# Step 1a: Check if python is present, exit if older version or not available
if ! command -v python3 &> /dev/null; then
  echo "Error: Python3 is not installed. Exiting."
  exit 1
fi

if command -v python &> /dev/null && python --version 2>&1 | grep -q "Python 2.7"; then
  echo "Error: Python 2.7 detected. Please run the script with Python 3. Exiting."
  exit 1
fi

# Step 2: Download virtualenv.pyz using curl
if ! curl -L -O https://bootstrap.pypa.io/virtualenv.pyz; then
  echo "Error: Failed to download virtualenv.pyz. Exiting."
  exit 1
fi

# Step 3: Create a virtual environment using the downloaded virtualenv.pyz
if ! python3 virtualenv.pyz myenv; then
  echo "Error: Failed to create the virtual environment. Exiting."
  exit 1
fi

# Step 4: Activate the virtual environment
source myenv/bin/activate
if [ $? -ne 0 ]; then
  echo "Error: Failed to activate the virtual environment. Exiting."
  exit 1
fi

# Step 5: Install the requests library using pip
if ! pip install requests; then
  echo "Error: Failed to install the requests library. Exiting."
  exit 1
fi

if ! curl -sSL -O https://example.net/myapp.py; then
  echo "Error: Failed to download myapp.py. Exiting."
  exit 1
fi

echo "Prerequisites have been downloaded & installed, exiting."
