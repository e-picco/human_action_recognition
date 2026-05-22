import pyvisa

def InitiateJDSHA9():
    """
    Initializes communication with the JDS HA9 Optical Attenuator via GPIB,
    queries its identification, and turns the output ON.
    """
    rm = pyvisa.ResourceManager()
    
    try:
        HA9 = rm.open_resource('GPIB0::10::INSTR')
    except Exception as e:
        print(f"Could not connect to instrument: {e}")
        return None

    data = HA9.query('*idn?')
    
    print(f"Optical Attenuator: {data.strip()}")

    # Turn ON
    HA9.write('OUTP ON ')

    return HA9