# uart-controller

## Author

David Tertre

## Target device

- **Board:** Nexys 4 DDR

- **FPGA:** xc7a100tcsg324-1

## Desciption

This project implements a UART controller for FPGA designs.

The UART line remains at logic '1' while the transmitter is in the IDLE state, as required by the UART protocol.

The design supports different operating modes and can be used as a simple serial communication interface for FPGA-based systems.

### Operating modes

- **Loopback:** received data is inmediately transmited back. 

- **LOWER case to UPPER case conversion:** received ASCII lowercase characters are converted to uppercase before transmission.

## Modules

- **baud_generator:** Generates the baud-rate tick used by both the UART transmitter and receiver.

- **reset_synchronizer:** Handles reset synchronization. Reset assertion is asynchronous and deassertion is synchronized to the system clock.

- **uart_tx (FSM):** UART transmitter implemented as a finite state machine.

- **uart_rx (FSM):** UART receiver implemented as a finite state machine with oversampling.

- **uart_processor:** Optional processing stage used to modify received data (e.g., lowercase to uppercase conversion). **TO DO**

- **uart_loopback_top:** Top-level module implementing a simple UART loopback. Received bytes are immediately transmitted back.

- **uart_uppercase_top:** Top-level module that processes received characters and converts lowercase ASCII letters to uppercase before transmission.

## Communication parameters

Default paramenters:

- **Baud rate:** 115200
- **Data bits:** 8
- **Parity:** None
- **Stop bits:** 1

The baud rate and oversampling multiplier can be configured through generic parameters in the corresponding modules.
The receiver uses oversampling (typically x16) to improve sampling accuracy

## Notes:

The UART receiver keeps the received byte valid until it is acknowledged through the ready/valid handshake.

The transmitter accepts input data when tx_valid is asserted and generates a pulse on tx_ready once the byte has been captured.

The design uses oversampling (x16) to improve UART reception reliability.

## Futures

FIFO Advance: using control signal. If is bigger, use Block RAM (BRAM)
