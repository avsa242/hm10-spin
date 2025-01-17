{
----------------------------------------------------------------------------------------------------
    Filename:       HMXX-Scan-Demo.spin
    Description:    Remote node scan demo for HMXX BLE modules
    Author:         Jesse Burt
    Started:        Apr 9, 2022
    Updated:        Feb 11, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode        = cfg._clkmode
    _xinfreq        = cfg._xinfreq

    MAX_ENTRIES     = 16                        ' max number of remote nodes to store
    MAX_NAME_LEN    = 32+1                      ' 32 chars+NUL terminator
    MAC_ADDR_LEN    = 6


OBJ

    cfg:    "boardcfg.flip"
    str:    "string"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    ble:    "wireless.bluetooth-le.hmxx" | RXPIN=8, TXPIN=9, BLE_BAUD=9600
    ' BLE_BAUD: 4800, 9600, 19200, 38400, 57600, 115200, 230400
    ' IMPORTANT: See data_rate() in the driver for instructions on changing this


VAR

    byte _tmp[MAX_NAME_LEN]                     ' scratch buffer
    byte _mac[MAC_ADDR_LEN*MAX_ENTRIES]         ' MAC address of remote nodes
    byte _name[MAX_NAME_LEN*MAX_ENTRIES]        ' name of remote nodes


PUB main() | entry, i

    setup()

    ble.set_scan_time(3)                        ' seconds (HM10: 1..9, HM19: 1..5)
    ser.printf1(@"Device name: %s\n\r", ble.node_name())
    ser.printf1(@"Version: %d\n\r", ble.version())
    ser.printf1(@"Scan time: %dsecs\n\r", ble.scan_time())

    time.msleep(500)                            ' give BLE module time to settle
    ble.flush_rx()

    ser.str(@"Scanning...")
    ble.str(@"AT+DISC?")


    repeat                                      ' wait for response from module
        ble.gets_max(@_tmp, 8)                  '   indicating the scan has started
    until (strcomp(@_tmp, @"OK+DISCS"))


    entry := 0
    repeat
        bytefill(@_tmp, 0, MAX_NAME_LEN)
        ble.gets_max(@_tmp, 8)                  ' look for response with remote MAC address
        if (    strcomp(@_tmp, @"OK+DIS0:") or ...
                strcomp(@_tmp, @"OK+DIS1:") or ...
                strcomp(@_tmp, @"OK+DIS2:") )
            repeat i from 0 to MAC_ADDR_LEN-1   ' store the MAC address
                _mac[(entry*MAC_ADDR_LEN)+i] := ble.gethex(2)

            bytefill(@_tmp, 0, MAX_NAME_LEN)
            ble.gets_max(@_tmp, 8)              ' look for response with remote node name
            if ( strcomp(@_tmp, @"OK+NAME:") )  ' response with remote node name (CRLF-terminated)
                bytefill(@_name+(entry*MAX_NAME_LEN), 0, MAX_NAME_LEN)
                ble.gets_max(@_name+(entry*MAX_NAME_LEN), MAX_NAME_LEN)

            entry++
            if ( entry => MAX_ENTRIES )
                quit
        elseif ( strcomp(@_tmp, @"OK+DISCE") )  ' module reports scan is finished
            quit
        else
            next                                ' unexpected response

    ser.strln(@"finished")

    { show the list of remote nodes found }
    repeat i from 0 to entry-1
        ser.printf3(@"Entry %d: %s (%s)\n\r", i, str.mactostr(@_mac+(i*6)), @_name+(i*33) )


    repeat


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

    ble.set_role(ble.CENTRAL)                   ' must be in central role to scan
    ble.set_work_mode(ble.IDLE)                 ' start in command mode
    ble.resolve_names(TRUE)                     ' we want the names of remote nodes, too


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

