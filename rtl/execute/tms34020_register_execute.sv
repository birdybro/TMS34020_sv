`timescale 1ns/1ps
`default_nettype none

module tms34020_register_execute (
    input  logic [15:0] first_word_i,
    input  logic [31:0] source_i,
    input  logic [31:0] destination_i,
    input  logic [31:0] status_i,
    output logic        supported_o,
    output logic        register_file_o,
    output logic [3:0]  source_index_o,
    output logic [3:0]  destination_index_o,
    output logic        register_write_enable_o,
    output logic [31:0] register_write_data_o,
    output logic        status_write_enable_o,
    output logic [31:0] status_write_data_o,
    output logic [31:0] status_write_mask_o
);

    import tms34020_pkg::*;

    logic decode_valid;
    tms34020_opcode_id_t opcode_id;
    logic [2:0] length_words;

    logic [31:0] binary_result;
    logic [3:0] binary_nczv;
    logic binary_register_write_enable;
    logic [31:0] unary_result;
    logic [3:0] unary_nczv;
    logic [3:0] unary_status_write_mask;
    logic [31:0] compare_result;
    logic [3:0] compare_nczv;
    logic [31:0] rmo_result;
    logic rmo_z;
    tms34020_binary_op_t increment_decrement_operation;
    logic [31:0] increment_decrement_result;
    logic [3:0] increment_decrement_nczv;
    logic increment_decrement_write_enable;

    tms34020_decode decode (
        .first_word_i(first_word_i),
        .valid_o(decode_valid),
        .opcode_id_o(opcode_id),
        .length_words_o(length_words)
    );

    tms34020_binary_arithmetic binary_arithmetic (
        .operation_i(tms34020_binary_op_t'(first_word_i[11:9])),
        .source_i(source_i),
        .destination_i(destination_i),
        .carry_or_borrow_i(status_i[TMS34020_ST_C_BIT]),
        .result_o(binary_result),
        .status_nczv_o(binary_nczv),
        .register_write_enable_o(binary_register_write_enable)
    );

    tms34020_unary unary (
        .operation_i(tms34020_unary_op_t'(first_word_i[6:5])),
        .destination_i(destination_i),
        .borrow_i(status_i[TMS34020_ST_C_BIT]),
        .result_o(unary_result),
        .status_nczv_o(unary_nczv),
        .status_write_mask_o(unary_status_write_mask)
    );

    tms34020_cmpk cmpk (
        .destination_i(destination_i),
        .encoded_constant_i(first_word_i[9:5]),
        .compare_result_o(compare_result),
        .status_n_o(compare_nczv[3]),
        .status_c_o(compare_nczv[2]),
        .status_z_o(compare_nczv[1]),
        .status_v_o(compare_nczv[0])
    );

    tms34020_rmo rmo (
        .source_i(source_i),
        .result_o(rmo_result),
        .status_z_o(rmo_z)
    );

    always_comb begin
        increment_decrement_operation = TMS34020_BINARY_ADD;
        if (opcode_id == TMS20_OP_DEC) begin
            increment_decrement_operation = TMS34020_BINARY_SUB;
        end
    end

    tms34020_binary_arithmetic increment_decrement (
        .operation_i(increment_decrement_operation),
        .source_i(32'd1),
        .destination_i(destination_i),
        .carry_or_borrow_i(1'b0),
        .result_o(increment_decrement_result),
        .status_nczv_o(increment_decrement_nczv),
        .register_write_enable_o(increment_decrement_write_enable)
    );

    always_comb begin
        supported_o = 1'b0;
        register_file_o = first_word_i[4];
        source_index_o = first_word_i[8:5];
        destination_index_o = first_word_i[3:0];
        register_write_enable_o = 1'b0;
        register_write_data_o = 32'd0;
        status_write_enable_o = 1'b0;
        status_write_data_o = 32'd0;
        status_write_mask_o = 32'd0;

        if (decode_valid && length_words == 3'd1) begin
            unique case (opcode_id)
                TMS20_OP_NOP: begin
                    supported_o = 1'b1;
                end

                TMS20_OP_CLRC: begin
                    supported_o = 1'b1;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = 32'd0;
                    status_write_mask_o = 32'h4000_0000;
                end

                TMS20_OP_DINT: begin
                    supported_o = 1'b1;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = 32'd0;
                    status_write_mask_o = 32'h0020_0000;
                end

                TMS20_OP_EINT: begin
                    supported_o = 1'b1;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = 32'h0020_0000;
                    status_write_mask_o = 32'h0020_0000;
                end

                TMS20_OP_SETC: begin
                    supported_o = 1'b1;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = 32'h4000_0000;
                    status_write_mask_o = 32'h4000_0000;
                end

                TMS20_OP_ABS,
                TMS20_OP_NEG,
                TMS20_OP_NEGB,
                TMS20_OP_NOT: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o = 1'b1;
                    register_write_data_o = unary_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = {unary_nczv, 28'd0};
                    status_write_mask_o =
                        {unary_status_write_mask, 28'd0};
                end

                TMS20_OP_ADD,
                TMS20_OP_ADDC,
                TMS20_OP_SUB,
                TMS20_OP_SUBB,
                TMS20_OP_CMP: begin
                    supported_o = 1'b1;
                    register_write_enable_o =
                        binary_register_write_enable;
                    register_write_data_o = binary_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = {binary_nczv, 28'd0};
                    status_write_mask_o = 32'hF000_0000;
                end

                TMS20_OP_CMPK: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_data_o = compare_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = {compare_nczv, 28'd0};
                    status_write_mask_o = 32'hF000_0000;
                end

                TMS20_OP_RMO: begin
                    supported_o = 1'b1;
                    register_write_enable_o = 1'b1;
                    register_write_data_o = rmo_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {2'd0, rmo_z, 29'd0};
                    status_write_mask_o = 32'h2000_0000;
                end

                TMS20_OP_GETST: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o = 1'b1;
                    register_write_data_o = status_i;
                end

                TMS20_OP_INC,
                TMS20_OP_DEC: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o =
                        increment_decrement_write_enable;
                    register_write_data_o = increment_decrement_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {increment_decrement_nczv, 28'd0};
                    status_write_mask_o = 32'hF000_0000;
                end

                default: begin
                    supported_o = 1'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
