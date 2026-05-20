import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

# Dummy placeholder for train_rc_har
def train_rc_har(reservoir, t_train, reg_term, targets, targets_bin, size_res, n_key_frames, n_tois, toi_last):
    return 0.1, 0.2 / n_tois, 1

data = sio.loadmat('optimum_point_NORM.mat', squeeze_me=True)
p = data['p']
reservoir = data['reservoir']
t_train = data['t_train']
targets = data['targets']
targets_bin = data['targets_bin']

p['reg_term'] = 0.25
err_test_toi = np.zeros(3)

# range(1, 4) produces loops for 1, 2, 3
for i in range(1, 4):
    p['n_tois'] = i
    # Note: fixed MATLAB's index issue here where it used i_run inside loops dynamically
    res_err_train, res_err_test, res_best_toi = train_rc_har(
        reservoir, t_train, p['reg_term'], targets, targets_bin, 
        p['size_res'], p['n_key_frames'], p['n_tois'], p['toi_last']
    )
    err_test_toi[i-1] = res_err_test

# Plotting Accuracy (1 - error)
plt.figure()
plt.plot([1, 2, 3], 1 - err_test_toi)
plt.xlabel('Number of TOIs')
plt.ylabel('Accuracy (best TOI combination)')
plt.show()