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

- **Case Converter:** received ASCII lowercase characters are converted to uppercase before transmission.

## Modules

- **baud_generator:** Generates the baud-rate tick used by both the UART transmitter and receiver.

- **reset_synchronizer:** Handles reset synchronization. Reset assertion is asynchronous and deassertion is synchronized to the system clock.

- **uart_tx (FSM):** UART transmitter implemented as a finite state machine.

- **uart_rx (FSM):** UART receiver implemented as a finite state machine with oversampling.

- **fifo_sync:** Standard synchronous FIFO with registered output. The output data is updated only when a valid read operation (read_en) occurs, resulting in a one-cycle latency. This approach provides predictable timing and simplifies control logic.

- **fifo_fwft:** Show-ahead FIFO (First-Word Fall-Through, FWFT). The first available data word is continuously presented at the output as soon as the FIFO is not empty, without requiring an explicit read request. This zero-latency behavior is well suited for high-throughput streaming and pipelined architectures.

- **case_converter:** processing module that performs case conversion on received data, toggling characters between uppercase and lowercase. This module can be integrated as a configurable stage in the processing pipeline to apply basic data transformations.

- **uart_loopback_top:** Top-level module implementing a simple UART loopback. Received bytes are immediately transmitted back.

- **uart_case_converter_top:** Top-level module that processes received characters and converts lowercase ASCII letters to uppercase before transmission.

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
