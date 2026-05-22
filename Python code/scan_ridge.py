import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

def train_rc_har(reservoir, t_train, reg_term, targets, targets_bin, size_res, n_key_frames, n_tois, toi_last):
    return 0.5 * (reg_term**0.1), 0.6 * (reg_term**0.12), 1

# Load variables 
data = sio.loadmat('optimum_point_NORM.mat', squeeze_me=True)
p = data['p']
reservoir = data['reservoir']
t_train = data['t_train']
targets = data['targets']
targets_bin = data['targets_bin']

reg_term = np.logspace(-3, 1, 1000)
res_err_train = np.zeros(len(reg_term))
res_err_test = np.zeros(len(reg_term))
res_best_toi = np.zeros(len(reg_term))

for i_run in range(len(reg_term)):
    p['reg_term'] = reg_term[i_run]
    res_err_train[i_run], res_err_test[i_run], res_best_toi[i_run] = train_rc_har(
        reservoir, t_train, p['reg_term'], targets, targets_bin, 
        p['size_res'], p['n_key_frames'], p['n_tois'], p['toi_last']
    )

min_val = np.min(res_err_test)
min_idx = np.argmin(res_err_test)

print(f"Minimum test error (first occurrence!!): {min_val:.2e}, @ ridge param = {reg_term[min_idx]:.2e}.")

# Plotting
plt.figure()
plt.plot(reg_term, res_err_train, 'b', label='Train Error')
plt.plot(reg_term, res_err_test, 'r', label='Test Error')
plt.ylabel('Train and Test error')
plt.xlabel('Ridge parameter')
plt.legend()
plt.show()