/* verilator lint_off IMPORTSTAR */
import ibex_ascon_defines::*;
/* verilator lint_off IMPORTSTAR */

//`define ROTATE_STATE_WORD(ARRAY, ROTATE) \
//	{ARRAY[ROTATE-1:0], ARRAY[$size(ARRAY)-1:ROTATE]}



module ibex_asconp
#(
	parameter UNROLLED_ROUNDS           = 1,
	parameter SWAP_ENDIANESS            = 1,
	parameter INTERMEDIATE_MULTIPLEXER  = 0
)
(
	input  ascon_meta_t    ascon_meta_info_i,

	input  ascon_state_t   ascon_state_i,
	output ascon_state_t   ascon_state_o,
	input  logic           ascon_instruction_en_i,
	output logic           ascon_update_done_o
);
	localparam  ASCON_LANE_BITS = 64;

	assign ascon_update_done_o = ascon_instruction_en_i;

	/// -----------------
	// System verilog port of https://github.com/IAIK/ascon_hardware/blob/master/caesar_hardware_api_v_1_0_3/ASCON_ASCON/src_rtl/CipherCore.vhd
	// Unroled round permutation
	/* verilator lint_off UNOPTFLAT */ // there is no combinatorial loop here but verilator complains
	logic [UNROLLED_ROUNDS:0] [ASCON_LANE_BITS-1:0] P0_DV;
	logic [UNROLLED_ROUNDS:0] [ASCON_LANE_BITS-1:0] P1_DV;
	logic [UNROLLED_ROUNDS:0] [ASCON_LANE_BITS-1:0] P2_DV;
	logic [UNROLLED_ROUNDS:0] [ASCON_LANE_BITS-1:0] P3_DV;
	logic [UNROLLED_ROUNDS:0] [ASCON_LANE_BITS-1:0] P4_DV;

	// Little endian
	always_comb begin
		unique if (ascon_instruction_en_i == 1'b1) begin
			if (SWAP_ENDIANESS == 1) begin
				// $write("Swapping endianess before instruction");
				P0_DV[0] = {SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x0.reg_view.x_hi), SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x0.reg_view.x_low)};
				P1_DV[0] = {SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x1.reg_view.x_hi), SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x1.reg_view.x_low)};
				P2_DV[0] = {SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x2.reg_view.x_hi), SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x2.reg_view.x_low)};
				P3_DV[0] = {SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x3.reg_view.x_hi), SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x3.reg_view.x_low)};
				P4_DV[0] = {SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x4.reg_view.x_hi), SWAP_REG_ENDIANESS_FUNC(ascon_state_i.x4.reg_view.x_low)};
			end else begin
				// Big endian
				// $write("NOT Swapping endianess before instruction");
				P0_DV[0] = ascon_state_i.x0.line_view;
				P1_DV[0] = ascon_state_i.x1.line_view;
				P2_DV[0] = ascon_state_i.x2.line_view;
				P3_DV[0] = ascon_state_i.x3.line_view;
				P4_DV[0] = ascon_state_i.x4.line_view;
			end
		end else begin
			P0_DV[0] = 'b0;
			P1_DV[0] = 'b0;
			P2_DV[0] = 'b0;
			P3_DV[0] = 'b0;
			P4_DV[0] = 'b0;
		end
	end


	genvar r;
	generate
		for (r = 0; r < UNROLLED_ROUNDS; r++) begin
			logic [7: 0] RoundConst_DV;
			logic [3: 0] HALF_RC;
			logic [ASCON_LANE_BITS-1:0] R0_DV;
			logic [ASCON_LANE_BITS-1:0] R1_DV;
			logic [ASCON_LANE_BITS-1:0] R2_DV;
			logic [ASCON_LANE_BITS-1:0] R3_DV;
			logic [ASCON_LANE_BITS-1:0] R4_DV;
			logic [ASCON_LANE_BITS-1:0] S0_DV;
			logic [ASCON_LANE_BITS-1:0] S1_DV;
			logic [ASCON_LANE_BITS-1:0] S2_DV;
			logic [ASCON_LANE_BITS-1:0] S3_DV;
			logic [ASCON_LANE_BITS-1:0] S4_DV;
			logic [ASCON_LANE_BITS-1:0] T0_DV;
			logic [ASCON_LANE_BITS-1:0] T1_DV;
			logic [ASCON_LANE_BITS-1:0] T2_DV;
			logic [ASCON_LANE_BITS-1:0] T3_DV;
			logic [ASCON_LANE_BITS-1:0] T4_DV;
			logic [ASCON_LANE_BITS-1:0] U0_DV;
			logic [ASCON_LANE_BITS-1:0] U1_DV;
			logic [ASCON_LANE_BITS-1:0] U2_DV;
			logic [ASCON_LANE_BITS-1:0] U3_DV;
			logic [ASCON_LANE_BITS-1:0] U4_DV;
			always_comb
			begin
			// Calculate round constant
			// RoundConst_DV             = (others => '0');  -- set to zero
			// RoundConst_DV(7 downto 0) = not std_logic_vector(unsigned(ascon_meta_info_i.(3 downto 0)) + r) &
			// 																 std_logic_vector(unsigned(RoundCounter_DP(3 downto 0)) + r);
			// RoundConst_DV = 8'({4'(ascon_meta_info_i.roundconstant[7:4] - r), 4'(ascon_meta_info_i.roundconstant[3:0] + r)});

			// TODO Fix this warning
			/* verilator lint_off WIDTH */
			HALF_RC = 4'(ascon_meta_info_i.roundconstant[7:4] - r);
			RoundConst_DV = 8'({HALF_RC, ~HALF_RC});
			// RoundConst_DV = ascon_meta_info_i.roundconstant[7:0];

			R0_DV = P0_DV[r] ^ P4_DV[r];
			R1_DV = P1_DV[r];
			R2_DV = P2_DV[r] ^ P1_DV[r] ^ RoundConst_DV;
			R3_DV = P3_DV[r];
			R4_DV = P4_DV[r] ^ P3_DV[r];
			/* verilator lint_on WIDTH */
			S0_DV = R0_DV ^ (~ R1_DV & R2_DV);
			S1_DV = R1_DV ^ (~ R2_DV & R3_DV);
			S2_DV = R2_DV ^ (~ R3_DV & R4_DV);
			S3_DV = R3_DV ^ (~ R4_DV & R0_DV);
			S4_DV = R4_DV ^ (~ R0_DV & R1_DV);

			T0_DV = S0_DV ^ S4_DV;
			T1_DV = S1_DV ^ S0_DV;
			T2_DV = ~ S2_DV;
			T3_DV = S3_DV ^ S2_DV;
			T4_DV = S4_DV;

			U0_DV = T0_DV ^ `ROTATE_STATE_WORD(T0_DV, 19) ^ `ROTATE_STATE_WORD(T0_DV, 28);
			U1_DV = T1_DV ^ `ROTATE_STATE_WORD(T1_DV, 61) ^ `ROTATE_STATE_WORD(T1_DV, 39);
			U2_DV = T2_DV ^ `ROTATE_STATE_WORD(T2_DV, 1)  ^ `ROTATE_STATE_WORD(T2_DV, 6);
			U3_DV = T3_DV ^ `ROTATE_STATE_WORD(T3_DV, 10) ^ `ROTATE_STATE_WORD(T3_DV, 17);
			U4_DV = T4_DV ^ `ROTATE_STATE_WORD(T4_DV, 7)  ^ `ROTATE_STATE_WORD(T4_DV, 41);

			P0_DV[r+1] = U0_DV;
			P1_DV[r+1] = U1_DV;
			P2_DV[r+1] = U2_DV;
			P3_DV[r+1] = U3_DV;
			P4_DV[r+1] = U4_DV;
			end
		end
	endgenerate
	/* verilator lint_on UNOPTFLAT */
	/// -----------------


		always_comb begin
			unique if (unsigned'(ascon_meta_info_i.rounds) < UNROLLED_ROUNDS) begin
				if (INTERMEDIATE_MULTIPLEXER == 1) begin
					logic [3:0] multiplexer_select;

					unique case(ascon_meta_info_i.rounds)
							3'b000 : multiplexer_select = 4'b0001;
							3'b001 : multiplexer_select = 4'b0010;
							3'b010 : multiplexer_select = 4'b0011;
							3'b011 : multiplexer_select = 4'b0100;
							3'b100 : multiplexer_select = 4'b0101;
							3'b101 : multiplexer_select = 4'b0110;
							3'b110 : multiplexer_select = 4'b0111;
							3'b111 : multiplexer_select = 4'b1000;
					endcase

					if (SWAP_ENDIANESS == 1) begin
						// little endian
						logic [31:0] P0_DV_hi;
						logic [31:0] P0_DV_low;
						logic [31:0] P1_DV_hi;
						logic [31:0] P1_DV_low;
						logic [31:0] P2_DV_hi;
						logic [31:0] P2_DV_low;
						logic [31:0] P3_DV_hi;
						logic [31:0] P3_DV_low;
						logic [31:0] P4_DV_hi;
						logic [31:0] P4_DV_low;


						P0_DV_hi  = P0_DV[multiplexer_select][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P0_DV_low = P0_DV[multiplexer_select][(ASCON_LANE_BITS/2)-1:0];
						P1_DV_hi  = P1_DV[multiplexer_select][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P1_DV_low = P1_DV[multiplexer_select][(ASCON_LANE_BITS/2)-1:0];
						P2_DV_hi  = P2_DV[multiplexer_select][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P2_DV_low = P2_DV[multiplexer_select][(ASCON_LANE_BITS/2)-1:0];
						P3_DV_hi  = P3_DV[multiplexer_select][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P3_DV_low = P3_DV[multiplexer_select][(ASCON_LANE_BITS/2)-1:0];
						P4_DV_hi  = P4_DV[multiplexer_select][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P4_DV_low = P4_DV[multiplexer_select][(ASCON_LANE_BITS/2)-1:0];
						ascon_state_o.x0.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P0_DV_hi);
						ascon_state_o.x0.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P0_DV_low);
						ascon_state_o.x1.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P1_DV_hi);
						ascon_state_o.x1.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P1_DV_low);
						ascon_state_o.x2.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P2_DV_hi);
						ascon_state_o.x2.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P2_DV_low);
						ascon_state_o.x3.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P3_DV_hi);
						ascon_state_o.x3.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P3_DV_low);
						ascon_state_o.x4.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P4_DV_hi);
						ascon_state_o.x4.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P4_DV_low);
					end else begin
						// big endian
						ascon_state_o.x0.line_view  = P0_DV[multiplexer_select];
						ascon_state_o.x1.line_view  = P1_DV[multiplexer_select];
						ascon_state_o.x2.line_view  = P2_DV[multiplexer_select];
						ascon_state_o.x3.line_view  = P3_DV[multiplexer_select];
						ascon_state_o.x4.line_view  = P4_DV[multiplexer_select];
					end // if (SWAP_ENDIANESS == 1)
				end else begin
					if (SWAP_ENDIANESS == 1) begin
						// little endian
						logic [31:0] P0_DV_hi;
						logic [31:0] P0_DV_low;
						logic [31:0] P1_DV_hi;
						logic [31:0] P1_DV_low;
						logic [31:0] P2_DV_hi;
						logic [31:0] P2_DV_low;
						logic [31:0] P3_DV_hi;
						logic [31:0] P3_DV_low;
						logic [31:0] P4_DV_hi;
						logic [31:0] P4_DV_low;

						P0_DV_hi  = P0_DV[UNROLLED_ROUNDS][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P0_DV_low = P0_DV[UNROLLED_ROUNDS][(ASCON_LANE_BITS/2)-1:0];
						P1_DV_hi  = P1_DV[UNROLLED_ROUNDS][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P1_DV_low = P1_DV[UNROLLED_ROUNDS][(ASCON_LANE_BITS/2)-1:0];
						P2_DV_hi  = P2_DV[UNROLLED_ROUNDS][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P2_DV_low = P2_DV[UNROLLED_ROUNDS][(ASCON_LANE_BITS/2)-1:0];
						P3_DV_hi  = P3_DV[UNROLLED_ROUNDS][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P3_DV_low = P3_DV[UNROLLED_ROUNDS][(ASCON_LANE_BITS/2)-1:0];
						P4_DV_hi  = P4_DV[UNROLLED_ROUNDS][ASCON_LANE_BITS-1:(ASCON_LANE_BITS/2)];
						P4_DV_low = P4_DV[UNROLLED_ROUNDS][(ASCON_LANE_BITS/2)-1:0];

						ascon_state_o.x0.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P0_DV_hi);
						ascon_state_o.x0.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P0_DV_low);
						ascon_state_o.x1.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P1_DV_hi);
						ascon_state_o.x1.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P1_DV_low);
						ascon_state_o.x2.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P2_DV_hi);
						ascon_state_o.x2.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P2_DV_low);
						ascon_state_o.x3.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P3_DV_hi);
						ascon_state_o.x3.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P3_DV_low);
						ascon_state_o.x4.reg_view.x_hi  = SWAP_REG_ENDIANESS_FUNC(P4_DV_hi);
						ascon_state_o.x4.reg_view.x_low = SWAP_REG_ENDIANESS_FUNC(P4_DV_low);
					end else begin
						// big endian
						ascon_state_o.x0.line_view  = P0_DV[UNROLLED_ROUNDS];
						ascon_state_o.x1.line_view  = P1_DV[UNROLLED_ROUNDS];
						ascon_state_o.x2.line_view  = P2_DV[UNROLLED_ROUNDS];
						ascon_state_o.x3.line_view  = P3_DV[UNROLLED_ROUNDS];
						ascon_state_o.x4.line_view  = P4_DV[UNROLLED_ROUNDS];
					end // if (SWAP_ENDIANESS == 1)
				end // if (INTERMEDIATE_MULTIPLEXER == 1)
			end else begin
				// ascon_state_o = {160{1'b10}};
				ascon_state_o = 'b0;
			end // if (unsigned'(ascon_meta_info_i.rounds) < UNROLLED_ROUNDS)
		end

endmodule