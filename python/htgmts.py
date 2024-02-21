from pynq import Overlay, GPIO, MMIO
import time
import os
import subprocess
import htgrfclk
import numpy as np
import xrfdc

class htgMTS(Overlay):
    def __init__(self, bitfile_name='htg_zrf_hh_mts.bit', reload=False, **kwargs):
        # Run lsmod command to get the loaded modules list
        output = subprocess.check_output(['lsmod'])
        # Check if "zocl" is present in the output
        if b'zocl' in output and reload == False:
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

        self.gpio_trig = GPIO(GPIO.get_gpio_pin(0), 'out')
        self.gpio_done = [ GPIO(GPIO.get_gpio_pin(8), 'in'),
                           GPIO(GPIO.get_gpio_pin(9), 'in'),
                           GPIO(GPIO.get_gpio_pin(10), 'in'),
                           GPIO(GPIO.get_gpio_pin(11), 'in'),
                           GPIO(GPIO.get_gpio_pin(12), 'in'),
                           GPIO(GPIO.get_gpio_pin(13), 'in'),
                           GPIO(GPIO.get_gpio_pin(14), 'in'),
                           GPIO(GPIO.get_gpio_pin(15), 'in') ]
        
        super().__init__(resolve_binary_path(bitfile_name), **kwargs)

        self.xrfdc = self.usp_rf_data_converter_0
        self.dbg = self.debug_bridge_0
        self.adcmem = [ self.memdict_to_view("adc_cap_0/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_1/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_2/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_3/axi_bram_ctrl_0") ]
        
    def memdict_to_view(self, ip, dtype='int16'):
        """ Configures access to internal memory via MMIO"""
        baseAddress = self.mem_dict[ip]["phys_addr"]
        mem_range = self.mem_dict[ip]["addr_range"]
        ipmmio = MMIO(baseAddress, mem_range)
        # this is WRONG how the hell did this work
        #return ipmmio.array[0:ipmmio.length].view(dtype)
        return ipmmio.array[0:(ipmmio.length >> 2)].view(dtype)
    
    # pointless
    def verify_clock_tree(self):
        return True

    def sync_tiles(self, dacTarget=-1, adcTarget=-1):
	# try with only ADCs
        self.xrfdc.mts_adc_config.Tiles = 0b1111
        self.xrfdc.mts_adc_config.SysRef_Enable = 1
        self.xrfdc.mts_adc_config.Target_Latency = -1
        self.xrfdc.mts_adc()

    def init_tile_sync(self):
        # Reset the engine, I guess. Start with tile 0 only
        self.xrfdc.dac_tiles[0].CustomStartUp(0, 6)
	# try only running for dac tile 0 and shutting it down to state 6
        self.xrfdc.mts_dac_config.Tiles = 0b0000
        self.xrfdc.mts_dac_config.SysRef_Enable = 1
        self.xrfdc.mts_dac_config.Target_Latency = -1
        self.xrfdc.mts_adc_config.Tiles = 0b0001
        self.xrfdc.mts_adc_config.SysRef_Enable = 1
        self.xrfdc.mts_adc_config.Target_Latency = -1
        # do the stuff to turn it on
        self.xrfdc.mts_dac()
        self.xrfdc.mts_adc()
        # reset the desired active tiles, which for us is fixed
        # use all ADC tiles. Turn off/on FIFOs
        self.xrfdc.adc_tiles[0].SetupFIFO(0)
        self.xrfdc.adc_tiles[1].SetupFIFO(0)
        self.xrfdc.adc_tiles[2].SetupFIFO(0)
        self.xrfdc.adc_tiles[3].SetupFIFO(0)
        self.xrfdc.adc_tiles[0].SetupFIFO(1)
        self.xrfdc.adc_tiles[1].SetupFIFO(1)
        self.xrfdc.adc_tiles[2].SetupFIFO(1)
        self.xrfdc.adc_tiles[3].SetupFIFO(1)
        
        
    # the default here is 3 to match the MTS workbooks
    def internal_capture(self, buf, num_chan=3):
        if not np.issubdtype(buf.dtype, np.int16):
            raise Exception("buffer not defined or np.int16")
        if not buf.shape[0] == num_chan:
            raise Exception("buffer must be of shape(num_chan, N)!")
        
        self.gpio_trig.write(1)
        self.gpio_trig.write(0)
        for i in range(num_chan):
            buf[i] = np.copy(self.adcmem[i][0:len(buf[i])])
            
        
def resolve_binary_path(bitfile_name):
    """ this helper function is necessary to locate the bit file during overlay loading"""
    if os.path.isfile(bitfile_name):
        return bitfile_name
    elif os.path.isfile(os.path.join(MODULE_PATH, bitfile_name)):
        return os.path.join(MODULE_PATH, bitfile_name)
    else:
        raise FileNotFoundError(f'Cannot find {bitfile_name}.')
    

