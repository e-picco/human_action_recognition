import os
import time
import subprocess
import numpy as np

def send_p(p): pass  

def fpga_run(p):
    """
    Executes binary command shell pipelining for local system operations.
    """
    mode = p.get('fpga_data_mode', 'x')
    if mode == 'x':
        n_nodes = p['size_res']
    elif mode == 'xy':
        n_nodes = p['size_res'] + 1
    elif mode == 'xw':
        n_nodes = 2 * p['size_res']
    elif mode == 'xwy':
        n_nodes = 2 * p['size_res'] + 1

    data = np.array([], dtype=np.uint8)
    
    while len(data) == 0:
        if os.name == 'nt':
            subprocess.Popen('cat \\\\.\\xillybus_read_32 > data_rx.bin', shell=True)
        
        wait_4 = np.tile([118, 85], (4, 1))
        M = np.array([
            [112, 0],
            [112, 1],
            [112, 35],
            [118, 84],
            [0, p['fake_sw_b']],
            [118, 85]
        ])
        M = np.vstack((M, wait_4, np.array([[112, 2]])))
        
        M = np.fliplr(M)
        M = np.hstack((M, np.zeros_like(M)))
        M_flattened = M.flatten(order='F').astype(np.uint8)
        
        with open('statetrain_tx.bin', 'wb') as f:
            f.write(M_flattened.tobytes())
            
        if os.name == 'nt':
            status = subprocess.call('cat statetrain_tx.bin > \\\\.\\xillybus_write_32', shell=True)
            if status != 0:
                print("Error: Train phase command not sent")

        time.sleep(0.1)
        
        if os.path.exists('data_rx.bin') and os.path.getsize('data_rx.bin') > 0:
            with open('data_rx.bin', 'rb') as f:
                data = np.frombuffer(f.read(), dtype=np.uint8)
        
        if os.name == 'nt':
            subprocess.call('TASKKILL /F /IM cmd.exe /T 1>nul 2>&1', shell=True)
            
        if len(data) == 0:
            print("Warning: data empty, retrying")
            send_p(p)

    data_2 = data.reshape((4, len(data) // 4), order='F')
    data_3 = data_2[0:2, :]
    data_4 = np.flipud(data_3)
    
    data_5 = data_4[0, :].astype(np.int32) * (2 ** 8) + data_4[1, :].astype(np.int32)
    high_vals = data_5 > (2 ** 15)
    data_5[high_vals] = -((2 ** 16) - data_5[high_vals])
    
    data_6 = data_5[0 : n_nodes * p['n_inputs']] / (2 ** 15)
    
    reservoir = data_6.reshape((p['size_res'], p['n_inputs']), order='F')
    
    outputs = np.full((1, p['n_inputs']), np.nan)
    weighted_states = np.full((p['size_res'], p['n_inputs']), np.nan)
    
    M_idle = np.array([[112, 0]], dtype=np.uint8)
    M_idle = np.fliplr(M_idle)
    M_idle = np.hstack((M_idle, np.zeros_like(M_idle)))
    M_idle_flat = M_idle.flatten(order='F').astype(np.uint8)
    
    with open('stateidle_tx.bin', 'wb') as f:
        f.write(M_idle_flat.tobytes())
        
    if os.name == 'nt':
        status = subprocess.call('cat stateidle_tx.bin > \\\\.\\xillybus_write_32', shell=True)
        if status != 0:
            print("Error: Idle phase command not sent")
            
    return reservoir, outputs, weighted_states