// Copyright lowRISC contributors.
// Copyright 2018 ETH Zurich and University of Bologna, see also CREDITS.md.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * RISC-V register file
 *
 * Register file with 31 or 15x 32 bit wide registers. Register 0 is fixed to 0.
 * This register file is based on flip flops. Use this register file when
 * targeting FPGA synthesis or Verilator simulation.
 */

/* verilator lint_off IMPORTSTAR */
import ibex_ascon_defines::*;
/* verilator lint_off IMPORTSTAR */
module ibex_register_file_ff #(
    parameter bit          RV32E             = 0,
    parameter int unsigned DataWidth         = 32,
    parameter bit          DummyInstructions = 0,
    parameter bit          Ascon_Instr = 0
) (
    // Clock and Reset
    input  logic                 clk_i,
    input  logic                 rst_ni,

    input  logic                 test_en_i,
    input  logic                 dummy_instr_id_i,

    //Read port R1
    input  logic [4:0]           raddr_a_i,
    output logic [DataWidth-1:0] rdata_a_o,

    //Read port R2
    input  logic [4:0]           raddr_b_i,
    output logic [DataWidth-1:0] rdata_b_o,


    // Write port W1
    input  logic [4:0]           waddr_a_i,
    input  logic [DataWidth-1:0] wdata_a_i,
    input  logic                 we_a_i,

    // ASCON read port
    output ascon_state_t           rdata_ascon_o,
    // ASCON write port
    input ascon_state_t            wdata_ascon_i,
    input logic                    we_ascon_update_i

);

  localparam int unsigned ADDR_WIDTH = RV32E ? 4 : 5;
  localparam int unsigned NUM_WORDS  = 2**ADDR_WIDTH;

  logic [NUM_WORDS-1:0][DataWidth-1:0] rf_reg;
  logic [NUM_WORDS-1:1][DataWidth-1:0] rf_reg_q;
  logic [NUM_WORDS-1:1]                we_a_dec;

  // ASCON definitions

  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
  /* verilator lint_off LITENDIAN */
  logic [0 : NUM_WORDS -1] ASCON_REGISTER_BITMAP;
  logic [NUM_WORDS -1 :0][DataWidth -1:0] ascon_port_reg_array;
  /* verilator lint_on LITENDIAN */
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  // generate register bitmap for RV32E or RV32
  generate
    if (RV32E == 1) begin
      assign ASCON_REGISTER_BITMAP = ASCON_REGISTER_BITMAP_RV32E;
    end else begin
      assign ASCON_REGISTER_BITMAP = ASCON_REGISTER_BITMAP_RV32;
    end
  endgenerate
  // ASCON assignments
  assign rdata_ascon_o.x0.reg_view.x_hi  = rf_reg_q[12];
  assign rdata_ascon_o.x0.reg_view.x_low = rf_reg_q[13];
  assign rdata_ascon_o.x1.reg_view.x_hi  = rf_reg_q[14];
  assign rdata_ascon_o.x1.reg_view.x_low = rf_reg_q[15];
  assign rdata_ascon_o.x2.reg_view.x_hi  = rf_reg_q[16];
  assign rdata_ascon_o.x2.reg_view.x_low = rf_reg_q[17];
  assign rdata_ascon_o.x3.reg_view.x_hi  = rf_reg_q[28];
  assign rdata_ascon_o.x3.reg_view.x_low = rf_reg_q[29];
  assign rdata_ascon_o.x4.reg_view.x_hi  = rf_reg_q[30];
  assign rdata_ascon_o.x4.reg_view.x_low = rf_reg_q[31];


  // TODO change this mapping depending on RV32 or RV32E

  assign ascon_port_reg_array[12] = wdata_ascon_i.x0.reg_view.x_hi;
  assign ascon_port_reg_array[13] = wdata_ascon_i.x0.reg_view.x_low;
  assign ascon_port_reg_array[14] = wdata_ascon_i.x1.reg_view.x_hi;
  assign ascon_port_reg_array[15] = wdata_ascon_i.x1.reg_view.x_low;
  assign ascon_port_reg_array[16] = wdata_ascon_i.x2.reg_view.x_hi;
  assign ascon_port_reg_array[17] = wdata_ascon_i.x2.reg_view.x_low;
  assign ascon_port_reg_array[28] = wdata_ascon_i.x3.reg_view.x_hi;
  assign ascon_port_reg_array[29] = wdata_ascon_i.x3.reg_view.x_low;
  assign ascon_port_reg_array[30] = wdata_ascon_i.x4.reg_view.x_hi;
  assign ascon_port_reg_array[31] = wdata_ascon_i.x4.reg_view.x_low;





  always_comb begin : we_a_decoder
    for (int unsigned i = 1; i < NUM_WORDS; i++) begin
      we_a_dec[i] = (waddr_a_i == 5'(i)) ?  we_a_i : 1'b0;
    end
  end

  if (Ascon_Instr == 1) begin
  // Generate Ascon connections to register file
  // No flops for R0 as it's hard-wired to 0
    for (genvar i = 1; i < NUM_WORDS; i++) begin : g_rf_flops
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          rf_reg_q[i] <= '0;
        end else begin
          if (ASCON_REGISTER_BITMAP[i] == 1) begin
            if (we_ascon_update_i == 1'b1) begin 
            //update designated registers from the ASCONp block
              rf_reg_q[i] <= ascon_port_reg_array[i];
            end else if(we_a_dec[i] == 1'b1) begin
              rf_reg_q[i] <= wdata_a_i;
            end
          end else begin
            if(we_a_dec[i] == 1'b1) begin
              rf_reg_q[i] <= wdata_a_i;
            end
          end
        end
      end
    end
  end else begin
  // No flops for R0 as it's hard-wired to 0
    for (genvar i = 1; i < NUM_WORDS; i++) begin : g_rf_flops
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          rf_reg_q[i] <= '0;
        end else if(we_a_dec[i]) begin
          rf_reg_q[i] <= wdata_a_i;
        end
      end
    end
  end

  // With dummy instructions enabled, R0 behaves as a real register but will always return 0 for
  // real instructions.
  if (DummyInstructions) begin : g_dummy_r0
    logic                 we_r0_dummy;
    logic [DataWidth-1:0] rf_r0_q;

    // Write enable for dummy R0 register (waddr_a_i will always be 0 for dummy instructions)
    assign we_r0_dummy = we_a_i & dummy_instr_id_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        rf_r0_q <= '0;
      end else if (we_r0_dummy) begin
        rf_r0_q <= wdata_a_i;
      end
    end

    // Output the dummy data for dummy instructions, otherwise R0 reads as zero
    assign rf_reg[0] = dummy_instr_id_i ? rf_r0_q : '0;

  end else begin : g_normal_r0
    logic unused_dummy_instr_id;
    assign unused_dummy_instr_id = dummy_instr_id_i;

    // R0 is nil
    assign rf_reg[0] = '0;
  end

  assign rf_reg[NUM_WORDS-1:1] = rf_reg_q[NUM_WORDS-1:1];

  assign rdata_a_o = rf_reg[raddr_a_i];
  assign rdata_b_o = rf_reg[raddr_b_i];

  // Signal not used in FF register file
  logic unused_test_en;
  assign unused_test_en = test_en_i;

endmodule
