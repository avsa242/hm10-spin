{
---------------------------------------------------------------------------------------------------
    Filename:       HMXX-TX-Demo.spin
    Description:    Simple transmit demo for HM-xx BLE modules
    Author:         Jesse Burt
    Started:        Nov 19, 2022
    Updated:        Feb 11, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    ble:    "wireless.bluetooth-le.hmxx" | RXPIN=8, TXPIN=9, BLE_BAUD=9600
    ' BLE_BAUD: 4800, 9600, 19200, 38400, 57600, 115200, 230400
    ' IMPORTANT: See data_rate() in the driver for instructions on changing this


PUB main()

    setup()
    ser.newline()
    ser.strln(@"Text typed into this terminal will be transmitted to the remote device")

    repeat                                      ' send data typed into the terminal to the
        ble.putchar(ser.getchar())              '   remote device


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( ble.start() )
        ser.strln(@"HMxx BLE driver started")
    else
        ser.strln(@"HMxx BLE driver failed to start - halting")
        repeat

    { make sure the device is setup to be a peripheral and goes immediately to online/data mode }
    ble.set_role(ble.PERIPHERAL)
    ble.set_work_mode(ble.IMMEDIATE)


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

