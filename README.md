

# Intelligent Parking System (FPGA/VHDL)

   

## 📖 Overview

This project is a complete VHDL implementation of an **Intelligent Parking Management System**, designed for deployment on an FPGA development board. The system provides real-time vehicle tracking, automated barrier control, and dynamic occupancy display using modular digital design principles.

It ensures safety and efficiency by automating entry/exit logic while strictly enforcing capacity limits and obstacle detection.

-----

## 🎯 Key Features

  * **Automatic Vehicle Counting:** Real-time tracking of available spots (Entry: -1, Exit: +1).
  * **Capacity Management:** Automatically denies entry when the parking lot is full (`places_disponibles = 0`).
  * **Safety-First Barrier Control:** Prevents the barrier from closing if an object is detected underneath (Interlock logic).
  * **Real-Time Display:** 4-digit multiplexed 7-segment display showing the number of free spots.
  * **Deadlock Prevention:** Exit is always authorized, even if the system is full.

-----

## ⚙️ System Architecture

The design is hierarchical and modular, centered around a top-level entity (`top_parking`) that coordinates three distinct sub-modules.

### 1\. Top Level (`top_parking`)

The central controller that interconnects all modules. It contains the generic parameter `MAX_PLACES` and handles the global authorization logic.

  * **Inputs:** Raw sensor data, Clock, Reset.
  * **Logic:**
      * **Entry Rule:** `Open` if `sensor_entry = '1'` AND `spots > 0`.
      * **Exit Rule:** `Open` if `sensor_exit = '1'` (Always allowed).

### 2\. Parking Counter (`counter_block`)

A bidirectional counter responsible for data integrity.

  * **Function:** Increments/decrements the count based on valid entry/exit flags.
  * **Output:** Current number of available places sent to the display and Top Level.

### 3\. Barrier Control FSM (`barrier_control`)

A Finite State Machine (FSM) driving the physical barrier motor.

  * **States:** `IDLE`, `OPENING`, `OPEN`, `WAITING_PASSAGE`, `CLOSING`.
  * **Safety Logic:** The `sensor_passage` (IR/Ultrasonic under barrier) acts as a hardware interlock. The state machine **cannot** transition to `CLOSING` while this signal is high.

### 4\. Display Controller (`display_block`)

Handles the visual interface for the user.

  * **Function:** Converts the binary spot count into BCD and drives a multiplexed 4-digit 7-segment display.
  * **Refresh Rate:** Uses the 50 MHz system clock to cycle through digits (anodes) to create persistence of vision.

-----

## 🔌 Hardware Specifications

The logic is synthesized for an FPGA board (e.g., Altera Cyclone, Xilinx Artix) with a **50 MHz system clock**.

### Pinout / Interface Table

| Signal Name | Type | Description | Hardware Example |
| :--- | :--- | :--- | :--- |
| `clk` | Input | System Clock (50 MHz) | On-board Oscillator |
| `rst_n` | Input | Active Low Reset | Push Button |
| `sensor_entry` | Input | Detects car arriving at entry | Inductive Loop / HC-SR04 |
| `sensor_exit` | Input | Detects car arriving at exit | Inductive Loop / HC-SR04 |
| `sensor_passage` | Input | Safety sensor under barrier | IR Break-beam |
| `limit_open` | Input | Barrier fully open switch | Limit Switch |
| `limit_closed` | Input | Barrier fully closed switch | Limit Switch |
| `motor_open` | Output | Motor H-Bridge Control (Open) | L298N Driver Input 1 |
| `motor_close` | Output | Motor H-Bridge Control (Close) | L298N Driver Input 2 |
| `seg[6:0]` | Output | 7-segment cathodes (a-g) | 4-Digit Display |
| `anode[3:0]` | Output | Digit selection (multiplexing) | 4-Digit Display |

-----

## 🧠 Control Logic & Rules

### 1\. Entry/Exit Authorization

The system uses combinational logic in the Top Level to determine intent.

```vhdl
-- Pseudo-code logic
enable_entry <= '1' when (sensor_entry = '1' AND current_spots > 0) else '0';
enable_exit  <= '1' when (sensor_exit = '1') else '0'; -- Always '1' to prevent deadlock
```

### 2\. Barrier Automation Cycle

1.  **Request:** Driver triggers entry/exit sensor.
2.  **Action:** Barrier opens until `limit_open` is hit.
3.  **Transit:** System waits for `sensor_passage` to go HIGH (car under barrier) then LOW (car cleared).
4.  **Close:** Barrier closes **only** if `sensor_passage` is '0'.

