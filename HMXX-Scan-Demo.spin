{
    --------------------------------------------
    Filename: HMXX-Scan-Demo.spin
    Author: Jesse Burt
    Description: Scan demo for HMXX BLE modules
        * set module to central role
        * scan/display all peripheral nodes found
    Copyright (c) 2022
    Started Apr 9, 2022
    Updated Apr 9, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    BLE_RX      = 8
    BLE_TX      = 9

    ' 4800, 9600, 19200, 38400, 57600, 115200, 230400
    ' See DataRate() in driver for instructions on changing this
    BLE_BAUD    = 9600
' --

    MAX_ENTRIES = 16

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ble     : "wireless.bluetooth-le.hmxx.uart"
    str     : "string"
    int     : "string.integer"

VAR

    byte _rxbuff[256]
    byte _tmp[32+1]

PUB Main{} | role, entry, i, ch

    setup{}

    ble.role(ble#CENTRAL)
    ble.workmode(1)
    ble.scantime(3)
    ble.resolvenames(TRUE)
    role := ble.role(-2)
    ser.printf1(@"Device name: %s\n", ble.nodename(-2))
    ser.printf1(@"Version: %d\n", ble.version{})
    ser.printf1(@"Scan time: %dsecs\n", ble.scantime(-2))
    ser.printf1(@"Workmode: %d\n", ble.workmode(-2))
    ser.str(@"Role: ")

    if (role == ble#PERIPH)
        ser.strln(@"Peripheral")
    elseif (role == ble#CENTRAL)
        ser.strln(@"Central")

    ser.strln(@"Scanning...")
    ble.str(@"AT+DISC?")
    time.sleep(1)
    ble.str(@"AT+DISC?")    'XXX get this to work without sending twice?

    entry := 0
    repeat
        ble.rdstr_max(@_tmp, 8)
        if (str.match(@_tmp, string("OK+DISCS")))
            ser.strln(@"SCAN START")
        elseif (str.match(@_tmp, string("OK+DIS0:")))
            ble.rdstr_max(@_tmp, 12)
            ser.printf1(@"Entry %d: ", entry)
            repeat i from 0 to 11
                ser.char(_tmp[i])
            ser.char(" ")
            entry++
        elseif (str.match(@_tmp, string("OK+NAME:")))
            i := 0
            repeat
                ch := ble.charin{}
                _tmp[i++] := ch
            until (ch == 10)
            _tmp[--i] := 0                      ' erase the LF/CR
            _tmp[--i] := 0
            ser.strln(@_tmp)
        elseif (str.match(@_tmp, string("OK+DISCE")))
            quit

    ser.strln(@"SCAN END")

    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ble.init(BLE_RX, BLE_TX, BLE_BAUD)
        ser.strln(string("HMxx BLE driver started"))
    else
        ser.strln(string("HMxx BLE driver failed to start - halting"))
        repeat

{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
