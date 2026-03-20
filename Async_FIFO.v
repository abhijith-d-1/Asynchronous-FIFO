module Async_FIFO
#(parameter DEPTH = 8,
  parameter WIDTH = 32)
(   input r_clk, 
    input r_rst_n, 
    input r_en,
    input w_clk, 
    input w_rst_n, 
    input w_en,
    input [WIDTH-1:0] data_in,

    output reg [WIDTH-1:0] data_out,
    output full,
    output empty );

localparam DEPTH_LOG = $clog2(DEPTH);

reg [WIDTH-1:0] fifo [0:DEPTH-1];
reg [DEPTH_LOG:0] b_rptr, g_rptr;
reg [DEPTH_LOG:0] b_wptr, g_wptr;

wire [DEPTH_LOG:0] g_rptr_sync, g_wptr_sync;

reg [DEPTH_LOG:0] r_d1_out, r_d2_out;
reg [DEPTH_LOG:0] w_d1_out, w_d2_out;

// --- READ LOGIC ---

always @(posedge r_clk or negedge r_rst_n) begin
    if (r_rst_n == 1'b0) begin
        b_rptr <= 0;
        g_rptr <= 0;
    end
    else if (r_en && !empty) begin
        b_rptr <= b_rptr + 1;
        g_rptr <= ((b_rptr + 1) >> 1) ^ (b_rptr + 1);
    end
end

always @(posedge r_clk or negedge r_rst_n) begin
    if (r_rst_n == 1'b0) begin
        data_out <= 0;
    end
    else if (r_en && !empty) begin
        data_out <= fifo[b_rptr[DEPTH_LOG-1:0]];
    end
end

always @(posedge r_clk or negedge r_rst_n) begin
    if (!r_rst_n) begin
        r_d1_out <= 0;
        r_d2_out <= 0;
    end
    else begin
        r_d1_out <= g_wptr;
        r_d2_out <= r_d1_out;
    end
end

assign g_wptr_sync = r_d2_out;
assign empty = (g_wptr_sync == g_rptr) ? 1'b1 : 1'b0;


// --- WRITE LOGIC ---

always @(posedge w_clk or negedge w_rst_n) begin
    if (w_rst_n == 1'b0) begin
        b_wptr <= 0;
        g_wptr <= 0;
    end
    else if (w_en && !full) begin
        b_wptr <= b_wptr + 1;
        g_wptr <= ((b_wptr + 1) >> 1) ^ (b_wptr + 1);
    end
end

always @(posedge w_clk) begin
    if (w_en && !full) begin
        fifo[b_wptr[DEPTH_LOG-1:0]] <= data_in;
    end
end

// Synchronizer: Added reset to ensure clean startup
always @(posedge w_clk or negedge w_rst_n) begin
    if (!w_rst_n) begin
        w_d1_out <= 0;
        w_d2_out <= 0;
    end
    else begin
        w_d1_out <= g_rptr;
        w_d2_out <= w_d1_out;
    end
end

assign g_rptr_sync = w_d2_out;

assign full = (g_wptr == {~g_rptr_sync[DEPTH_LOG:DEPTH_LOG-1], g_rptr_sync[DEPTH_LOG-2:0]});

endmodule