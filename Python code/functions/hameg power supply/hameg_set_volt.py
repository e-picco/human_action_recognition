def hameg_set_volt(obj, channel, voltage):
    """
    Sets specific power output values onto physical HAMEG instrumentation channels.
    """
    command_sel = f"INST:NSEL {channel}\n"
    command_volt = f"VOLT {voltage}\n"
    
    obj.write(command_sel.encode('utf-8'))
    obj.write(command_volt.encode('utf-8'))