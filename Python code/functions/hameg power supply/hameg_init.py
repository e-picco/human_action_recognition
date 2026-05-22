import serial

def hameg_init(port):
    """
    Initialises connection parameters mapping to HAMEG power management architectures.
    """
    obj = serial.Serial(port, baudrate=9600, timeout=1) 
    
    obj.write(b'*idn?\n')
    device_id = obj.readline().decode('utf-8').strip()
    
    print(f"Power Source: {device_id}.")
    return obj