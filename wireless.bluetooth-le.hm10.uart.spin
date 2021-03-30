{
    --------------------------------------------
    Filename: wireless.bluetooth-le.hm10.uart.spin
    Author: Jesse Burt
    Description: Driver for UART-connected HM10 BLE modules
    Copyright (c) 2021
    Started Mar 28, 2021
    Updated Mar 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Advertising types
    ADV_SCANRESP_CONN   = 0
    LASTDEV_ONLY        = 1
    ADV_SCANRESP        = 2
    ADV_ONLY            = 3

' BLE module type filter
    ALL_BLE             = 0
    HM_ONLY             = 1

' Authentication modes
    NOPIN               = 0
    AUTH_NOPIN          = 1
    AUTH_PIN            = 2
    AUTH_PAIR           = 3

' HM-10 system LED pin modes
    FLASH                = 0
    STEADY              = 1

' Internal-use constants
    NDEC                = 10
    NHEX                = 16

    OK                  = $4B4F                 ' "OK"

    BUFFSZ              = 32

OBJ

    time    : "time"
    uart    : "com.serial"
    st      : "string"
    int     : "string.integer"

VAR

    byte _rxbuff[BUFFSZ], _tries

PUB Null{}
' This is not a top-level object

PUB Init(BLE_RX, BLE_TX, BLE_BAUD): status
' Start driver using custom I/O settings and bitrate
'   BLE_BAUD: 9600 (currently only supported rate)
    if lookdown(BLE_RX: 0..31) and lookdown(BLE_TX: 0..31) and {
}   lookdown(BLE_BAUD: 9600)
        if (status := uart.startrxtx(BLE_RX, BLE_TX, 0, BLE_BAUD))
            time.msleep(30)
            if deviceid{} == OK                 ' validate device
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog

    ' NOTE: The driver will also fail to start if the module is already
    '   connected to a remote device, due to the initial check for
    '   the 'OK' response.
    return FALSE

PUB Defaults{}
' Factory default settings
'   NOTE: This resets ALL settings to factory default, including user-data
'   such as module name, PIN code, etc
    cmdresp(string("AT+RENEW"))

PUB AdvInterval(intv): curr_intv | cmd
' Set advertising interval, in milliseconds
'   Valid values:
'       100, 152, 211, 318, 417, 546, 760, 852, 1022, *1285, 2000, 3000, 4000,
'       5000, 6000, 7000
'   Any other value polls the device and returns the current setting
    case intv
        100, 152, 211, 318, 417, 546, 760, 852, 1022, 1285, 2000, 3000, 4000, {
}       5000, 6000, 7000:
            intv := lookdownz(intv: 100, 152, 211, 318, 417, 546, 760, 852, {
}           1022, 1285, 2000, 3000, 4000, 5000, 6000, 7000)
            cmd := string("AT+ADVI#")
            st.replacechar(cmd, "#", lookupz(intv & $f: "0".."9", "A".."F"))
            cmdresp(cmd)
        other:
            cmd := string("AT+ADVI?")
            cmdresp(cmd)
            ' settings data is on the right side of the ':' in the response
            '   from the module (e.g., '9' if the module responds "AT+Get:9")
            ' Grab it, convert it to binary form, and look up the corresponding
            '   time interval in the table
            curr_intv := int.strtobase(st.getfield(@_rxbuff, 2, ":"), NHEX)
            return lookupz(curr_intv: 100, 152, 211, 318, 417, 546, 760, 852, {
}           1022, 1285, 2000, 3000, 4000, 5000, 6000, 7000)

PUB AdvType(type): curr_type | cmd
' Set advertising type
'   Valid values:
'      *ADV_SCANRESP_CONN (0): Advertising, ScanResponse, Connectable
'       LASTDEV_ONLY (1): Only allow last device connect in 1.28 seconds
'       ADV_SCANRESP (2): Only allow Advertising and ScanResponse
'       ADV_ONLY (3): Only allow advertising
'   Any other value polls the device and returns the current setting
    cmd := 0
    case type
        ADV_SCANRESP_CONN, LASTDEV_ONLY, ADV_SCANRESP, ADV_ONLY:
            cmd := string("AT+ADTY#")
            st.replacechar(cmd, "#", lookupz(type & $f: "0".."9", "A".."F"))
            cmdresp(cmd)
        other:
            cmd := string("AT+ADTY?")
            cmdresp(cmd)
            return int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)

PUB AuthMode(mode): curr_mode | cmd
' Set authentication mode
'   Valid values:
'       NOPIN (0): No PIN code required
'       AUTH_NOPIN (1): authenticate, but no PIN required
'       AUTO_PIN (2): authenticate, PIN required (every connection)
'       AUTH_PAIR (3): authenticate, PIN required (only once per pairing)
    if version{} < 515                          ' per the datasheet, don't use
        return                                  ' if firmware is older than 515
    case mode
        NOPIN, AUTH_NOPIN, AUTH_PIN, AUTH_PAIR:
            cmd := string("AT+TYPE#")
            st.replacechar(cmd, "#", lookupz(mode & 3: "0".."3"))
            cmdresp(cmd)
        other:
            cmd := string("AT+TYPE?")
            cmdresp(cmd)
            return int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)

PUB Char(c)
' Send character
    uart.char(c)

PUB CharIn{}: c
' Receive character from module (blocking)
'   Returns: ASCII code of character received
    return uart.charin{}

PUB ConnNotify(state): curr_state | cmd
' Enable (dis)connection notifications
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   NOTE:
'       When module connects, the notification 'OK+CONN' will be sent
'       When module disconnects, the notification 'OK+LOST' will be sent
    case ||(state)
        0, 1:
            cmd := string("AT+NOTI#")
            st.replacechar(cmd, "#", lookupz(||(state): "0", "1"))
            cmdresp(cmd)
        other:
            cmd := string("AT+NOTI?")
            cmdresp(cmd)
            return int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC) == 1

PUB Count{}: c
' Get number of characters in receive buffer
    return uart.count{}

PUB DataRate(rate): curr_rate | cmd, tmp
' Set data rate, in bps
'   Valid values: 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400
'   Any other value polls the device and returns the current setting
'   NOTE: This affects both OTA and serial interface data rates. When updating
'       data rates, the driver must first be started with the existing rate.
'       The updated rate takes effect when reset or power cycled
'   CAUTION: When rates of 1200 or 2400 are used, the module will no longer
'       respond to AT commands. In order to restore serial connectivity, the
'       module's I/O pin P1_3 must be grounded temporarily. The module will
'       then change rates to 9600.
'       Ensure this pin is accessible on your module before using such
'       data rates!
    case rate
        1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400:
            rate := lookdownz(rate: 9600, 19200, 38400, 57600, 115200, 4800, {
}           2400, 1200, 230400)
            cmd := string("AT+BAUD#")
            st.replacechar(cmd, "#", lookupz(rate: "0".."8"))
            cmdresp(cmd)
        other:
            cmd := string("AT+BAUD?")
            cmdresp(cmd)
            curr_rate := int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)
            return lookupz(curr_rate: 9600, 19200, 38400, 57600, 115200, 4800,{
}           2400, 1200, 230400)

PUB DeviceID{}: id
' Read device identification
'   Returns: $4B4F ('OK')
    cmdresp(string("AT"))
    bytemove(@id, @_rxbuff, 2)

PUB LastConnected{}: ptr_addr
' Get last connected device's address
'   Returns: pointer to string containing MAC address of device
    cmdresp(string("AT+RADD?"))
    return st.getfield(@_rxbuff, 2, ":")

PUB NodeAddress(addr): ptr_curr_addr
' Read device node address
'   Returns: pointer to string containing 48-bit MAC address
'   NOTE: Parameter is unused, for API compatibility with other wireless device drivers
    cmdresp(string("AT+ADDR?"))
    return st.getfield(@_rxbuff, 2, ":")

PUB NodeName(ptr_name): curr_name | cmd, tmp
' Set BLE module name
'   Valid values: pointer to string from 1 to 12 chars in length
'   Any other value polls the device and returns the current setting
'   NOTE: The module must be reset (e.g., Reset(), or power cycle)
'       for this to take effect
    case ptr_name
        $0004..$7FF3:
            if strsize(ptr_name) < 1 or strsize(ptr_name) > 12
                return                          ' reject invalid length names
            tmp := string("AT+NAME            ")' template
            ' replace the spaces with the name string
            st.replace(tmp, string("            "), ptr_name)
            cmd := st.strip(tmp)
            cmdresp(cmd)
        other:
            cmdresp(string("AT+NAME?"))
            return st.getfield(@_rxbuff, 2, ":")

PUB PinCode(pin): curr_pin | cmd
' Set PIN code
'   Valid values: 000000..999999
'   Any other value polls the device and returns the current setting
    case pin
        0..999999:
            cmd := string("AT+PASS######")
            st.replace(cmd, string("######"), int.deczeroed(pin, 6))
            cmdresp(cmd)
        other:
            cmdresp(string("AT+PASS?"))
            return int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)

PUB Reset{}
' Perform soft-reset
    cmdresp(string("AT+RESET"))

PUB RXCheck{}: r
' Check if there's a character received (non-blocking)
'   Returns:
'       -1 if no character pending
'       ASCII value of pending character
    return uart.rxcheck{}

PUB SysLEDMode(mode): curr_mode | cmd
' Set output mode of module's system LED pin
'   Valid values:
'      *FLASH (0): flash 500ms high/500ms low when unconnected,
'           steady when connected
'       STEADY (1): low when unconnected, high when connected
'   NOTE: STEADY is more useful when monitoring of the module's connection
'       state by the Propeller is desired
'   NOTE: The module must be reset (e.g., Reset(), or power cycle)
'       for this to take effect
    case mode
        FLASH, STEADY:
            cmd := string("AT+PIO1#")
            st.replacechar(cmd, "#", mode + 48)
            cmdresp(cmd)
        other:
            cmd := string("AT+PIO1?")
            cmdresp(cmd)
            return int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)

PUB TXPower(pwr): curr_pwr | cmd
' Set transmit power, in dBm
'   Valid values: -23, -6, 0, 6
'   Any other value polls the device and returns the current setting
    case pwr
        -23, -6, 0, 6:
            pwr := lookdownz(pwr: -23, -6, 0, 6)
            cmd := string("AT+POWE#")
            st.replacechar(cmd, "#", lookupz(pwr & 3: "0".."3"))
            cmdresp(cmd)
        other:
            cmd := string("AT+POWE?")
            cmdresp(cmd)
            curr_pwr := int.strtobase(st.getfield(@_rxbuff, 2, ":"), NDEC)
            return lookupz(curr_pwr: -23, -6, 0, 6)

PUB Unpair{}
' Remove pairing/bonding information
'   NOTE: The module must be reset (e.g., Reset(), or power cycle)
'       for this to take effect
    cmdresp(string("AT+ERASE"))

PUB Version{}: ver | cmd, tmp
' Get firmware version
    tmp := st.right(@ver, @_rxbuff, 3)          ' version is rightmost 3 chars
    return int.strtobase(tmp, NDEC)             ' convert ASCII to binary

PRI cmdResp(ptr_cmdstr): resp | i, chr
' Send command and store the response
    bytefill(@_rxbuff, 0, BUFFSZ)
    uart.flush{}
    _tries := 1
    repeat                                      ' keep sending the cmd to the
        str(ptr_cmdstr)                         '   module, and wait for resp.
        time.msleep(30)                         ' give the module time to resp.
        _tries++                                ' otherwise, might get hung up
    until uart.count{}                          ' in this loop

    i := chr := 0
    repeat
        if (chr := lookdown(uart.rxcheck{}: 1..255))
            _rxbuff[i++] := chr
            time.msleep(2)                      ' wait, to mitigate underflow
    while chr

' Pull in the common terminal type methods so they can be used over the air
#include "lib.terminal.spin"

DAT
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
