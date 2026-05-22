import numpy as np

def eval_rc(p, d):
    """
    Evaluates reservoir metrics and targets matching matrix math boundaries.
    """
    warmup = int(p['n_warmup'])
    n_inputs = int(p['n_inputs'])
    
    D = d.d[warmup:n_inputs]
    
    y = d.w @ d.x
    y_mchd = (np.round(y / 2.0 + 1.5) - 1.5) * 2.0
    Y = y_mchd[warmup:n_inputs]
    
    err = np.sum(Y != D) / (n_inputs - warmup)

    d.idx_err = np.where(y_mchd[warmup:n_inputs] != d.d[warmup:n_inputs])[0]
    d.D = D
    d.Y = Y

    return d, err