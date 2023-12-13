# Installing Vivado

This project was undertaken using Vivado 2023.2 in project mode, using Linux Mint 21.1 Cinnamon.

Download the Vivado installer for the latest version, mark it as executable, and run it:

```bash
sudo apt install libncurses5 libncurses5-dev libncursesw5-dev libtinfo5
chmod u+x FPGAs_AdaptiveSoCs_Unified_2023.2_1013_2256_Lin64.bin
./FPGAs_AdaptiveSoCs_Unified_2023.2_1013_2256_Lin64.bin
```

Ignore the warning about unsupported OS if you get it. Put in your login details, and progress to install Vivado. Choose to install Vivado ML Standard. Choose the devices you want to install (at least Artix-7), and progress to choose an install location. By installing less devices, the download size and disk space requirement will be minimised. Pick `$HOME/tools/Xilinx` and begin the download/install.

Once the installation is complete, source the `settings64.sh` in the Xilinx directory. You can do this by modifying the environment variables in `settings.sh` (in this repository) and then running `. settings.sh` (note the dot).

To install the board support files, clone the following repository to some location:

```bash
git clone git@github.com:Digilent/vivado-boards.git
```

Copy the folder `new/board_files` to `$HOME/tools/Xilinx/Vivado/2023.2/data/boards/board_files` and restart Vivado. Now the board support packages should be present when creating a new project.

The project is tested on the Arty A7 (containing the Artix-A7 35T FPGA) development board. In project mode, the BSP is called `Arty A7-35`, file revision 1.1.
