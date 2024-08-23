{
----------------------------------------------------------------------------------------------------
    Filename:       HMXX-TX-Textfile-demo.spin
    Description:    HMxx BLE: Demo transmitting a text file to a remote node
    Author:         Jesse Burt
    Started:        Mar 28, 2021
    Updated:        Feb 11, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
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


PUB main() | i, text_len

    setup()
    text_len := strsize(@text)-1                ' get length/last char of text
    i := 0
    repeat                                      ' continuously send text char by char
        ble.putchar(byte[@text][i++])
        if ( i > text_len )                     ' send notification if the end of the text
            i := 0                              '   is reached
            repeat 3
                ble.newline()
            ble.strln(@"*** DONE ***")
            repeat 3
                ble.newline()
            time.sleep(2)
'        time.msleep(10)                         ' optional inter-char delay


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

    { text file to transmit }
    text        file "lincoln.txt"
    EOT         byte 0                          ' terminate string


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

