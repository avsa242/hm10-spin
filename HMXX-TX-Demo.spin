{
    --------------------------------------------
    Filename: HMXX-TX-Demo.spin
    Author: Jesse Burt
    Description: Simple transmit demo for HM-xx BLE modules
    Copyright (c) 2022
    Started Nov 19, 2022
    Updated Nov 19, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    BLE_RX      = 0
    BLE_TX      = 1
    BLE_BAUD    = 9600
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ble     : "wireless.bluetooth-le.hmxx"

PUB main{}

    setup{}
    ser.newline{}
    ser.strln(string("Text typed into this terminal will be transmitted to the remote device"))

    repeat                                      ' send data typed into the terminal to the
        ble.putchar(ser.getchar{})              '   remote device

PUB setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ble.init(BLE_RX, BLE_TX, BLE_BAUD)
        ser.strln(string("HMxx BLE driver started"))
    else
        ser.strln(string("HMxx BLE driver failed to start - halting"))
        repeat

DAT
{
Copyright 2022 Jesse Burt

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

