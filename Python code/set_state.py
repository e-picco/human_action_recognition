import numpy as np
import subprocess
import os

M = np.array([[112, 0]], dtype=np.uint8)

M = np.fliplr(M)

M = np.hstack((M, np.zeros_like(M)))

M_flattened = M.flatten(order='F')

with open('state_tx.bin', 'wb') as f:
    f.write(M_flattened.tobytes())

xillybus_device_path = r'\\.\xillybus_write_32'

try:
    if os.name == 'nt':  
        with open('state_tx.bin', 'rb') as infile:
            with open(xillybus_device_path, 'wb') as outfile:
                outfile.write(infile.read())
        print("State successfully sent to FPGA device stream loop interface context handler endpoint.")
    else:
        print("Device connection aborted: This platform environment architecture context requires a local Windows OS base node setup target.")
except Exception as e:
    print(f"Error transferring tracking signal status info packet header stream: {e}")