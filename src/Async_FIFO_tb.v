module Async_FIFO_tb;

    parameter WIDTH = 32;
    parameter DEPTH = 8;

    reg r_clk, r_rst_n, r_en;
    reg w_clk, w_rst_n, w_en;
    reg [WIDTH-1:0] data_in;

    wire [WIDTH-1:0] data_out;
    wire full, empty;

    // Instantiate UUT
    Async_FIFO #(.DEPTH(DEPTH), .WIDTH(WIDTH)) uut (
        .r_clk(r_clk), .r_rst_n(r_rst_n), .r_en(r_en),
        .w_clk(w_clk), .w_rst_n(w_rst_n), .w_en(w_en),
        .data_in(data_in), .data_out(data_out),
        .full(full), .empty(empty)
    );

    // Clock Generation
    always #5  w_clk = ~w_clk; // Fast Write Clock
    always #12 r_clk = ~r_clk; // Slower Read Clock

    // --- TASK: Write Data ---
    task write_data(input [WIDTH-1:0] d_in);
        begin
            @(posedge w_clk);
            if (!full) begin
                w_en = 1'b1;
                data_in = d_in;
                @(posedge w_clk);
                w_en = 1'b0;
                $display("Time=%0t [WRITE] data_in = %0d", $time, d_in);
            end else begin
                $display("Time=%0t [WRITE SKIP] FIFO FULL! Cannot write %0d", $time, d_in);
            end
        end
    endtask

    // --- TASK: Read Data ---
    task read_data();
        begin
            @(posedge r_clk);
            if (!empty) begin
                r_en = 1'b1;
                @(posedge r_clk);
                r_en = 1'b0;
                // Note: data_out is registered, so it updates after the edge
                $display("Time=%0t [READ] data_out = %0d", $time, data_out);
            end else begin
                $display("Time=%0t [READ SKIP] FIFO EMPTY!", $time);
            end
        end
    endtask

    integer i;
    initial begin
        // Initialize
        w_clk = 0; r_clk = 0;
        w_rst_n = 0; r_rst_n = 0;
        w_en = 0; r_en = 0;
        data_in = 0;

        #30 w_rst_n = 1; r_rst_n = 1;
        #20;

        $display("\n--- SCENARIO 1: Basic Write/Read ---");
        write_data(1);
        write_data(10);
        write_data(100);
        repeat(3) read_data();

        $display("\n--- SCENARIO 2: Burst to Full ---");
        for (i=0; i<DEPTH; i=i+1) begin
            write_data(2**i);
        end
        
        // Wait for synchronizers to catch up
        repeat(5) @(posedge r_clk); 

        $display("\n--- SCENARIO 3: Drain to Empty ---");
        for (i=0; i<DEPTH; i=i+1) begin
            read_data();
        end

        #100;
        $display("Simulation Finished");
        $finish;
    end

    initial begin
        $dumpfile("Async_FIFO.vcd");
        $dumpvars(0);
    end

endmodule