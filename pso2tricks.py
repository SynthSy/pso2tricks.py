#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "requests",
# ]
# ///
#
# pso2tricks - helps GNU/Linux users install & patch the Japanese version of
# Phantasy Star Online 2: New Genesis via the PSO2 Tweaker.
#
# configure.sh rewrites the shebang above to point at the uv binary it
# installed, so the script can be run as "./pso2tricks" without any
# virtualenv or requirements.txt.
#
# Licensed under the WTFPL.

import os
import sys
import argparse
import getpass
import re
import requests
import shutil
import stat
import zipfile
import subprocess
import traceback
from datetime import datetime
from pathlib import Path

# I use tabs instead of spaces like a monster :)

class prettyHelp(argparse.ArgumentDefaultsHelpFormatter):
	def _format_action_invocation(self, action):
		if action.option_strings:
			return ', '.join(action.option_strings)
		return super()._format_action_invocation(action)
class PSO2TweakerPy:
	def __init__(self):
		self.parser = argparse.ArgumentParser(
			prog="pso2tricks.py",
			description="Helps GNU/Linux users install the PSO2 Tweaker to play the Japanese version.",
			epilog="Created by SynthSy. Licensed under the WTFPL.",
			formatter_class=lambda prog: prettyHelp(prog, width=100),
			usage='%(prog)s [-h] [-v] [--tweaker [-up]] [--patcher <ngs|both> <path to pso2_bin>]'
		)
		self._configArgs()
		self.homeDir = Path.home() # get current user's home folder
		self.user = getpass.getuser() # get the current user
		self.tweaker_folder = Path(os.environ.get('PSO2_FILES_LOCATION') or f'{Path.home()}/pso2_files').expanduser() # sets the tweaker folder
		self.timeout = (15, 60)

	def _configArgs(self): # define commands
		self.parser.add_argument("-t", "--tweaker", action="store_true", help="Downloads the PSO2 Tweaker.")
		self.parser.add_argument("-up", action='store_true', dest="update", help="Updates the PSO2 Tweaker if previously downloaded.")
		self.parser.add_argument("-p","--patcher", nargs=2, metavar=("patch", "path"), help="Downloads & applies the English fan patches. ")
		self.parser.add_argument("-v", dest="version", action='store_true', help="Displays the version.")

	def _version(self, info):
		if info is True:
			version = '1.7'
			print('pso2tricks v' + version)

	def regexPath(self, directory, pattern): # check if file exists by matching regex
		try:
			for entry in os.listdir(directory):
				full_path = os.path.join(directory, entry)
				if os.path.isfile(full_path) and re.fullmatch(pattern, entry):
					return entry
		except FileNotFoundError:
			return None

	def downloadFile(self, url, filename):
		filename = Path(filename)
		tmp = filename.with_name(filename.name + '.part') # download to a .part file first so a failed download never destroys a working file

		try:
			response = requests.get(url, stream=True, timeout=self.timeout)
			response.raise_for_status()

			with open(filename, 'wb') as file:
				for chunk in response.iter_content(chunk_size=8192):
					if chunk:
						file.write(chunk)
			os.replace(tmp, filename)
			print(f"File successfully downloaded: {filename}")
		except (requests.exceptions.RequestException, OSError) as e:
			tmp.unlink(missing_ok=True)
			print(f"Failed to download file: {e}")
			raise

	def getTweaker(self, tweaker, update): # download the tweaker, will also set flatpak override if allowed
		# tweaker exe origin
		tweakerUrl = 'https://github.com/Aida-Enna/PSO2TweakerReleases/releases/latest/download/PSO2.Tweaker.exe'
		themeUrl = 'https://github.com/SynthSy/pso2tricks.py/raw/refs/heads/main/tweaker_files/theme.json'
		pattern = re.compile(r"PSO2 Tweaker\.exe") # simple "PSO2 Tweaker.exe" regex
		tweakerExe = self.regexPath(self.tweaker_folder, pattern)
		if tweaker is True:
			# make the folder if it doesn't exist
			self.tweaker_folder.mkdir(parents=True, exist_ok=True)

			filepath = f'{self.tweaker_folder}/PSO2 Tweaker.exe'

			if tweakerExe and update is not True:
				print(f'{filepath} already exists. Use "--tweaker -up" to update it.')
			else:
				if tweakerExe:
					print('Updating the PSO2 Tweaker from GitHub...')
				else:
					print('Downloading the PSO2 Tweaker from GitHub...')
				self.downloadFile(tweakerUrl, filepath)

			theme = f'{self.tweaker_folder}/theme.json'
			if update is True or not os.path.exists(theme):
				print('Downloading the Linux-readable Tweaker theme...')
				self.downloadFile(themeUrl, theme)
			self.flatpakOverride(self.tweaker_folder)

	def patchDownload(self, patch, pso2_bin): # download patches if the tweaker did not
		patcher = 'https://synthsy.space/json/els_linux' # https://github.com/HybridEidolon/pso2-modpatcher || I compiled a binary using ubuntu 20.04 then uploaded it.
		ngs_en_patch = 'https://cdn.arks-layer.com/TweakerTemp/Latest_Patch_EN_Reboot.zip'
		classic_en_patch = 'https://cdn.arks-layer.com/TweakerTemp/Latest_Patch_EN_win32.zip'
		els_path = f'{self.tweaker_folder}/ELS'
		elsFilename = self.tweaker_folder / 'els_linux'

		patch = str(patch).lower()
		if patch not in ('ngs', 'both'):
			raise ValueError(f'patch must be "ngs" or "both", got "{patch}".')
		pso2_bin = Path(pso2_bin).expanduser().resolve()
		if not (pso2_bin / 'data').is_dir():
			raise ValueError(f'{pso2_bin} is not a valid pso2_bin folder.')

		print('Removing old files before downloading new ones.')
		shutil.rmtree(els_path, ignore_errors=True)
		els_path.mkdir(parents=True)

		print('Downloading required files...')
		self.downloadFile(patcher, elsFilename)
		os.chmod(elsFilename, 0o755) # required or we can't execute the command
		zips = [self.tweaker_folder / 'Latest_Patch_EN_Reboot.zip']
		self.downloadFile(ngs_en_patch, zips[0])

		if patch == 'both':
			zips.append(self.tweaker_folder / 'Latest_Patch_EN_win32.zip')
			self.downloadFile(classic_en_patch, zips[1])

		print('Extracting files, please wait...')
		for z in zips:
			with zipfile.ZipFile(z, "r") as zip_ref:
				zip_ref.extractall(els_path)
		print('Done')

		print('Beginning patch process, please wait...')
		patched = False
		for folder in ('win32', 'win32reboot'):
			src = els_path / folder
			if src.is_dir():
				subprocess.run([str(elsFilename), '--no-backup', str(src), str(pso2_bin / 'data' / folder)],
				text=True,
				check=True
			)
			patched = True

		if not patched:
			raise ValueError('Patch files did not download correctly; Nothing was patched.')
		print('Cleaning up...')
		for z in zips:
			os.remove(z)

	def flatpakOverride(self, path):
		heroic = 'com.heroicgameslauncher.hgl'
		if not shutil.which('flatpak') or subprocess.run(['flatpak', 'info', heroic], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
			return
		path = Path(path).expanduser().resolve()
		result = subprocess.run(['flatpak', 'override', '--user', f'--filesystem={path}', heroic])
		if result.returncode == 0:
			print(f'Heroic (flatpak) can now access: ``{path}``')
		else:
			print(f'Warning: could not give Heroic (flatpak) access to {path}; run ``flatpak override --user --filesystem={path} {heroic}`` yourself.')

	def writeErrorLog(self, error):
		now = datetime.now()
		stamp = now.strftime('%Y-%m-%d_%H-%M-%S')
		try:
			self.tweaker_folder.mkdir(parents=True, exist_ok=True)
			logfile = self.tweaker_folder / f'error-{stamp}.log'
		except OSError:
			logfile = Path.cwd() / f'error-{stamp}.log'

		with open(logfile, 'w', encoding='utf-8') as file:
			file.write(f'[{now:%Y-%m-%d}] [{now:%H:%M:%S}]: {str(error) or type(error).__name__}\n\n')
			file.write(f'Command used: {" ".join(sys.argv)}\n\n')
			file.write(''.join(traceback.format_exception(type(error), error, error.__traceback__)))
		return log_file

	def parseArgs(self): # parse commands
		args = self.parser.parse_args()

		try:
			if args.tweaker:
				self.getTweaker(args.tweaker, args.update)
			if args.patcher:
				self.patchDownload(args.patcher[0], args.patcher[1])
		except Exception as e:
			log_file = self.writeErrorLog(e)
			print(f'Something went wrong. The details were saved to {log_file}', file=sys.stderr)
			return

		if args.version:
			self._version(args.version)

if __name__ == "__main__":
	app = PSO2TweakerPy()
	app.parseArgs()
