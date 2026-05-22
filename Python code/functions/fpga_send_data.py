import numpy as np
import subprocess
import os
from fpga_real_to_fpga import fpga_real_to_fpga

def fpga_send_data(pattern, mask):
    """
    Encodes array buffers and pushes payload sequence straight onto Xillybus handle descriptors.
    """
    pat_fpga, _ = fpga_real_to_fpga(pattern, 15)
    pat_fpga = pat_fpga.reshape((2, len(pat_fpga) // 2), order='F').T
    
    msk_fpga, _ = fpga_real_to_fpga(mask, 15)
    msk_fpga = msk_fpga.reshape((2, len(msk_fpga) // 2), order='F').T

    M = np.array([
        [112, 0],
        [112, 1]
    ])
    
    p_header = np.array([[112, 17], [118, 84]])
    p_footer = np.array([[118, 85]])
    M = np.vstack((M, p_header, pat_fpga, p_footer))
    
    m_header = np.array([[112, 18], [118, 84]])
    m_footer = np.array([[118, 85], [112, 0]])
    M = np.vstack((M, m_header, msk_fpga, m_footer))

    M = np.fliplr(M)
    M = np.hstack((M, np.zeros_like(M)))
    M_flattened = M.flatten(order='F').astype(np.uint8)

    with open('data_tx.bin', 'wb') as f:
        f.write(M_flattened.tobytes())

    if os.name == 'nt':
        status = subprocess.call('cat data_tx.bin > \\\\.\\xillybus_write_32', shell=True)
        if status == 1:
            print("Error: Data not sent to fpga")