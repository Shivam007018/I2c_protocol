`timescale 1ns / 1ps

module master (
    input wire i2c_clk,
    input wire reset,
    inout wire sda_line,
    output reg scl,
    output wire [2:0] state_out
);

    parameter SLAVE_ADDR = 7'b1101001;
    parameter DATA_BYTE  = 8'b10101010;

    reg [7:0] transmit_byte;  // byte to be transmitted
    reg [3:0] bit_count;
    reg [2:0] state;
    assign state_out = state;

    reg sda_drive;
    reg sda_out;
    assign sda_line = sda_drive ? sda_out : 1'bz;

    parameter IDLE      = 3'b000,
              START     = 3'b001,
              SEND_ADDR = 3'b010,
              WAIT_ACK1 = 3'b011,
              SEND_DATA = 3'b100,
              WAIT_ACK2 = 3'b101,
              STOP      = 3'b110;

    reg [2:0] phase;
    reg [3:0] delay_count;

    always @(posedge i2c_clk) begin
        if (reset) begin
            state <= IDLE;
            scl <= 1;
            sda_out <= 1;
            sda_drive <= 1;
            transmit_byte <= 0;
            bit_count <= 0;
            phase <= 0;
            delay_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    scl <= 1;
                    sda_out <= 1;
                    sda_drive <= 1;
                    phase <= 0;
                    delay_count <= 0;
                    if (delay_count < 4) begin
                        delay_count <= delay_count + 1;
                    end else begin
                        state <= START;
                    end
                end

                START: begin
                    case (phase)
                        0: begin
                            scl <= 1;
                            sda_out <= 0; // START condition
                            sda_drive <= 1;
                            phase <= 1;
                        end
                        1: begin
                            scl <= 0; // Pull SCL low
                            transmit_byte <= {SLAVE_ADDR, 1'b0}; // Address + Write bit
                            bit_count <= 7;
                            phase <= 0;
                            state <= SEND_ADDR;
                        end
                    endcase
                end

                SEND_ADDR: begin
                    case (phase)
                        0: begin
                            sda_out <= transmit_byte[bit_count];
                            sda_drive <= 1;
                            phase <= 1;
                        end
                        1: begin
                            scl <= 1;
                            phase <= 2;
                        end
                        2: begin
                            scl <= 0;
                            if (bit_count == 0) begin
                                phase <= 0;
                                state <= WAIT_ACK1;
                            end else begin
                                bit_count <= bit_count - 1;
                                phase <= 0;
                            end
                        end
                    endcase
                end

                WAIT_ACK1: begin
                    case (phase)
                        0: begin
                            sda_drive <= 0; // Release SDA
                            phase <= 1;
                        end
                        1: begin
                            scl <= 1;
                            phase <= 2;
                        end
                        2: begin
                            scl <= 0;
                            transmit_byte <= DATA_BYTE;
                            bit_count <= 7;
                            sda_drive <= 1;
                            phase <= 0;
                            state <= SEND_DATA;
                        end
                    endcase
                end

                SEND_DATA: begin
                    case (phase)
                        0: begin
                            sda_out <= transmit_byte[bit_count];
                            sda_drive <= 1;
                            phase <= 1;
                        end
                        1: begin
                            scl <= 1;
                            phase <= 2;
                        end
                        2: begin
                            scl <= 0;
                            if (bit_count == 0) begin
                                phase <= 0;
                                state <= WAIT_ACK2;
                            end else begin
                                bit_count <= bit_count - 1;
                                phase <= 0;
                            end
                        end
                    endcase
                end

                WAIT_ACK2: begin
                    case (phase)
                        0: begin
                            sda_drive <= 0; // Release SDA
                            phase <= 1;
                        end
                        1: begin
                            scl <= 1;
                            phase <= 2;
                        end
                        2: begin
                            scl <= 0;
                            sda_drive <= 1;
                            phase <= 0;
                            state <= STOP;
                        end
                    endcase
                end

                STOP: begin
                    case (phase)
                        0: begin
                            sda_out <= 0;
                            sda_drive <= 1;
                            phase <= 1;
                        end
                        1: begin
                            scl <= 1;
                            phase <= 2;
                        end
                        2: begin
                            sda_out <= 1; // STOP condition
                            phase <= 3;
                        end
                        3: begin
                            state <= IDLE;
                            phase <= 0;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule
