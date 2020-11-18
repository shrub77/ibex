// Taken from: https://github.com/Steinegger/riscv_asconp_accelerator_core/blob/a1268ae59bcec48f6dbd302462020bf019434714/rtl/include/riscv_ascon_defines.sv

 // Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
//                                                                            //
// Design Name:    RISC-V processor core                                      //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Defines for various constants used by the processor core.  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

package ibex_ascon_defines;

// ASCON
// ASCON state type, makes access easier
parameter ASCON_REGISTERS    = 10;

/* verilator lint_off LITENDIAN */
localparam logic [ 0 : 32-1 ] ASCON_REGISTER_BITMAP_RV32    = 32'({
      // ra    sp    gp    tp    t0    t1    t2
  1'b0,     1'b0,    1'b0,    1'b0,    1'b0,    1'b0,    1'b0,    1'b0,
//s0    s1    a0    a1    a2    a3    a4    a5
  1'b0,    1'b0,    1'b0,    1'b0,    1'b1,    1'b1,    1'b1,    1'b1,
//a6    a7    s2    s3    s4    s5    s6    s7
  1'b1,    1'b1,    1'b0,    1'b0,    1'b0,    1'b0,    1'b0,    1'b0,
//s8    s9    s10   s11   t3    t4    t5    t6
  1'b0,    1'b0,    1'b0,    1'b0,    1'b1,    1'b1,    1'b1,    1'b1
});

localparam logic [ 0 : 16-1 ] ASCON_REGISTER_BITMAP_RV32E    = 16'({
//x0    ra    sp    gp    tp    t0    t1    t2
  1'b0,    1'b1,    1'b0,    1'b0,    1'b1,    1'b1,    1'b1,    1'b1,
//s0    s1    a0    a1    a2    a3    a4    a5
  1'b1,    1'b0,    1'b0,    1'b0,    1'b1,    1'b1,    1'b1,    1'b1
});
/* verilator lint_on LITENDIAN */
typedef struct packed {
  logic [31:0] x_hi;
  logic [31:0] x_low;
} ascon_reg_state_t;

typedef union packed {
  ascon_reg_state_t reg_view;
  logic [63:0] line_view;
} ascon_line_state_t;

typedef struct packed {
  ascon_line_state_t x0;
  ascon_line_state_t x1;
  ascon_line_state_t x2;
  ascon_line_state_t x3;
  ascon_line_state_t x4;
} ascon_state_t;

typedef struct packed {
  logic [2:0] rounds;
	logic [7:0] roundconstant;
} ascon_meta_t;

typedef struct packed {
  bit [4:0] reg_num;
  logic [31:0] val;
} ascon_port_t;

`define ROTATE_STATE_WORD(ARRAY, ROTATE) \
  {ARRAY[ROTATE-1:0], ARRAY[$size(ARRAY)-1:ROTATE]}

`define SWAP_REG_ENDIANESS(ARRAY) \
  {ARRAY[7:0], ARRAY[15:8], ARRAY[23:16], ARRAY[31:24]}

function automatic logic [31:0] SWAP_REG_ENDIANESS_FUNC(logic [31:0] inp);
	begin
		SWAP_REG_ENDIANESS_FUNC = 32'({inp[7:0], inp[15:8], inp[23:16], inp[31:24]});
	end
endfunction


endpackage
