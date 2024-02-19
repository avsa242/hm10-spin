# hmxx-spin
-----------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for HMxx Bluetooth-LE modules.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* UART connection at common data rates from 4800 to 230400bps
* Change module name
* Read module's MAC address
* Read module's firmware version
* Read last connected device's MAC address
* Set advertising interval
* Set transmit power
* Set module system LED mode (show connection state as flashing or steady-state)
* Set serial/OTA data rate
* Authentication: set PIN code, authentication mode (none, PIN every time, or pair device), remove stored pairing info
* Integration with terminal.common.spinh, for full terminal I/O support (char(), bin(), dec(), hex(), printf(), etc)


## Requirements

P1/SPIN1:
* spin-standard-library
* terminal.common.spinh (provided by the spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* terminal.common.spinh (provided by the spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.8.0)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.8.0)       | Native/PASM  | Runtime fail          |
| P2        | SPIN2    | FlexSpin (6.8.0)       | NuCode       | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (6.8.0)       | Native/PASM2 | Not yet implemented   |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware Compatibility

* Tested with HM10 (BLE 4.0), HM19 (BLE 5.0) modules


## Limitations

* Very early in development - may malfunction, or outright fail to build
* No validation performed on responses to commands sent (i.e., was the command "OK")

