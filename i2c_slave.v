

`timescale 1ns / 1ps


module slave (
    input wire scl,             // Clock signal from master
    input wire i2c_clk,        
    inout wire sda_line,        // Bidirectional data line
    output reg [6:0] addr_data_out,    // capture data    // for debugging and display use
    output reg [7:0] data_data_out    // capture data
);

   // Internal SDA control
    reg sda_o  ;                  // Output value driven on SDA
    reg sda_t ;              // SDA tri-state control: 1 = Z, 0 = drive
    wire sda_i;           //slave reads the value currently present on the SDA line.
    assign sda_line = sda_t ? 1'bz : sda_o;
    assign sda_i = sda_line;


  // Parameters: FSM states
    parameter IDLE          = 3'b000;
    parameter RECEIVE_ADDR  = 3'b001;
    parameter  ACK_ADDR      = 3'b010;
    parameter  RECEIVE_DATA  = 3'b011;
    parameter  ACK_DATA = 3'b100;

    reg [2:0] state, next_state;

      reg rw_bit ;

       // Data and control signals
    reg [6:0] addr_shift ;
    reg [7:0] data_shift ;
    reg [3:0] bit_count ;

    parameter SLAVE_ADDR = 7'b1101001;

   // Start and Stop condition detection
    reg start_flag;
    reg stop_flag;
    reg sda_prev, scl_prev;
    
    always @(posedge i2c_clk) begin
        sda_prev <= sda_i;   // storing previous state of sda
        scl_prev <= scl;      // storing previous state of scl 
        
        // Start condition: SDA falling while SCL high
        start_flag <= (scl_prev & scl) & (sda_prev & ~sda_i);
        
        // Stop condition: SDA rising while SCL high
        stop_flag <= (scl_prev & scl) & (~sda_prev & sda_i);
    end
     
   

        // FSM: State Register
    always @(posedge scl or posedge start_flag or posedge stop_flag) begin

      if (stop_flag) begin

           state <= IDLE;
            bit_count <= 0;
            addr_shift <= 7'b0000000;
            data_shift <= 8'b00000000;
            sda_t <= 1; // Release SDA
            sda_o <= 1;
      end

        else if (start_flag)
          begin
            state<= RECEIVE_ADDR ;
            bit_count <=0;
           addr_shift <= 7'b0000000;
            data_shift <= 8'b00000000;
            sda_t <= 1; // Release SDA
            sda_o <= 1;
        end
  else
            state <= next_state;
    end

      // FSM: Next-State Logic
    always @(*) begin
        case (state)
            IDLE: next_state = (start_flag ==1) ? RECEIVE_ADDR :IDLE ;

            RECEIVE_ADDR: next_state = (bit_count ==6) ? ACK_ADDR : RECEIVE_ADDR ;
            

            ACK_ADDR: begin

    if (addr_shift == SLAVE_ADDR)
        next_state =  RECEIVE_DATA; 
    else
        next_state = IDLE;
end
       RECEIVE_DATA: next_state = (bit_count==7) ? ACK_DATA : RECEIVE_DATA ; 

            ACK_DATA: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // FSM: Output Logic + Data Handling
    always @(posedge scl or posedge start_flag or posedge stop_flag) begin
        case (state)

            IDLE : begin

                sda_t<=1;    // Release SDA
                sda_o<=1 ;             // No active drive

                bit_count <= 0;
                 addr_shift <= 7'b0000000;
                    data_shift <= 8'b00000000;

            end


 RECEIVE_ADDR: begin
 
    sda_t<=1;  // release sda to read 

       addr_shift <= {addr_shift[5:0], sda_i};  // Shift bits left
    if (bit_count < 6) begin
        bit_count <= bit_count + 1;
    end
    else if (bit_count == 6) begin
        rw_bit <= sda_i;         // Capture R/W bit on 8th clock
      bit_count <=0;
    end
end

            

            ACK_ADDR: begin
     if(addr_shift == SLAVE_ADDR) begin
        sda_t <=0; // drive sda 
        sda_o <= 0 ; // Send ACK 
        addr_data_out <= addr_shift ;
        data_shift <= 8'b00000000;
        bit_count <=0;
            end
     else begin
       sda_t <= 1; // Release sda -->line stays high -->which means a NACK.
       sda_o <=1;
     end
            end

               RECEIVE_DATA: begin

                sda_t<=1;
             data_shift <= {sda_i, data_shift[7:1]}; // Shift in data bits
             if(bit_count <7) begin
                bit_count <= bit_count + 1;
            end
            else begin
                bit_count <=0 ;
            end
               end

            ACK_DATA: begin
                sda_t <= 0;  // Drive sda
                sda_o <= 0; // Always ACK for data
                bit_count <= 0;
                data_data_out <= data_shift;
            end

            default: begin
                sda_t <= 1; // Release SDA
                sda_o <= 1;
                
            end
        endcase
    end

  

endmodule


