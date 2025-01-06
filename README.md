# pso2tricks.py
Helps GNU/Linux users install the PSO2 Tweaker to play the Japanese version.

## Requirements
This only requires the requests python library, everything else is part of python3's normal stack.
The shell script is highly optional, but it automates the requirements for people. It requires basic user permissions and will never need sudo.

## Usage
```
pso2tricks.py [-h] [-v] [-w] [--tweaker [-up]] [--patcher <ngs|both> <path to pso2_bin>]

options:
  -h, --help     show this help message and exit
  -w, --wine     Install GloriousEggroll's wine-ge-proton. (default: False)
  -t, --tweaker  Downloads the PSO2 Tweaker. (default: False)
  -up            Updates the PSO2 Tweaker if previously downloaded. (default: False)
  -p, --patcher  Downloads & applies the English fan patches. (default: None)
  -v             Displays the version. (default: False)

```

## Options
### --wine
Searches for a `wine-lutris-GE-Proton*-x86_64.tar.xz` package in the same directory as pso2tricks.py and automatically extracts it into Bottles.

### --tweaker [-up]
Creates a folder called `pso2_files` in your home folder and downloads the "PSO2 Tweaker" into `~/pso2_files`. The `-up` flag will attempt to download a new copy of the Tweaker and delete your old one. (If you have a better solution, feel free to suggest it)

## --patcher <ngs|both> <path_to_pso2_bin>
Downloads a pre-compiled version of [pso2-modpatcher](https://github.com/HybridEidolon/pso2-modpatcher) (used with permission) as well as the latest English patches.
You can compile your own version using cargo-install.

Example usage: ``python pso2tricks.py --patcher ngs ~/phantasystaronline2/pso2_bin``

