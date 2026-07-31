`timescale 1ns/1ps
`default_nettype none

module tms34020_pc_execute (
    input  logic [15:0] first_word_i,
    input  logic [2:0]  packet_length_words_i,
    input  logic [15:0] immediate_word_i,
    input  logic [31:0] sequential_next_pc_i,
    input  logic [31:0] destination_i,
    input  logic [31:0] status_i,

    output logic        supported_o,
    output logic        register_write_enable_o,
    output logic [31:0] register_write_data_o,
    output logic        redirect_enable_o,
    output logic [31:0] redirect_bit_address_o
);

    import tms34020_pkg::*;

    logic decode_valid;
    tms34020_opcode_id_t opcode_id;
    logic [2:0] decoded_length_words;
    logic [31:0] decrement_result;
    logic [31:0] signed_displacement_bits;
    logic [31:0] dsjs_magnitude_bits;
    logic dsj_condition;

    tms34020_decode decode (
        .first_word_i(first_word_i),
        .valid_o(decode_valid),
        .opcode_id_o(opcode_id),
        .length_words_o(decoded_length_words)
    );

    always_comb begin
        decrement_result = destination_i - 32'd1;
        signed_displacement_bits = {
            {12{immediate_word_i[15]}},
            immediate_word_i,
            4'd0
        };
        dsjs_magnitude_bits = {
            23'd0,
            first_word_i[9:5],
            4'd0
        };
        dsj_condition =
            opcode_id == TMS20_OP_DSJ ||
            (
                opcode_id == TMS20_OP_DSJEQ &&
                status_i[TMS34020_ST_Z_BIT]
            ) ||
            (
                opcode_id == TMS20_OP_DSJNE &&
                !status_i[TMS34020_ST_Z_BIT]
            );
        supported_o = 1'b0;
        register_write_enable_o = 1'b0;
        register_write_data_o = 32'd0;
        redirect_enable_o = 1'b0;
        redirect_bit_address_o = 32'd0;

        if (decode_valid &&
            packet_length_words_i == decoded_length_words) begin
            unique case (opcode_id)
                TMS20_OP_GETPC: begin
                    supported_o = 1'b1;
                    register_write_enable_o = 1'b1;
                    register_write_data_o = sequential_next_pc_i;
                end

                TMS20_OP_EXGPC: begin
                    supported_o = 1'b1;
                    register_write_enable_o = 1'b1;
                    register_write_data_o = sequential_next_pc_i;
                    redirect_enable_o = 1'b1;
                    redirect_bit_address_o =
                        destination_i & 32'hFFFF_FFF0;
                end

                TMS20_OP_JUMP: begin
                    supported_o = 1'b1;
                    redirect_enable_o = 1'b1;
                    redirect_bit_address_o =
                        destination_i & 32'hFFFF_FFF0;
                end

                TMS20_OP_DSJ,
                TMS20_OP_DSJEQ,
                TMS20_OP_DSJNE: begin
                    supported_o = 1'b1;
                    if (dsj_condition) begin
                        register_write_enable_o = 1'b1;
                        register_write_data_o = decrement_result;
                        if (decrement_result != 32'd0) begin
                            redirect_enable_o = 1'b1;
                            redirect_bit_address_o =
                                sequential_next_pc_i +
                                signed_displacement_bits;
                        end
                    end
                end

                TMS20_OP_DSJS: begin
                    supported_o = 1'b1;
                    register_write_enable_o = 1'b1;
                    register_write_data_o = decrement_result;
                    if (decrement_result != 32'd0) begin
                        redirect_enable_o = 1'b1;
                        if (first_word_i[10]) begin
                            redirect_bit_address_o =
                                sequential_next_pc_i -
                                dsjs_magnitude_bits;
                        end else begin
                            redirect_bit_address_o =
                                sequential_next_pc_i +
                                dsjs_magnitude_bits;
                        end
                    end
                end

                default: begin
                    supported_o = 1'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
