🚀 DMA Controller – AXI-Lite Based Data Transfer Engine

The DMA Controller is a Verilog-based hardware module designed to transfer a specified number of bytes from a source address to a destination address using the AXI-Lite protocol.
It supports unaligned transfers, byte-accurate writes, and uses a FIFO buffer to smoothly handle read–write timing differences.

This project is great for understanding how real hardware DMAs operate internally, covering concepts like FSMs, strobes, alignment, buffering, and AXI handshakes.

🌟 Features

⚙️ AXI-Lite Interface – Supports AR/AW/W/B/R channel handshakes.

📦 FIFO Buffering – 16×32-bit synchronous FIFO for storing read data.

🎯 Unaligned Transfer Support – Works with any source/destination byte offset.

✂️ Automatic WSTRB Generation – Handles partial writes and leftover bytes.

🔄 Dual FSM Architecture – Independent Read and Write state machines.

📏 Byte-Accurate Transfer Logic – Computes exact number of required reads.

✔️ done Signal – Indicates when the DMA operation finishes successfully.

📁 Modules Included
1️⃣ dma_controller.v

Implements the full DMA pipeline:

Read FSM:

Issues AXI read transactions

Aligns data based on source offset

Handles last partial word using shifting

Pushes data into FIFO

Write FSM:

Fetches FIFO data

Aligns output to destination offset

Generates correct WSTRB patterns

Handles write address, data, and response channels

2️⃣ sync_fifo.v

A fully synchronous FIFO used to store intermediate 32-bit data.

16-entry depth

FULL/EMPTY detection

Supports simultaneous read/write

Exposes memory taps (mem0–mem7) for debugging

▶️ How It Works (High-Level)

User asserts trigger to start DMA

Module captures byte offsets from source/destination addresses

Read FSM:

Reads words from the source

Aligns data correctly

Writes them into FIFO

Write FSM:

Pulls words from FIFO

Aligns data to destination

Applies correct WSTRB for partial writes

Writes data to the destination address

done goes HIGH when the complete length of bytes has been transferred

🎥 Demo (Optional)

You can add waveform screenshots or simulation output here later:
