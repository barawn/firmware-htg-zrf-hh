from pynq import Overlay
import time
import os
import subprocess
import htgrfclk

class htgADC(Overlay):
    def __init__(self, bitfile_name='htg_zrf_hh_top.bit', **kwargs):
        # Run lsmod command to get the loaded modules list
        output = subprocess.check_output(['lsmod'])
        # Check if "zocl" is present in the output
        if b'zocl' in output:
            # If present, remove the module using rmmod command
            rmmod_output = subprocess.run(['rmmod', 'zocl'])
            # Check return code
            assert rmmod_output.returncode == 0, "Could not restart zocl. Please Shutdown All Kernels and then restart"
            # If successful, load the module using modprobe command
            modprobe_output = subprocess.run(['modprobe', 'zocl'])
            assert modprobe_output.returncode == 0, "Could not restart zocl. It did not restart as expected"
        else:
            modprobe_output = subprocess.run(['modprobe', 'zocl'])
            # Check return code
            assert modprobe_output.returncode == 0, "Could not restart ZOCL!"

        # initialize the clocks. The clocks here generate 24 MHz to the LMXs and to the FPGA
        # and 1.5 MHz to SYSREF and LMX syncs.
        # The LMXs then generate 600 MHz to the RFSoC which generates 3 GHz for sampling.
        htgrfclk.set_rf_clks(lmkfn='LMK_HTGADC.txt',lmxfn='LMX_HTGADC.txt')            
        super().__init__(resolve_binary_path(bitfile_name), **kwargs)

def resolve_binary_path(bitfile_name):
    """ this helper function is necessary to locate the bit file during overlay loading"""
    if os.path.isfile(bitfile_name):
        return bitfile_name
    elif os.path.isfile(os.path.join(MODULE_PATH, bitfile_name)):
        return os.path.join(MODULE_PATH, bitfile_name)
    else:
        raise FileNotFoundError(f'Cannot find {bitfile_name}.')
    
