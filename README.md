# pcileech_bar_impl_fake_wifi

A simple fake Wi-Fi adapter module for PCIe BAR emulation.  
This project is intended for testing, fuzzing, and development environments where simulating Wi-Fi behavior is required without real network hardware.
Inspired by [pcileech-Fakeconnect](https://github.com/fif5o/pcileech-Fakeconnect).

## Features
- Simulates 4 different fake Wi-Fi SSIDs: `Home`, `Cafe`, `Boss`, `Free`
- Supports multi-station selection and connection switching
- Simulates connection stages: Idle → Scanning → Authenticating → Associating → Connected
- RSSI (signal strength) varies slightly to emulate real network behavior
- Simple, minimal, and easy-to-integrate design
- Compatible with [pcileech](https://github.com/ufrisk/pcileech) style BAR device communication

## Registers
| Address       | Description                         |
|:--------------|:-------------------------------------|
| `0x0000`      | Link Status (1 = connected, 0 = not connected) |
| `0x0004`      | Select Wi-Fi network (write)         |
| `0x0008`      | Connected SSID (read)                |
| `0x000C`      | Current RSSI (read)                  |
| `0x0010`      | Number of available networks (read)  |
| `0x0014`      | SSID of the network (based on index) |

## How It Works
- Upon reset, the module enters an idle state.
- After a short time, it starts scanning available networks.
- Upon selecting a network (via `REG_SCAN_RESULT`), it simulates authenticating and associating.
- After connection, the module responds with the SSID and RSSI.
- RSSI fluctuates naturally to mimic real-world signal strength changes.

## Usage Example
Instantiate the module with BAR routing:

```verilog
pcileech_bar_impl_fake_wifi i_barX(
    .rst            (rst),
    .clk            (clk),
    .wr_addr        (wr_addr),
    .wr_be          (wr_be),
    .wr_data        (wr_data),
    .wr_valid       (wr_valid && wr_bar[X]),
    .rd_req_ctx     (rd_req_ctx),
    .rd_req_addr    (rd_req_addr),
    .rd_req_valid   (rd_req_valid && rd_req_bar[X]),
    .rd_rsp_ctx     (bar_rsp_ctx[X]),
    .rd_rsp_data    (bar_rsp_data[X]),
    .rd_rsp_valid   (bar_rsp_valid[X])
);
