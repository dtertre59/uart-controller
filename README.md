# uart-controller

## Author

David Tertre

## Part

Nexys 4 DDR: xc7a100tcsg324-1

## Desciption

UART controller

on IDLE state, line value is '1'

Options:

- Loopback
- LOWER case to UPPER case characters

## Modules

- baud_generator: tick depending on the baud config

- reset controler: Async active, sync deactive

- uart_tx (FSM)

- uart_rx (FSM)

- uart_processor

- (Top) UART