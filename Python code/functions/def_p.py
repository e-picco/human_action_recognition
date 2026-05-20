def def_p(p):
    """
    Sets default structural parameter constants for the experiment.
    """
    p['size_res'] = 200

    # exp2fpga:
    p['smp_dly1'] = 5  # sampling delay for ADC 1
    p['smp_dly2'] = p['smp_dly1'] + 2  # sampling delay for ADC 2
    p['trig_level'] = 200  # min signal level required to start acquiring reservoir states
    p['amp_nrn1'] = 5  # amplification of neurons in FPGA
    p['amp_nrn2'] = 5  # amplification of weighted nodes in FPGA

    # fpga2exp:
    p['n_inputs'] = 10  # max is 8192
    p['amp_dac'] = 0  # it was 0. Set 6 for debug
    p['wts_dly'] = p['smp_dly2'] + 5

    # fpga2PCI
    max_sampled_data = p['size_res'] * p['n_inputs']
    p['max_sampled_data'] = int(max_sampled_data / (2**10))  # ceil or int division representation

    # xilldemo: fake switches {0-x, 1-xy, 4-xw, 7-xwy}
    mode = p.get('fpga_data_mode', 'x')
    if mode == 'x':
        p['fake_sw_b'] = 0
    elif mode == 'xy':
        p['fake_sw_b'] = 1
    elif mode == 'xw':
        p['fake_sw_b'] = 4
    elif mode == 'xwy':
        p['fake_sw_b'] = 7

    # fmc151
    p['i_delay_clk'] = 0
    p['i_delay_b'] = 30
    p['i_delay_a'] = 30
    p['idelay'] = p['i_delay_clk'] * (2**10) + p['i_delay_b'] * (2**5) + p['i_delay_a']

    return p