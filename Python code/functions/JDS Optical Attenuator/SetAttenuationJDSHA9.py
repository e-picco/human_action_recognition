import time

def SetAttenuationJDSHA9(HA9=None, Attenuation=None, Offset=0):
    """
    Sets the attenuation and offset values on the JDS HA9 optical attenuator.
    Attenuation and Offset values are in dB.
    """
    if HA9 is None:
        print('missing device name')
        return
    elif Attenuation is None:
        print('missing attenuation')
        return

    # Combine the commands into a single string using a semicolon, matching the MATLAB command
    command = f":INP:OFFS {Offset};:INP:ATT {Attenuation}"
    HA9.write(command)
    
    # pause(1) in MATLAB is equivalent to time.sleep(1) in Python
    time.sleep(1)