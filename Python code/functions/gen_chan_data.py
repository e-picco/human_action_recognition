import numpy as np

def gen_chan_data(n_symbols, seed, amp):
    """
    Implements wireless multi-tap non-linear echo channel processing simulations.
    """
    rng = np.random.default_rng(seed)
    systemorder = 10
    p1 = 1
    p2 = 0.036
    p3 = -0.011
    
    total_len = n_symbols + 2 * systemorder
    d = 2 * rng.integers(1, 5, size=total_len) - 5

    inputs = np.zeros(n_symbols)
    targets = np.zeros(n_symbols)

    for n in range(systemorder - 2, n_symbols + systemorder - 2):
        # Channel linear memory modeling 
        q = (0.08 * d[n + 2] - 0.12 * d[n + 1] + d[n] + 0.18 * d[n - 1] - 0.1 * d[n - 2] +
             0.091 * d[n - 3] - 0.05 * d[n - 4] + 0.04 * d[n - 5] + 0.03 * d[n - 6] + 0.01 * d[n - 7])
        
        # Channel nonlinearity execution mapping setup
        inputs[n - 7] = p1 * q + p2 * (q ** 2) + p3 * (q ** 3)
        targets[n - 7] = d[n]

    inputs = inputs * amp
    return inputs, targets