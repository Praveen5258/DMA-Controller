`timescale 1ns / 1ps

module dma_controller_tb;
    reg clk;
    reg reset;
    reg trigger;
    reg [4:0] length;
    reg [31:0] source_address;
    reg [31:0] destination_add;
    wire done;
    
    // AXI-Lite interface signals
    wire [31:0] ARADDR, AWADDR, RDATA, WDATA;
    wire [3:0] WSTRB;
    wire ARVALID, AWVALID, RREADY, WVALID, BREADY;
    wire ARREADY, AWREADY, RVALID, WREADY, BVALID;
    
    wire [31:0] mem0, mem1, mem2, mem3, mem4, mem5, mem6, mem7;
    
    sync_fifo fifo (
        .clk(clk),
        .reset(reset),
        .FIFO_WR_EN(dut.fifo_write_en),
        .FIFO_RD_EN(dut.fifo_read_en),
        .write_data(dut.fifo_write_data),
        .read_data(dut.fifo_read_data),
        .FIFO_FULL(),
        .FIFO_EMPTY(),
        .mem0(mem0),
        .mem1(mem1),
        .mem2(mem2),
        .mem3(mem3),
        .mem4(mem4),
        .mem5(mem5),
        .mem6(mem6),
        .mem7(mem7)
    );
              
    // Instantiate DMA controller
    dma_controller dut (
        .clk(clk),
        .reset(reset),
        .trigger(trigger),
        .length(length),
        .source_address(source_address),
        .destination_add(destination_add),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .AWREADY(AWREADY),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .done(done),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .RREADY(RREADY),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .BREADY(BREADY),
        .WSTRB(WSTRB)
    );

    // Instantiate slave testbench
        testbench_slave slave (
        .clk(clk),
        .reset(reset),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );
        
        initial begin
  $monitor("Time=%0t | mem0=%h | mem1=%h | mem2=%h | mem3=%h | mem4=%h | mem5=%h | mem6=%h | mem7=%h",
           $time, mem0, mem1, mem2, mem3, mem4, mem5, mem6, mem7);
        end
                 
    // Clock generation
    always #5 clk = ~clk;
                 
    // Test sequence
    initial begin
    
        // Initialize signals
        clk = 0;
        reset = 1;
        trigger = 0;
        length = 0;
        source_address = 0;
        destination_add = 0;

        // Reset sequence
        #20 reset = 0;

//         Test case 1: Simple transfer (4 bytes)
//        #10 source_address = 32'h1002;  // Aligned to 4 bytes
//            destination_add = 32'h2003; // Aligned to 4 bytes
//            length = 5'd10;             // Multiple of 4 bytes
//            trigger = 1;                // Trigger DMA operation
//            #10 trigger = 0;            // Deassert trigger after one clock cycle
//            wait(done);                 // Wait for operation to complete

//         Test case 2: Maximum transfer (28 bytes)
        #20 source_address = 32'h1012; // Aligned to 4 bytes
            destination_add = 32'h2103; // Aligned to 4 bytes
            length = 5'd11;            // Multiple of 4 bytes (28 bytes)
            trigger = 1;                // Trigger DMA operation
            #10 trigger = 0;            // Deassert trigger after one clock cycle
            wait(done);                 // Wait for operation to complete

////         Test case 3: Back-to-back transfers with valid alignment
//        #20 source_address = 32'h1200;   // Aligned to 4 bytes
//            destination_add = 32'h2200;  // Aligned to 4 bytes
//            length = 5'h08;              // Multiple of 4 bytes (8 bytes)
//            trigger = 1;                 // Trigger DMA operation
//            #10 trigger = 0;             // Deassert trigger after one clock cycle
//            wait(done);                  // Wait for operation to complete

//            #10 source_address = 32'h1300;   // Aligned to 4 bytes
//                destination_add = 32'h2300;   // Aligned to 4 bytes
//                length = 5'h10;               // Multiple of 4 bytes (16 bytes)
//                trigger = 1;                  // Trigger DMA operation
//                #10 trigger = 0;              // Deassert trigger after one clock cycle
//                wait(done);                   // Wait for operation to complete

//         End simulation after all test cases are executed
        #100 $finish;
    end
endmodule