`timescale 1ns / 1ps

module dma_controller(
    input wire clk,
    input wire reset,
    input wire trigger,
    input wire [4:0] length,
    input wire [31:0] source_address,
    input wire [31:0] destination_add,
    input wire ARREADY,
    input wire [31:0] RDATA,
    input wire RVALID,
    input wire AWREADY,
    input wire WREADY,
    input wire BVALID,
    output reg [3:0] WSTRB,
    output reg done,
    output reg [31:0] ARADDR,
    output reg ARVALID,
    output reg RREADY,
    output reg [31:0] AWADDR,
    output reg AWVALID,
    output reg [31:0] WDATA,
    output reg WVALID,
    output reg BREADY
);

    // Read FSM states
    localparam READ_IDLE = 3'b000;
    localparam READ_INIT = 3'b001;
    localparam READ_WAIT = 3'b010;
    localparam READ_DATA = 3'b011;
    localparam LAST_SHOW = 3'b100;

    // Write FSM states
    localparam WRITE_IDLE = 3'b000;
    localparam WRITE_WAIT = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_AW_HANDSHAKE = 3'b011;
    localparam WRITE_W_HANDSHAKE = 3'b100;
    localparam WRITE_RESP = 3'b101;
    localparam FIRST_WRITE = 3'b110;

    reg [2:0] read_state;
    reg [2:0] write_state;
    reg [4:0] read_count;
    reg [31:0] temp, Wtemp;
    wire read_done, write_done;
    reg [5:0] bytes_written, bytes_read;
    reg [31:0] current_read_addr, current_write_addr;

    // FIFO signals
    reg fifo_write_en, fifo_read_en;
    wire fifo_full, fifo_empty;
    wire [31:0] fifo_read_data;
    reg [31:0] fifo_write_data;
    reg [3:0] fifo_write_strobe;
    
    sync_fifo fifo (
        .clk(clk),
        .reset(reset),
        .FIFO_RD_EN(fifo_read_en),
        .FIFO_WR_EN(fifo_write_en),
        .write_data(fifo_write_data),
        .read_data(fifo_read_data),
        .FIFO_FULL(fifo_full),
        .FIFO_EMPTY(fifo_empty)
    );
    
    reg [1:0] src_offset;
    reg [1:0] dest_offset;
    wire [10:0] total_transfers;
    
    // Transfer calculation
    assign total_transfers = (length + src_offset + 3) >> 2;
    assign read_done = (read_count == total_transfers + 1);
    assign write_done = (bytes_written == length) && (write_state == 3'b000);
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            done <= 0;
        else 
            done <= read_done && write_done;
    end    
    
    // Offset capture and initialization
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            src_offset <= 0;
            dest_offset <= 0;
        end 
        else if (trigger) begin
            src_offset <= source_address[1:0];
            dest_offset <= destination_add[1:0];
        end
    end

    // Read FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_state <= READ_IDLE;
            read_count <= 0;
            ARADDR <= 0;
            ARVALID <= 0;
            RREADY <= 1;
            fifo_write_en <= 0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    ARADDR <= 0;
                    ARVALID <= 0;
                    fifo_write_en <= 0;
                    if (trigger) begin
                        read_count <= 0;
                        current_read_addr <= (source_address >> 2) << 2 ;
                        read_state <= READ_INIT;
                    end
                end

                READ_INIT: begin
                    fifo_write_en <= 0;
                    if (read_count == total_transfers) begin
                        if((length % 4) != 0)
                            read_state <= LAST_SHOW;
                         else begin
                            read_count <= read_count + 1;
                            read_state <= READ_IDLE;
                        end
                    end
                    else if (!fifo_full) begin
                        ARADDR <= current_read_addr;
                        ARVALID <= 1;
                        read_state <= READ_WAIT;
                    end
                end
                
                READ_WAIT: begin
                    if (ARREADY && ARVALID) begin
                        ARVALID <= 0;
                        read_state <= READ_DATA;
                    end
                end

                READ_DATA: begin
                    if (RVALID && RREADY) begin
                        if(read_count == 0) begin
                            temp <= RDATA << (32 - (4 - src_offset)*8) >> 32 - (4 - src_offset)*8;
                            if(src_offset == 0) begin
                                fifo_write_en <= 1;
                                fifo_write_data <= RDATA << (32 - (4 - src_offset)*8) >> 32 - (4 - src_offset)*8;
                            end
                        end
                        else begin
                            temp <= RDATA << 32 - (4 - src_offset)*8 >> 32 - (4 - src_offset)*8; 
                            fifo_write_en <= 1;
                            if(src_offset == 0)
                                fifo_write_data <= RDATA;
                            else
                            fifo_write_data <= ({temp, RDATA} >> (4 - src_offset)*8);
                        end
                        read_count <= read_count + 1;
                        current_read_addr <= current_read_addr + 4;
                        read_state <= READ_INIT;
                    end
                end
                
                LAST_SHOW: begin
                    fifo_write_en <= 1;
                    fifo_write_data <= temp << (src_offset)*8;
                    read_count <= read_count + 1;
                    read_state <= READ_IDLE;
                end
                default: read_state <= READ_IDLE;
            endcase
        end
    end

// Write FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            write_state <= WRITE_IDLE;
            bytes_written <= 0;
            
            AWADDR <= 32'b0;            
            WDATA <= 32'b0;            
            AWVALID <= 0;
            WVALID <= 0;
            WSTRB <= 0;
            BREADY <= 1;
            fifo_read_en <= 0;
        end 
        else begin
            case (write_state)
                WRITE_IDLE: begin
                    AWADDR <= 32'b0;
                    WDATA <= 32'b0;
                    AWVALID <= 0;
                    WVALID <= 0;
                    WSTRB <= 0;
                    if(!fifo_empty) begin
                        bytes_written = 0;
                        current_write_addr <= (destination_add >> 2) << 4;
                        fifo_read_en <= 1;
                        write_state <= WRITE_WAIT;
                    end
                end
                
                WRITE_WAIT: begin
                    fifo_read_en <= 0;
                    if (bytes_written == length) begin   
                        write_state <= WRITE_IDLE;
                    end    
                    else begin
                        if(bytes_written == 0)
                            write_state <= FIRST_WRITE;
                         else
                            write_state <= WRITE_DATA;
                    end
                end
                
                FIRST_WRITE: begin
                    AWADDR <= current_write_addr;
                    AWVALID <= 1;
                    WDATA <= fifo_read_data >> (dest_offset*8);
                    Wtemp <= (fifo_read_data << 32 - dest_offset*8) >> (32 - dest_offset*8);
                    WVALID <= 1;
                    WSTRB <= 4'b1111 >> dest_offset;
                    bytes_written <= bytes_written + (4 - dest_offset);
                    write_state <= WRITE_AW_HANDSHAKE;
                end
            
                WRITE_DATA: begin
                        AWADDR <= current_write_addr;
                        AWVALID <= 1;
                        WDATA <= ({Wtemp, fifo_read_data}) >> (dest_offset)*8;
                        Wtemp <= (fifo_read_data << (32 - dest_offset*8)) >> (32 - dest_offset*8);
                        WVALID <= 1;
                        if ((length - bytes_written) < 4) begin
                            WSTRB <= 4'b1111 << (4 - (length - bytes_written));
                            bytes_written <= bytes_written + (length - bytes_written);
                        end
                        else begin
                            WSTRB <= 4'b1111;
                            bytes_written <= bytes_written + 4;
                        end 
                        write_state <= WRITE_AW_HANDSHAKE;
                end
            
                WRITE_AW_HANDSHAKE: begin
                    if(AWVALID && AWREADY) begin
                        AWVALID <= 0;
                        write_state <= WRITE_W_HANDSHAKE;
                    end
                end
                
                WRITE_W_HANDSHAKE: begin
                    if(WVALID && WREADY) begin
                        WVALID <= 0;
                        write_state <= WRITE_RESP;
                    end
                end
            
            
                WRITE_RESP: begin
                    if(BVALID && BREADY) begin
                        fifo_read_en <= 1;
                        current_write_addr <= current_write_addr + 4;
                        write_state <= WRITE_WAIT;
                    end
                end
                default: write_state <= WRITE_IDLE;
            endcase 
        end
    end
endmodule