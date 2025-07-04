output : ![Screenshot 2025-07-04 231235](https://github.com/user-attachments/assets/117f867f-05b5-4a6f-aef2-5964070a57ce)

output waveform : ![Screenshot 2025-07-04 221846](https://github.com/user-attachments/assets/f138ca12-270c-4ac9-b996-9312d5bb2793)





🛠️ I2C Protocol Implementation – Write Operation (Master to Slave)
📌 Overview
This project implements the I2C (Inter-Integrated Circuit) Protocol in Verilog, focusing on the write operation. In this implementation:

The I2C Master sends:

a.)A 7-bit slave address

b.)A write bit (0)

c.)An 8-bit data byte

d.)The I2C Slave receives:

e.)The address and data

f.)Sends an ACK (Acknowledge) signal back to the master after each byte


📂 Project Structure

i2c_write_operation/
├── master.v          # I2C master module (with FSM for write sequence)
├── slave.v           # I2C slave module (with address match and ACK)
├── i2c_tb.v   # Testbench to simulate the entire operation
├── README.md         # Project documentation (this file)

🔁 Communication Sequence


Start Condition →
Send 7-bit Slave Address →
Send Write Bit (0) →
Slave ACKs →
Send 8-bit Data →
Slave ACKs →
Stop Condition

⚙️ Modules
✅ Master (master.v)
Generates SCL (clock) and drives the SDA line

FSM handles:

Start condition

Address transmission

Write bit

Data transmission

Wait for ACK

Stop condition

✅ Slave (slave.v)
Listens on SCL and SDA

Checks received address against its own

Acknowledges valid address

Receives 8-bit data and stores it

Sends ACK after address and data reception



