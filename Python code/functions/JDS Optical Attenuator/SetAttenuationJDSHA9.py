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

    command = f":INP:OFFS {Offset};:INP:ATT {Attenuation}"
    HA9.write(command)
    
    time.sleep(1)