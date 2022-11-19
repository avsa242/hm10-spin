{
    --------------------------------------------
    Filename: wireless.bluetooth-le.hmxx.spin
    Author: Jesse Burt
    Description: Driver for UART-connected HM-XX BLE modules
    Copyright (c) 2022
    Started Mar 28, 2021
    Updated Nov 19, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    { Advertising types }
    ADV_SCANRESP_CONN   = 0
    LASTDEV_ONLY        = 1
    ADV_SCANRESP        = 2
    ADV_ONLY            = 3

    { BLE module type filter }
    ALL_BLE             = 0
    HM_ONLY             = 1

    { Authentication modes }
    NOPIN               = 0
    AUTH_NOPIN          = 1
    AUTH_PIN            = 2
    AUTH_PAIR           = 3

    { HM-10 system LED pin modes }
    FLASH               = 0
    STEADY              = 1

    { Device roles }
    PERIPHERAL          = 0
    CENTRAL             = 1

    { Work modes }
    IMMEDIATE           = 0
    IDLE                = 1

    { Internal-use constants }
    NDEC                = 10
    NHEX                = 16

    OK                  = $4B4F                 ' "OK"

    BUFFSZ              = 32

OBJ

    time    : "time"
    uart    : "com.serial.terminal"
    st      : "string"

VAR

    byte _rxbuff[BUFFSZ], _tries

PUB null{}
' This is not a top-level object

PUB init(BLE_RX, BLE_TX, BLE_BAUD): status
' Start driver using custom I/O settings and bitrate
'   BLE_RX: pin connected to BLE module's TX pin
'   BLE_TX: pin connected to BLE module's RX pin
'   BLE_BAUD: 4800..230_400 (default: 9600)
    if lookdown(BLE_RX: 0..31) and lookdown(BLE_TX: 0..31) and {
}   lookdown(BLE_BAUD: 4800, 9600, 19200, 38400, 57600, 115200, 230400)
        if (status := uart.startrxtx(BLE_RX, BLE_TX, 0, BLE_BAUD))
            time.msleep(30)
            if (dev_id{} == OK)                 ' validate device
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog

    ' NOTE: The driver will also fail to start if the module is already
    '   connected to a remote device, due to the initial check for
    '   the 'OK' response.
    return FALSE

PUB deinit{}
' Stop the driver
    uart.stop{}

PUB defaults{}
' Factory default settings
'   NOTE: This resets ALL settings to factory default, including user-data
'   such as module name, PIN code, etc
    cmdresp(string("AT+RENEW"))

PUB advert_interval{}: curr_intv | cmd
' Get advertising interval
'   Returns: milliseconds
    cmd := string("AT+ADVI?")
    cmdresp(cmd)
    ' settings data is on the right side of the ':' in the response
    '   from the module (e.g., '9' if the module responds "AT+Get:9")
    ' Grab it, convert it to binary form, and look up the corresponding
    '   time interval in the table
    curr_intv := st.atoib(st.getfield(@_rxbuff, 2, ":"), NHEX)
    return lookupz(curr_intv: 100, 152, 211, 318, 417, 546, 760, 852, 1022, 1285, 2000, 3000, {
}                             4000, 5000, 6000, 7000)

PUB set_advert_interval(intv) | cmd
' Set advertising interval, in milliseconds
'   Valid values:
'       100, 152, 211, 318, 417, 546, 760, 852, 1022, *1285, 2000, 3000, 4000,
'       5000, 6000, 7000
    case intv
        100, 152, 211, 318, 417, 546, 760, 852, 1022, 1285, 2000, 3000, 4000, 5000, 6000, 7000:
            intv := lookdownz(intv: 100, 152, 211, 318, 417, 546, 760, 852, 1022, 1285, 2000, {
}                                   3000, 4000, 5000, 6000, 7000)
            cmd := string("AT+ADVI#")
            st.replacechar(cmd, "#", lookupz(intv & $f: "0".."9", "A".."F"))
            cmdresp(cmd)

PUB advert_type{}: curr_type | cmd
' Get advertising type
'   Returns: integer
    cmd := string("AT+ADTY?")
    cmdresp(cmd)
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_advert_type(type): curr_type | cmd
' Set advertising type
'   Valid values:
'      *ADV_SCANRESP_CONN (0): Advertising, ScanResponse, Connectable
'       LASTDEV_ONLY (1): Only allow last device connect in 1.28 seconds
'       ADV_SCANRESP (2): Only allow Advertising and ScanResponse
'       ADV_ONLY (3): Only allow advertising
    case type
        ADV_SCANRESP_CONN, LASTDEV_ONLY, ADV_SCANRESP, ADV_ONLY:
            cmd := string("AT+ADTY#")
            st.replacechar(cmd, "#", lookupz(type & $f: "0".."9", "A".."F"))
            cmdresp(cmd)

PUB auth_mode{}: curr_mode | cmd
' Get authentication mode
'   Returns: integer
    cmd := string("AT+TYPE?")
    cmdresp(cmd)
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_auth_mode(mode): curr_mode | cmd
' Set authentication mode
'   Valid values:
'       NOPIN (0): No PIN code required
'       AUTH_NOPIN (1): authenticate, but no PIN required
'       AUTO_PIN (2): authenticate, PIN required (every connection)
'       AUTH_PAIR (3): authenticate, PIN required (only once per pairing)
    if (version{} < 515)                        ' per the datasheet, don't use
        return                                  ' if firmware is older than 515
    case mode
        NOPIN, AUTH_NOPIN, AUTH_PIN, AUTH_PAIR:
            cmd := string("AT+TYPE#")
            st.replacechar(cmd, "#", lookupz(mode & 3: "0".."3"))
            cmdresp(cmd)

PUB char = putchar
PUB putchar(c)
' Send character
    uart.putchar(c)

PUB charin = getchar
PUB getchar{}: c
' Receive character from module (blocking)
'   Returns: ASCII code of character received
    return uart.getchar{}

PUB is_conn_notify_ena{}: curr_state
' Get current state of (dis)connection notifications
'   Returns: TRUE (-1) or FALSE (0)
    cmd := string("AT+NOTI?")
    cmdresp(cmd)
    return (st.atoi(st.getfield(@_rxbuff, 2, ":")) == 1)

PUB conn_notify_ena(state) | cmd
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

PUB count = fifo_rx_bytes
PUB fifo_rx_bytes{}: c
' Get number of characters in receive buffer
'   Returns: integer
    return uart.fifo_rx_bytes{}

PUB data_rate{}: curr_rate
' Get current data rate
'   Returns: integer
    cmd := string("AT+BAUD?")
    cmdresp(cmd)
    curr_rate := st.atoi(st.getfield(@_rxbuff, 2, ":"))
    return lookupz(curr_rate: 9600, 19200, 38400, 57600, 115200, 4800, 2400, 1200, 230400)

PUB set_data_rate(rate)| cmd, tmp
' Set data rate, in bps
'   Valid values: 4800, 9600, 19200, 38400, 57600, 115200, 230400
'   NOTE: This affects both on-air and serial interface data rates. When
'       updating data rates, the driver must first be started with the existing
'       rate. The updated rate takes effect when reset or power cycled.
'   Example: Current data rate 9600, new rate desired: 19200
'   ble.init(RX, TX, 9600)                      ' start the driver with the current data rate
'   ble.set_data_rate(19200)                    ' set the new one
'   ble.reset                                   ' reset the chip (the change takes effect here)
'   ble.deinit                                  ' stop the ble driver
'   ble.init(RX, TX, 19200)                     ' restart it at the new rate
    case rate
        4800, 9600, 19200, 38400, 57600, 115200, 230400:
            rate := lookdownz(rate: 9600, 19200, 38400, 57600, 115200, 4800, 2400, 1200, 230400)
            cmd := string("AT+BAUD#")
            st.replacechar(cmd, "#", lookupz(rate: "0".."8"))
            cmdresp(cmd)

PUB dev_id{}: id
' Read device identification
'   Returns: $4B4F ('OK')
    cmdresp(string("AT"))
    bytemove(@id, @_rxbuff, 2)

PUB last_connected_dev{}: ptr_addr
' Get last connected device's address
'   Returns: pointer to string containing MAC address of device
    cmdresp(string("AT+RADD?"))
    return st.getfield(@_rxbuff, 2, ":")

PUB node_addr(addr): ptr_addr
' Read device node address
'   Returns: pointer to string containing 48-bit MAC address
'   NOTE: Parameter is unused - exists only for API compatibility with other wireless drivers
    cmdresp(string("AT+ADDR?"))
    return st.getfield(@_rxbuff, 2, ":")

PUB node_name{}: ptr_name | cmd, tmp
' Get BLE module current name
'   Returns: pointer to string
    cmdresp(string("AT+NAME?"))
    return st.getfield(@_rxbuff, 2, ":")

PUB set_node_name(ptr_name): curr_name | cmd, tmp
' Set BLE module name
'   Valid values: pointer to string from 1 to 12 chars in length
'   NOTE: The module must be reset (e.g., reset(), or power cycle) for this to take effect
    case ptr_name
        $0004..$7FF3:
            if ( (strsize(ptr_name) < 1) or (strsize(ptr_name) > 12) )
                return                          ' reject invalid length names
            tmp := string("AT+NAME            ")' template
            ' replace the spaces with the name string
            st.replace(tmp, string("            "), ptr_name)
            cmd := st.strip(tmp)
            cmdresp(cmd)

PUB pin_code{}: curr_pin
' Get current PIN code
    cmdresp(string("AT+PASS?"))
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_pin_code(pin) | cmd
' Set PIN code
'   Valid values: 000000..999999
    case pin
        0..999999:
            cmd := string("AT+PASS######")
            st.replace(cmd, string("######"), st.decpadz(pin, 6))
            cmdresp(cmd)

PUB reset{}
' Perform soft-reset
    cmdresp(string("AT+RESET"))

PUB is_resolve_names_ena{}: curr_state
' Get current setting of BLE MAC address resolution to names during scans
    cmdresp(string("AT+SHOW?"))
    return (st.atoi(st.getfield(@_rxbuff, 2, ":")) == 1)

PUB resolve_names(state) | cmd
' Resolve BLE MAC addresses to names (when possible) during scans
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(state)
        0, 1:
            cmd := string("AT+SHOW#")
            st.replace(cmd, string("#"), st.dec((state & 1)))
            cmdresp(cmd)

PUB role{}: curr_role | cmd
' Get device current role
'   Returns: integer
    cmd := string("AT+ROLE?")
    cmdresp(cmd)
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_role(role) | cmd
' Set device role
'   Valid values:
'      *PERIPHERAL (0): Peripheral
'       CENTRAL (1): Central
    case role
        PERIPHERAL, CENTRAL:
            cmd := string("AT+ROLE#")
            st.replacechar(cmd, "#", role + "0")
            cmdresp(cmd)

PUB rx_check{}: r
' Check if there's a character received (non-blocking)
'   Returns:
'       -1 if no character pending, or ASCII value of pending character
    return uart.rx_check{}

PUB scan_time{}: curr_tm | cmd
' Get length of scan
'   Returns: seconds
    cmdresp(string("AT+SCAN?"))
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_scan_time(tm) | cmd
' Set length of scan, in seconds
'   Valid values:
'       HM-10 (as of v545): 1..9 (default: 3)
'       HM-19 (as of v114): 1..5 (default: 3)
    case tm
        1..9:
            cmd := string("AT+SCAN#")
            st.replace(cmd, string("#"), st.dec(tm))
            cmdresp(cmd)

PUB gets_max(ptr_str, max_len)
' Read string from BLE into ptr_str, up to max_len bytes
    uart.gets_max(ptr_str, max_len)

PUB sys_led_mode{}: curr_mode | cmd
' Get current mode of module's system LED pin
    cmd := string("AT+PIO1?")
    cmdresp(cmd)
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_sys_led_mode(mode) | cmd
' Set output mode of module's system LED pin
'   Valid values:
'      *FLASH (0): flash 500ms high/500ms low when unconnected,
'           steady when connected
'       STEADY (1): low when unconnected, high when connected
'   NOTE: STEADY is more useful if monitoring of the module's connection state by the Propeller
'       is desired
'   NOTE: The module must be reset (e.g., reset(), or power cycle) for this to take effect
    case mode
        FLASH, STEADY:
            cmd := string("AT+PIO1#")
            st.replacechar(cmd, "#", mode + 48)
            cmdresp(cmd)

PUB tx_pwr{}: curr_pwr | cmd
' Get transmit power
'   Returns: dBm
    cmd := string("AT+POWE?")
    cmdresp(cmd)
    curr_pwr := st.atoi(st.getfield(@_rxbuff, 2, ":"))
    return lookupz(curr_pwr: -23, -6, 0, 6)

PUB set_tx_pwr(pwr) | cmd
' Set transmit power, in dBm
'   Valid values: -23, -6, 0, 6
    case pwr
        -23, -6, 0, 6:
            pwr := lookdownz(pwr: -23, -6, 0, 6)
            cmd := string("AT+POWE#")
            st.replacechar(cmd, "#", lookupz(pwr & 3: "0".."3"))
            cmdresp(cmd)

PUB unpair{}
' Remove pairing/bonding information
'   NOTE: The module must be reset (e.g., Reset(), or power cycle)
'       for this to take effect
    cmdresp(string("AT+ERASE"))

PUB version{}: ver
' Get firmware version
    cmdresp(string("AT+VERS?"))
    return st.atoi(st.right(@_rxbuff, 3))

PUB work_mode{}: curr_mode | cmd
' Get device current working mode
    cmd := string("AT+IMME?")
    cmdresp(cmd)
    return st.atoi(st.getfield(@_rxbuff, 2, ":"))

PUB set_work_mode(mode) | cmd
' Set device working mode
'   Valid values:
'      *IMMEDIATE (0): immediate
'       IDLE (1): idle; don't do anything until commanded
    case mode
        0, 1:
            cmd := string("AT+IMME#")
            st.replacechar(cmd, "#", mode + "0")
            cmdresp(cmd)

PRI cmdresp(ptr_cmdstr): resp | i, chr
' Send command and store the response
    bytefill(@_rxbuff, 0, BUFFSZ)
    uart.flush_rx{}
    _tries := 1
    repeat                                      ' keep sending the cmd to the
        puts(ptr_cmdstr)                        '   module, and wait for resp.
        time.msleep(30)                         ' give the module time to resp.
        _tries++                                ' otherwise, might get hung up
    until uart.fifo_rx_bytes{}                  ' in this loop

    i := chr := 0
    repeat
        if (chr := lookdown(uart.rx_check{}: 1..255))
            _rxbuff[i++] := chr
            time.msleep(2)                      ' wait, to mitigate underflow
    while chr

' Pull in the common terminal type methods so they can be used over the air
#include "terminal.common.spinh"

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

