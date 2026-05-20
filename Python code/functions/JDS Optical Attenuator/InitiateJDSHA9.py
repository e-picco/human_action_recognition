import pyvisa

def InitiateJDSHA9():
    """
    Initializes communication with the JDS HA9 Optical Attenuator via GPIB,
    queries its identification, and turns the output ON.
    """
    # Initialize the VISA Resource Manager
    rm = pyvisa.ResourceManager()
    
    # Open connection to the device using its VISA resource name
    try:
        HA9 = rm.open_resource('GPIB0::10::INSTR')
    except Exception as e:
        print(f"Could not connect to instrument: {e}")
        return None

    # Query instrument identification (*idn?)
    data = HA9.query('*idn?')
    
    # strip() removes trailing newline characters, similar to data(1:end-1) in MATLAB
    print(f"Optical Attenuator: {data.strip()}")

    # Turn output ON
    HA9.write('OUTP ON ')

    return HA9