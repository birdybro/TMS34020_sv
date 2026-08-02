`timescale 1ns/1ps
`default_nettype none

module tms34020_leaf_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [15:0] first_word_i,
    input  logic [31:0] operand_i,
    input  logic [31:0] immediate_i,
    input  logic [5:0]  pixel_size_i,
    input  logic        pixel_exchange_i,
    input  logic        write_enable_i,
    input  logic        write_file_i,
    input  logic [3:0]  write_index_i,
    output logic [31:0] result_digest_o
);

    import tms34020_pkg::*;

    tms34020_opcode_id_t decoded_id;
    logic decode_valid;
    logic [2:0] decode_length;
    logic pc_execute_supported;
    logic pc_execute_register_write_enable;
    logic [31:0] pc_execute_register_write_data;
    logic pc_execute_redirect_enable;
    logic [31:0] pc_execute_redirect_bit_address;
    logic [31:0] add_result;
    logic [3:0] add_nczv;
    logic [31:0] xy_result;
    logic [3:0] xy_nczv;
    logic [3:0] cmpxy_nczv;
    logic [31:0] binary_result;
    logic [3:0] binary_nczv;
    logic binary_register_write_enable;
    logic [31:0] pixel_result;
    logic pixel_valid;
    logic [3:0] pixel_states;
    logic [31:0] compare_result;
    logic [3:0] compare_nczv;
    logic [31:0] lmo_result;
    logic lmo_z;
    logic bit_test_z;
    logic [31:0] rmo_result;
    logic rmo_z;
    logic [31:0] unary_result;
    logic [3:0] unary_nczv;
    logic [3:0] unary_status_write_mask;
    logic [31:0] pixel_size_result;
    logic pixel_size_write_enable;
    logic [15:0] pixel_size_write_data;
    logic [15:0] pitch_conversion;
    logic [2:0] pitch_conversion_visible_states;
    logic [31:0] register_data;
    logic [31:0] sp;
    logic register_read_file;
    logic [3:0] register_read_index;
    logic [31:0] second_register_data;
    logic [31:0] status_value;
    logic execute_supported;
    logic execute_register_file;
    logic execute_destination_register_file;
    logic [3:0] execute_source_index;
    logic [3:0] execute_destination_index;
    logic execute_register_write_enable;
    logic [31:0] execute_register_write_data;
    logic execute_status_write_enable;
    logic [31:0] execute_status_write_data;
    logic [31:0] execute_status_write_mask;
    logic commit_supported;
    logic commit_accepted;
    logic commit_register_write_enable;
    logic commit_register_write_file;
    logic [3:0] commit_register_write_index;
    logic [31:0] commit_register_write_data;
    logic commit_status_write_enable;
    logic [31:0] commit_status_write_data;
    logic [31:0] commit_status_write_mask;
    logic commit_pc_redirect_enable;
    logic [31:0] commit_pc_redirect_bit_address;
    logic [31:0] commit_status;
    logic [31:0] commit_sp;
    logic [31:0] window_outcode;
    logic window_outside;
    logic [31:0] xy_linear_result;
    logic [1:0] xy_linear_pitch_class;
    logic [3:0] xy_linear_visible_states;
    logic divider_busy;
    logic divider_done;
    logic [31:0] divider_quotient;
    logic [31:0] divider_remainder;
    logic divider_overflow;
    logic divider_n;
    logic divider_z;
    logic divider_v;
    logic [5:0] divider_visible_states;
    logic multiplier_legal_field_size;
    logic [63:0] multiplier_product;
    logic multiplier_n;
    logic multiplier_z;
    logic [5:0] multiplier_visible_states;
    logic swap_legal_in_word;
    logic [31:0] swap_memory_result;
    logic [31:0] swap_register_result;
    logic swap_n;
    logic swap_z;
    logic swap_v;
    logic [15:0] multiple_normalized_mask;
    logic [4:0] multiple_register_count;
    logic multiple_list_valid;
    logic [31:0] multiple_final_pointer;
    logic multiple_n;
    logic [5:0] multiple_visible_states;
    logic [1:0] multiple_hidden_write_states;
    logic interrupt_return_normal_context;
    logic interrupt_return_ix_context;
    logic interrupt_return_bf_context;
    logic [5:0] interrupt_return_extra_words;
    logic [5:0] interrupt_return_visible_states;
    logic [31:0] interrupt_return_final_sp;
    logic [31:0] interrupt_return_aligned_pc;
    logic interrupt_return_saved_pc_misaligned;
    logic [31:0] interrupt_return_post_st;

    assign register_read_file = first_word_i[4];
    assign register_read_index = first_word_i[3:0];
    assign result_digest_o =
        add_result ^
        xy_result ^
        binary_result ^
        pixel_result ^
        compare_result ^
        lmo_result ^
        rmo_result ^
        unary_result ^
        pixel_size_result ^
        {16'd0, pitch_conversion} ^
        {29'd0, pitch_conversion_visible_states} ^
        {15'd0, pixel_size_write_enable, pixel_size_write_data} ^
        register_data ^
        second_register_data ^
        sp ^
        status_value ^
        pc_execute_register_write_data ^
        pc_execute_redirect_bit_address ^
        execute_register_write_data ^
        execute_status_write_data ^
        execute_status_write_mask ^
        commit_register_write_data ^
        commit_status_write_data ^
        commit_status_write_mask ^
        commit_pc_redirect_bit_address ^
        commit_status ^
        commit_sp ^
        window_outcode ^
        xy_linear_result ^
        divider_quotient ^
        divider_remainder ^
        multiplier_product[63:32] ^
        multiplier_product[31:0] ^
        swap_memory_result ^
        swap_register_result ^
        {16'd0, multiple_normalized_mask} ^
        multiple_final_pointer ^
        {26'd0, xy_linear_pitch_class, xy_linear_visible_states} ^
        {20'd0, divider_busy, divider_done, divider_overflow,
         divider_n, divider_z, divider_v, divider_visible_states} ^
        {23'd0, multiplier_legal_field_size, multiplier_n,
         multiplier_z, multiplier_visible_states} ^
        {28'd0, swap_legal_in_word, swap_n, swap_z, swap_v} ^
        {17'd0, multiple_register_count, multiple_list_valid, multiple_n,
         multiple_visible_states, multiple_hidden_write_states} ^
        interrupt_return_final_sp ^
        interrupt_return_aligned_pc ^
        interrupt_return_post_st ^
        {16'd0, interrupt_return_saved_pc_misaligned,
         interrupt_return_normal_context,
         interrupt_return_ix_context, interrupt_return_bf_context,
         interrupt_return_extra_words, interrupt_return_visible_states} ^
        {24'd0, commit_supported, commit_accepted,
         commit_register_write_enable, commit_register_write_file,
         commit_register_write_index} ^
        {31'd0, commit_status_write_enable} ^
        {30'd0, commit_pc_redirect_enable,
         pc_execute_redirect_enable} ^
        {30'd0, pc_execute_supported,
         pc_execute_register_write_enable} ^
        {19'd0, execute_supported, execute_register_file,
         execute_destination_register_file,
         execute_source_index, execute_destination_index,
         execute_register_write_enable, execute_status_write_enable} ^
        {27'd0, binary_nczv, binary_register_write_enable} ^
        {28'd0, xy_nczv} ^
        {28'd0, cmpxy_nczv} ^
        {31'd0, lmo_z} ^
        {31'd0, window_outside} ^
        {31'd0, bit_test_z} ^
        {6'd0, unary_nczv, unary_status_write_mask,
         add_nczv, compare_nczv, rmo_z, decode_valid,
         decode_length, pixel_valid, pixel_states} ^
        {25'd0, decoded_id};

    tms34020_decode decode (
        .first_word_i(first_word_i),
        .valid_o(decode_valid),
        .opcode_id_o(decoded_id),
        .length_words_o(decode_length)
    );

    tms34020_pc_execute pc_execute (
        .first_word_i(first_word_i),
        .packet_length_words_i(decode_length),
        .immediate_i(immediate_i),
        .sequential_next_pc_i(immediate_i),
        .destination_i(operand_i),
        .status_i(status_value),
        .supported_o(pc_execute_supported),
        .register_write_enable_o(
            pc_execute_register_write_enable
        ),
        .register_write_data_o(pc_execute_register_write_data),
        .redirect_enable_o(pc_execute_redirect_enable),
        .redirect_bit_address_o(
            pc_execute_redirect_bit_address
        )
    );

    tms34020_addxyi addxyi (
        .destination_i(operand_i),
        .immediate_i(immediate_i),
        .result_o(add_result),
        .status_n_o(add_nczv[3]),
        .status_c_o(add_nczv[2]),
        .status_z_o(add_nczv[1]),
        .status_v_o(add_nczv[0])
    );

    tms34020_xy_arithmetic xy_arithmetic (
        .operation_i(tms34020_xy_op_t'(first_word_i[9])),
        .source_i(immediate_i),
        .destination_i(operand_i),
        .result_o(xy_result),
        .status_nczv_o(xy_nczv)
    );

    tms34020_cmpxy cmpxy (
        .source_i(immediate_i),
        .destination_i(operand_i),
        .status_nczv_o(cmpxy_nczv)
    );

    tms34020_binary_arithmetic binary_arithmetic (
        .operation_i(tms34020_binary_op_t'(first_word_i[11:9])),
        .source_i(immediate_i),
        .destination_i(operand_i),
        .carry_or_borrow_i(pixel_exchange_i),
        .result_o(binary_result),
        .status_nczv_o(binary_nczv),
        .register_write_enable_o(binary_register_write_enable)
    );

    tms34020_pixel_replicate pixel_replicate (
        .pixel_i(operand_i),
        .pixel_size_i(pixel_size_i),
        .result_o(pixel_result),
        .valid_o(pixel_valid),
        .machine_states_o(pixel_states)
    );

    tms34020_cmpk cmpk (
        .destination_i(operand_i),
        .encoded_constant_i(first_word_i[9:5]),
        .compare_result_o(compare_result),
        .status_n_o(compare_nczv[3]),
        .status_c_o(compare_nczv[2]),
        .status_z_o(compare_nczv[1]),
        .status_v_o(compare_nczv[0])
    );

    tms34020_lmo lmo (
        .source_i(operand_i),
        .result_o(lmo_result),
        .status_z_o(lmo_z)
    );

    tms34020_bit_test bit_test (
        .value_i(operand_i),
        .bit_index_i(first_word_i[9:5]),
        .status_z_o(bit_test_z)
    );

    tms34020_rmo rmo (
        .source_i(operand_i),
        .result_o(rmo_result),
        .status_z_o(rmo_z)
    );

    tms34020_unary unary_operation (
        .operation_i(tms34020_unary_op_t'(first_word_i[6:5])),
        .destination_i(operand_i),
        .borrow_i(immediate_i[TMS34020_ST_C_BIT]),
        .result_o(unary_result),
        .status_nczv_o(unary_nczv),
        .status_write_mask_o(unary_status_write_mask)
    );

    tms34020_pixel_size_ops pixel_size_ops (
        .register_low_i(operand_i[15:0]),
        .psize_i({10'd0, pixel_size_i}),
        .exchange_i(pixel_exchange_i),
        .register_result_o(pixel_size_result),
        .psize_write_enable_o(pixel_size_write_enable),
        .psize_write_data_o(pixel_size_write_data)
    );

    tms34020_pitch_conversion pitch_conversion_operation (
        .pitch_i(operand_i),
        .conversion_o(pitch_conversion),
        .visible_states_o(pitch_conversion_visible_states)
    );

    tms34020_window_compare window_compare (
        .point_i(operand_i),
        .window_start_i(immediate_i),
        .window_end_i({immediate_i[15:0], immediate_i[31:16]}),
        .outcode_o(window_outcode),
        .outside_o(window_outside)
    );

    tms34020_xy_to_linear xy_to_linear (
        .xy_i(operand_i),
        .pitch_i(immediate_i),
        .offset_i({operand_i[15:0], operand_i[31:16]}),
        .conversion_value_1_i(first_word_i[4:0]),
        .conversion_value_2_i(first_word_i[12:8]),
        .pixel_size_i({10'd0, pixel_size_i}),
        .scale_x_by_pixel_size_i(first_word_i[0]),
        .cvxyl_extra_state_i(first_word_i[1]),
        .linear_o(xy_linear_result),
        .pitch_class_o(xy_linear_pitch_class),
        .visible_states_o(xy_linear_visible_states)
    );

    tms34020_divider divider (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .start_i(write_enable_i &&
                 ((decoded_id == TMS20_OP_DIVS) ||
                  (decoded_id == TMS20_OP_DIVU) ||
                  (decoded_id == TMS20_OP_MODS) ||
                  (decoded_id == TMS20_OP_MODU))),
        .signed_i((decoded_id == TMS20_OP_DIVS) ||
                  (decoded_id == TMS20_OP_MODS)),
        .pair_i(((decoded_id == TMS20_OP_DIVS) ||
                 (decoded_id == TMS20_OP_DIVU)) &&
                ~first_word_i[0]),
        .modulo_i((decoded_id == TMS20_OP_MODS) ||
                  (decoded_id == TMS20_OP_MODU)),
        .dividend_high_i(operand_i),
        .dividend_low_i(immediate_i),
        .divisor_i(second_register_data),
        .busy_o(divider_busy),
        .done_o(divider_done),
        .quotient_o(divider_quotient),
        .remainder_o(divider_remainder),
        .overflow_o(divider_overflow),
        .n_o(divider_n),
        .z_o(divider_z),
        .v_o(divider_v),
        .visible_states_o(divider_visible_states)
    );

    tms34020_multiplier multiplier (
        .signed_i(decoded_id == TMS20_OP_MPYS),
        .field_size_encoded_i(status_value[4:0]),
        .source_i(second_register_data),
        .destination_i(operand_i),
        .legal_field_size_o(multiplier_legal_field_size),
        .product_o(multiplier_product),
        .n_o(multiplier_n),
        .z_o(multiplier_z),
        .visible_states_o(multiplier_visible_states)
    );

    tms34020_swap_field swap_field (
        .field_size_encoded_i(status_value[4:0]),
        .sign_extend_i(status_value[5]),
        .bit_offset_i(operand_i[4:0]),
        .memory_word_i(immediate_i),
        .register_i(second_register_data),
        .legal_in_word_o(swap_legal_in_word),
        .memory_word_o(swap_memory_result),
        .register_o(swap_register_result),
        .n_o(swap_n),
        .z_o(swap_z),
        .v_o(swap_v)
    );

    tms34020_multiple_register_control multiple_register_control (
        .memory_to_registers_i(first_word_i[5]),
        .register_list_i(immediate_i[15:0]),
        .pointer_index_i(first_word_i[3:0]),
        .pointer_i(second_register_data),
        .instruction_misaligned_i(operand_i[4]),
        .normalized_register_mask_o(multiple_normalized_mask),
        .register_count_o(multiple_register_count),
        .list_valid_o(multiple_list_valid),
        .final_pointer_o(multiple_final_pointer),
        .n_o(multiple_n),
        .visible_states_o(multiple_visible_states),
        .hidden_write_states_o(multiple_hidden_write_states)
    );

    tms34020_interrupt_return_control interrupt_return_control (
        .old_sp_i(sp),
        .saved_st_i(immediate_i),
        .saved_pc_i(operand_i),
        .normal_context_o(interrupt_return_normal_context),
        .ix_context_o(interrupt_return_ix_context),
        .bf_context_o(interrupt_return_bf_context),
        .extra_context_words_o(interrupt_return_extra_words),
        .visible_states_o(interrupt_return_visible_states),
        .normal_final_sp_o(interrupt_return_final_sp),
        .aligned_pc_o(interrupt_return_aligned_pc),
        .saved_pc_misaligned_o(interrupt_return_saved_pc_misaligned),
        .post_context_st_o(interrupt_return_post_st)
    );

    tms34020_regfile regfile (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(write_enable_i),
        .write_file_i(write_file_i),
        .write_index_i(write_index_i),
        .write_data_i(immediate_i),
        .read0_file_i(register_read_file),
        .read0_index_i(register_read_index),
        .read0_data_o(register_data),
        .read1_file_i(~register_read_file),
        .read1_index_i(register_read_index),
        .read1_data_o(second_register_data),
        .sp_o(sp)
    );

    tms34020_status status (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(write_enable_i),
        .write_data_i(immediate_i),
        .write_mask_i(operand_i),
        .status_o(status_value)
    );

    tms34020_register_execute register_execute (
        .first_word_i(first_word_i),
        .packet_length_words_i(decode_length),
        .immediate_i(immediate_i),
        .source_i(immediate_i),
        .destination_i(operand_i),
        .status_i(status_value),
        .supported_o(execute_supported),
        .source_register_file_o(execute_register_file),
        .destination_register_file_o(
            execute_destination_register_file
        ),
        .source_index_o(execute_source_index),
        .destination_index_o(execute_destination_index),
        .register_write_enable_o(execute_register_write_enable),
        .register_write_data_o(execute_register_write_data),
        .status_write_enable_o(execute_status_write_enable),
        .status_write_data_o(execute_status_write_data),
        .status_write_mask_o(execute_status_write_mask)
    );

    tms34020_register_commit register_commit (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .commit_i(write_enable_i),
        .packet_words_i({immediate_i, first_word_i}),
        .packet_length_words_i(decode_length),
        .sequential_next_pc_i(immediate_i),
        .supported_o(commit_supported),
        .commit_accepted_o(commit_accepted),
        .register_write_enable_o(commit_register_write_enable),
        .register_write_file_o(commit_register_write_file),
        .register_write_index_o(commit_register_write_index),
        .register_write_data_o(commit_register_write_data),
        .status_write_enable_o(commit_status_write_enable),
        .status_write_data_o(commit_status_write_data),
        .status_write_mask_o(commit_status_write_mask),
        .pc_redirect_enable_o(commit_pc_redirect_enable),
        .pc_redirect_bit_address_o(
            commit_pc_redirect_bit_address
        ),
        .status_o(commit_status),
        .sp_o(commit_sp)
    );

endmodule

`default_nettype wire
