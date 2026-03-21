# uart-controller

## Author

David Tertre

## Target device

- **Board:** Nexys 4 DDR

- **FPGA:** xc7a100tcsg324-1

## Desciption

This project implements a UART controller for FPGA designs.

The UART line remains at logic '1' while the transmitter is in the IDLE state, as required by the UART protocol.

e design supports different operating modes and follows a streaming-oriented architecture based on valid/ready handshaking, enabling easy integration of processing stages such as FIFOs and data transformation modules.

### Operating modes

- **Loopback:** Received data is inmediately transmited back. 

- **Case Converter:** Received ASCII characters are processed by toggling their case (lowercase to uppercase and vice versa) before transmission.

## Communication parameters

Default paramenters:

- **Baud rate:** 115200
- **Data bits:** 8
- **Parity:** None
- **Stop bits:** 1

The baud rate and oversampling multiplier can be configured through generic parameters in the corresponding modules.
The receiver uses oversampling (typically x16) to improve sampling accuracy.

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

## FIFO selection rationale

During development, a standard FIFO with registered output (fifo_sync) was initially used. However, this introduced an additional latency of one clock cycle when reading data.

When integrating the FIFO with the case_converter module (which uses a valid/ready streaming interface), this latency caused a misalignment in the data flow, resulting in a visible delay of up to two characters in the UART output.

To solve this issue, the design was updated to use a FWFT (First-Word Fall-Through) FIFO. With this approach, data is immediately available at the output as soon as the FIFO is not empty, eliminating the extra latency and ensuring proper synchronization with the streaming interface.

## System architecture

UART RX → FIFO (FWFT) → Case Converter → FIFO (FWFT) → UART TX

## Key design concepts

- **Finite State Machines (FSM):** Used to implement UART transmitter and receiver control logic.

- **Clock domain considerations:** Emphasis on synchronous design and proper reset handling to ensure reliable operation.

- **Reset synchronization:** Asynchronous reset assertion with synchronous deassertion to avoid metastability issues.

- **FIFO buffers:** Implemented to decouple data producer and consumer, enabling smooth data flow between modules.

- **FWFT (First-Word Fall-Through):** Used to eliminate read latency and improve compatibility with streaming interfaces.

- **Streaming interfaces (valid/ready):** Applied to enable modular and scalable data processing pipelines.

- **Pipelining:** Introduced through modular stages (e.g., FIFO → case_converter → FIFO) to improve throughput and system flexibility.


## Notes:

- The UART receiver holds the received byte valid until it is acknowledged through the ready/valid handshake, ensuring no data loss.

- The UART transmitter accepts input data when `tx_valid` is asserted and generates a `tx_ready` pulse once the byte has been successfully captured.

- The receiver uses oversampling (typically x16) to improve sampling accuracy and robustness against timing variations.

- The design follows a streaming-oriented architecture using ready/valid handshaking, enabling easy integration of processing stages such as FIFOs and data transformation modules.

- Simultaneous read and write operations are supported even when the FIFO is full, keeping occupancy unchanged. However, standalone write attempts while full are ignored and may result in data loss if upstream flow control is not implemented.

## Futures

- **FIFO improvements:** add configurable control signals and support for Block RAM (BRAM) when larger buffer sizes are required.

- Extend processing pipeline with additional data transformation modules.

- Extend the current valid/ready interface towards standard protocols such as AXI-Stream.
