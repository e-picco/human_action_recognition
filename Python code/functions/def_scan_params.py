import numpy as np

def def_scan_params(hp):
    """
    Generates permutation lists for grid scans mirroring MATLAB's loop matrix configurations.
    """
    scan_params = {
        'lbls': ['In', 'MZb', 'Fdb'],
        'vals': [hp.inp_vals, hp.mzb_vals, hp.fdb_vals],
        'vars': ['hp.inp', 'hp.mzb', 'hp.fdb']
    }
    scan_params['lens'] = [len(v) for v in scan_params['vals']]

    # Generate permutations list length
    n_runs = int(np.prod(scan_params['lens']))
    n_scan_params = len(scan_params['lbls'])
    scan_list = np.zeros((n_scan_params, n_runs))

    for i in range(n_scan_params):
        # Python ranges are 0-indexed: 
        # scan_params['lens'][0:i] corresponds to 1:i-1 in 1-based MATLAB
        rep = int(np.prod(scan_params['lens'][0:i])) if i > 0 else 1
        cyc = int(np.prod(scan_params['lens'][i+1:])) if (i + 1) < n_scan_params else 1
        
        # Tile array items matching repmat structure
        arr_val = np.array(scan_params['vals'][i])
        # Repeat elements horizontally, tile the whole thing vertically
        repeated = np.repeat(arr_val, rep)
        tiled = np.tile(repeated, cyc)
        
        scan_list[i, :] = tiled

    return scan_params, scan_list, n_runs