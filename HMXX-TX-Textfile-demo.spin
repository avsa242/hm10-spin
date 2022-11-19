{
    --------------------------------------------
    Filename: HMXX-TX-Demo.spin
    Author: Jesse Burt
    Description: Simple transmit demo for HMXX BLE modules
    Copyright (c) 2022
    Started Mar 28, 2021
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

    ' 4800, 9600, 19200, 38400, 57600, 115200, 230400
    ' See set_data_rate() in driver for instructions on changing this
    BLE_BAUD    = 9600
' --

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ble     : "wireless.bluetooth-le.hmxx"

PUB main{} | i, text_len

    setup{}
    text_len := strsize(@text)-1                ' get length/last char of text
    i := 0
    repeat                                      ' continuously send text char by char
        ble.putchar(byte[@text][i++])
        if (i > text_len)                       ' send notification if the end of the text
            i := 0                              '   is reached
            repeat 3
                ble.newline{}
            ble.strln(string("*** DONE ***"))
            repeat 3
                ble.newline{}
            time.sleep(2)
'        time.msleep(10)                         ' optional inter-char delay

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ble.init(BLE_RX, BLE_TX, BLE_BAUD)
        ser.strln(string("HMxx BLE driver started"))
    else
        ser.strln(string("HMxx BLE driver failed to start - halting"))
        repeat

    ble.set_work_mode(ble#IMMEDIATE)
    ble.set_role(ble#PERIPHERAL)

DAT

    { text file to transmit }
    text        file "lincoln.txt"
    EOT         byte 0                          ' terminate string

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

