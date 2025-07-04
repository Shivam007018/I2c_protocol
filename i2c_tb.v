`timescale 1ns/1ps


module i2c_tb;

    reg i2c_clk;
    reg reset;
    wire scl;
    wire sda_line;
    wire [6:0] addr_data_out;
    wire [7:0] data_data_out;
    wire [2:0] state_out;

    // Clock generation 
    initial i2c_clk = 0;
    always #50 i2c_clk = ~i2c_clk; 

    // Reset generation
    initial begin
        reset = 1;
        #200;
        reset = 0;
    end

    // DUT instantiation
    master dut_master (
        .i2c_clk(i2c_clk),
        .reset(reset),
        .sda_line(sda_line),
        .scl(scl),
        .state_out(state_out)
    );

    slave dut_slave (
        .scl(scl),
        .i2c_clk(i2c_clk),
        .sda_line(sda_line),
        .addr_data_out(addr_data_out),
        .data_data_out(data_data_out)
    );

    // Simulation control and monitoring
    initial begin
        $dumpfile("i2c_test.vcd");
        $dumpvars(0, i2c_tb);

        // Wait for transaction to complete
        #10000;
        
      
        $display("FINAL RESULTS:");
        $display("Slave received Address: %b ", addr_data_out, addr_data_out);
        $display("Slave received Data:    %b )", data_data_out, data_data_out);
      
        
        // Verify results
        if (addr_data_out == 7'b1101001) begin
            $display(" Address reception: PASS");
        end else begin
            $display(" Address reception: FAIL" );
        end
        
        if (data_data_out == 8'b10101010) begin
            $display(" Data reception: PASS");
        end else begin
            $display(" Data reception: FAIL" );
        end
        
  
        $finish;
    end

endmodule
