import numpy as np
import subprocess
import os

def reset_p_0(p):
    """
    Flashes default initialization state packets straight to hardware device registries.
    """
    wait_4 = np.tile([118, 85], (4, 1))

    # Rebuilding structural base blocks directly
    M = np.array([[112, 0], [112, 1]])
    
    blocks = [
        (21, [0, 0]), (32, [0, 0]), (27, [0, 0]), (26, [0, 0]),
        (28, [0, 0]), (22, [0, 0]), (29, [0, 0]), (33, [0, 0]),
        (36, [0, 0]), (35, [0, 0]), (20, [0, 0])
    ]
    
    for cmd, val in blocks:
        M = np.vstack((M, np.array([[112, cmd], [118, 84], val, [118, 85]]), wait_4))
        
    M = np.vstack((M, np.array([[112, 0]])))

    # Matrix alignment mapping conversions
    M = np.fliplr(M)
    M = np.hstack((M, np.zeros_like(M)))
    M_flattened = M.flatten(order='F').astype(np.uint8)

    with open('param0_tx.bin', 'wb') as f:
        f.write(M_flattened.tobytes())

    if os.name == 'nt':
        status = subprocess.call('cat param0_tx.bin > \\\\.\\xillybus_write_32', shell=True)
        if status == 0:
            print("Parameters 0 sent to fpga")
        else:
            print("Error: parameters 0 not sent to fpga")