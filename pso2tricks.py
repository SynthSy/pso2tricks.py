# /// script
# dependencies = [
#   "requests"
# ]
# ///

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
		self.tweaker_folder = f'{Path.home()}/pso2_files' # sets the tweaker folder

	def _configArgs(self): # define commands
		self.parser.add_argument("-t", "--tweaker", action="store_true", help="Downloads the PSO2 Tweaker.")
		self.parser.add_argument("-up", action='store_true', dest="update", help="Updates the PSO2 Tweaker if previously downloaded.")	
		self.parser.add_argument("-p","--patcher", nargs=2, metavar=("patch", "path"), help="Downloads & applies the English fan patches. ")
		self.parser.add_argument("-v", dest="version", action='store_true', help="Displays the version.")

	def _version(self, info):
		if info is True:
			version = '1.6'
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
		try:
			response = requests.get(url, stream=True)
			response.raise_for_status()

			with open(filename, 'wb') as file:
				for chunk in response.iter_content(chunk_size=8192):
					if chunk:
						file.write(chunk)
			print(f"File successfully downloaded: {filename}")
		except requests.exceptions.RequestException as e:
			print(f"Failed to download file: {e}")

	def getTweaker(self, tweaker, update): # download the tweaker, will also set flatpak override if allowed
		# tweaker exe origin
		tweakerUrl = 'https://github.com/Aida-Enna/PSO2TweakerReleases/blob/master/6.2.1.9/PSO2%20Tweaker.exe?raw=true'
		pattern = re.compile(r"PSO2 Tweaker\.exe") # simple "PSO2 Tweaker.exe" regex
		tweakerExe = self.regexPath(self.tweaker_folder, pattern)
		if tweaker is True:
			# check if folder exists
			if os.path.exists(f'{self.tweaker_folder}') or os.getcwd() == self.tweaker_folder: 
				pass
			elif os.getcwd() == self.homeDir:
				#os.system(f'mkdir {self.tweaker_folder}')
				Path(self.tweaker_folder).mkdir(parents=False, exist_ok=False)
			else:
				pass

			if (update is True and os.path.exists(f'./{tweakerExe}')) or os.path.exists(f'./{tweakerExe}'):
				print('Updating the PSO2 Tweaker from https://arks-layer.com...')
				call(f'cd {self.tweaker_folder} && rm "PSO2 Tweaker.exe"', shell=True)
				path = f'{self.tweaker_folder}/{tweakerExe}'
				os.remove(path)

			else:
				print('Downloading the PSO2 Tweaker from https://arks-layer.com...')

			filepath = f'{self.tweaker_folder}/PSO2 Tweaker.exe'
			self.downloadFile(tweakerUrl, filepath)

	def patchDownload(self, patch, pso2_bin): # download patches if the tweaker did not
		patcher = 'https://synthsy.space/json/els_linux' # https://github.com/HybridEidolon/pso2-modpatcher || I compiled a binary using ubuntu 20.04 then uploaded it.
		ngs_en_patch = 'https://cdn.arks-layer.com/TweakerTemp/Latest_Patch_EN_Reboot.zip'
		classic_en_patch = 'https://cdn.arks-layer.com/TweakerTemp/Latest_Patch_EN_win32.zip'
		els_path = f'{self.tweaker_folder}/ELS'

		print('Deleting old patch files before downloading new ones...')
		if os.path.exists(f'{self.tweaker_folder}/ELS'):
			shutil.rmtree(els_path)
			Path(els_path).mkdir(parents=False, exist_ok=False)
		else:
			Path(els_path).mkdir(parents=False, exist_ok=False)

		print('Downloading required files...')
		elsFilename = f'{self.tweaker_folder}/els_linux'
		self.downloadFile(patcher, elsFilename)
		os.chmod(elsFilename, 0o755) # required or we can't execute the command
		if str(patch) == 'ngs':
			reboot_zip = f'{self.tweaker_folder}/Latest_Patch_EN_Reboot.zip'
			self.downloadFile(ngs_en_patch, reboot_zip)
			
			with zipfile.ZipFile(reboot_zip, "r") as zip_ref:
				zip_ref.extractall(f'{self.tweaker_folder}/ELS')
			win32_dir = f'{self.tweaker_folder}/ELS/win32'
			win32reboot_dir = f'{self.tweaker_folder}/ELS/win32reboot'
			
			result = subprocess.run(['./els_linux', '--no-backup', '-v', win32_dir, f'{pso2_bin}/data/win32'],
				cwd=self.tweaker_folder,
				check=True
			)
			reboot = subprocess.run(['./els_linux', '--no-backup', '-v', win32reboot_dir, f'{pso2_bin}/data/win32reboot'],
				cwd=self.tweaker_folder,
				check=True
			)
			
			print('Cleaning up...')
			os.remove(reboot_zip)
			print('done')

		if str(patch) == 'both':
			reboot_zip = f'{self.tweaker_folder}/Latest_Patch_EN_Reboot.zip'
			win32_zip = f'{self.tweaker_folder}/Latest_Patch_EN_win32.zip'
			self.downloadFile(classic_en_patch, win32_zip)
			self.downloadFile(ngs_en_patch, reboot_zip)
			with zipfile.ZipFile(win32_zip, "r") as win32:
				win32.extractall(f'{self.tweaker_folder}/ELS')
			with zipfile.ZipFile(reboot_zip, "r") as reboot:
				reboot.extractall(f'{self.tweaker_folder}/ELS')
			result = subprocess.run(['./els_linux', '--no-backup', '-v', win32_dir, f'{pso2_bin}/data/win32'],
				cwd=self.tweaker_folder,
				check=True
			)
			reboot = subprocess.run(['./els_linux', '--no-backup', '-v', win32reboot_dir, f'{pso2_bin}/data/win32reboot'],
				cwd=self.tweaker_folder,
				check=True
			)
			print('Cleaning up...')
			os.remove(reboot_zip)
			os.remove(win32_zip)
			print('done')

	def parseArgs(self): # parse commands
		args = self.parser.parse_args()

		if args.tweaker:
			self.getTweaker(args.tweaker, args.update)

		if args.patcher:
			self.patchDownload(args.patcher[0], args.patcher[1])

		if args.version:
			self._version(args.version)

if __name__ == "__main__":
	app = PSO2TweakerPy()
	app.parseArgs()
