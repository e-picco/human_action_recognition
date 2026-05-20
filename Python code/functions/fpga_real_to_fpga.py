import numpy as np

def fpga_real_to_fpga(array, n_bits):
    """
    Converts reals to an explicit 2N layout of unsigned byte array structures.
    """
    # Enforce flat array context processing
    arr = np.atleast_1d(array).flatten()
    
    a = np.round(arr * (2 ** n_bits)).astype(np.int32)
    output_debug = np.copy(a)
    
    # Convert negative signed integers to unsigned 16-bit space representation
    negative_mask = a < 0
    a[negative_mask] = (2 ** 16) + a[negative_mask] - 1
    
    # Byte splitting
    high_bytes = np.floor(a / (2 ** 8)).astype(np.uint8)
    low_bytes = (a % (2 ** 8)).astype(np.uint8)
    
    # Emulate the MATLAB `reshape(bytes', 2*length(array), 1)'` interleaving behavior
    output_fpga = np.empty(2 * len(arr), dtype=np.uint8)
    output_fpga[0::2] = high_bytes
    output_fpga[1::2] = low_bytes
    
    return output_fpga, output_debug