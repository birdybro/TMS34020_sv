`timescale 1ns/1ps
`default_nettype none

module tms34020_register_execute (
    input  logic [15:0] first_word_i,
    input  logic [2:0]  packet_length_words_i,
    input  logic [31:0] immediate_i,
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
    logic [31:0] logical_result;
    logic logical_z;
    tms34020_logical_op_t immediate_logical_operation;
    logic [31:0] immediate_logical_result;
    logic immediate_logical_z;
    logic [31:0] addxyi_result;
    logic [3:0] addxyi_nczv;
    logic [31:0] immediate_add_source;
    logic [31:0] immediate_add_result;
    logic [3:0] immediate_add_nczv;
    logic immediate_add_write_enable;
    logic [31:0] immediate_subtract_source;
    logic [31:0] immediate_subtract_result;
    logic [3:0] immediate_subtract_nczv;
    logic immediate_subtract_write_enable;
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

    tms34020_logical logical (
        .operation_i(tms34020_logical_op_t'(first_word_i[10:9])),
        .source_i(source_i),
        .destination_i(destination_i),
        .result_o(logical_result),
        .status_z_o(logical_z)
    );

    always_comb begin
        immediate_logical_operation = TMS34020_LOGICAL_ANDN;
        if (opcode_id == TMS20_OP_ORI) begin
            immediate_logical_operation = TMS34020_LOGICAL_OR;
        end else if (opcode_id == TMS20_OP_XORI) begin
            immediate_logical_operation = TMS34020_LOGICAL_XOR;
        end
    end

    tms34020_logical immediate_logical (
        .operation_i(immediate_logical_operation),
        .source_i(immediate_i),
        .destination_i(destination_i),
        .result_o(immediate_logical_result),
        .status_z_o(immediate_logical_z)
    );

    tms34020_addxyi addxyi (
        .destination_i(destination_i),
        .immediate_i(immediate_i),
        .result_o(addxyi_result),
        .status_n_o(addxyi_nczv[3]),
        .status_c_o(addxyi_nczv[2]),
        .status_z_o(addxyi_nczv[1]),
        .status_v_o(addxyi_nczv[0])
    );

    always_comb begin
        immediate_add_source = immediate_i;
        if (opcode_id == TMS20_OP_ADDI_W) begin
            immediate_add_source = {
                {16{immediate_i[15]}},
                immediate_i[15:0]
            };
        end
    end

    tms34020_binary_arithmetic immediate_add (
        .operation_i(TMS34020_BINARY_ADD),
        .source_i(immediate_add_source),
        .destination_i(destination_i),
        .carry_or_borrow_i(1'b0),
        .result_o(immediate_add_result),
        .status_nczv_o(immediate_add_nczv),
        .register_write_enable_o(immediate_add_write_enable)
    );

    always_comb begin
        immediate_subtract_source = ~immediate_i;
        if (opcode_id == TMS20_OP_SUBI_W) begin
            immediate_subtract_source = {
                {16{~immediate_i[15]}},
                ~immediate_i[15:0]
            };
        end
    end

    tms34020_binary_arithmetic immediate_subtract (
        .operation_i(TMS34020_BINARY_SUB),
        .source_i(immediate_subtract_source),
        .destination_i(destination_i),
        .carry_or_borrow_i(1'b0),
        .result_o(immediate_subtract_result),
        .status_nczv_o(immediate_subtract_nczv),
        .register_write_enable_o(immediate_subtract_write_enable)
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

        if (decode_valid &&
            packet_length_words_i == length_words) begin
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

                TMS20_OP_AND,
                TMS20_OP_ANDN,
                TMS20_OP_OR,
                TMS20_OP_XOR: begin
                    supported_o = 1'b1;
                    register_write_enable_o = 1'b1;
                    register_write_data_o = logical_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {2'd0, logical_z, 29'd0};
                    status_write_mask_o = 32'h2000_0000;
                end

                TMS20_OP_ANDNI,
                TMS20_OP_ORI,
                TMS20_OP_XORI: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o = 1'b1;
                    register_write_data_o = immediate_logical_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {2'd0, immediate_logical_z, 29'd0};
                    status_write_mask_o = 32'h2000_0000;
                end

                TMS20_OP_ADDXYI: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o = 1'b1;
                    register_write_data_o = addxyi_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o = {addxyi_nczv, 28'd0};
                    status_write_mask_o = 32'hF000_0000;
                end

                TMS20_OP_ADDI_W,
                TMS20_OP_ADDI_L: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o =
                        immediate_add_write_enable;
                    register_write_data_o = immediate_add_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {immediate_add_nczv, 28'd0};
                    status_write_mask_o = 32'hF000_0000;
                end

                TMS20_OP_SUBI_W,
                TMS20_OP_SUBI_L: begin
                    supported_o = 1'b1;
                    source_index_o = first_word_i[3:0];
                    register_write_enable_o =
                        immediate_subtract_write_enable;
                    register_write_data_o =
                        immediate_subtract_result;
                    status_write_enable_o = 1'b1;
                    status_write_data_o =
                        {immediate_subtract_nczv, 28'd0};
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
