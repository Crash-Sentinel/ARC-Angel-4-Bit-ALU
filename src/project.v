/*
 * Copyright (c) 2026 Bennett Miller
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bennett_miller_4_bit_arc_angel_alu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  parameter ADD        = 4'b0000;
  parameter SUB        = 4'b0001;
  parameter MUL        = 4'b0010;
  parameter DIV        = 4'b0011;
  parameter AND        = 4'b0100; // Logical AND
  parameter OR         = 4'b0101; // Logical OR
  parameter XOR        = 4'b0110; // Logical XOR
  parameter NOT        = 4'b0111; // Logical NOT (Unary operation)
  parameter RAND       = 4'b1000;
  parameter NAND       = 4'b1001;
  parameter NOR        = 4'b1010;
  parameter LEFTSHIFT  = 4'b1011;
  parameter RIGHTSHIFT = 4'b1100;
  parameter INCREMENT  = 4'b1101;
  parameter DECREMENT  = 4'b1110;
  parameter ROTATE     = 4'b1111; // left once

  wire [3:0] a = ui_in[7:4];
  wire [3:0] b = ui_in[3:0];
  wire [3:0] opcode = uio_in[3:0];

  reg [7:0] counter = 8'h0; // internal counter for random numbers
  wire [7:0] random_output;

  wire [4:0] add_result;
  wire [4:0] sub_result;
  wire [7:0] mul_result;
  wire [3:0] div_quotient;
  wire [3:0] div_remainder;
  wire [3:0] inc_result;
  wire [3:0] dec_result;

  wire [3:0] and_result = a & b;
  wire [3:0] or_result = a | b;
  wire [3:0] xor_result = a ^ b;
  wire [3:0] not_result_a = ~a;
  wire [3:0] not_result_b = ~b;
  wire [3:0] nand_result = ~(a & b);
  wire [3:0] nor_result = ~(a | b);

  wire [3:0] leftshift_result_a = a << 1;
  wire [3:0] leftshift_result_b = b << 1;

  wire [3:0] rightshift_result_a = a >> 1;
  wire [3:0] rightshift_result_b = b >> 1;

  wire [3:0] inc_result_a;
  wire [3:0] inc_result_b;

  wire [3:0] dec_result_a;
  wire [3:0] dec_result_b;

  reg [7:0] result;
  reg [1:0] carry_out;
  reg [1:0] overflow;

  // pseudo-random algorithm using linear shiftback registers
  // maximal length feedback taps
  wire feedback_tap;
  assign feedback_tap = counter[7] ^ counter[5] ^ counter[4] ^ counter[3];
  assign random_output = {counter[6:0], feedback_tap};

  assign add_result = a + b;

  assign sub_result = a - b;

  assign mul_result = a * b;

  assign div_quotient = (b != 0) ? a / b : 4'b0000;
  assign div_remainder = (b != 0) ? a % b : 4'b0000;

  assign inc_result_a = a + 1'b1;
  assign inc_result_b = b + 1'b1;

  assign dec_result_a = a - 1'b1;
  assign dec_result_b = b - 1'b1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      result <= 8'h0;
      carry_out <= 2'b00;
      overflow <= 2'b00;
      counter <= 8'h00;
    end else begin
      case (opcode)
        ADD: begin
          result <= {4'b0000, add_result[3:0]};
          carry_out <= {1'b0, add_result[4]};
          overflow <= {1'b0, (a[3] & b[3] & ~add_result[3]) | (~a[3] & ~b[3] & add_result[3])};
        end

        SUB: begin
          result <= {4'b0000, sub_result[3:0]};
          carry_out <= {1'b0, sub_result[4]};
          overflow <= {1'b0, (a[3] & ~b[3] & ~sub_result[3]) | (~a[3] & b[3] & sub_result[3])};
        end
        
        MUL: begin
          result <= mul_result;
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end
        
        DIV: begin
          result <= {div_remainder, div_quotient};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end
        
        AND: begin
          result <= {4'b0000, and_result};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        OR: begin
          result <= {4'b0000, or_result};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end
        
        XOR: begin
          result <= {4'b0000, xor_result};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        NOT: begin
          result <= {not_result_a, not_result_b};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        RAND: begin
          result <= random_output;
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        NAND: begin
          result <= {4'b0000, nand_result};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        NOR: begin
          result <= {4'b0000, nor_result};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        LEFTSHIFT: begin
          result <= {leftshift_result_a, leftshift_result_b};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        RIGHTSHIFT: begin
          result <= {rightshift_result_a, rightshift_result_b};
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end

        INCREMENT: begin
          result <= {inc_result_a, inc_result_b};
          carry_out <= {&a, &b}; // returns 1 if a carry out has occured
          overflow <= {~a[3] & a[2] & a[1] & a[0], ~b[3] & b[2] & b[1] & b[0]}; // similar since if carried out then likely overflowed
        end

        DECREMENT: begin
          result <= {dec_result_a, dec_result_b};
          carry_out <= {~(&a) , ~(&b)};
          overflow <= {a[3] & ~(a[2]) & ~(a[1]) & ~(a[0]), b[3] & ~(b[2]) & ~(b[1]) & ~(b[0])};
        end

        ROTATE: begin // rotate left
          result <= {
             {a[2:0], a[3]},
             {b[2:0], b[3]} 
            };
          carry_out <= 2'b00;
          overflow <= 2'b00;
        end
        
        default: begin
          result <= 8'h0;
          carry_out <= {1'b0, 1'b0};
          overflow <= {1'b0, 1'b0};
        end
      endcase

      counter <= counter + 1;
    end
  
  end

  // // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  // assign uio_out = 0;
  // assign uio_oe  = 0;

  assign uo_out = result;
  assign uio_out[7:6] = carry_out[1:0];
  assign uio_out[5:4] = overflow[1:0];
  assign uio_out[3] = 1'b0;
  assign uio_out[2] = 1'b0;
  assign uio_out[1] = 1'b0;
  assign uio_out[0] = 1'b0;

  assign uio_oe[7:6] = 2'b11;
  assign uio_oe[5:0] = 6'h0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0}; // clk, rst_n,

endmodule
