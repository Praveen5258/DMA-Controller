# 📦✨ DMA Controller – AXI-Lite Data Transfer Engine

The **DMA Controller** is a Verilog-based hardware module designed to move data efficiently from a **source address** to a **destination address** using the AXI-Lite protocol.  
It supports **unaligned transfers**, **byte-level strobes**, and uses a **FIFO buffer** to keep reads and writes flowing smoothly.

This project is ideal for anyone learning about hardware datapaths, AXI handshakes, or real DMA architecture inside processors and SoCs.

---

## 🌟 Features (Stickers Included)

- ⚙️ **AXI-Lite Read/Write Support**  
- 🧩 **Handles Unaligned Addresses** (source + destination)  
- ✂️ **Smart WSTRB Generation** for partial writes  
- 📥 **16×32-bit FIFO Buffer**  
- 🔄 **Dual FSM Design** (Read FSM + Write FSM)  
- 📏 **Accurate Byte Counting**  
- 🎉 **`done` Signal When Transfer Completes**  
- 🔍 Built-in alignment logic using shifting + masking  

---

## 📁 Modules Included

### **1️⃣ dma_controller.v**  
🛠 Handles the main DMA pipeline:

- Issues AXI read requests  
- Aligns incoming read data  
- Pushes aligned data into FIFO  
- Fetches data from FIFO for writing  
- Aligns data for destination address  
- Generates correct `WSTRB` for all cases  
- Tracks progress and asserts `done`  

---

### **2️⃣ sync_fifo.v**  
📦 A simple synchronous FIFO used to buffer read data.

- 16 entries × 32 bits  
- FULL / EMPTY indicators  
- Supports simultaneous read + write  
- Internal memory taps exposed for debugging (mem0–mem7)  

---

## 🚀 How It Works (High-Level)

1. User pulses **trigger** to start DMA  
2. Controller reads byte offsets from source & destination addresses  
3. **Read FSM** begins:
   - Sends AR request  
   - Receives data via R channel  
   - Aligns data using shifts  
   - Writes aligned data into FIFO  

4. **Write FSM** starts:
   - Pulls FIFO data  
   - Re-aligns for destination offset  
   - Generates correct WSTRB patterns  
   - Performs AW/W/B handshakes  

5. When all bytes are written, the controller raises **`done`**  

---

## 🧪 Good For

- Students learning AXI protocols  
- FPGA designers building memory subsystems  
- Anyone exploring DMA architecture  
- Testbench + simulation practice  

---

## 🎯 Notes

- All logic is synchronous  
- Works with AXI-Lite (32-bit data width)  
- Read and write operations run independently thanks to FIFO decoupling  

---

<img width="1920" height="1080" alt="Screenshot (156)" src="https://github.com/user-attachments/assets/c067d602-b642-4b9c-a827-5f6e4a39568b" />
<img width="1920" height="1080" alt="Screenshot (138)" src="https://github.com/user-attachments/assets/286354bd-1fe2-4291-88c6-df0441fd4ee8" />

  
