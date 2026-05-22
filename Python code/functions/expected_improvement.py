import numpy as np
from scipy.stats import norm

def expected_improvement(x_grid, gp_model, f_best):
    """
    Computes Gaussian Process Bayesian Optimization parameters using scipy stats packages.
    """
    margin = 0
    

    f_mean, y_sd = gp_model.predict(x_grid, return_std=True)
    
    sigma = getattr(gp_model, 'Sigma', 0.0)
    
    f_sd = np.sqrt(np.maximum(0.0, (y_sd ** 2) - (sigma ** 2)))
    
    with np.errstate(divide='ignore', invalid='ignore'):
        z_x = (f_best - margin - f_mean) / f_sd
        z_x = np.nan_to_num(z_x)
        
    cdf_z = norm.cdf(z_x, 0, 1)
    pdf_z = norm.pdf(z_x, 0, 1)
    
    EI = f_sd * (z_x * cdf_z + pdf_z)
    
    return EI, f_mean, f_sd