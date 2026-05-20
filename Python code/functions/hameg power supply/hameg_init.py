import serial

def hameg_init(port):
    """
    Initialises connection parameters mapping to HAMEG power management architectures.
    """
    # Create device object context interface mapping to default baudrates
    obj = serial.Serial(port, baudrate=9600, timeout=1) 
    
    # Query identification verification command tracking matches
    obj.write(b'*idn?\n')
    device_id = obj.readline().decode('utf-8').strip()
    
    print(f"Power Source: {device_id}.")
    return obj