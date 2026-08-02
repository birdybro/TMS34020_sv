`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_verified_leaves;

    import tms34020_pkg::*;

    logic clk;
    logic reset;
    integer constant_index;
    integer rotate_index;
    integer shift_index;
    integer shift_step;
    integer field_size_index;
    integer pitch_first_power;
    integer pitch_second_power;
    integer condition_code_index;
    integer condition_status_index;
    logic [15:0] constant_opcode;
    logic [31:0] expected_rotate;
    logic [31:0] expected_shift;
    logic expected_shift_c;
    logic expected_shift_v;
    logic [31:0] expected_field_mask;
    logic [31:0] expected_field_zero;
    logic [31:0] expected_field_sign;
    logic shift_original_sign;
    logic [31:0] pitch_value;
    logic [15:0] pitch_conversion;
    logic [2:0] pitch_visible_states;
    logic [15:0] expected_pitch_conversion;

    logic [15:0] decode_word;
    logic decode_valid;
    tms34020_opcode_id_t decode_id;
    logic [2:0] decode_length;

    logic [15:0] pc_execute_first_word;
    logic [2:0] pc_execute_packet_length;
    logic [31:0] pc_execute_immediate;
    logic [31:0] pc_execute_sequential_next_pc;
    logic [31:0] pc_execute_destination;
    logic [31:0] pc_execute_status;
    logic pc_execute_supported;
    logic pc_execute_register_write_enable;
    logic [31:0] pc_execute_register_write_data;
    logic pc_execute_redirect_enable;
    logic [31:0] pc_execute_redirect_bit_address;

    logic [31:0] add_destination;
    logic [31:0] add_immediate;
    logic [31:0] add_result;
    logic add_n;
    logic add_c;
    logic add_z;
    logic add_v;

    tms34020_xy_op_t xy_operation;
    logic [31:0] xy_source;
    logic [31:0] xy_destination;
    logic [31:0] xy_result;
    logic [3:0] xy_nczv;
    logic [31:0] cmpxy_source;
    logic [31:0] cmpxy_destination;
    logic [3:0] cmpxy_nczv;
    logic [31:0] window_point;
    logic [31:0] window_start;
    logic [31:0] window_end;
    logic [31:0] window_outcode;
    logic window_outside;
    logic [31:0] xy_linear_xy;
    logic [31:0] xy_linear_pitch;
    logic [31:0] xy_linear_offset;
    logic [4:0] xy_linear_conversion_value_1;
    logic [4:0] xy_linear_conversion_value_2;
    logic [15:0] xy_linear_pixel_size;
    logic xy_linear_scale_x;
    logic xy_linear_extra_state;
    logic [31:0] xy_linear_result;
    logic [1:0] xy_linear_pitch_class;
    logic [3:0] xy_linear_visible_states;
    logic divider_start;
    logic divider_signed;
    logic divider_pair;
    logic divider_modulo;
    logic [31:0] divider_dividend_high;
    logic [31:0] divider_dividend_low;
    logic [31:0] divider_divisor;
    logic divider_busy;
    logic divider_done;
    logic [31:0] divider_quotient;
    logic [31:0] divider_remainder;
    logic divider_overflow;
    logic divider_n;
    logic divider_z;
    logic divider_v;
    logic [5:0] divider_visible_states;
    logic multiplier_signed;
    logic [4:0] multiplier_field_size;
    logic [31:0] multiplier_source;
    logic [31:0] multiplier_destination;
    logic multiplier_legal_field_size;
    logic [63:0] multiplier_product;
    logic multiplier_n;
    logic multiplier_z;
    logic [5:0] multiplier_visible_states;
    logic [4:0] swap_field_size;
    logic swap_sign_extend;
    logic [4:0] swap_bit_offset;
    logic [31:0] swap_memory_word;
    logic [31:0] swap_register;
    logic swap_legal_in_word;
    logic [31:0] swap_memory_result;
    logic [31:0] swap_register_result;
    logic swap_n;
    logic swap_z;
    logic swap_v;
    logic [4:0] field_store_size;
    logic [4:0] field_store_offset;
    logic [31:0] field_store_source;
    logic [31:0] field_store_word0;
    logic [31:0] field_store_word1;
    logic [5:0] field_store_decoded_size;
    logic [2:0] field_store_alignment_case;
    logic [2:0] field_store_hidden_states;
    logic field_store_writes_word1;
    logic [31:0] field_store_word0_result;
    logic [31:0] field_store_word1_result;
    logic [4:0] field_address_size;
    logic [31:0] field_address_pointer;
    logic field_address_predecrement;
    logic field_address_postincrement;
    logic [5:0] field_address_decoded_size;
    logic [31:0] field_address_effective;
    logic [31:0] field_address_final;
    logic field_address_write;
    logic field_address_mode_valid;
    logic [4:0] field_pair_size;
    logic [31:0] field_pair_source_pointer;
    logic [31:0] field_pair_destination_pointer;
    logic field_pair_same_register;
    logic [5:0] field_pair_decoded_size;
    logic [31:0] field_pair_source_effective;
    logic [31:0] field_pair_destination_effective;
    logic [31:0] field_pair_source_final;
    logic [31:0] field_pair_destination_final;
    logic [5:0] field_pair_pre_decoded_size;
    logic [31:0] field_pair_pre_source_effective;
    logic [31:0] field_pair_pre_destination_effective;
    logic [31:0] field_pair_pre_source_updated;
    logic [31:0] field_pair_pre_destination_final;
    logic [31:0] field_offset_base;
    logic [15:0] field_offset_value;
    logic [31:0] field_offset_effective;
    logic [4:0] field_source_offset_post_size_encoded;
    logic [31:0] field_source_offset_post_source_base;
    logic [15:0] field_source_offset_post_offset;
    logic [31:0] field_source_offset_post_destination_pointer;
    logic [5:0] field_source_offset_post_size;
    logic [31:0] field_source_offset_post_source_effective;
    logic [31:0] field_source_offset_post_destination_effective;
    logic [31:0] field_source_offset_post_destination_final;
    logic [4:0] field_load_size;
    logic field_load_sign_extend;
    logic [4:0] field_load_offset;
    logic [31:0] field_load_word0;
    logic [31:0] field_load_word1;
    logic [5:0] field_load_decoded_size;
    logic [2:0] field_load_alignment_case;
    logic field_load_reads_word1;
    logic [2:0] field_load_visible_states;
    logic [31:0] field_load_raw;
    logic [31:0] field_load_result;
    logic field_load_n;
    logic field_load_z;
    logic field_load_v;
    logic [4:0] field_move_size;
    logic [4:0] field_move_source_offset;
    logic [4:0] field_move_destination_offset;
    logic [31:0] field_move_source_word0;
    logic [31:0] field_move_source_word1;
    logic [31:0] field_move_destination_word0;
    logic [31:0] field_move_destination_word1;
    logic [5:0] field_move_decoded_size;
    logic [2:0] field_move_source_case;
    logic [2:0] field_move_destination_case;
    logic field_move_reads_word1;
    logic field_move_writes_word1;
    logic [2:0] field_move_visible_states;
    logic [2:0] field_move_hidden_states;
    logic [31:0] field_move_value;
    logic [31:0] field_move_word0_result;
    logic [31:0] field_move_word1_result;
    logic multiple_memory_to_registers;
    logic [15:0] multiple_register_list;
    logic [3:0] multiple_pointer_index;
    logic [31:0] multiple_pointer;
    logic multiple_instruction_misaligned;
    logic [15:0] multiple_normalized_mask;
    logic [4:0] multiple_register_count;
    logic multiple_list_valid;
    logic [31:0] multiple_final_pointer;
    logic multiple_n;
    logic [5:0] multiple_visible_states;
    logic [1:0] multiple_hidden_write_states;
    logic [31:0] interrupt_return_old_sp;
    logic [31:0] interrupt_return_saved_st;
    logic [31:0] interrupt_return_saved_pc;
    logic interrupt_return_monitor;
    logic interrupt_return_normal_context;
    logic interrupt_return_ix_context;
    logic interrupt_return_bf_context;
    logic [5:0] interrupt_return_extra_words;
    logic [5:0] interrupt_return_visible_states;
    logic [31:0] interrupt_return_final_sp;
    logic [31:0] interrupt_return_aligned_pc;
    logic interrupt_return_saved_pc_misaligned;
    logic interrupt_return_force_bypass;
    logic interrupt_return_delay_recognition;
    logic [31:0] interrupt_return_post_st;

    tms34020_binary_op_t binary_operation;
    logic [31:0] binary_source;
    logic [31:0] binary_destination;
    logic binary_carry_or_borrow;
    logic [31:0] binary_result;
    logic [3:0] binary_nczv;
    logic binary_register_write_enable;

    tms34020_logical_op_t logical_operation;
    logic [31:0] logical_source;
    logic [31:0] logical_destination;
    logic [31:0] logical_result;
    logic logical_z;

    logic [31:0] pixel;
    logic [5:0] pixel_size;
    logic [31:0] pixel_result;
    logic pixel_valid;
    logic [3:0] pixel_states;

    logic [4:0] compare_constant;
    logic [31:0] compare_result;
    logic compare_n;
    logic compare_c;
    logic compare_z;
    logic compare_v;

    logic [31:0] lmo_source;
    logic [31:0] lmo_result;
    logic lmo_z;

    logic [31:0] bit_test_value;
    logic [4:0] bit_test_index;
    logic bit_test_z;

    logic [31:0] field_extension_value;
    logic [4:0] field_extension_size;
    logic field_extension_sign;
    logic [31:0] field_extension_result;
    logic field_extension_n;
    logic field_extension_z;

    logic [31:0] rmo_source;
    logic [31:0] rmo_result;
    logic rmo_z;

    logic [31:0] rotate_value;
    logic [4:0] rotate_count;
    logic [31:0] rotate_result;
    logic rotate_c;
    logic rotate_z;

    tms34020_shift_op_t shift_operation;
    logic [31:0] shift_value;
    logic [4:0] shift_count;
    logic [31:0] shift_result;
    logic [3:0] shift_nczv;
    logic [3:0] shift_status_write_mask;

    tms34020_unary_op_t unary_operation;
    logic [31:0] unary_destination;
    logic unary_borrow;
    logic [31:0] unary_result;
    logic [3:0] unary_nczv;
    logic [3:0] unary_status_write_mask;

    logic [15:0] pixel_size_register;
    logic [15:0] pixel_size_value;
    logic pixel_size_exchange;
    logic [31:0] pixel_size_register_result;
    logic pixel_size_write_enable;
    logic [15:0] pixel_size_write_data;

    logic register_write_enable;
    logic register_write_file;
    logic [3:0] register_write_index;
    logic [31:0] register_write_data;
    logic register_read0_file;
    logic [3:0] register_read0_index;
    logic [31:0] register_read0_data;
    logic register_read1_file;
    logic [3:0] register_read1_index;
    logic [31:0] register_read1_data;
    logic [31:0] sp;

    logic status_write_enable;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;
    logic [31:0] status_value;

    logic [15:0] execute_first_word;
    logic [2:0] execute_packet_length;
    logic [31:0] execute_immediate;
    logic [31:0] execute_source;
    logic [31:0] execute_destination;
    logic [31:0] execute_status;
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

    logic commit_valid;
    logic [47:0] commit_packet_words;
    logic [2:0] commit_packet_length;
    logic [31:0] commit_sequential_next_pc;
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

    tms34020_decode decode_dut (
        .first_word_i(decode_word),
        .valid_o(decode_valid),
        .opcode_id_o(decode_id),
        .length_words_o(decode_length)
    );

    tms34020_pc_execute pc_execute_dut (
        .first_word_i(pc_execute_first_word),
        .packet_length_words_i(pc_execute_packet_length),
        .immediate_i(pc_execute_immediate),
        .sequential_next_pc_i(pc_execute_sequential_next_pc),
        .destination_i(pc_execute_destination),
        .status_i(pc_execute_status),
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

    tms34020_addxyi addxyi_dut (
        .destination_i(add_destination),
        .immediate_i(add_immediate),
        .result_o(add_result),
        .status_n_o(add_n),
        .status_c_o(add_c),
        .status_z_o(add_z),
        .status_v_o(add_v)
    );

    tms34020_xy_arithmetic xy_arithmetic_dut (
        .operation_i(xy_operation),
        .source_i(xy_source),
        .destination_i(xy_destination),
        .result_o(xy_result),
        .status_nczv_o(xy_nczv)
    );

    tms34020_cmpxy cmpxy_dut (
        .source_i(cmpxy_source),
        .destination_i(cmpxy_destination),
        .status_nczv_o(cmpxy_nczv)
    );

    tms34020_window_compare window_compare_dut (
        .point_i(window_point),
        .window_start_i(window_start),
        .window_end_i(window_end),
        .outcode_o(window_outcode),
        .outside_o(window_outside)
    );

    tms34020_xy_to_linear xy_to_linear_dut (
        .xy_i(xy_linear_xy),
        .pitch_i(xy_linear_pitch),
        .offset_i(xy_linear_offset),
        .conversion_value_1_i(xy_linear_conversion_value_1),
        .conversion_value_2_i(xy_linear_conversion_value_2),
        .pixel_size_i(xy_linear_pixel_size),
        .scale_x_by_pixel_size_i(xy_linear_scale_x),
        .cvxyl_extra_state_i(xy_linear_extra_state),
        .linear_o(xy_linear_result),
        .pitch_class_o(xy_linear_pitch_class),
        .visible_states_o(xy_linear_visible_states)
    );

    tms34020_divider divider_dut (
        .clk_i(clk),
        .reset_i(reset),
        .start_i(divider_start),
        .signed_i(divider_signed),
        .pair_i(divider_pair),
        .modulo_i(divider_modulo),
        .dividend_high_i(divider_dividend_high),
        .dividend_low_i(divider_dividend_low),
        .divisor_i(divider_divisor),
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

    tms34020_multiplier multiplier_dut (
        .signed_i(multiplier_signed),
        .field_size_encoded_i(multiplier_field_size),
        .source_i(multiplier_source),
        .destination_i(multiplier_destination),
        .legal_field_size_o(multiplier_legal_field_size),
        .product_o(multiplier_product),
        .n_o(multiplier_n),
        .z_o(multiplier_z),
        .visible_states_o(multiplier_visible_states)
    );

    tms34020_swap_field swap_field_dut (
        .field_size_encoded_i(swap_field_size),
        .sign_extend_i(swap_sign_extend),
        .bit_offset_i(swap_bit_offset),
        .memory_word_i(swap_memory_word),
        .register_i(swap_register),
        .legal_in_word_o(swap_legal_in_word),
        .memory_word_o(swap_memory_result),
        .register_o(swap_register_result),
        .n_o(swap_n),
        .z_o(swap_z),
        .v_o(swap_v)
    );

    tms34020_field_store field_store_dut (
        .field_size_encoded_i(field_store_size),
        .bit_offset_i(field_store_offset),
        .source_i(field_store_source),
        .word0_i(field_store_word0),
        .word1_i(field_store_word1),
        .field_size_o(field_store_decoded_size),
        .alignment_case_o(field_store_alignment_case),
        .hidden_write_states_o(field_store_hidden_states),
        .writes_word1_o(field_store_writes_word1),
        .word0_o(field_store_word0_result),
        .word1_o(field_store_word1_result)
    );

    tms34020_field_address_update field_address_update_dut (
        .field_size_encoded_i(field_address_size),
        .pointer_i(field_address_pointer),
        .predecrement_i(field_address_predecrement),
        .postincrement_i(field_address_postincrement),
        .field_size_o(field_address_decoded_size),
        .effective_address_o(field_address_effective),
        .final_pointer_o(field_address_final),
        .pointer_write_o(field_address_write),
        .mode_valid_o(field_address_mode_valid)
    );

    tms34020_field_pair_postincrement field_pair_postincrement_dut (
        .field_size_encoded_i(field_pair_size),
        .source_pointer_i(field_pair_source_pointer),
        .destination_pointer_i(field_pair_destination_pointer),
        .same_register_i(field_pair_same_register),
        .field_size_o(field_pair_decoded_size),
        .source_effective_address_o(field_pair_source_effective),
        .destination_effective_address_o(field_pair_destination_effective),
        .source_final_pointer_o(field_pair_source_final),
        .destination_final_pointer_o(field_pair_destination_final)
    );

    tms34020_field_pair_predecrement field_pair_predecrement_dut (
        .field_size_encoded_i(field_pair_size),
        .source_pointer_i(field_pair_source_pointer),
        .destination_pointer_i(field_pair_destination_pointer),
        .same_register_i(field_pair_same_register),
        .field_size_o(field_pair_pre_decoded_size),
        .source_effective_address_o(field_pair_pre_source_effective),
        .destination_effective_address_o(
            field_pair_pre_destination_effective
        ),
        .source_updated_pointer_o(field_pair_pre_source_updated),
        .destination_final_pointer_o(field_pair_pre_destination_final)
    );

    tms34020_field_offset_address field_offset_address_dut (
        .base_address_i(field_offset_base),
        .signed_offset_i(field_offset_value),
        .effective_address_o(field_offset_effective)
    );

    tms34020_field_source_offset_postincrement
        field_source_offset_postincrement_dut (
            .field_size_encoded_i(field_source_offset_post_size_encoded),
            .source_base_i(field_source_offset_post_source_base),
            .signed_source_offset_i(field_source_offset_post_offset),
            .destination_pointer_i(
                field_source_offset_post_destination_pointer
            ),
            .field_size_o(field_source_offset_post_size),
            .source_effective_address_o(
                field_source_offset_post_source_effective
            ),
            .destination_effective_address_o(
                field_source_offset_post_destination_effective
            ),
            .destination_final_pointer_o(
                field_source_offset_post_destination_final
            )
        );

    tms34020_field_load field_load_dut (
        .field_size_encoded_i(field_load_size),
        .sign_extend_i(field_load_sign_extend),
        .bit_offset_i(field_load_offset),
        .word0_i(field_load_word0),
        .word1_i(field_load_word1),
        .field_size_o(field_load_decoded_size),
        .alignment_case_o(field_load_alignment_case),
        .reads_word1_o(field_load_reads_word1),
        .visible_states_o(field_load_visible_states),
        .raw_field_o(field_load_raw),
        .result_o(field_load_result),
        .n_o(field_load_n),
        .z_o(field_load_z),
        .v_o(field_load_v)
    );

    tms34020_field_move field_move_dut (
        .field_size_encoded_i(field_move_size),
        .source_bit_offset_i(field_move_source_offset),
        .destination_bit_offset_i(field_move_destination_offset),
        .source_word0_i(field_move_source_word0),
        .source_word1_i(field_move_source_word1),
        .destination_word0_i(field_move_destination_word0),
        .destination_word1_i(field_move_destination_word1),
        .field_size_o(field_move_decoded_size),
        .source_alignment_case_o(field_move_source_case),
        .destination_alignment_case_o(field_move_destination_case),
        .reads_source_word1_o(field_move_reads_word1),
        .writes_destination_word1_o(field_move_writes_word1),
        .visible_states_o(field_move_visible_states),
        .hidden_write_states_o(field_move_hidden_states),
        .field_value_o(field_move_value),
        .destination_word0_o(field_move_word0_result),
        .destination_word1_o(field_move_word1_result)
    );

    tms34020_multiple_register_control multiple_register_control_dut (
        .memory_to_registers_i(multiple_memory_to_registers),
        .register_list_i(multiple_register_list),
        .pointer_index_i(multiple_pointer_index),
        .pointer_i(multiple_pointer),
        .instruction_misaligned_i(multiple_instruction_misaligned),
        .normalized_register_mask_o(multiple_normalized_mask),
        .register_count_o(multiple_register_count),
        .list_valid_o(multiple_list_valid),
        .final_pointer_o(multiple_final_pointer),
        .n_o(multiple_n),
        .visible_states_o(multiple_visible_states),
        .hidden_write_states_o(multiple_hidden_write_states)
    );

    tms34020_interrupt_return_control interrupt_return_control_dut (
        .old_sp_i(interrupt_return_old_sp),
        .saved_st_i(interrupt_return_saved_st),
        .saved_pc_i(interrupt_return_saved_pc),
        .monitor_return_i(interrupt_return_monitor),
        .normal_context_o(interrupt_return_normal_context),
        .ix_context_o(interrupt_return_ix_context),
        .bf_context_o(interrupt_return_bf_context),
        .extra_context_words_o(interrupt_return_extra_words),
        .visible_states_o(interrupt_return_visible_states),
        .normal_final_sp_o(interrupt_return_final_sp),
        .aligned_pc_o(interrupt_return_aligned_pc),
        .saved_pc_misaligned_o(interrupt_return_saved_pc_misaligned),
        .force_next_instruction_bypass_o(interrupt_return_force_bypass),
        .delay_interrupt_recognition_o(
            interrupt_return_delay_recognition
        ),
        .post_context_st_o(interrupt_return_post_st)
    );

    tms34020_binary_arithmetic binary_arithmetic_dut (
        .operation_i(binary_operation),
        .source_i(binary_source),
        .destination_i(binary_destination),
        .carry_or_borrow_i(binary_carry_or_borrow),
        .result_o(binary_result),
        .status_nczv_o(binary_nczv),
        .register_write_enable_o(binary_register_write_enable)
    );

    tms34020_logical logical_dut (
        .operation_i(logical_operation),
        .source_i(logical_source),
        .destination_i(logical_destination),
        .result_o(logical_result),
        .status_z_o(logical_z)
    );

    tms34020_pixel_replicate pixel_dut (
        .pixel_i(pixel),
        .pixel_size_i(pixel_size),
        .result_o(pixel_result),
        .valid_o(pixel_valid),
        .machine_states_o(pixel_states)
    );

    tms34020_cmpk cmpk_dut (
        .destination_i(add_destination),
        .encoded_constant_i(compare_constant),
        .compare_result_o(compare_result),
        .status_n_o(compare_n),
        .status_c_o(compare_c),
        .status_z_o(compare_z),
        .status_v_o(compare_v)
    );

    tms34020_lmo lmo_dut (
        .source_i(lmo_source),
        .result_o(lmo_result),
        .status_z_o(lmo_z)
    );

    tms34020_bit_test bit_test_dut (
        .value_i(bit_test_value),
        .bit_index_i(bit_test_index),
        .status_z_o(bit_test_z)
    );

    tms34020_field_extend field_extend_dut (
        .value_i(field_extension_value),
        .encoded_size_i(field_extension_size),
        .sign_extend_i(field_extension_sign),
        .result_o(field_extension_result),
        .status_n_o(field_extension_n),
        .status_z_o(field_extension_z)
    );

    tms34020_rmo rmo_dut (
        .source_i(rmo_source),
        .result_o(rmo_result),
        .status_z_o(rmo_z)
    );

    tms34020_rotate_left rotate_left_dut (
        .value_i(rotate_value),
        .count_i(rotate_count),
        .result_o(rotate_result),
        .status_c_o(rotate_c),
        .status_z_o(rotate_z)
    );

    tms34020_shift shift_dut (
        .operation_i(shift_operation),
        .value_i(shift_value),
        .count_i(shift_count),
        .result_o(shift_result),
        .status_nczv_o(shift_nczv),
        .status_write_mask_o(shift_status_write_mask)
    );

    tms34020_unary unary_dut (
        .operation_i(unary_operation),
        .destination_i(unary_destination),
        .borrow_i(unary_borrow),
        .result_o(unary_result),
        .status_nczv_o(unary_nczv),
        .status_write_mask_o(unary_status_write_mask)
    );

    tms34020_pixel_size_ops pixel_size_ops_dut (
        .register_low_i(pixel_size_register),
        .psize_i(pixel_size_value),
        .exchange_i(pixel_size_exchange),
        .register_result_o(pixel_size_register_result),
        .psize_write_enable_o(pixel_size_write_enable),
        .psize_write_data_o(pixel_size_write_data)
    );

    tms34020_pitch_conversion pitch_conversion_dut (
        .pitch_i(pitch_value),
        .conversion_o(pitch_conversion),
        .visible_states_o(pitch_visible_states)
    );

    tms34020_regfile regfile_dut (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(register_write_enable),
        .write_file_i(register_write_file),
        .write_index_i(register_write_index),
        .write_data_i(register_write_data),
        .read0_file_i(register_read0_file),
        .read0_index_i(register_read0_index),
        .read0_data_o(register_read0_data),
        .read1_file_i(register_read1_file),
        .read1_index_i(register_read1_index),
        .read1_data_o(register_read1_data),
        .sp_o(sp)
    );

    tms34020_status status_dut (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(status_write_enable),
        .write_data_i(status_write_data),
        .write_mask_i(status_write_mask),
        .status_o(status_value)
    );

    tms34020_register_execute register_execute_dut (
        .first_word_i(execute_first_word),
        .packet_length_words_i(execute_packet_length),
        .immediate_i(execute_immediate),
        .source_i(execute_source),
        .destination_i(execute_destination),
        .status_i(execute_status),
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

    tms34020_register_commit register_commit_dut (
        .clk_i(clk),
        .reset_i(reset),
        .commit_i(commit_valid),
        .packet_words_i(commit_packet_words),
        .packet_length_words_i(commit_packet_length),
        .sequential_next_pc_i(commit_sequential_next_pc),
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

    always #5 clk = ~clk;

    task automatic check_condition(input logic condition, input string message);
        if (!condition) begin
            $display("FAIL: %s", message);
            $fatal(1);
        end
    endtask

    task automatic check_field_pair_predecrement(
        input logic [4:0] field_size_encoded,
        input logic [31:0] source_pointer,
        input logic [31:0] destination_pointer,
        input logic same_register,
        input logic [5:0] expected_size,
        input logic [31:0] expected_source_effective,
        input logic [31:0] expected_destination_effective,
        input logic [31:0] expected_source_updated,
        input logic [31:0] expected_destination_final,
        input string message
    );
        field_pair_size = field_size_encoded;
        field_pair_source_pointer = source_pointer;
        field_pair_destination_pointer = destination_pointer;
        field_pair_same_register = same_register;
        #1;
        check_condition(
            field_pair_pre_decoded_size == expected_size &&
            field_pair_pre_source_effective == expected_source_effective &&
            field_pair_pre_destination_effective ==
                expected_destination_effective &&
            field_pair_pre_source_updated == expected_source_updated &&
            field_pair_pre_destination_final == expected_destination_final,
            message
        );
    endtask

    task automatic check_field_offset_address(
        input logic [31:0] base_address,
        input logic [15:0] signed_offset,
        input logic [31:0] expected_effective,
        input string message
    );
        field_offset_base = base_address;
        field_offset_value = signed_offset;
        #1;
        check_condition(field_offset_effective == expected_effective, message);
    endtask

    task automatic check_field_source_offset_postincrement(
        input logic [4:0] field_size_encoded,
        input logic [31:0] source_base,
        input logic [15:0] signed_offset,
        input logic [31:0] destination_pointer,
        input logic [5:0] expected_size,
        input logic [31:0] expected_source_effective,
        input logic [31:0] expected_destination_effective,
        input logic [31:0] expected_destination_final,
        input string message
    );
        field_source_offset_post_size_encoded = field_size_encoded;
        field_source_offset_post_source_base = source_base;
        field_source_offset_post_offset = signed_offset;
        field_source_offset_post_destination_pointer = destination_pointer;
        #1;
        check_condition(
            field_source_offset_post_size == expected_size
            && field_source_offset_post_source_effective
                == expected_source_effective
            && field_source_offset_post_destination_effective
                == expected_destination_effective
            && field_source_offset_post_destination_final
                == expected_destination_final,
            message
        );
    endtask

    function automatic logic reference_condition_true(
        input logic [3:0] condition_code,
        input logic [3:0] nczv
    );
        logic n;
        logic c;
        logic z;
        logic v;
        begin
            n = nczv[3];
            c = nczv[2];
            z = nczv[1];
            v = nczv[0];
            case (condition_code)
                4'h0: reference_condition_true = 1'b1;
                4'h1: reference_condition_true = !n && !z;
                4'h2: reference_condition_true = c || z;
                4'h3: reference_condition_true = !c && !z;
                4'h4: reference_condition_true = n != v;
                4'h5: reference_condition_true = n == v;
                4'h6: reference_condition_true = (n != v) || z;
                4'h7: reference_condition_true = (n == v) && !z;
                4'h8: reference_condition_true = c;
                4'h9: reference_condition_true = !c;
                4'hA: reference_condition_true = z;
                4'hB: reference_condition_true = !z;
                4'hC: reference_condition_true = v;
                4'hD: reference_condition_true = !v;
                4'hE: reference_condition_true = n;
                4'hF: reference_condition_true = !n;
                default: reference_condition_true = 1'b0;
            endcase
        end
    endfunction

    task automatic check_immediate_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] immediate,
        input logic [31:0] destination,
        input logic [31:0] expected_register_data,
        input logic expected_zero,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = 3'd3;
        execute_immediate = immediate;
        execute_source = 32'd0;
        execute_destination = destination;
        execute_status = 32'hD000_0010;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_source_index == first_word[3:0] &&
            execute_destination_index == first_word[3:0] &&
            execute_register_write_enable &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable &&
            execute_status_write_data ==
                {2'd0, expected_zero, 29'd0} &&
            execute_status_write_mask == 32'h2000_0000,
            message
        );
    endtask

    task automatic check_addxyi_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] immediate,
        input logic [31:0] destination,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = 3'd3;
        execute_immediate = immediate;
        execute_source = 32'd0;
        execute_destination = destination;
        execute_status = 32'h0FFF_FFFF;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_source_index == first_word[3:0] &&
            execute_destination_index == first_word[3:0] &&
            execute_register_write_enable &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable &&
            execute_status_write_data == {expected_nczv, 28'd0} &&
            execute_status_write_mask == 32'hF000_0000,
            message
        );
    endtask

    task automatic check_xy_arithmetic(
        input tms34020_xy_op_t operation,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input string message
    );
        xy_operation = operation;
        xy_source = source;
        xy_destination = destination;
        #1;
        check_condition(
            xy_result == expected_result &&
            xy_nczv == expected_nczv,
            message
        );
    endtask

    task automatic check_xy_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = 3'd1;
        execute_immediate = 32'd0;
        execute_source = source;
        execute_destination = destination;
        execute_status = 32'h0ABC_DEF0;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_destination_register_file == first_word[4] &&
            execute_source_index == first_word[8:5] &&
            execute_destination_index == first_word[3:0] &&
            execute_register_write_enable &&
            execute_register_write_data == expected_result &&
            execute_status_write_enable &&
            execute_status_write_data == {expected_nczv, 28'd0} &&
            execute_status_write_mask == 32'hF000_0000,
            message
        );
    endtask

    task automatic check_cmpxy(
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [3:0] expected_nczv,
        input string message
    );
        cmpxy_source = source;
        cmpxy_destination = destination;
        #1;
        check_condition(cmpxy_nczv == expected_nczv, message);
    endtask

    task automatic check_window_compare(
        input logic [31:0] point,
        input logic [31:0] expected_outcode,
        input string message
    );
        window_point = point;
        #1;
        check_condition(
            window_outcode == expected_outcode &&
            window_outside == (expected_outcode != 32'd0),
            message
        );
    endtask

    task automatic check_xy_to_linear(
        input logic [31:0] xy_value,
        input logic [31:0] pitch,
        input logic [31:0] offset,
        input logic [4:0] conversion_value_1,
        input logic [4:0] conversion_value_2,
        input logic [15:0] pixel_size_value_input,
        input logic scale_x,
        input logic extra_state,
        input logic [31:0] expected_result,
        input logic [1:0] expected_pitch_class,
        input logic [3:0] expected_states,
        input string message
    );
        xy_linear_xy = xy_value;
        xy_linear_pitch = pitch;
        xy_linear_offset = offset;
        xy_linear_conversion_value_1 = conversion_value_1;
        xy_linear_conversion_value_2 = conversion_value_2;
        xy_linear_pixel_size = pixel_size_value_input;
        xy_linear_scale_x = scale_x;
        xy_linear_extra_state = extra_state;
        #1;
        check_condition(
            xy_linear_result == expected_result &&
            xy_linear_pitch_class == expected_pitch_class &&
            xy_linear_visible_states == expected_states,
            message
        );
    endtask

    task automatic check_divider(
        input logic signed_operation,
        input logic pair_operation,
        input logic modulo_operation,
        input logic [31:0] dividend_high,
        input logic [31:0] dividend_low,
        input logic [31:0] divisor,
        input logic [31:0] expected_quotient,
        input logic [31:0] expected_remainder,
        input logic expected_overflow,
        input logic [2:0] expected_nzv,
        input logic [5:0] expected_states,
        input string message
    );
        divider_signed = signed_operation;
        divider_pair = pair_operation;
        divider_modulo = modulo_operation;
        divider_dividend_high = dividend_high;
        divider_dividend_low = dividend_low;
        divider_divisor = divisor;
        divider_start = 1'b1;
        @(posedge clk);
        #1;
        divider_start = 1'b0;
        while (!divider_done) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            !divider_busy &&
            divider_quotient == expected_quotient &&
            divider_remainder == expected_remainder &&
            divider_overflow == expected_overflow &&
            {divider_n, divider_z, divider_v} == expected_nzv &&
            divider_visible_states == expected_states,
            message
        );
        @(posedge clk);
        #1;
        check_condition(!divider_done, "divider done is a single-cycle pulse");
    endtask

    task automatic check_multiplier(
        input logic signed_operation,
        input logic [4:0] field_size_encoded,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic expected_legal,
        input logic [63:0] expected_product,
        input logic expected_n,
        input logic expected_z,
        input logic [5:0] expected_states,
        input string message
    );
        multiplier_signed = signed_operation;
        multiplier_field_size = field_size_encoded;
        multiplier_source = source;
        multiplier_destination = destination;
        #1;
        check_condition(
            multiplier_legal_field_size == expected_legal &&
            multiplier_product == expected_product &&
            multiplier_n == expected_n &&
            multiplier_z == expected_z &&
            multiplier_visible_states == expected_states,
            message
        );
    endtask

    task automatic check_swap_field(
        input logic [4:0] field_size_encoded,
        input logic sign_extend,
        input logic [4:0] bit_offset,
        input logic [31:0] memory_word,
        input logic [31:0] register_value,
        input logic expected_legal,
        input logic [31:0] expected_memory_word,
        input logic [31:0] expected_register,
        input logic [2:0] expected_nzv,
        input string message
    );
        swap_field_size = field_size_encoded;
        swap_sign_extend = sign_extend;
        swap_bit_offset = bit_offset;
        swap_memory_word = memory_word;
        swap_register = register_value;
        #1;
        check_condition(
            swap_legal_in_word == expected_legal &&
            swap_memory_result == expected_memory_word &&
            swap_register_result == expected_register &&
            {swap_n, swap_z, swap_v} == expected_nzv,
            message
        );
    endtask

    task automatic check_field_store(
        input logic [4:0] field_size_encoded,
        input logic [4:0] bit_offset,
        input logic [31:0] source,
        input logic [63:0] old_window,
        input logic [5:0] expected_size,
        input logic [2:0] expected_case,
        input logic [2:0] expected_hidden_states,
        input logic expected_writes_word1,
        input logic [63:0] expected_window,
        input string message
    );
        field_store_size = field_size_encoded;
        field_store_offset = bit_offset;
        field_store_source = source;
        field_store_word0 = old_window[31:0];
        field_store_word1 = old_window[63:32];
        #1;
        check_condition(
            field_store_decoded_size == expected_size &&
            field_store_alignment_case == expected_case &&
            field_store_hidden_states == expected_hidden_states &&
            field_store_writes_word1 == expected_writes_word1 &&
            {field_store_word1_result, field_store_word0_result} ==
                expected_window,
            message
        );
    endtask

    task automatic check_field_address_update(
        input logic [4:0] field_size_encoded,
        input logic [31:0] pointer,
        input logic predecrement,
        input logic postincrement,
        input logic [5:0] expected_size,
        input logic [31:0] expected_effective,
        input logic [31:0] expected_final,
        input logic expected_write,
        input logic expected_valid,
        input string message
    );
        field_address_size = field_size_encoded;
        field_address_pointer = pointer;
        field_address_predecrement = predecrement;
        field_address_postincrement = postincrement;
        #1;
        check_condition(
            field_address_decoded_size == expected_size &&
            field_address_effective == expected_effective &&
            field_address_final == expected_final &&
            field_address_write == expected_write &&
            field_address_mode_valid == expected_valid,
            message
        );
    endtask

    task automatic check_field_pair_postincrement(
        input logic [4:0] field_size_encoded,
        input logic [31:0] source_pointer,
        input logic [31:0] destination_pointer,
        input logic same_register,
        input logic [5:0] expected_size,
        input logic [31:0] expected_source_effective,
        input logic [31:0] expected_destination_effective,
        input logic [31:0] expected_source_final,
        input logic [31:0] expected_destination_final,
        input string message
    );
        field_pair_size = field_size_encoded;
        field_pair_source_pointer = source_pointer;
        field_pair_destination_pointer = destination_pointer;
        field_pair_same_register = same_register;
        #1;
        check_condition(
            field_pair_decoded_size == expected_size &&
            field_pair_source_effective == expected_source_effective &&
            field_pair_destination_effective ==
                expected_destination_effective &&
            field_pair_source_final == expected_source_final &&
            field_pair_destination_final == expected_destination_final,
            message
        );
    endtask

    task automatic check_field_load(
        input logic [4:0] field_size_encoded,
        input logic sign_extend,
        input logic [4:0] bit_offset,
        input logic [63:0] source_window,
        input logic [5:0] expected_size,
        input logic [2:0] expected_case,
        input logic expected_reads_word1,
        input logic [2:0] expected_visible_states,
        input logic [31:0] expected_raw,
        input logic [31:0] expected_result,
        input logic expected_n,
        input logic expected_z,
        input string message
    );
        field_load_size = field_size_encoded;
        field_load_sign_extend = sign_extend;
        field_load_offset = bit_offset;
        field_load_word0 = source_window[31:0];
        field_load_word1 = source_window[63:32];
        #1;
        check_condition(
            field_load_decoded_size == expected_size &&
            field_load_alignment_case == expected_case &&
            field_load_reads_word1 == expected_reads_word1 &&
            field_load_visible_states == expected_visible_states &&
            field_load_raw == expected_raw &&
            field_load_result == expected_result &&
            field_load_n == expected_n &&
            field_load_z == expected_z &&
            !field_load_v,
            message
        );
    endtask

    task automatic check_field_move(
        input logic [4:0] field_size_encoded,
        input logic [4:0] source_bit_offset,
        input logic [4:0] destination_bit_offset,
        input logic [63:0] source_window,
        input logic [63:0] old_destination_window,
        input logic [5:0] expected_size,
        input logic [2:0] expected_source_case,
        input logic [2:0] expected_destination_case,
        input logic expected_reads_word1,
        input logic expected_writes_word1,
        input logic [2:0] expected_visible_states,
        input logic [2:0] expected_hidden_states,
        input logic [31:0] expected_value,
        input logic [63:0] expected_destination_window,
        input string message
    );
        field_move_size = field_size_encoded;
        field_move_source_offset = source_bit_offset;
        field_move_destination_offset = destination_bit_offset;
        field_move_source_word0 = source_window[31:0];
        field_move_source_word1 = source_window[63:32];
        field_move_destination_word0 = old_destination_window[31:0];
        field_move_destination_word1 = old_destination_window[63:32];
        #1;
        check_condition(
            field_move_decoded_size == expected_size &&
            field_move_source_case == expected_source_case &&
            field_move_destination_case == expected_destination_case &&
            field_move_reads_word1 == expected_reads_word1 &&
            field_move_writes_word1 == expected_writes_word1 &&
            field_move_visible_states == expected_visible_states &&
            field_move_hidden_states == expected_hidden_states &&
            field_move_value == expected_value &&
            {field_move_word1_result, field_move_word0_result} ==
                expected_destination_window,
            message
        );
    endtask

    task automatic check_multiple_register_control(
        input logic memory_to_registers,
        input logic [15:0] register_list,
        input logic [3:0] pointer_index,
        input logic [31:0] pointer,
        input logic instruction_misaligned,
        input logic [15:0] expected_normalized_mask,
        input logic [4:0] expected_register_count,
        input logic expected_list_valid,
        input logic [31:0] expected_final_pointer,
        input logic expected_n,
        input logic [5:0] expected_visible_states,
        input logic [1:0] expected_hidden_write_states,
        input string message
    );
        multiple_memory_to_registers = memory_to_registers;
        multiple_register_list = register_list;
        multiple_pointer_index = pointer_index;
        multiple_pointer = pointer;
        multiple_instruction_misaligned = instruction_misaligned;
        #1;
        check_condition(
            multiple_normalized_mask == expected_normalized_mask &&
            multiple_register_count == expected_register_count &&
            multiple_list_valid == expected_list_valid &&
            multiple_final_pointer == expected_final_pointer &&
            multiple_n == expected_n &&
            multiple_visible_states == expected_visible_states &&
            multiple_hidden_write_states == expected_hidden_write_states,
            message
        );
    endtask

    task automatic check_interrupt_return_control(
        input logic [31:0] old_sp,
        input logic [31:0] saved_st,
        input logic [31:0] saved_pc,
        input logic monitor_return,
        input logic expected_normal_context,
        input logic expected_ix_context,
        input logic expected_bf_context,
        input logic [5:0] expected_extra_words,
        input logic [5:0] expected_visible_states,
        input logic [31:0] expected_final_sp,
        input logic [31:0] expected_aligned_pc,
        input logic expected_saved_pc_misaligned,
        input logic expected_force_bypass,
        input logic expected_delay_recognition,
        input logic [31:0] expected_post_st,
        input string message
    );
        interrupt_return_old_sp = old_sp;
        interrupt_return_saved_st = saved_st;
        interrupt_return_saved_pc = saved_pc;
        interrupt_return_monitor = monitor_return;
        #1;
        check_condition(
            interrupt_return_normal_context == expected_normal_context &&
            interrupt_return_ix_context == expected_ix_context &&
            interrupt_return_bf_context == expected_bf_context &&
            interrupt_return_extra_words == expected_extra_words &&
            interrupt_return_visible_states == expected_visible_states &&
            interrupt_return_final_sp == expected_final_sp &&
            interrupt_return_aligned_pc == expected_aligned_pc &&
            interrupt_return_saved_pc_misaligned ==
                expected_saved_pc_misaligned &&
            interrupt_return_force_bypass == expected_force_bypass &&
            interrupt_return_delay_recognition ==
                expected_delay_recognition &&
            interrupt_return_post_st == expected_post_st,
            message
        );
    endtask

    task automatic check_cmpxy_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [3:0] expected_nczv,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = 3'd1;
        execute_immediate = 32'd0;
        execute_source = source;
        execute_destination = destination;
        execute_status = 32'h0ABC_DEF0;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_destination_register_file == first_word[4] &&
            execute_source_index == first_word[8:5] &&
            execute_destination_index == first_word[3:0] &&
            !execute_register_write_enable &&
            execute_register_write_data == 32'd0 &&
            execute_status_write_enable &&
            execute_status_write_data == {expected_nczv, 28'd0} &&
            execute_status_write_mask == 32'hF000_0000,
            message
        );
    endtask

    task automatic check_immediate_arithmetic_register_execute(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic [31:0] destination,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = packet_length;
        execute_immediate = immediate;
        execute_source = 32'd0;
        execute_destination = destination;
        execute_status = 32'h0FFF_FFFF;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_source_index == first_word[3:0] &&
            execute_destination_index == first_word[3:0] &&
            execute_register_write_enable &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable &&
            execute_status_write_data == {expected_nczv, 28'd0} &&
            execute_status_write_mask == 32'hF000_0000,
            message
        );
    endtask

    task automatic check_immediate_move_register_execute(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic [31:0] expected_register_data,
        input logic expected_n,
        input logic expected_z,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = packet_length;
        execute_immediate = immediate;
        execute_source = 32'hDEAD_BEEF;
        execute_destination = 32'hCAFE_BABE;
        execute_status = 32'h5FFF_FFFF;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_source_index == first_word[3:0] &&
            execute_destination_index == first_word[3:0] &&
            execute_register_write_enable &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable &&
            execute_status_write_data ==
                {expected_n, 1'b0, expected_z, 1'b0, 28'd0} &&
            execute_status_write_mask == 32'hB000_0000,
            message
        );
    endtask

    task automatic check_immediate_compare_register_execute(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic [31:0] destination,
        input logic [3:0] expected_nczv,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = packet_length;
        execute_immediate = immediate;
        execute_source = 32'd0;
        execute_destination = destination;
        execute_status = 32'h0FFF_FFFF;
        #1;
        check_condition(
            execute_supported &&
            execute_register_file == first_word[4] &&
            execute_source_index == first_word[3:0] &&
            execute_destination_index == first_word[3:0] &&
            !execute_register_write_enable &&
            execute_status_write_enable &&
            execute_status_write_data == {expected_nczv, 28'd0} &&
            execute_status_write_mask == 32'hF000_0000,
            message
        );
    endtask

    task automatic check_decode(
        input logic [15:0] first_word,
        input tms34020_opcode_id_t expected_id,
        input logic [2:0] expected_length,
        input string message
    );
        decode_word = first_word;
        #1;
        check_condition(
            decode_valid &&
            decode_id == expected_id &&
            decode_length == expected_length,
            message
        );
    endtask

    task automatic check_pc_execute(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [15:0] immediate,
        input logic [31:0] sequential_next_pc,
        input logic [31:0] destination,
        input logic [31:0] status,
        input logic expected_supported,
        input logic expected_register_write,
        input logic [31:0] expected_register_data,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input string message
    );
        pc_execute_first_word = first_word;
        pc_execute_packet_length = packet_length;
        pc_execute_immediate = {16'd0, immediate};
        pc_execute_sequential_next_pc = sequential_next_pc;
        pc_execute_destination = destination;
        pc_execute_status = status;
        #1;
        check_condition(
            pc_execute_supported == expected_supported &&
            pc_execute_register_write_enable ==
                expected_register_write &&
            pc_execute_register_write_data ==
                expected_register_data &&
            pc_execute_redirect_enable == expected_redirect &&
            pc_execute_redirect_bit_address ==
                expected_redirect_address,
            message
        );
    endtask

    task automatic check_pc_execute_absolute(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic [31:0] sequential_next_pc,
        input logic [31:0] destination,
        input logic [31:0] status,
        input logic expected_supported,
        input logic expected_register_write,
        input logic [31:0] expected_register_data,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input string message
    );
        pc_execute_first_word = first_word;
        pc_execute_packet_length = packet_length;
        pc_execute_immediate = immediate;
        pc_execute_sequential_next_pc = sequential_next_pc;
        pc_execute_destination = destination;
        pc_execute_status = status;
        #1;
        check_condition(
            pc_execute_supported == expected_supported &&
            pc_execute_register_write_enable ==
                expected_register_write &&
            pc_execute_register_write_data ==
                expected_register_data &&
            pc_execute_redirect_enable == expected_redirect &&
            pc_execute_redirect_bit_address ==
                expected_redirect_address,
            message
        );
    endtask

    task automatic commit_immediate_instruction(
        input logic [15:0] first_word,
        input logic [31:0] immediate,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_zero,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {immediate, first_word};
        commit_packet_length = 3'd3;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == expected_register_file &&
            commit_register_write_index == expected_register_index &&
            commit_register_write_data == expected_register_data &&
            commit_status_write_enable &&
            commit_status_write_data ==
                {2'd0, expected_zero, 29'd0} &&
            commit_status_write_mask == 32'h2000_0000,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_addxyi_instruction(
        input logic [15:0] first_word,
        input logic [31:0] immediate,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {immediate, first_word};
        commit_packet_length = 3'd3;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == expected_register_file &&
            commit_register_write_index == expected_register_index &&
            commit_register_write_data == expected_register_data &&
            commit_status_write_enable &&
            commit_status_write_data == {expected_nczv, 28'd0} &&
            commit_status_write_mask == 32'hF000_0000,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_immediate_arithmetic_instruction(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {immediate, first_word};
        commit_packet_length = packet_length;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == expected_register_file &&
            commit_register_write_index == expected_register_index &&
            commit_register_write_data == expected_register_data &&
            commit_status_write_enable &&
            commit_status_write_data == {expected_nczv, 28'd0} &&
            commit_status_write_mask == 32'hF000_0000,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_immediate_move_instruction(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_n,
        input logic expected_z,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {immediate, first_word};
        commit_packet_length = packet_length;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == expected_register_file &&
            commit_register_write_index == expected_register_index &&
            commit_register_write_data == expected_register_data &&
            commit_status_write_enable &&
            commit_status_write_data ==
                {expected_n, 1'b0, expected_z, 1'b0, 28'd0} &&
            commit_status_write_mask == 32'hB000_0000,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_immediate_compare_instruction(
        input logic [15:0] first_word,
        input logic [2:0] packet_length,
        input logic [31:0] immediate,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {immediate, first_word};
        commit_packet_length = packet_length;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            !commit_register_write_enable &&
            commit_register_write_file == first_word[4] &&
            commit_register_write_index == first_word[3:0] &&
            commit_status_write_enable &&
            commit_status_write_data == {expected_nczv, 28'd0} &&
            commit_status_write_mask == 32'hF000_0000,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic check_pixel_replicate(
        input logic [5:0] size,
        input logic [31:0] expected_result,
        input logic [3:0] expected_states,
        input string message
    );
        pixel_size = size;
        #1;
        check_condition(
            pixel_valid &&
            pixel_result == expected_result &&
            pixel_states == expected_states,
            message
        );
    endtask

    task automatic check_unary(
        input tms34020_unary_op_t operation,
        input logic [31:0] destination,
        input logic borrow,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input logic [3:0] expected_write_mask,
        input string message
    );
        unary_operation = operation;
        unary_destination = destination;
        unary_borrow = borrow;
        #1;
        check_condition(
            unary_result == expected_result &&
            unary_nczv == expected_nczv &&
            unary_status_write_mask == expected_write_mask,
            message
        );
    endtask

    task automatic check_binary_arithmetic(
        input tms34020_binary_op_t operation,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic carry_or_borrow,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input logic expected_register_write_enable,
        input string message
    );
        binary_operation = operation;
        binary_source = source;
        binary_destination = destination;
        binary_carry_or_borrow = carry_or_borrow;
        #1;
        check_condition(
            binary_result == expected_result &&
            binary_nczv == expected_nczv &&
            binary_register_write_enable ==
                expected_register_write_enable,
            message
        );
    endtask

    task automatic check_logical(
        input tms34020_logical_op_t operation,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] expected_result,
        input logic expected_z,
        input string message
    );
        logical_operation = operation;
        logical_source = source;
        logical_destination = destination;
        #1;
        check_condition(
            logical_result == expected_result &&
            logical_z == expected_z,
            message
        );
    endtask

    task automatic write_register(
        input logic register_file,
        input logic [3:0] register_index_value,
        input logic [31:0] register_value
    );
        register_write_file = register_file;
        register_write_index = register_index_value;
        register_write_data = register_value;
        register_write_enable = 1'b1;
        @(posedge clk);
        #1;
        register_write_enable = 1'b0;
    endtask

    task automatic check_rotate_left(
        input logic [31:0] value,
        input logic [4:0] count,
        input logic [31:0] expected_result,
        input logic expected_c,
        input logic expected_z,
        input string message
    );
        rotate_value = value;
        rotate_count = count;
        #1;
        check_condition(
            rotate_result == expected_result &&
            rotate_c == expected_c &&
            rotate_z == expected_z,
            message
        );
    endtask

    task automatic check_bit_test(
        input logic [31:0] value,
        input logic [4:0] bit_index,
        input logic expected_z,
        input string message
    );
        bit_test_value = value;
        bit_test_index = bit_index;
        #1;
        check_condition(bit_test_z == expected_z, message);
    endtask

    task automatic check_field_extension(
        input logic [31:0] value,
        input logic [4:0] encoded_size,
        input logic sign_extend,
        input logic [31:0] expected_result,
        input string message
    );
        field_extension_value = value;
        field_extension_size = encoded_size;
        field_extension_sign = sign_extend;
        #1;
        check_condition(
            field_extension_result == expected_result &&
            field_extension_n == expected_result[31] &&
            field_extension_z == (expected_result == 32'd0),
            message
        );
    endtask

    task automatic check_shift(
        input tms34020_shift_op_t operation,
        input logic [31:0] value,
        input logic [4:0] count,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input logic [3:0] expected_status_write_mask,
        input string message
    );
        shift_operation = operation;
        shift_value = value;
        shift_count = count;
        #1;
        check_condition(
            shift_result == expected_result &&
            shift_nczv == expected_nczv &&
            shift_status_write_mask == expected_status_write_mask,
            message
        );
    endtask

    task automatic check_pitch_conversion(
        input logic [31:0] pitch,
        input logic [15:0] expected_conversion,
        input logic [2:0] expected_machine_states,
        input string message
    );
        pitch_value = pitch;
        #1;
        check_condition(
            pitch_conversion == expected_conversion &&
            pitch_visible_states == expected_machine_states,
            message
        );
    endtask

    task automatic write_status(
        input logic [31:0] write_data,
        input logic [31:0] write_mask
    );
        status_write_data = write_data;
        status_write_mask = write_mask;
        status_write_enable = 1'b1;
        @(posedge clk);
        #1;
        status_write_enable = 1'b0;
    endtask

    task automatic check_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] status,
        input logic expected_supported,
        input logic expected_register_write,
        input logic [31:0] expected_register_data,
        input logic expected_status_write,
        input logic [31:0] expected_status_data,
        input logic [31:0] expected_status_mask,
        input string message
    );
        execute_first_word = first_word;
        execute_packet_length = 3'd1;
        execute_immediate = 32'd0;
        execute_source = source;
        execute_destination = destination;
        execute_status = status;
        #1;
        check_condition(
            execute_supported == expected_supported &&
            execute_register_write_enable == expected_register_write &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable == expected_status_write &&
            execute_status_write_data == expected_status_data &&
            execute_status_write_mask == expected_status_mask,
            message
        );
    endtask

    task automatic commit_register_instruction(
        input logic [15:0] first_word,
        input logic expected_supported,
        input logic expected_register_write,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_status_write,
        input logic [31:0] expected_status_data,
        input logic [31:0] expected_status_mask,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {32'd0, first_word};
        commit_packet_length = 3'd1;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported == expected_supported &&
            commit_accepted == expected_supported &&
            commit_register_write_enable == expected_register_write &&
            commit_status_write_enable == expected_status_write &&
            !commit_pc_redirect_enable,
            message
        );
        if (expected_register_write) begin
            check_condition(
                commit_register_write_file == expected_register_file &&
                commit_register_write_index == expected_register_index &&
                commit_register_write_data == expected_register_data,
                message
            );
        end
        if (expected_status_write) begin
            check_condition(
                commit_status_write_data == expected_status_data &&
                commit_status_write_mask == expected_status_mask,
                message
            );
        end
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_pc_instruction(
        input logic [15:0] first_word,
        input logic [31:0] sequential_next_pc,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {32'd0, first_word};
        commit_packet_length = 3'd1;
        commit_sequential_next_pc = sequential_next_pc;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == expected_register_file &&
            commit_register_write_index == expected_register_index &&
            commit_register_write_data == expected_register_data &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable == expected_redirect &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_jump_instruction(
        input logic [15:0] first_word,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {32'd0, first_word};
        commit_packet_length = 3'd1;
        commit_sequential_next_pc = 32'hDEAD_BEEF;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            !commit_register_write_enable &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_jacc_instruction(
        input logic [15:0] first_word,
        input logic [31:0] absolute_target,
        input logic [31:0] sequential_next_pc,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {absolute_target, first_word};
        commit_packet_length = 3'd3;
        commit_sequential_next_pc = sequential_next_pc;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            !commit_register_write_enable &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable == expected_redirect &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_jr_long_instruction(
        input logic [15:0] first_word,
        input logic [15:0] displacement,
        input logic [31:0] sequential_next_pc,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {16'd0, displacement, first_word};
        commit_packet_length = 3'd2;
        commit_sequential_next_pc = sequential_next_pc;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            !commit_register_write_enable &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable == expected_redirect &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_dsj_instruction(
        input logic [15:0] first_word,
        input logic [15:0] displacement,
        input logic [31:0] sequential_next_pc,
        input logic expected_register_write,
        input logic [31:0] expected_register_data,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {16'd0, displacement, first_word};
        commit_packet_length = 3'd2;
        commit_sequential_next_pc = sequential_next_pc;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable ==
                expected_register_write &&
            commit_register_write_file == first_word[4] &&
            commit_register_write_index == first_word[3:0] &&
            commit_register_write_data == expected_register_data &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable == expected_redirect &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    task automatic commit_dsjs_instruction(
        input logic [15:0] first_word,
        input logic [31:0] sequential_next_pc,
        input logic [31:0] expected_register_data,
        input logic expected_redirect,
        input logic [31:0] expected_redirect_address,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        commit_packet_words = {32'd0, first_word};
        commit_packet_length = 3'd1;
        commit_sequential_next_pc = sequential_next_pc;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported &&
            commit_accepted &&
            commit_register_write_enable &&
            commit_register_write_file == first_word[4] &&
            commit_register_write_index == first_word[3:0] &&
            commit_register_write_data == expected_register_data &&
            !commit_status_write_enable &&
            commit_pc_redirect_enable == expected_redirect &&
            commit_pc_redirect_bit_address ==
                expected_redirect_address,
            message
        );
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        decode_word = 16'd0;
        pc_execute_first_word = 16'd0;
        pc_execute_packet_length = 3'd1;
        pc_execute_immediate = 32'd0;
        pc_execute_sequential_next_pc = 32'd0;
        pc_execute_destination = 32'd0;
        pc_execute_status = 32'd0;
        add_destination = 32'd0;
        add_immediate = 32'd0;
        xy_operation = TMS34020_XY_ADD;
        xy_source = 32'd0;
        xy_destination = 32'd0;
        cmpxy_source = 32'd0;
        cmpxy_destination = 32'd0;
        window_point = 32'd0;
        window_start = 32'd0;
        window_end = 32'd0;
        xy_linear_xy = 32'd0;
        xy_linear_pitch = 32'd0;
        xy_linear_offset = 32'd0;
        xy_linear_conversion_value_1 = 5'd0;
        xy_linear_conversion_value_2 = 5'd0;
        xy_linear_pixel_size = 16'd1;
        xy_linear_scale_x = 1'b0;
        xy_linear_extra_state = 1'b0;
        divider_start = 1'b0;
        divider_signed = 1'b0;
        divider_pair = 1'b0;
        divider_modulo = 1'b0;
        divider_dividend_high = 32'd0;
        divider_dividend_low = 32'd0;
        divider_divisor = 32'd0;
        multiplier_signed = 1'b0;
        multiplier_field_size = 5'd0;
        multiplier_source = 32'd0;
        multiplier_destination = 32'd0;
        swap_field_size = 5'd0;
        swap_sign_extend = 1'b0;
        swap_bit_offset = 5'd0;
        swap_memory_word = 32'd0;
        swap_register = 32'd0;
        field_store_size = 5'd0;
        field_store_offset = 5'd0;
        field_store_source = 32'd0;
        field_store_word0 = 32'd0;
        field_store_word1 = 32'd0;
        field_address_size = 5'd0;
        field_address_pointer = 32'd0;
        field_address_predecrement = 1'b0;
        field_address_postincrement = 1'b0;
        field_pair_size = 5'd0;
        field_pair_source_pointer = 32'd0;
        field_pair_destination_pointer = 32'd0;
        field_pair_same_register = 1'b0;
        field_offset_base = 32'd0;
        field_offset_value = 16'd0;
        field_source_offset_post_size_encoded = 5'd0;
        field_source_offset_post_source_base = 32'd0;
        field_source_offset_post_offset = 16'd0;
        field_source_offset_post_destination_pointer = 32'd0;
        field_load_size = 5'd0;
        field_load_sign_extend = 1'b0;
        field_load_offset = 5'd0;
        field_load_word0 = 32'd0;
        field_load_word1 = 32'd0;
        field_move_size = 5'd0;
        field_move_source_offset = 5'd0;
        field_move_destination_offset = 5'd0;
        field_move_source_word0 = 32'd0;
        field_move_source_word1 = 32'd0;
        field_move_destination_word0 = 32'd0;
        field_move_destination_word1 = 32'd0;
        multiple_memory_to_registers = 1'b0;
        multiple_register_list = 16'd0;
        multiple_pointer_index = 4'd0;
        multiple_pointer = 32'd0;
        multiple_instruction_misaligned = 1'b0;
        interrupt_return_old_sp = 32'd0;
        interrupt_return_saved_st = 32'd0;
        interrupt_return_saved_pc = 32'd0;
        interrupt_return_monitor = 1'b0;
        binary_operation = TMS34020_BINARY_ADD;
        binary_source = 32'd0;
        binary_destination = 32'd0;
        binary_carry_or_borrow = 1'b0;
        logical_operation = TMS34020_LOGICAL_AND;
        logical_source = 32'd0;
        logical_destination = 32'd0;
        pixel = 32'd0;
        pixel_size = 6'd0;
        compare_constant = 5'd0;
        lmo_source = 32'd0;
        bit_test_value = 32'd0;
        bit_test_index = 5'd0;
        field_extension_value = 32'd0;
        field_extension_size = 5'd0;
        field_extension_sign = 1'b0;
        rmo_source = 32'd0;
        rotate_value = 32'd0;
        rotate_count = 5'd0;
        shift_operation = TMS34020_SHIFT_SLA;
        shift_value = 32'd0;
        shift_count = 5'd0;
        pitch_value = 32'd0;
        unary_operation = TMS34020_UNARY_ABS;
        unary_destination = 32'd0;
        unary_borrow = 1'b0;
        pixel_size_register = 16'd0;
        pixel_size_value = 16'd0;
        pixel_size_exchange = 1'b0;
        register_write_enable = 1'b0;
        register_write_file = 1'b0;
        register_write_index = 4'd0;
        register_write_data = 32'd0;
        register_read0_file = 1'b0;
        register_read0_index = 4'd0;
        register_read1_file = 1'b1;
        register_read1_index = 4'd0;
        status_write_enable = 1'b0;
        status_write_data = 32'd0;
        status_write_mask = 32'd0;
        execute_first_word = 16'd0;
        execute_packet_length = 3'd1;
        execute_immediate = 32'd0;
        execute_source = 32'd0;
        execute_destination = 32'd0;
        execute_status = 32'd0;
        commit_valid = 1'b0;
        commit_packet_words = 48'd0;
        commit_packet_length = 3'd1;
        commit_sequential_next_pc = 32'd0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;

        check_condition(TMS34020_DATA_WIDTH == 32,
                        "architectural data width constant");
        check_condition(TMS34020_WORD_BITS == 16,
                        "instruction word width constant");
        check_condition(TMS34020_ST_N_BIT == 31 &&
                        TMS34020_ST_C_BIT == 30 &&
                        TMS34020_ST_Z_BIT == 29 &&
                        TMS34020_ST_V_BIT == 28,
                        "status bit positions");
        check_condition(
            TMS34020_ST_IE_BIT == 21 &&
            TMS34020_ST_SS_BIT == 22 &&
            TMS34020_ST_IX_BIT == 25 &&
            TMS34020_ST_BF_BIT == 26,
            "status control and fault bit positions"
        );
        check_condition(
            TMS34020_ST_FS0_LSB == 0 &&
            TMS34020_ST_FE0_BIT == 5 &&
            TMS34020_ST_FS1_LSB == 6 &&
            TMS34020_ST_FE1_BIT == 11,
            "status field-parameter positions"
        );
        check_condition(TMS34020_ST_RESET == 32'h0000_0010,
                        "status reset constant");
        check_condition(
            TMS34020_ST_RESERVED_MASK == 32'h099F_F000,
            "status reserved-bit mask"
        );
        for (
            condition_code_index = 0;
            condition_code_index < 16;
            condition_code_index = condition_code_index + 1
        ) begin
            for (
                condition_status_index = 0;
                condition_status_index < 16;
                condition_status_index = condition_status_index + 1
            ) begin
                check_condition(
                    tms34020_condition_true(
                        condition_code_index[3:0],
                        {condition_status_index[3:0], 28'd0}
                    ) ==
                    reference_condition_true(
                        condition_code_index[3:0],
                        condition_status_index[3:0]
                    ),
                    "all condition-code/status truth-table cells"
                );
                pc_execute_first_word = {
                    4'hC,
                    condition_code_index[3:0],
                    8'h80
                };
                pc_execute_packet_length = 3'd3;
                pc_execute_immediate = 32'h1234_567F;
                pc_execute_sequential_next_pc = 32'h0000_10B0;
                pc_execute_destination = 32'hDEAD_BEEF;
                pc_execute_status = {
                    condition_status_index[3:0],
                    28'd0
                };
                #1;
                check_condition(
                    pc_execute_supported &&
                    !pc_execute_register_write_enable &&
                    (
                        pc_execute_redirect_enable ==
                        reference_condition_true(
                            condition_code_index[3:0],
                            condition_status_index[3:0]
                        )
                    ) &&
                    (
                        pc_execute_redirect_bit_address ==
                        (
                            reference_condition_true(
                                condition_code_index[3:0],
                                condition_status_index[3:0]
                            )
                            ? 32'h1234_5670
                            : 32'd0
                        )
                    ),
                    "all JACC condition-code/status execute cells"
                );
            end
        end
        check_condition(status_value == 32'h0000_0010,
                        "status state reset value");

        check_bit_test(
            32'h5555_5555, 5'd0, 1'b0, "BTST.K primary row 0"
        );
        check_bit_test(
            32'h5555_5555, 5'd15, 1'b1, "BTST.K primary row 1"
        );
        check_bit_test(
            32'h5555_5555, 5'd31, 1'b1, "BTST.K primary row 2"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd0, 1'b1, "BTST.K primary row 3"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd15, 1'b0, "BTST.K primary row 4"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd31, 1'b0, "BTST.K primary row 5"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd0, 1'b0, "BTST.K primary row 6"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd15, 1'b0, "BTST.K primary row 7"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd31, 1'b0, "BTST.K primary row 8"
        );
        check_bit_test(
            32'd0, 5'd0, 1'b1, "BTST.K primary row 9"
        );
        check_bit_test(
            32'd0, 5'd15, 1'b1, "BTST.K primary row 10"
        );
        check_bit_test(
            32'd0, 5'd31, 1'b1, "BTST.K primary row 11"
        );

        check_bit_test(
            32'h5555_5555, 5'd0, 1'b0, "BTST.R primary row 0"
        );
        check_bit_test(
            32'h5555_5555, 5'd15, 1'b1, "BTST.R primary row 1"
        );
        check_bit_test(
            32'h5555_5555, 5'd31, 1'b1, "BTST.R primary row 2"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd0, 1'b1, "BTST.R primary row 3"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd15, 1'b0, "BTST.R primary row 4"
        );
        check_bit_test(
            32'hAAAA_AAAA, 5'd31, 1'b0, "BTST.R primary row 5"
        );
        check_bit_test(
            32'hFFFF_7FFF, 5'd15, 1'b1,
            "BTST.R corrected contradictory primary row 6"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd0, 1'b0, "BTST.R primary row 7"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd15, 1'b0, "BTST.R primary row 8"
        );
        check_bit_test(
            32'hFFFF_FFFF, 5'd31, 1'b0, "BTST.R primary row 9"
        );
        check_bit_test(
            32'd0, 5'd0, 1'b1, "BTST.R primary row 10"
        );
        check_bit_test(
            32'd0, 5'd15, 1'b1, "BTST.R primary row 11"
        );
        check_bit_test(
            32'd0, 5'd31, 1'b1, "BTST.R primary row 12"
        );

        check_field_extension(
            32'h0000_8000, 5'd17, 1'b1, 32'h0000_8000,
            "SEXT primary size seventeen"
        );
        check_field_extension(
            32'h0000_8000, 5'd16, 1'b1, 32'hFFFF_8000,
            "SEXT primary size sixteen"
        );
        check_field_extension(
            32'h0000_8000, 5'd15, 1'b1, 32'd0,
            "SEXT primary size fifteen"
        );
        check_field_extension(
            32'hFFFF_FFFF, 5'd0, 1'b0, 32'hFFFF_FFFF,
            "ZEXT primary size thirty-two"
        );
        check_field_extension(
            32'hFFFF_FFFF, 5'd31, 1'b0, 32'h7FFF_FFFF,
            "ZEXT primary size thirty-one"
        );
        check_field_extension(
            32'hFFFF_FFFF, 5'd1, 1'b0, 32'd1,
            "ZEXT primary size one"
        );
        check_field_extension(
            32'hFFFF_0000, 5'd16, 1'b0, 32'd0,
            "ZEXT primary zero result"
        );

        for (
            field_size_index = 0;
            field_size_index < 32;
            field_size_index = field_size_index + 1
        ) begin
            expected_field_mask = 32'hFFFF_FFFF;
            if (field_size_index != 0) begin
                expected_field_mask =
                    32'hFFFF_FFFF >>
                    (32 - field_size_index);
            end
            field_extension_value = 32'hA5A5_5A5A;
            if (field_size_index == 0) begin
                field_extension_value =
                    field_extension_value | 32'h8000_0000;
            end else begin
                field_extension_value =
                    field_extension_value |
                    (32'd1 << (field_size_index - 1));
            end
            expected_field_zero =
                field_extension_value & expected_field_mask;
            expected_field_sign = expected_field_zero;
            if (
                field_size_index == 0
                ? expected_field_zero[31]
                : (
                    expected_field_zero &
                    (32'd1 << (field_size_index - 1))
                ) != 32'd0
            ) begin
                expected_field_sign =
                    expected_field_zero | ~expected_field_mask;
            end
            check_field_extension(
                field_extension_value,
                field_size_index[4:0],
                1'b0,
                expected_field_zero,
                "ZEXT all encoded sizes"
            );
            check_field_extension(
                field_extension_value,
                field_size_index[4:0],
                1'b1,
                expected_field_sign,
                "SEXT all encoded sizes"
            );
        end

        check_rotate_left(
            32'hF000_0000, 5'd0, 32'hF000_0000, 1'b0, 1'b0,
            "RL count zero clears carry"
        );
        check_rotate_left(
            32'h8000_0000, 5'd1, 32'h0000_0001, 1'b1, 1'b0,
            "RL count one"
        );
        check_rotate_left(
            32'h1234_5678, 5'd4, 32'h2345_6781, 1'b1, 1'b0,
            "RL nibble"
        );
        check_rotate_left(
            32'hF000_0000, 5'd30, 32'h3C00_0000, 1'b0, 1'b0,
            "RL count thirty primary-result interpretation"
        );
        check_rotate_left(
            32'h0000_0001, 5'd31, 32'h8000_0000, 1'b0, 1'b0,
            "RL count thirty-one"
        );
        check_rotate_left(
            32'd0, 5'd17, 32'd0, 1'b0, 1'b1,
            "RL zero result"
        );
        expected_rotate = 32'hA5C3_0F96;
        for (rotate_index = 0;
             rotate_index < 32;
             rotate_index = rotate_index + 1) begin
            if (rotate_index != 0) begin
                expected_rotate = {
                    expected_rotate[30:0],
                    expected_rotate[31]
                };
            end
            check_rotate_left(
                32'hA5C3_0F96,
                rotate_index[4:0],
                expected_rotate,
                (rotate_index == 0) ? 1'b0 : expected_rotate[0],
                1'b0,
                "RL every five-bit count"
            );
        end

        check_shift(
            TMS34020_SHIFT_SLA,
            32'h3333_3333, 5'd0, 32'h3333_3333,
            4'b0000, 4'b1111, "SLA primary count-zero positive"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd0, 32'hCCCC_CCCC,
            4'b1000, 4'b1111, "SLA primary count-zero negative"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd1, 32'h9999_9998,
            4'b1100, 4'b1111, "SLA primary count one"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'h3333_3333, 5'd2, 32'hCCCC_CCCC,
            4'b1001, 4'b1111, "SLA primary positive overflow"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd2, 32'h3333_3330,
            4'b0101, 4'b1111, "SLA primary negative overflow"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd3, 32'h6666_6660,
            4'b0001, 4'b1111, "SLA primary shifted-bit overflow"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd5, 32'h9999_9980,
            4'b1101, 4'b1111, "SLA primary count five"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd30, 32'd0,
            4'b0111, 4'b1111, "SLA primary count thirty"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'hCCCC_CCCC, 5'd31, 32'd0,
            4'b0011, 4'b1111, "SLA primary count thirty-one"
        );
        check_shift(
            TMS34020_SHIFT_SLA,
            32'd0, 5'd31, 32'd0,
            4'b0010, 4'b1111, "SLA primary zero count thirty-one"
        );

        check_shift(
            TMS34020_SHIFT_SLL,
            32'd0, 5'd0, 32'd0,
            4'b0010, 4'b0110, "SLL primary zero"
        );
        check_shift(
            TMS34020_SHIFT_SLL,
            32'h8888_8888, 5'd0, 32'h8888_8888,
            4'b0000, 4'b0110, "SLL primary count zero"
        );
        check_shift(
            TMS34020_SHIFT_SLL,
            32'h8888_8888, 5'd1, 32'h1111_1110,
            4'b0100, 4'b0110, "SLL primary count one"
        );
        check_shift(
            TMS34020_SHIFT_SLL,
            32'h8888_8888, 5'd4, 32'h8888_8880,
            4'b0000, 4'b0110, "SLL primary count four"
        );
        check_shift(
            TMS34020_SHIFT_SLL,
            32'hFFFF_FFFC, 5'd30, 32'd0,
            4'b0110, 4'b0110, "SLL primary count thirty"
        );
        check_shift(
            TMS34020_SHIFT_SLL,
            32'hFFFF_FFFC, 5'd31, 32'd0,
            4'b0010, 4'b0110, "SLL primary count thirty-one"
        );

        check_shift(
            TMS34020_SHIFT_SRA,
            32'd0, 5'd0, 32'd0,
            4'b0010, 4'b1110, "SRA primary zero"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'hFFFF_0000, 5'd0, 32'hFFFF_0000,
            4'b1000, 4'b1110, "SRA primary count zero negative"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'h7FFF_0000, 5'd8, 32'h007F_FF00,
            4'b0000, 4'b1110, "SRA primary positive count eight"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'hFFFF_0000, 5'd8, 32'hFFFF_FF00,
            4'b1000, 4'b1110, "SRA primary sign extension"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'h7FFF_0000, 5'd30, 32'h0000_0001,
            4'b0100, 4'b1110, "SRA primary count thirty"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'h7FFF_0000, 5'd31, 32'd0,
            4'b0110, 4'b1110, "SRA primary positive count thirty-one"
        );
        check_shift(
            TMS34020_SHIFT_SRA,
            32'hFFFF_0000, 5'd31, 32'hFFFF_FFFF,
            4'b1100, 4'b1110, "SRA primary negative count thirty-one"
        );

        check_shift(
            TMS34020_SHIFT_SRL,
            32'd0, 5'd0, 32'd0,
            4'b0010, 4'b0110, "SRL primary zero"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h7FFF_FFFF, 5'd0, 32'h7FFF_FFFF,
            4'b0000, 4'b0110, "SRL primary count zero nonzero"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h7FFF_FFFF, 5'd1, 32'h3FFF_FFFF,
            4'b0100, 4'b0110, "SRL primary count one"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h7FFF_0000, 5'd8, 32'h007F_FF00,
            4'b0000, 4'b0110, "SRL primary count eight"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h7FFF_0000, 5'd30, 32'h0000_0001,
            4'b0100, 4'b0110, "SRL primary count thirty"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h7FFF_0000, 5'd31, 32'd0,
            4'b0110, 4'b0110, "SRL primary carry count thirty-one"
        );
        check_shift(
            TMS34020_SHIFT_SRL,
            32'h3FFF_0000, 5'd31, 32'd0,
            4'b0010, 4'b0110, "SRL primary clear carry count thirty-one"
        );

        for (shift_index = 0;
             shift_index < 32;
             shift_index = shift_index + 1) begin
            expected_shift = 32'hA5C3_0F96;
            expected_shift_c = 1'b0;
            expected_shift_v = 1'b0;
            shift_original_sign = expected_shift[31];
            for (shift_step = 0;
                 shift_step < shift_index;
                 shift_step = shift_step + 1) begin
                expected_shift_c = expected_shift[31];
                expected_shift = {expected_shift[30:0], 1'b0};
                if (expected_shift_c != shift_original_sign ||
                    expected_shift[31] != shift_original_sign) begin
                    expected_shift_v = 1'b1;
                end
            end
            check_shift(
                TMS34020_SHIFT_SLA,
                32'hA5C3_0F96,
                shift_index[4:0],
                expected_shift,
                {
                    expected_shift[31],
                    expected_shift_c,
                    expected_shift == 32'd0,
                    expected_shift_v
                },
                4'b1111,
                "SLA every five-bit count iterative oracle"
            );
        end

        window_start = 32'h0005_0005;
        window_end = 32'h000A_000A;
        check_window_compare(
            32'h0004_0004, 32'h0000_00A0,
            "CPW primary above-left outcode"
        );
        check_window_compare(
            32'h0005_0005, 32'd0,
            "CPW primary inclusive start corner"
        );
        check_window_compare(
            32'h000A_000A, 32'd0,
            "CPW primary inclusive end corner"
        );
        check_window_compare(
            32'h000B_000B, 32'h0000_0140,
            "CPW primary below-right outcode"
        );
        window_start = 32'hFFFA_FFFB;
        window_end = 32'h0006_0005;
        check_window_compare(
            32'hFFF9_FFFA, 32'h0000_00A0,
            "CPW signed negative above-left comparison"
        );
        check_window_compare(
            32'h0007_0006, 32'h0000_0140,
            "CPW signed positive below-right comparison"
        );

        check_xy_to_linear(
            32'h0040_0030, 32'h0000_0800, 32'd0,
            5'h14, 5'd0, 16'd16, 1'b1, 1'b1,
            32'h0002_0300, 2'd0, 4'd3,
            "CVXYL primary power-of-two equation row"
        );
        check_xy_to_linear(
            32'h0040_0030, 32'h0000_0800, 32'd0,
            5'h14, 5'd0, 16'd4, 1'b1, 1'b1,
            32'h0002_00C0, 2'd0, 4'd3,
            "CVXYL corrected contradictory PSIZE four row"
        );
        check_xy_to_linear(
            32'h0001_0001, 32'h0000_1400, 32'd0,
            5'h13, 5'h15, 16'd8, 1'b1, 1'b1,
            32'h0000_1408, 2'd1, 4'd4,
            "CVXYL two-power conversion and timing"
        );
        check_xy_to_linear(
            32'h0000_7FFF, 32'h0000_1000, 32'd0,
            5'h13, 5'd0, 16'd32, 1'b1, 1'b1,
            32'h000F_FFE0, 2'd0, 4'd3,
            "CVXYL maximum positive X times 32 retains full product"
        );
        check_xy_to_linear(
            32'h0001_0001, 32'h0000_00E0, 32'hFF30_0000,
            5'd0, 5'd0, 16'd16, 1'b1, 1'b0,
            32'hFF30_00F0, 2'd2, 4'd14,
            "CVDXYL arbitrary conversion and offset"
        );
        check_xy_to_linear(
            32'h0001_0001, 32'h0000_1000, 32'd0,
            5'h13, 5'd0, 16'd32, 1'b0, 1'b0,
            32'h0000_1001, 2'd0, 4'd2,
            "CVMXYL unscaled X and no offset"
        );
        check_xy_to_linear(
            32'hFFFF_0002, 32'hFFFF_FFF0, 32'hFFFF_FFF0,
            5'd0, 5'd0, 16'd4, 1'b1, 1'b1,
            32'd8, 2'd2, 4'd14,
            "CVXYL signed arbitrary pitch and modulo wrap"
        );

        check_divider(
            1'b0, 1'b1, 1'b0, 32'h1234_5678, 32'h8765_4321,
            32'h789A_BCDF, 32'h26A4_39F6, 32'h15CA_1DD7,
            1'b0, 3'b000, 6'd37,
            "DIVU primary 64-by-32 quotient and remainder"
        );
        check_divider(
            1'b0, 1'b0, 1'b0, 32'd0, 32'd0, 32'h8765_4321,
            32'd0, 32'd0, 1'b0, 3'b010, 6'd37,
            "DIVU odd-destination zero quotient"
        );
        check_divider(
            1'b0, 1'b1, 1'b0, 32'h8765_4321, 32'd0,
            32'h8765_4321, 32'd0, 32'd0,
            1'b1, 3'b001, 6'd5,
            "DIVU even-destination early overflow"
        );
        check_divider(
            1'b1, 1'b1, 1'b0, 32'h1234_5678, 32'h8765_4321,
            32'h8765_4321, 32'hD95B_C60A, 32'h15CA_1DD7,
            1'b0, 3'b100, 6'd40,
            "DIVS primary signed pair quotient and remainder"
        );
        check_divider(
            1'b1, 1'b0, 1'b0, 32'd0, 32'h8000_0000, 32'd1,
            32'h8000_0000, 32'd0, 1'b0, 3'b100, 6'd41,
            "DIVS valid minimum result special timing"
        );
        check_divider(
            1'b1, 1'b0, 1'b0, 32'd0, 32'h8000_0000, 32'hFFFF_FFFF,
            32'h8000_0000, 32'd0, 1'b1, 3'b101, 6'd41,
            "DIVS positive signed-range overflow"
        );
        check_divider(
            1'b1, 1'b1, 1'b0, 32'hFFFF_FFFF, 32'h7FFF_FFFF, 32'd1,
            32'h7FFF_FFFF, 32'd0, 1'b1, 3'b101, 6'd40,
            "DIVS negative signed-range overflow"
        );
        check_divider(
            1'b1, 1'b1, 1'b0, 32'h8000_0000, 32'd0, 32'd1,
            32'd0, 32'd0, 1'b1, 3'b001, 6'd7,
            "DIVS raw high-half early overflow"
        );
        check_divider(
            1'b0, 1'b0, 1'b1, 32'd0, 32'd7, 32'd4,
            32'd1, 32'd3, 1'b0, 3'b000, 6'd35,
            "MODU nonzero remainder"
        );
        check_divider(
            1'b0, 1'b0, 1'b1, 32'd0, 32'd8, 32'd4,
            32'd2, 32'd0, 1'b0, 3'b010, 6'd35,
            "MODU zero remainder controls Z"
        );
        check_divider(
            1'b0, 1'b0, 1'b1, 32'd0, 32'd7, 32'd0,
            32'd0, 32'd7, 1'b1, 3'b001, 6'd3,
            "MODU zero divisor"
        );
        check_divider(
            1'b1, 1'b0, 1'b1, 32'd0, 32'hFFFF_FFF9, 32'd4,
            32'hFFFF_FFFF, 32'hFFFF_FFFD, 1'b0, 3'b100, 6'd40,
            "MODS negative remainder keeps dividend sign"
        );
        check_divider(
            1'b1, 1'b0, 1'b1, 32'd0, 32'h8000_0000,
            32'hFFFF_FFFF, 32'h8000_0000, 32'd0,
            1'b0, 3'b010, 6'd40,
            "MODS quotient overflow does not invalidate remainder"
        );
        check_divider(
            1'b1, 1'b0, 1'b1, 32'd0, 32'hFFFF_FFF9, 32'd0,
            32'd0, 32'hFFFF_FFF9, 1'b1, 3'b001, 6'd3,
            "MODS zero divisor"
        );

        check_multiplier(
            1'b1, 5'd0, 32'h7FF3_B074, 32'h8040_1056,
            1'b1, 64'hC026_2CDC_53E4_86F8, 1'b1, 1'b0, 6'd21,
            "MPYS primary full-width signed product"
        );
        check_multiplier(
            1'b1, 5'd8, 32'h7FF3_B074, 32'h8040_1056,
            1'b1, 64'hFFFF_FFC6_1D07_66F8, 1'b1, 1'b0, 6'd9,
            "MPYS primary eight-bit sign extension"
        );
        check_multiplier(
            1'b1, 5'd0, 32'd3, 32'h4000_0000,
            1'b1, 64'h0000_0000_C000_0000, 1'b0, 1'b0, 6'd21,
            "MPYS status uses full positive product"
        );
        check_multiplier(
            1'b1, 5'd0, 32'hFFFF_FFFD, 32'h4000_0000,
            1'b1, 64'hFFFF_FFFF_4000_0000, 1'b1, 1'b0, 6'd21,
            "MPYS status uses full negative product"
        );
        check_multiplier(
            1'b0, 5'd16, 32'h1000_1010, 32'hFFFF_0000,
            1'b1, 64'h0000_100F_EFF0_0000, 1'b0, 1'b0, 6'd13,
            "MPYU primary sixteen-bit product"
        );
        check_multiplier(
            1'b0, 5'd0, 32'h0001_0000, 32'h0001_0000,
            1'b1, 64'h0000_0001_0000_0000, 1'b0, 1'b0, 6'd21,
            "MPYU full product controls zero"
        );
        check_multiplier(
            1'b0, 5'd2, 32'h8000_0001, 32'd7,
            1'b1, 64'd7, 1'b0, 1'b0, 6'd7,
            "MPYU provisional raw-source sign timing"
        );
        check_multiplier(
            1'b0, 5'd3, 32'd7, 32'd9,
            1'b0, 64'd63, 1'b0, 1'b0, 6'd6,
            "multiply odd FS1 is explicitly unsupported"
        );
        check_swap_field(
            5'd0, 1'b0, 5'd0, 32'hA5C3_5A3C, 32'h1234_5678,
            1'b1, 32'h1234_5678, 32'hA5C3_5A3C, 3'b100,
            "SWAPF full-word exchange"
        );
        check_swap_field(
            5'd8, 1'b0, 5'd7, 32'hA5C3_5A3C, 32'h0000_0069,
            1'b1, 32'hA5C3_34BC, 32'h0000_00B4, 3'b000,
            "SWAPF positioned zero-extended field"
        );
        check_swap_field(
            5'd8, 1'b1, 5'd0, 32'h0000_0080, 32'h0000_005A,
            1'b1, 32'h0000_005A, 32'hFFFF_FF80, 3'b100,
            "SWAPF sign extension and negative status"
        );
        check_swap_field(
            5'd3, 1'b1, 5'd29, 32'h0000_0000, 32'hFFFF_FFFF,
            1'b1, 32'hE000_0000, 32'd0, 3'b010,
            "SWAPF valid top-of-word zero result"
        );
        check_swap_field(
            5'd2, 1'b0, 5'd31, 32'h1234_5678, 32'd1,
            1'b0, 32'h9234_5678, 32'd0, 3'b010,
            "SWAPF crossing field is marked unsupported"
        );
        check_field_store(
            5'd0, 5'd0, 32'h1234_5678,
            64'hC33C_F00F_A5A5_5A5A,
            6'd32, 3'd1, 3'd1, 1'b0,
            64'hC33C_F00F_1234_5678,
            "MOVE.RM full aligned field-store boundary"
        );
        check_field_store(
            5'd16, 5'd24, 32'h0000_CDEF,
            64'hC33C_F00F_A5A5_5A5A,
            6'd16, 3'd3, 3'd2, 1'b1,
            64'hC33C_F0CD_EFA5_5A5A,
            "MOVE.RM byte-aligned crossing field-store boundary"
        );
        check_field_store(
            5'd9, 5'd29, 32'h0000_0155,
            64'hC33C_F00F_A5A5_5A5A,
            6'd9, 3'd5, 3'd4, 1'b1,
            64'hC33C_F02A_A5A5_5A5A,
            "MOVE.RM non-byte crossing field-store boundary"
        );
        for (int unsigned encoded_size = 0; encoded_size < 32;
             encoded_size++) begin
            for (int unsigned bit_offset = 0; bit_offset < 32;
                 bit_offset++) begin
                logic [5:0] expected_size;
                logic [6:0] expected_end;
                logic [63:0] expected_mask;
                logic [63:0] expected_window;
                logic [2:0] expected_case;
                logic [2:0] expected_hidden;
                expected_size = encoded_size == 0 ? 6'd32 :
                    encoded_size[5:0];
                expected_end = bit_offset[6:0] + expected_size;
                expected_mask = 64'h0000_0000_FFFF_FFFF;
                if (expected_size != 6'd32) begin
                    expected_mask = (64'd1 << expected_size) - 64'd1;
                end
                expected_mask = expected_mask << bit_offset;
                expected_window =
                    (64'hC33C_F00F_A5A5_5A5A & ~expected_mask) |
                    ((64'h0000_0000_D69A_35C7 << bit_offset) &
                     expected_mask);
                if (expected_end <= 7'd32) begin
                    expected_case =
                        ((bit_offset[2:0] == 3'd0) &&
                         (expected_end[2:0] == 3'd0)) ? 3'd1 : 3'd2;
                end else if ((bit_offset[2:0] == 3'd0) &&
                             (expected_end[2:0] == 3'd0)) begin
                    expected_case = 3'd3;
                end else if ((bit_offset[2:0] == 3'd0) ||
                             (expected_end[2:0] == 3'd0)) begin
                    expected_case = 3'd4;
                end else begin
                    expected_case = 3'd5;
                end
                unique case (expected_case)
                    3'd1: expected_hidden = 3'd1;
                    3'd2: expected_hidden = 3'd2;
                    3'd3: expected_hidden = 3'd2;
                    3'd4: expected_hidden = 3'd3;
                    default: expected_hidden = 3'd4;
                endcase
                check_field_store(
                    encoded_size[4:0], bit_offset[4:0], 32'hD69A_35C7,
                    64'hC33C_F00F_A5A5_5A5A,
                    expected_size, expected_case, expected_hidden,
                    expected_end > 7'd32, expected_window,
                    "MOVE.RM exhaustive little-endian field geometry"
                );
            end
        end
        for (int unsigned encoded_size = 0; encoded_size < 32;
             encoded_size++) begin
            logic [5:0] expected_size;
            logic [31:0] pointer;
            expected_size = encoded_size == 0 ? 6'd32 :
                encoded_size[5:0];
            pointer = 32'hFFFF_FFF0 + encoded_size;
            check_field_address_update(
                encoded_size[4:0], pointer, 1'b0, 1'b0,
                expected_size, pointer, pointer, 1'b0, 1'b1,
                "ordinary field address has no pointer update"
            );
            check_field_address_update(
                encoded_size[4:0], pointer, 1'b0, 1'b1,
                expected_size, pointer,
                pointer + {26'd0, expected_size},
                1'b1, 1'b1,
                "postincrement field address captures old pointer"
            );
            check_field_address_update(
                encoded_size[4:0], pointer, 1'b1, 1'b0,
                expected_size, pointer - {26'd0, expected_size},
                pointer - {26'd0, expected_size}, 1'b1, 1'b1,
                "predecrement field address uses updated pointer"
            );
            check_field_pair_postincrement(
                encoded_size[4:0], pointer, 32'h7FFF_FFF0, 1'b0,
                expected_size, pointer, 32'h7FFF_FFF0,
                pointer + {26'd0, expected_size},
                32'h7FFF_FFF0 + {26'd0, expected_size},
                "paired postincrement uses two captured addresses"
            );
            check_field_pair_postincrement(
                encoded_size[4:0], pointer, pointer, 1'b1,
                expected_size, pointer,
                pointer + {26'd0, expected_size},
                pointer + {26'd0, expected_size},
                pointer + {26'd0, expected_size} +
                    {26'd0, expected_size},
                "paired alias writes after first increment and finishes after two"
            );
            check_field_pair_predecrement(
                encoded_size[4:0], pointer, 32'h8000_0010, 1'b0,
                expected_size,
                pointer - {26'd0, expected_size},
                32'h8000_0010 - {26'd0, expected_size},
                pointer - {26'd0, expected_size},
                32'h8000_0010 - {26'd0, expected_size},
                "paired predecrement uses independently updated pointers"
            );
            check_field_pair_predecrement(
                encoded_size[4:0], pointer, pointer, 1'b1,
                expected_size,
                pointer - {26'd0, expected_size},
                pointer - {26'd0, expected_size} -
                    {26'd0, expected_size},
                pointer - {26'd0, expected_size},
                pointer - {26'd0, expected_size} -
                    {26'd0, expected_size},
                "paired alias reads after one decrement and finishes after two"
            );
        end
        for (int unsigned offset_value = 0; offset_value < 65536;
             offset_value++) begin
            logic [31:0] sign_extended_offset;
            sign_extended_offset = {
                {16{offset_value[15]}}, offset_value[15:0]
            };
            check_field_offset_address(
                32'h7000_8000, offset_value[15:0],
                32'h7000_8000 + sign_extended_offset,
                "signed field offset exhausts all 16-bit values"
            );
        end
        check_field_offset_address(
            32'hFFFF_FFF0, 16'h0020, 32'h0000_0010,
            "positive field offset wraps modulo 2^32"
        );
        check_field_offset_address(
            32'h0000_0010, 16'hFFE0, 32'hFFFF_FFF0,
            "negative field offset wraps modulo 2^32"
        );
        for (int unsigned offset_value = 0; offset_value < 65536;
             offset_value++) begin
            logic [4:0] encoded_size;
            logic [5:0] decoded_size;
            logic [31:0] sign_extended_offset;
            encoded_size = offset_value[4:0];
            decoded_size = encoded_size == 5'd0
                ? 6'd32 : {1'b0, encoded_size};
            sign_extended_offset = {
                {16{offset_value[15]}}, offset_value[15:0]
            };
            check_field_source_offset_postincrement(
                encoded_size,
                32'h7000_8000,
                offset_value[15:0],
                32'hFFFF_FFF0,
                decoded_size,
                32'h7000_8000 + sign_extended_offset,
                32'hFFFF_FFF0,
                32'hFFFF_FFF0 + {26'd0, decoded_size},
                "source-offset/destination-postincrement exhausts offsets"
            );
        end
        check_field_source_offset_postincrement(
            5'd8, 32'h0000_4000, 16'h0020, 32'h0000_4000,
            6'd8, 32'h0000_4020, 32'h0000_4000, 32'h0000_4008,
            "source-offset alias uses original base then one destination update"
        );
        check_field_address_update(
            5'd16, 32'h1234_5678, 1'b1, 1'b1,
            6'd16, 32'h1234_5678, 32'h1234_5678,
            1'b0, 1'b0,
            "simultaneous predecrement and postincrement is rejected"
        );
        check_field_load(
            5'd0, 1'b0, 5'd0,
            64'hC33C_F00F_A5A5_5A5A,
            6'd32, 3'd1, 1'b0, 3'd3,
            32'hA5A5_5A5A, 32'hA5A5_5A5A, 1'b1, 1'b0,
            "MOVE.MR full aligned zero-extension boundary"
        );
        check_field_load(
            5'd8, 1'b1, 5'd8,
            64'h0000_0000_0000_0000,
            6'd8, 3'd1, 1'b0, 3'd4,
            32'd0, 32'd0, 1'b0, 1'b1,
            "MOVE.MR zero sign-extension and status boundary"
        );
        for (int unsigned sign_extend = 0; sign_extend < 2;
             sign_extend++) begin
            for (int unsigned encoded_size = 0; encoded_size < 32;
                 encoded_size++) begin
                for (int unsigned bit_offset = 0; bit_offset < 32;
                     bit_offset++) begin
                    logic [5:0] expected_size;
                    logic [6:0] expected_end;
                    logic [31:0] expected_mask;
                    logic [63:0] expected_window;
                    logic [4:0] expected_sign_index;
                    logic [31:0] expected_raw;
                    logic [31:0] expected_result;
                    logic [2:0] expected_case;
                    logic [2:0] expected_visible;
                    expected_size = encoded_size == 0 ? 6'd32 :
                        encoded_size[5:0];
                    expected_end = bit_offset[6:0] + expected_size;
                    expected_mask = 32'hFFFF_FFFF;
                    if (expected_size != 6'd32) begin
                        expected_mask =
                            (32'd1 << expected_size) - 32'd1;
                    end
                    expected_window = 64'hC33C_F00F_A5A5_5A5A;
                    expected_raw =
                        expected_window[bit_offset +: 32] & expected_mask;
                    expected_result = expected_raw;
                    expected_sign_index =
                        expected_size[4:0] - 5'd1;
                    if (
                        sign_extend != 0 &&
                        expected_size != 6'd32 &&
                        expected_raw[expected_sign_index]
                    ) begin
                        expected_result = expected_raw | ~expected_mask;
                    end
                    if (expected_end <= 7'd32) begin
                        expected_case =
                            ((bit_offset[2:0] == 3'd0) &&
                             (expected_end[2:0] == 3'd0)) ? 3'd1 : 3'd2;
                    end else if ((bit_offset[2:0] == 3'd0) &&
                                 (expected_end[2:0] == 3'd0)) begin
                        expected_case = 3'd3;
                    end else if ((bit_offset[2:0] == 3'd0) ||
                                 (expected_end[2:0] == 3'd0)) begin
                        expected_case = 3'd4;
                    end else begin
                        expected_case = 3'd5;
                    end
                    expected_visible =
                        ((expected_case <= 3'd2) ? 3'd3 : 3'd4) +
                        sign_extend[2:0];
                    check_field_load(
                        encoded_size[4:0], sign_extend[0], bit_offset[4:0],
                        64'hC33C_F00F_A5A5_5A5A,
                        expected_size, expected_case,
                        expected_end > 7'd32, expected_visible,
                        expected_raw, expected_result,
                        expected_result[31], expected_result == 32'd0,
                        "MOVE.MR exhaustive little-endian field geometry"
                    );
                end
            end
        end
        for (int unsigned encoded_size = 0; encoded_size < 32;
             encoded_size++) begin
            for (int unsigned source_offset = 0; source_offset < 32;
                 source_offset++) begin
                for (int unsigned destination_offset = 0;
                     destination_offset < 32; destination_offset++) begin
                    logic [5:0] expected_size;
                    logic [6:0] expected_source_end;
                    logic [6:0] expected_destination_end;
                    logic [31:0] expected_mask;
                    logic [63:0] expected_source_window;
                    logic [31:0] expected_value;
                    logic [63:0] expected_positioned_mask;
                    logic [63:0] expected_destination_window;
                    logic [2:0] expected_source_case;
                    logic [2:0] expected_destination_case;
                    logic [2:0] expected_hidden;
                    expected_size = encoded_size == 0 ? 6'd32 :
                        encoded_size[5:0];
                    expected_source_end = source_offset[6:0] + expected_size;
                    expected_destination_end =
                        destination_offset[6:0] + expected_size;
                    expected_mask = 32'hFFFF_FFFF;
                    if (expected_size != 6'd32) begin
                        expected_mask =
                            (32'd1 << expected_size) - 32'd1;
                    end
                    expected_source_window = 64'hC33C_F00F_A5A5_5A5A;
                    expected_value =
                        expected_source_window[source_offset +: 32] &
                        expected_mask;
                    expected_positioned_mask =
                        {32'd0, expected_mask} << destination_offset;
                    expected_destination_window =
                        (64'h6996_3CC3_5AA5_C33C &
                         ~expected_positioned_mask) |
                        (({32'd0, expected_value} << destination_offset) &
                         expected_positioned_mask);

                    if (expected_source_end <= 7'd32) begin
                        expected_source_case =
                            ((source_offset[2:0] == 3'd0) &&
                             (expected_source_end[2:0] == 3'd0)) ?
                            3'd1 : 3'd2;
                    end else if ((source_offset[2:0] == 3'd0) &&
                                 (expected_source_end[2:0] == 3'd0)) begin
                        expected_source_case = 3'd3;
                    end else if ((source_offset[2:0] == 3'd0) ||
                                 (expected_source_end[2:0] == 3'd0)) begin
                        expected_source_case = 3'd4;
                    end else begin
                        expected_source_case = 3'd5;
                    end

                    if (expected_destination_end <= 7'd32) begin
                        expected_destination_case =
                            ((destination_offset[2:0] == 3'd0) &&
                             (expected_destination_end[2:0] == 3'd0)) ?
                            3'd1 : 3'd2;
                    end else if ((destination_offset[2:0] == 3'd0) &&
                                 (expected_destination_end[2:0] == 3'd0)) begin
                        expected_destination_case = 3'd3;
                    end else if ((destination_offset[2:0] == 3'd0) ||
                                 (expected_destination_end[2:0] == 3'd0)) begin
                        expected_destination_case = 3'd4;
                    end else begin
                        expected_destination_case = 3'd5;
                    end
                    unique case (expected_destination_case)
                        3'd1: expected_hidden = 3'd1;
                        3'd2: expected_hidden = 3'd2;
                        3'd3: expected_hidden = 3'd2;
                        3'd4: expected_hidden = 3'd3;
                        default: expected_hidden = 3'd4;
                    endcase
                    check_field_move(
                        encoded_size[4:0], source_offset[4:0],
                        destination_offset[4:0],
                        64'hC33C_F00F_A5A5_5A5A,
                        64'h6996_3CC3_5AA5_C33C,
                        expected_size, expected_source_case,
                        expected_destination_case,
                        expected_source_end > 7'd32,
                        expected_destination_end > 7'd32,
                        (expected_source_case <= 3'd2) ? 3'd3 : 3'd4,
                        expected_hidden, expected_value,
                        expected_destination_window,
                        "MOVE.MM exhaustive source/destination field geometry"
                    );
                end
            end
        end
        check_multiple_register_control(
            1'b1, 16'h4015, 4'd15, 32'h0000_0780, 1'b0,
            16'h4015, 5'd4, 1'b1, 32'h0000_0800, 1'b1, 6'd9, 2'd0,
            "MMFM direct mask, descending register order, and n+5 timing"
        );
        check_multiple_register_control(
            1'b0, 16'hA802, 4'd15, 32'h0000_0800, 1'b0,
            16'h4015, 5'd4, 1'b1, 32'h0000_0780, 1'b1, 6'd8, 2'd1,
            "MMTM reversed mask and long-word aligned timing"
        );
        check_multiple_register_control(
            1'b0, 16'h8000, 4'd3, 32'h0000_0408, 1'b0,
            16'h0001, 5'd1, 1'b1, 32'h0000_03E8, 1'b1, 6'd4, 2'd1,
            "MMTM one-register byte-aligned special timing"
        );
        check_multiple_register_control(
            1'b0, 16'h8000, 4'd3, 32'h0000_0401, 1'b0,
            16'h0001, 5'd1, 1'b1, 32'h0000_03E1, 1'b1, 6'd4, 2'd2,
            "MMTM one-register bit-aligned hidden-write timing"
        );
        check_multiple_register_control(
            1'b0, 16'hEC00, 4'd3, 32'h0000_0401, 1'b0,
            16'h0037, 5'd5, 1'b1, 32'h0000_0361, 1'b1, 6'd12, 2'd1,
            "MMTM general bit-aligned list timing"
        );
        check_multiple_register_control(
            1'b0, 16'h8000, 4'd3, 32'hFFFF_FFFF, 1'b1,
            16'h0001, 5'd1, 1'b1, 32'hFFFF_FFDF, 1'b0, 6'd5, 2'd2,
            "MMTM instruction alignment penalty and inverted-pointer N"
        );
        check_multiple_register_control(
            1'b1, 16'h0008, 4'd3, 32'h0000_0400, 1'b0,
            16'h0008, 5'd1, 1'b0, 32'h0000_0420, 1'b1, 6'd6, 2'd0,
            "MMFM rejects a pointer present in the list"
        );
        check_multiple_register_control(
            1'b0, 16'h0000, 4'd3, 32'h0000_0400, 1'b0,
            16'h0000, 5'd0, 1'b0, 32'h0000_0400, 1'b1, 6'd4, 2'd1,
            "MMTM marks an empty list outside the portable domain"
        );
        for (int unsigned mask_index = 0; mask_index < 65536;
             mask_index++) begin
            logic [15:0] expected_reversed_mask;
            logic [4:0] expected_mask_count;
            expected_reversed_mask = 16'd0;
            expected_mask_count = 5'd0;
            for (int unsigned bit_index = 0; bit_index < 16;
                 bit_index++) begin
                expected_reversed_mask[bit_index] =
                    mask_index[15 - bit_index];
                expected_mask_count = expected_mask_count +
                    {4'd0, mask_index[bit_index]};
            end
            multiple_register_list = mask_index[15:0];
            multiple_memory_to_registers = 1'b1;
            #1;
            check_condition(
                multiple_normalized_mask == mask_index[15:0] &&
                multiple_register_count == expected_mask_count,
                "MMFM exhaustive direct-mask normalization"
            );
            multiple_memory_to_registers = 1'b0;
            #1;
            check_condition(
                multiple_normalized_mask == expected_reversed_mask &&
                multiple_register_count == expected_mask_count,
                "MMTM exhaustive reverse-mask normalization"
            );
        end
        check_interrupt_return_control(
            32'h0000_0400, 32'hF123_4567, 32'h1234_567F, 1'b0,
            1'b1, 1'b0, 1'b0, 6'd0, 6'd7,
            32'h0000_0440, 32'h1234_5670, 1'b1, 1'b0, 1'b0,
            32'hF123_4567,
            "RETI normal-context classification and outputs"
        );
        check_interrupt_return_control(
            32'hFFFF_FFE7, 32'hA200_0010, 32'hFFFF_FFF0, 1'b0,
            1'b0, 1'b1, 1'b0, 6'd24, 6'd38,
            32'h0000_0027, 32'hFFFF_FFF0, 1'b0, 1'b0, 1'b0,
            32'hA000_0010,
            "RETI IX-context classification and IX clearing"
        );
        check_interrupt_return_control(
            32'h0000_0400, 32'hA600_0010, 32'h1234_567F, 1'b0,
            1'b0, 1'b0, 1'b1, 6'd31, 6'd52,
            32'h0000_0440, 32'h1234_5670, 1'b1, 1'b0, 1'b0,
            32'hA000_0010,
            "RETI BF context takes priority and clears IX/BF"
        );
        check_interrupt_return_control(
            32'h0000_0400, 32'hF123_4567, 32'h1234_567F, 1'b1,
            1'b1, 1'b0, 1'b0, 6'd0, 6'd10,
            32'h0000_0440, 32'h1234_5670, 1'b1, 1'b1, 1'b1,
            32'hF123_4567,
            "RETM normal context arms bypass and recognition delay"
        );
        check_interrupt_return_control(
            32'h0000_0400, 32'hA200_0010, 32'h1234_5670, 1'b1,
            1'b0, 1'b1, 1'b0, 6'd24, 6'd38,
            32'h0000_0440, 32'h1234_5670, 1'b0, 1'b1, 1'b1,
            32'hA000_0010,
            "RETM IX context retains shared continuation state count"
        );
        check_interrupt_return_control(
            32'h0000_0400, 32'hA600_0010, 32'h1234_5670, 1'b1,
            1'b0, 1'b0, 1'b1, 6'd31, 6'd52,
            32'h0000_0440, 32'h1234_5670, 1'b0, 1'b1, 1'b1,
            32'hA000_0010,
            "RETM BF context retains shared continuation state count"
        );

        check_pitch_conversion(
            32'h0000_1000, 16'h0013, 3'd4,
            "SETC pitch primary 4096 row"
        );
        check_pitch_conversion(
            32'h0000_0400, 16'h0015, 3'd4,
            "SETC pitch primary 1024 row"
        );
        check_pitch_conversion(
            32'h0000_1400, 16'h1513, 3'd6,
            "SETC pitch primary two-power row"
        );
        check_pitch_conversion(
            32'h0000_0019, 16'h0000, 3'd3,
            "SETC pitch primary arbitrary row"
        );
        check_pitch_conversion(
            32'd0, 16'd0, 3'd3,
            "SETC pitch zero uses arbitrary path"
        );
        for (pitch_first_power = 0;
             pitch_first_power < 32;
             pitch_first_power = pitch_first_power + 1) begin
            expected_pitch_conversion =
                (pitch_first_power == 31)
                ? 16'd0
                : {11'd0, (~pitch_first_power[4:0]) & 5'h1F};
            check_pitch_conversion(
                32'h0000_0001 << pitch_first_power,
                expected_pitch_conversion,
                (pitch_first_power == 31) ? 3'd3 : 3'd4,
                "SETC pitch every single-power field"
            );
            for (pitch_second_power = pitch_first_power + 1;
                 pitch_second_power < 32;
                 pitch_second_power = pitch_second_power + 1) begin
                expected_pitch_conversion =
                    (pitch_second_power == 31)
                    ? 16'd0
                    : {
                        3'd0,
                        (~pitch_first_power[4:0]) & 5'h1F,
                        3'd0,
                        (~pitch_second_power[4:0]) & 5'h1F
                    };
                check_pitch_conversion(
                    (32'h0000_0001 << pitch_first_power) |
                    (32'h0000_0001 << pitch_second_power),
                    expected_pitch_conversion,
                    (pitch_second_power == 31) ? 3'd3 : 3'd6,
                    "SETC pitch every two-power field pair"
                );
            end
        end

        write_status(32'hF000_0000, 32'hF000_0000);
        check_condition(status_value == 32'hF000_0010,
                        "status full NCZV update");
        write_status(32'h2000_0000, 32'hB000_0000);
        check_condition(status_value == 32'h6000_0010,
                        "status partial NZV update preserves C");
        write_status(32'd0, 32'h2000_0000);
        check_condition(status_value == 32'h4000_0010,
                        "status Z-only update preserves NCV");
        write_status(32'h0020_0000, 32'h0020_0000);
        check_condition(status_value == 32'h4020_0010,
                        "status IE set without collateral changes");
        write_status(32'd0, 32'h4000_0000);
        check_condition(status_value == 32'h0020_0010,
                        "status carry clear without collateral changes");

        status_write_enable = 1'b1;
        status_write_data = 32'hFFFF_FFFF;
        status_write_mask = 32'hFFFF_FFFF;
        reset = 1'b1;
        @(posedge clk);
        #1;
        check_condition(status_value == 32'h0000_0010,
                        "status reset dominates masked write");
        reset = 1'b0;
        status_write_enable = 1'b0;
        @(posedge clk);
        #1;
        check_condition(status_value == 32'h0000_0010,
                        "status holds without write enable");

        check_register_execute(
            16'h0300, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "register execute NOP"
        );
        check_register_execute(
            16'h0392, 32'd0, 32'hFFFF_FFFF, 32'h4000_0000,
            1'b1, 1'b1, 32'h0000_0001, 1'b1,
            32'd0, 32'hB000_0000,
            "register execute ABS partial flags"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute unary operand selectors"
        );
        check_register_execute(
            16'h03C0, 32'd0, 32'd0, 32'h4000_0000,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'hC000_0000, 32'hF000_0000,
            "register execute NEGB consumes carry as borrow"
        );
        check_register_execute(
            16'h4074, 32'd1, 32'd2, 32'd0,
            1'b1, 1'b1, 32'd3, 1'b1,
            32'd0, 32'hF000_0000,
            "register execute binary ADD"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd3 &&
            execute_destination_index == 4'd4,
            "register execute binary operand selectors"
        );
        check_register_execute(
            16'h4820, 32'd1, 32'd1, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'hF000_0000,
            "register execute nondestructive CMP"
        );
        check_register_execute(
            16'h5020, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hD000_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute AND only writes zero"
        );
        check_register_execute(
            16'h5220, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hF000_0010,
            1'b1, 1'b1, 32'h5555_5555, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute ANDN only clears zero"
        );
        check_register_execute(
            16'h5420, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hF000_0010,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute OR only clears zero"
        );
        check_register_execute(
            16'h5620, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'hD000_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute XOR only writes zero"
        );
        for (int unsigned file_index = 0; file_index < 2; file_index++) begin
            for (int unsigned register_index = 0;
                register_index < 16; register_index++) begin
                check_register_execute(
                    {
                        7'b0101011,
                        register_index[3:0],
                        file_index[0],
                        register_index[3:0]
                    },
                    32'hA5A5_5A5A, 32'hA5A5_5A5A,
                    32'hD000_0010,
                    1'b1, 1'b1, 32'd0, 1'b1,
                    32'h2000_0000, 32'h2000_0000,
                    "register execute CLR same-register XOR alias"
                );
                check_condition(
                    execute_register_file == file_index[0] &&
                    execute_source_index == register_index[3:0] &&
                    execute_destination_index == register_index[3:0],
                    "register execute CLR alias selectors"
                );
            end
        end
        check_register_execute(
            16'h3400, 32'd0, 32'd32, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'hF000_0000,
            "register execute CMPK"
        );
        check_register_execute(
            16'h7A21, 32'h0000_0010, 32'd0, 32'd0,
            1'b1, 1'b1, 32'd4, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute RMO"
        );
        check_register_execute(
            16'h0320, 32'd0, 32'd0, 32'hF000_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'd0, 32'h4000_0000,
            "register execute CLRC partial status write"
        );
        check_register_execute(
            16'h0DE0, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h4000_0000, 32'h4000_0000,
            "register execute SETC partial status write"
        );
        check_register_execute(
            16'h0360, 32'd0, 32'd0, 32'h0020_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'd0, 32'h0020_0000,
            "register execute DINT partial status write"
        );
        check_register_execute(
            16'h0D60, 32'd0, 32'd0, 32'h0000_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h0020_0000, 32'h0020_0000,
            "register execute EINT partial status write"
        );
        check_register_execute(
            16'h0192, 32'd0, 32'd0, 32'hF020_0010,
            1'b1, 1'b1, 32'hF020_0010, 1'b0,
            32'd0, 32'd0,
            "register execute GETST"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute GETST operand selector"
        );
        check_pc_execute(
            16'h0141, 3'd1, 16'd0, 32'h0000_1BE0,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_1BE0,
            1'b0, 32'd0,
            "PC execute GETPC sequential address"
        );
        check_pc_execute(
            16'h0132, 3'd1, 16'd0, 32'h0000_2090,
            32'h1234_567F, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_2090,
            1'b1, 32'h1234_5670,
            "PC execute EXGPC exchange and alignment"
        );
        check_pc_execute(
            16'h017F, 3'd1, 16'd0, 32'h0000_2090,
            32'h89AB_CDEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'h89AB_CDE0,
            "PC execute JUMP redirect and alignment"
        );
        check_pc_execute(
            16'h0D80, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0002, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0001,
            1'b1, 32'h0000_20C0,
            "PC execute DSJ forward redirect"
        );
        check_pc_execute(
            16'h0D80, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0001, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0000,
            1'b0, 32'd0,
            "PC execute DSJ decrement-to-zero skip"
        );
        check_pc_execute(
            16'h0D80, 3'd2, 16'hFFFE, 32'h0000_20A0,
            32'h0000_0000, 32'hA000_0010,
            1'b1, 1'b1, 32'hFFFF_FFFF,
            1'b1, 32'h0000_2080,
            "PC execute DSJ wrapping decrement and backward redirect"
        );
        check_pc_execute(
            16'h0DA0, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0009, 32'h2000_0010,
            1'b1, 1'b1, 32'h0000_0008,
            1'b1, 32'h0000_20C0,
            "PC execute DSJEQ enabled"
        );
        check_pc_execute(
            16'h0DA0, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0009, 32'h0000_0010,
            1'b1, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute DSJEQ suppressed"
        );
        check_pc_execute(
            16'h0DC0, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0009, 32'h0000_0010,
            1'b1, 1'b1, 32'h0000_0008,
            1'b1, 32'h0000_20C0,
            "PC execute DSJNE enabled"
        );
        check_pc_execute(
            16'h0DC0, 3'd2, 16'h0002, 32'h0000_20A0,
            32'h0000_0009, 32'h2000_0010,
            1'b1, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute DSJNE suppressed"
        );
        check_pc_execute(
            16'h3845, 3'd1, 16'd0, 32'h0000_20A0,
            32'h0000_0009, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0008,
            1'b1, 32'h0000_20C0,
            "PC execute DSJS forward decrement and redirect"
        );
        check_pc_execute(
            16'h3845, 3'd1, 16'd0, 32'h0000_20A0,
            32'h0000_0001, 32'hA000_0010,
            1'b1, 1'b1, 32'd0,
            1'b0, 32'd0,
            "PC execute DSJS decrement-to-zero falls through"
        );
        check_pc_execute(
            16'h3800, 3'd1, 16'd0, 32'h0000_20A0,
            32'h0000_0002, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0001,
            1'b1, 32'h0000_20A0,
            "PC execute DSJS zero-magnitude taken redirect"
        );
        check_pc_execute(
            16'h3BE0, 3'd1, 16'd0, 32'hFFFF_FF10,
            32'h0000_0002, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0001,
            1'b1, 32'h0000_0100,
            "PC execute DSJS maximum forward redirect wraps PC"
        );
        check_pc_execute(
            16'h3FE0, 3'd1, 16'd0, 32'h0000_0090,
            32'h0000_0002, 32'hA000_0010,
            1'b1, 1'b1, 32'h0000_0001,
            1'b1, 32'hFFFF_FEA0,
            "PC execute DSJS maximum backward redirect wraps PC"
        );
        check_pc_execute(
            16'hC000, 3'd2, 16'h0002, 32'h0000_20A0,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'h0000_20C0,
            "PC execute unconditional JR.L forward redirect"
        );
        check_pc_execute(
            16'hC800, 3'd2, 16'h0002, 32'h0000_20A0,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute JR.C false condition falls through"
        );
        check_pc_execute(
            16'hC800, 3'd2, 16'h0002, 32'h0000_20A0,
            32'hDEAD_BEEF, 32'h4000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'h0000_20C0,
            "PC execute JR.C true condition redirects"
        );
        check_pc_execute(
            16'hC000, 3'd2, 16'h7FFF, 32'hFFFF_0120,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'h0007_0110,
            "PC execute JR.L maximum positive displacement wraps"
        );
        check_pc_execute(
            16'hC000, 3'd2, 16'h8000, 32'h0007_FF20,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'hFFFF_FF20,
            "PC execute JR.L minimum negative displacement wraps"
        );
        check_pc_execute_absolute(
            16'hC080, 3'd3, 32'h1234_567F, 32'h0000_20B0,
            32'hDEAD_BEEF, 32'hA000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'h1234_5670,
            "PC execute unconditional JACC assembles aligned target"
        );
        check_pc_execute_absolute(
            16'hC880, 3'd3, 32'hFFFF_FFFF, 32'h0000_20B0,
            32'hDEAD_BEEF, 32'h0000_0010,
            1'b1, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute JA.C false condition falls through"
        );
        check_pc_execute_absolute(
            16'hC880, 3'd3, 32'hFFFF_FFFF, 32'h0000_20B0,
            32'hDEAD_BEEF, 32'h4000_0010,
            1'b1, 1'b0, 32'd0,
            1'b1, 32'hFFFF_FFF0,
            "PC execute JA.C true condition redirects"
        );
        check_pc_execute(
            16'h0121, 3'd2, 16'd0, 32'h0000_2090,
            32'h1234_567F, 32'hA000_0010,
            1'b0, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute rejects length mismatch"
        );
        check_pc_execute(
            16'hFFFF, 3'd1, 16'd0, 32'h0000_2090,
            32'h1234_567F, 32'hA000_0010,
            1'b0, 1'b0, 32'd0,
            1'b0, 32'd0,
            "PC execute rejects unclassified word"
        );
        check_register_execute(
            16'h1031, 32'd0, 32'hFFFF_FFFF, 32'd0,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'hF000_0000,
            "register execute ADDK/INC carry and zero"
        );
        check_register_execute(
            16'h1000, 32'd0, 32'h7FFF_FFE0, 32'd0,
            1'b1, 1'b1, 32'h8000_0000, 1'b1,
            32'h9000_0000, 32'hF000_0000,
            "register execute ADDK encoded zero means 32"
        );
        check_register_execute(
            16'h13F2, 32'd0, 32'hFFFF_FFE1, 32'd0,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'hF000_0000,
            "register execute ADDK 31 B-file carry and zero"
        );
        check_register_execute(
            16'h1421, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'hC000_0000, 32'hF000_0000,
            "register execute SUBK/DEC borrow and negative"
        );
        check_register_execute(
            16'h1400, 32'd0, 32'd9, 32'd0,
            1'b1, 1'b1, 32'hFFFF_FFE9, 1'b1,
            32'hC000_0000, 32'hF000_0000,
            "register execute SUBK encoded zero means 32"
        );
        check_register_execute(
            16'h17F2, 32'd0, 32'd32, 32'd0,
            1'b1, 1'b1, 32'd1, 1'b1,
            32'd0, 32'hF000_0000,
            "register execute SUBK 31 B-file"
        );
        for (constant_index = 1;
             constant_index <= 32;
             constant_index = constant_index + 1) begin
            constant_opcode = 16'h1400;
            constant_opcode[9:5] = constant_index[4:0];
            check_register_execute(
                constant_opcode,
                32'd0, constant_index, 32'd0,
                1'b1, 1'b1, 32'd0, 1'b1,
                32'h2000_0000, 32'hF000_0000,
                "register execute SUBK every constant"
            );
        end
        for (constant_index = 1;
             constant_index <= 32;
             constant_index = constant_index + 1) begin
            constant_opcode = 16'h1812;
            constant_opcode[9:5] = constant_index[4:0];
            check_register_execute(
                constant_opcode,
                32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hF020_0010,
                1'b1, 1'b1, constant_index, 1'b0,
                32'd0, 32'd0,
                "register execute MOVK every constant"
            );
        end
        check_condition(
            execute_register_file &&
            execute_destination_index == 4'd2,
            "register execute MOVK B-file selector"
        );
        check_register_execute(
            16'h180F, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hF020_0010,
            1'b1, 1'b1, 32'd32, 1'b0, 32'd0, 32'd0,
            "register execute MOVK encoded-zero shared SP"
        );
        check_condition(
            !execute_register_file &&
            execute_destination_index == 4'd15,
            "register execute MOVK shared-SP selector"
        );
        check_register_execute(
            16'h00F0, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decoded but unsupported register execute instruction"
        );
        check_register_execute(
            16'h8001, 32'hD69A_35C7, 32'h0000_2003,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.RM cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h8401, 32'h0000_2003, 32'hDEAD_BEEF,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MR cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h8801, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MM cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h9001, 32'hD69A_35C7, 32'h0000_2003,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.RM.POST cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h9401, 32'h0000_2003, 32'hDEAD_BEEF,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MR.POST cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h9801, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MM.POST cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hA001, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.RM.PRE cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hA401, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MR.PRE cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hA801, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MM.PRE cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hB001, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.RM.OFFSET cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hB401, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MR.OFFSET cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hB801, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MM.OFFSET cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'hD001, 32'h0000_2003, 32'h0000_3005,
            32'hA020_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MOVE.MM.SOFF_POST cannot bypass absent field-memory ownership"
        );
        check_register_execute(
            16'h0020, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "REV cannot execute without a selected device revision profile"
        );
        check_register_execute(
            16'h0900, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "TRAP 0 cannot bypass unimplemented stack/vector ownership"
        );
        check_register_execute(
            16'h091F, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "TRAP 31 cannot bypass unimplemented stack/vector ownership"
        );
        check_register_execute(
            16'h0860, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "RETM cannot bypass stack/context/fetch ownership"
        );
        check_register_execute(
            16'h0940, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "RETI cannot bypass stack/context/redirect ownership"
        );
        check_register_execute(
            16'h0960, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "RETS 0 cannot bypass unimplemented stack-read ownership"
        );
        check_register_execute(
            16'h097F, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "RETS 31 cannot bypass unimplemented stack-read ownership"
        );
        check_register_execute(
            16'h0920, 32'h1234_567F, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CALL A0 cannot bypass unimplemented stack-write ownership"
        );
        check_register_execute(
            16'h093F, 32'h1234_567F, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CALL shared SP cannot bypass stack-write and redirect ownership"
        );
        check_register_execute(
            16'h0D3F, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CALLR cannot bypass extension, stack-write, and redirect ownership"
        );
        check_register_execute(
            16'h0D5F, 32'hDEAD_BEEF, 32'hCAFE_BABE, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CALLA cannot bypass extension, stack-write, and redirect ownership"
        );
        check_register_execute(
            16'hE600, 32'h0004_0004, 32'hDEAD_BEEF, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CPW cannot bypass the unimplemented implied B5/B6 read owner"
        );
        check_register_execute(
            16'h0A60, 32'h0001_0001, 32'hDEAD_BEEF, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CVMXYL cannot bypass implied pitch/conversion ownership"
        );
        check_register_execute(
            16'h0A80, 32'h0001_0001, 32'hDEAD_BEEF, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CVDXYL cannot bypass implied offset/pitch/PSIZE ownership"
        );
        check_register_execute(
            16'hE800, 32'h0001_0001, 32'hDEAD_BEEF, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CVXYL cannot bypass implied B3/B4/I/O ownership"
        );
        check_register_execute(
            16'hEA00, 32'h0001_0001, 32'hDEAD_BEEF, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "CVSXYL cannot bypass source/destination/implied ownership"
        );
        check_register_execute(
            16'h5800, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "DIVS cannot bypass iterative divide/pair commit ownership"
        );
        check_register_execute(
            16'h5BFF, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "DIVU cannot bypass iterative divide/pair commit ownership"
        );
        check_register_execute(
            16'h6C00, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MODS cannot bypass iterative modulus commit ownership"
        );
        check_register_execute(
            16'h6FFF, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MODU cannot bypass iterative modulus commit ownership"
        );
        check_register_execute(
            16'h5C00, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MPYS cannot bypass atomic multiply-pair commit ownership"
        );
        check_register_execute(
            16'h5FFF, 32'h0000_0002, 32'h0000_0008, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MPYU cannot bypass atomic multiply-pair commit ownership"
        );
        check_register_execute(
            16'h7E00, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "SWAPF cannot bypass locked memory commit ownership"
        );
        check_register_execute(
            16'h7FFF, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "SWAPF upper bound cannot bypass memory ownership"
        );
        check_register_execute(
            16'h0980, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MMTM cannot bypass multiwrite memory ownership"
        );
        check_register_execute(
            16'h099F, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MMTM upper bound cannot bypass multiwrite ownership"
        );
        check_register_execute(
            16'h09A0, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MMFM cannot bypass multiread memory ownership"
        );
        check_register_execute(
            16'h09BF, 32'h0000_0400, 32'h0000_0001, 32'hA123_4567,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "MMFM upper bound cannot bypass multiread ownership"
        );
        check_register_execute(
            16'h6A01, 32'h0800_0000, 32'hDEAD_BEEF, 32'hF000_0010,
            1'b1, 1'b1, 32'd4,
            1'b1, 32'd0, 32'h2000_0000,
            "register execute LMO primary example"
        );
        check_condition(
            !execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd1,
            "register execute LMO A-file selectors"
        );
        check_register_execute(
            16'h6A52, 32'h0000_0010, 32'hDEAD_BEEF, 32'hC000_0010,
            1'b1, 1'b1, 32'd27,
            1'b1, 32'd0, 32'h2000_0000,
            "register execute LMO same-register source is read first"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute LMO B-file same-register selectors"
        );
        check_register_execute(
            16'h6BFE, 32'd1, 32'hDEAD_BEEF, 32'hD000_0010,
            1'b1, 1'b1, 32'd31,
            1'b1, 32'd0, 32'h2000_0000,
            "register execute LMO shared-SP source"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd15 &&
            execute_destination_index == 4'd14,
            "register execute LMO shared-SP source selector"
        );
        check_register_execute(
            16'h6A5F, 32'h8000_0000, 32'hDEAD_BEEF, 32'h1000_0010,
            1'b1, 1'b1, 32'd0,
            1'b1, 32'd0, 32'h2000_0000,
            "register execute LMO shared-SP destination"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd15,
            "register execute LMO shared-SP destination selector"
        );
        check_register_execute(
            16'h09C0, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete MOVI.W cannot enter register execute"
        );
        check_register_execute(
            16'h09E0, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete MOVI.L cannot enter register execute"
        );
        check_immediate_move_register_execute(
            16'h09C0, 3'd2, 32'hF00D_7FFF,
            32'h0000_7FFF, 1'b0, 1'b0,
            "register execute MOVI.W maximum positive"
        );
        check_immediate_move_register_execute(
            16'h09C0, 3'd2, 32'hF00D_0001,
            32'h0000_0001, 1'b0, 1'b0,
            "register execute MOVI.W positive one"
        );
        check_immediate_move_register_execute(
            16'h09C0, 3'd2, 32'hF00D_0000,
            32'h0000_0000, 1'b0, 1'b1,
            "register execute MOVI.W zero"
        );
        check_immediate_move_register_execute(
            16'h09D2, 3'd2, 32'hF00D_FFFF,
            32'hFFFF_FFFF, 1'b1, 1'b0,
            "register execute MOVI.W B-file negative one"
        );
        check_immediate_move_register_execute(
            16'h09DF, 3'd2, 32'hF00D_8000,
            32'hFFFF_8000, 1'b1, 1'b0,
            "register execute MOVI.W shared-SP sign extension"
        );
        check_immediate_move_register_execute(
            16'h09E0, 3'd3, 32'h7FFF_FFFF,
            32'h7FFF_FFFF, 1'b0, 1'b0,
            "register execute MOVI.L maximum positive"
        );
        check_immediate_move_register_execute(
            16'h09E0, 3'd3, 32'h0000_8000,
            32'h0000_8000, 1'b0, 1'b0,
            "register execute MOVI.L low-word sign is not extended"
        );
        check_immediate_move_register_execute(
            16'h09E0, 3'd3, 32'hFFFF_7FFF,
            32'hFFFF_7FFF, 1'b1, 1'b0,
            "register execute MOVI.L high word controls sign"
        );
        check_immediate_move_register_execute(
            16'h09E0, 3'd3, 32'h8000_0000,
            32'h8000_0000, 1'b1, 1'b0,
            "register execute MOVI.L minimum negative"
        );
        check_immediate_move_register_execute(
            16'h09FF, 3'd3, 32'hFFFF_FFFF,
            32'hFFFF_FFFF, 1'b1, 1'b0,
            "register execute MOVI.L shared-SP negative one"
        );
        check_immediate_move_register_execute(
            16'h09F2, 3'd3, 32'h0000_0000,
            32'h0000_0000, 1'b0, 1'b1,
            "register execute MOVI.L B-file zero"
        );
        check_register_execute(
            16'hEC01, 32'h0000_0000, 32'hFFFF_FFFF, 32'hF020_001F,
            1'b1, 1'b1, 32'hFFFF_0000, 1'b0, 32'd0, 32'd0,
            "register execute MOVX zero source"
        );
        check_register_execute(
            16'hEC01, 32'h1234_5678, 32'h0000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'h0000_5678, 1'b0, 32'd0, 32'd0,
            "register execute MOVX low-half merge"
        );
        check_register_execute(
            16'hEC01, 32'hFFFF_FFFF, 32'h0000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'h0000_FFFF, 1'b0, 32'd0, 32'd0,
            "register execute MOVX negative source"
        );
        check_register_execute(
            16'hEE01, 32'h0000_0000, 32'hFFFF_FFFF, 32'hF020_001F,
            1'b1, 1'b1, 32'h0000_FFFF, 1'b0, 32'd0, 32'd0,
            "register execute MOVY zero source"
        );
        check_register_execute(
            16'hEE11, 32'h1234_5678, 32'h0000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'h1234_0000, 1'b0, 32'd0, 32'd0,
            "register execute MOVY B-file high-half merge"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd1,
            "register execute MOVY B-file selectors"
        );
        check_register_execute(
            16'hEDF2, 32'h1234_5678, 32'hABCD_EF01, 32'hF020_001F,
            1'b1, 1'b1, 32'hABCD_5678, 1'b0, 32'd0, 32'd0,
            "register execute MOVX shared-SP source selector"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd15 &&
            execute_destination_index == 4'd2,
            "register execute MOVX shared-SP source selector"
        );
        check_register_execute(
            16'h4C01, 32'h0000_FFFF, 32'hABCD_EF01, 32'h5020_0010,
            1'b1, 1'b1, 32'h0000_FFFF, 1'b1, 32'd0, 32'hB000_0000,
            "register execute MOVE A to A positive"
        );
        check_register_execute(
            16'h4C01, 32'd0, 32'hABCD_EF01, 32'h5020_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'hB000_0000,
            "register execute MOVE A to A zero"
        );
        check_register_execute(
            16'h4C01, 32'hFFFF_FFFF, 32'hABCD_EF01, 32'h5020_0010,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'h8000_0000, 32'hB000_0000,
            "register execute MOVE A to A negative"
        );
        check_register_execute(
            16'h4E01, 32'h1234_5678, 32'hABCD_EF01, 32'hF020_001F,
            1'b1, 1'b1, 32'h1234_5678, 1'b1, 32'd0, 32'hB000_0000,
            "register execute MOVE A to B"
        );
        check_condition(
            !execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd1,
            "register execute MOVE A-to-B selectors"
        );
        check_register_execute(
            16'h4E11, 32'h89AB_CDEF, 32'hABCD_EF01, 32'h7020_001F,
            1'b1, 1'b1, 32'h89AB_CDEF, 1'b1,
            32'h8000_0000, 32'hB000_0000,
            "register execute MOVE B to A"
        );
        check_condition(
            execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd1,
            "register execute MOVE B-to-A selectors"
        );
        check_register_execute(
            16'h4FFF, 32'hCAFE_BABE, 32'hCAFE_BABE, 32'h7020_001F,
            1'b1, 1'b1, 32'hCAFE_BABE, 1'b1,
            32'h8000_0000, 32'hB000_0000,
            "register execute cross-file MOVE shared SP"
        );
        check_condition(
            execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd15 &&
            execute_destination_index == 4'd15,
            "register execute cross-file MOVE shared-SP selectors"
        );
        check_register_execute(
            16'h3001, 32'd0, 32'hF000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'hF000_0000, 1'b1,
            32'd0, 32'h6000_0000,
            "register execute RL.K count zero"
        );
        check_condition(
            !execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd1 &&
            execute_destination_index == 4'd1,
            "register execute RL.K reads destination only"
        );
        check_register_execute(
            16'h33C1, 32'd0, 32'hF000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'h3C00_0000, 1'b1,
            32'd0, 32'h6000_0000,
            "register execute RL.K count thirty"
        );
        check_register_execute(
            16'h6801, 32'd4, 32'hF000_0000, 32'hF020_001F,
            1'b1, 1'b1, 32'h0000_000F, 1'b1,
            32'h4000_0000, 32'h6000_0000,
            "register execute RL.R source count"
        );
        check_condition(
            !execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd1,
            "register execute RL.R selectors"
        );
        check_register_execute(
            16'h6811, 32'hFFFF_FFE4, 32'hF000_0000,
            32'hF020_001F,
            1'b1, 1'b1, 32'h0000_000F, 1'b1,
            32'h4000_0000, 32'h6000_0000,
            "register execute RL.R uses source low five bits"
        );
        check_register_execute(
            16'h69FF, 32'd31, 32'd1, 32'h9020_001F,
            1'b1, 1'b1, 32'h8000_0000, 1'b1,
            32'd0, 32'h6000_0000,
            "register execute RL.R shared SP"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd15 &&
            execute_destination_index == 4'd15,
            "register execute RL.R shared-SP selectors"
        );
        check_register_execute(
            16'h2041, 32'd0, 32'h3333_3333, 32'hF020_001F,
            1'b1, 1'b1, 32'hCCCC_CCCC, 1'b1,
            32'h9000_0000, 32'hF000_0000,
            "register execute SLA.K direct count"
        );
        check_condition(
            !execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd1 &&
            execute_destination_index == 4'd1,
            "register execute SLA.K reads destination only"
        );
        check_register_execute(
            16'h6022, 32'd5, 32'hCCCC_CCCC, 32'h0020_001F,
            1'b1, 1'b1, 32'h9999_9980, 1'b1,
            32'hD000_0000, 32'hF000_0000,
            "register execute SLA.R source count"
        );
        check_condition(
            !execute_register_file &&
            !execute_destination_register_file &&
            execute_source_index == 4'd1 &&
            execute_destination_index == 4'd2,
            "register execute SLA.R selectors"
        );
        check_register_execute(
            16'h27C1, 32'd0, 32'hFFFF_FFFC, 32'h9020_001F,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'h6000_0000,
            "register execute SLL.K direct count"
        );
        check_register_execute(
            16'h6273, 32'd4, 32'd4, 32'h9020_001F,
            1'b1, 1'b1, 32'h0000_0040, 1'b1,
            32'd0, 32'h6000_0000,
            "register execute SLL.R same-register pre-write count"
        );
        check_condition(
            execute_register_file &&
            execute_destination_register_file &&
            execute_source_index == 4'd3 &&
            execute_destination_index == 4'd3,
            "register execute SLL.R B-file selectors"
        );
        check_register_execute(
            16'h2B01, 32'd0, 32'hFFFF_0000, 32'h1020_001F,
            1'b1, 1'b1, 32'hFFFF_FF00, 1'b1,
            32'h8000_0000, 32'hE000_0000,
            "register execute SRA.K two's-complement count"
        );
        check_register_execute(
            16'h6401, 32'hFFFF_FFF8, 32'h7FFF_0000,
            32'h1020_001F,
            1'b1, 1'b1, 32'h007F_FF00, 1'b1,
            32'd0, 32'hE000_0000,
            "register execute SRA.R negated source low five bits"
        );
        check_register_execute(
            16'h2C21, 32'd0, 32'h7FFF_0000, 32'h9020_001F,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'h6000_0000,
            "register execute SRL.K two's-complement count"
        );
        check_register_execute(
            16'h6601, 32'hFFFF_FFE1, 32'h7FFF_0000,
            32'h9020_001F,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'h6000_0000,
            "register execute SRL.R negated source low five bits"
        );
        execute_first_word = 16'h2041;
        execute_packet_length = 3'd2;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "incorrect-length SLA.K cannot enter register execute"
        );
        check_register_execute(
            16'h0B80, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete ANDNI cannot enter register execute"
        );
        check_immediate_register_execute(
            16'h0B80, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'd0, 1'b1,
            "register execute ANDNI zero"
        );
        check_immediate_register_execute(
            16'h0B80, 32'h5555_5555, 32'hAAAA_AAAA,
            32'hAAAA_AAAA, 1'b0,
            "register execute ANDNI nonzero"
        );
        check_immediate_register_execute(
            16'h0BA0, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hFFFF_FFFF, 1'b0,
            "register execute ORI nonzero"
        );
        check_immediate_register_execute(
            16'h0BA0, 32'd0, 32'd0,
            32'd0, 1'b1,
            "register execute ORI zero"
        );
        check_immediate_register_execute(
            16'h0BC0, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'd0, 1'b1,
            "register execute XORI zero"
        );
        check_immediate_register_execute(
            16'h0BD2, 32'hFFFF_FFFF, 32'hAAAA_AAAA,
            32'h5555_5555, 1'b0,
            "register execute XORI B-file nonzero"
        );
        check_register_execute(
            16'h0C00, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete ADDXYI cannot enter register execute"
        );
        check_addxyi_register_execute(
            16'h0C00, 32'hFFFF_FFFF, 32'h0001_0001,
            32'd0, 4'b1010,
            "register execute ADDXYI independent halves"
        );
        check_addxyi_register_execute(
            16'h0C12, 32'h7FFF_7FFF, 32'h0002_0001,
            32'h8001_8000, 4'b0101,
            "register execute ADDXYI B-file sign flags"
        );
        check_register_execute(
            16'h0B00, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete ADDI.W cannot enter register execute"
        );
        check_immediate_arithmetic_register_execute(
            16'h0B00, 3'd2, 32'h0000_FFF0, 32'h0000_0020,
            32'h0000_0010, 4'b0100,
            "register execute ADDI.W sign extension"
        );
        check_immediate_arithmetic_register_execute(
            16'h0B10, 3'd2, 32'h0000_0001, 32'h7FFF_FFFF,
            32'h8000_0000, 4'b1001,
            "register execute ADDI.W B-file overflow"
        );
        check_immediate_arithmetic_register_execute(
            16'h0B20, 3'd3, 32'h0000_0001, 32'hFFFF_FFFF,
            32'd0, 4'b0110,
            "register execute ADDI.L carry and zero"
        );
        check_immediate_arithmetic_register_execute(
            16'h0B20, 3'd3, 32'h8000_0000, 32'hFFFF_FFFF,
            32'h7FFF_FFFF, 4'b0101,
            "register execute ADDI.L signed overflow"
        );
        execute_first_word = 16'h0B20;
        execute_packet_length = 3'd2;
        execute_immediate = 32'h0000_0001;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "incomplete ADDI.L cannot enter register execute"
        );
        check_register_execute(
            16'h0BE0, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete SUBI.W cannot enter register execute"
        );
        check_immediate_arithmetic_register_execute(
            16'h0BE0, 3'd2, 32'h0000_8000, 32'h0000_7FFE,
            32'hFFFF_FFFF, 4'b1100,
            "register execute SUBI.W complemented positive"
        );
        check_immediate_arithmetic_register_execute(
            16'h0BF0, 3'd2, 32'h0000_7FFF, 32'h7FFF_8000,
            32'h8000_0000, 4'b1101,
            "register execute SUBI.W complemented negative"
        );
        check_immediate_arithmetic_register_execute(
            16'h0D00, 3'd3, 32'hFFFF_7FFE, 32'h0000_8001,
            32'd0, 4'b0010,
            "register execute SUBI.L borrow-free zero"
        );
        check_immediate_arithmetic_register_execute(
            16'h0D00, 3'd3, 32'h0000_8002, 32'h7FFF_7FFD,
            32'h8000_0000, 4'b1101,
            "register execute SUBI.L borrow and overflow"
        );
        execute_first_word = 16'h0D00;
        execute_packet_length = 3'd2;
        execute_immediate = 32'hFFFF_7FFE;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "incomplete SUBI.L cannot enter register execute"
        );
        check_register_execute(
            16'h0B40, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "incomplete CMPI.W cannot enter register execute"
        );
        check_immediate_compare_register_execute(
            16'h0B40, 3'd2, 32'h0000_FFFE, 32'd1,
            4'b0010,
            "register execute CMPI.W nondestructive zero"
        );
        check_immediate_compare_register_execute(
            16'h0B50, 3'd2, 32'h0000_0000, 32'h7FFF_FFFF,
            4'b1101,
            "register execute CMPI.W B-file overflow"
        );
        check_immediate_compare_register_execute(
            16'h0B60, 3'd3, 32'hFFFF_7FFE, 32'h0000_8001,
            4'b0010,
            "register execute CMPI.L nondestructive zero"
        );
        check_immediate_compare_register_execute(
            16'h0B60, 3'd3, 32'h0000_8002, 32'h7FFF_7FFD,
            4'b1101,
            "register execute CMPI.L borrow and overflow"
        );
        execute_first_word = 16'h0B60;
        execute_packet_length = 3'd2;
        execute_immediate = 32'hFFFF_7FFE;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "incomplete CMPI.L cannot enter register execute"
        );
        check_register_execute(
            16'hFFFF, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "unclassified register execute instruction"
        );
        check_cmpxy_register_execute(
            16'hE420, 32'h0009_0009, 32'h0001_0001,
            4'b0101,
            "register execute CMPXY primary result-sign flags"
        );
        check_cmpxy_register_execute(
            16'hE452, 32'h0009_0009, 32'h0009_0009,
            4'b1010,
            "register execute CMPXY B-file same-register operands"
        );
        check_cmpxy_register_execute(
            16'hE5E0, 32'h8000_8000, 32'h0000_0000,
            4'b0101,
            "register execute CMPXY shared-SP source"
        );
        check_cmpxy_register_execute(
            16'hE43F, 32'h0000_0000, 32'h8000_8000,
            4'b0101,
            "register execute CMPXY shared-SP destination"
        );
        check_cmpxy_register_execute(
            16'hE420, 32'hFFFF_0000, 32'h0000_FFFF,
            4'b0001,
            "register execute CMPXY signs differ from borrow flags"
        );
        check_register_execute(
            16'h01A0, 32'hA5C3_5A3C, 32'd0, 32'hF000_0FFF,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'hA5C3_5A3C, 32'hFFFF_FFFF,
            "register execute PUTST A-file full-status write"
        );
        check_condition(
            !execute_register_file &&
            execute_source_index == 4'd0,
            "register execute PUTST A-file source selector"
        );
        check_register_execute(
            16'h01BF, 32'hFFFF_FFFF, 32'd0, 32'h0000_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'hFFFF_FFFF, 32'hFFFF_FFFF,
            "register execute PUTST B-file shared-SP full-status write"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd15,
            "register execute PUTST B-file shared-SP source selector"
        );
        check_register_execute(
            16'h01C0, 32'd0, 32'd0, 32'hA5C3_5A3C,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decode-only POPST cannot enter register execute"
        );
        check_register_execute(
            16'h01E0, 32'd0, 32'd0, 32'hA5C3_5A3C,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decode-only PUSHST cannot enter register execute"
        );
        check_register_execute(
            16'h0160, 32'h1234_567F, 32'd0, 32'hA5C3_5A3C,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decode-only JUMP cannot enter register execute"
        );
        execute_first_word = 16'h0D80;
        execute_packet_length = 3'd2;
        execute_immediate = 32'h0000_FFFE;
        execute_source = 32'd0;
        execute_destination = 32'h1234_5678;
        execute_status = 32'hA000_0010;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "complete DSJ cannot enter register execute"
        );
        check_register_execute(
            16'h3FFF, 32'd0, 32'h1234_5678, 32'hA000_0010,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decode-only DSJS cannot enter register execute"
        );
        execute_first_word = 16'hC000;
        execute_packet_length = 3'd2;
        execute_immediate = 32'h0000_0002;
        execute_source = 32'd0;
        execute_destination = 32'h1234_5678;
        execute_status = 32'hA000_0010;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "complete JR.L cannot enter register execute"
        );
        execute_first_word = 16'hC080;
        execute_packet_length = 3'd3;
        execute_immediate = 32'h1234_5678;
        execute_source = 32'd0;
        execute_destination = 32'h1234_5678;
        execute_status = 32'hA000_0010;
        #1;
        check_condition(
            !execute_supported &&
            !execute_register_write_enable &&
            !execute_status_write_enable,
            "complete JACC cannot enter register execute"
        );
        check_register_execute(
            16'hD505, 32'd0, 32'hFFFF_FFC0, 32'hF000_0FFF,
            1'b1, 1'b1, 32'h0000_003F, 1'b1,
            32'd0, 32'h0000_003F,
            "register execute EXGF field zero"
        );
        check_condition(
            !execute_register_file &&
            execute_source_index == 4'd5 &&
            execute_destination_index == 4'd5,
            "register execute EXGF field-zero A-file selector"
        );
        check_register_execute(
            16'hD705, 32'd0, 32'hFFFF_FFC0, 32'hF000_0FFF,
            1'b1, 1'b1, 32'h0000_003F, 1'b1,
            32'd0, 32'h0000_0FC0,
            "register execute EXGF field one"
        );
        check_register_execute(
            16'hD71F, 32'd0, 32'hFFFF_FF95, 32'hB5A3_4A95,
            1'b1, 1'b1, 32'h0000_002A, 1'b1,
            32'h0000_0540, 32'h0000_0FC0,
            "register execute EXGF field one shared SP"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd15 &&
            execute_destination_index == 4'd15,
            "register execute EXGF field-one B-file shared-SP selector"
        );
        check_register_execute(
            16'h0540, 32'd0, 32'd0, 32'hF020_001F,
            1'b1, 1'b0, 32'd0, 1'b1, 32'd0, 32'h0000_003F,
            "register execute SETF field zero size thirty-two"
        );
        check_register_execute(
            16'h0760, 32'd0, 32'd0, 32'hF020_001F,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h0000_0800, 32'h0000_0FC0,
            "register execute SETF field one sign-extension"
        );
        check_register_execute(
            16'h0500, 32'd0, 32'h0000_8000, 32'hF020_0011,
            1'b1, 1'b1, 32'h0000_8000, 1'b1,
            32'd0, 32'hA000_0000,
            "register execute SEXT field zero size seventeen"
        );
        check_condition(
            !execute_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd0,
            "register execute SEXT field-zero A-file selector"
        );
        check_register_execute(
            16'h0712, 32'd0, 32'h0000_8000, 32'h7020_041F,
            1'b1, 1'b1, 32'hFFFF_8000, 1'b1,
            32'h8000_0000, 32'hA000_0000,
            "register execute SEXT field one B-file size sixteen"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute SEXT field-one B-file selector"
        );
        check_register_execute(
            16'h0520, 32'd0, 32'hFFFF_0000, 32'hD020_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute ZEXT field zero zero result"
        );
        check_register_execute(
            16'h0520, 32'd0, 32'hFFFF_FFFF, 32'hD020_0000,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute ZEXT size thirty-two leaves N unowned"
        );
        check_register_execute(
            16'h073F, 32'd0, 32'hFFFF_FF80, 32'hD020_021F,
            1'b1, 1'b1, 32'h0000_0080, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute ZEXT field one shared SP"
        );
        check_condition(
            execute_register_file &&
            execute_destination_index == 4'd15,
            "register execute ZEXT B15 shared-SP selector"
        );
        check_register_execute(
            16'h1FE0, 32'd0, 32'h5555_5555, 32'hD020_001F,
            1'b1, 1'b0, 32'd0, 1'b1, 32'd0, 32'h2000_0000,
            "register execute BTST.K recovers complemented bit zero"
        );
        check_condition(
            !execute_register_file &&
            execute_source_index == 4'd0 &&
            execute_destination_index == 4'd0,
            "register execute BTST.K destination selector"
        );
        check_register_execute(
            16'h4A20, 32'd15, 32'h5555_5555, 32'hD020_001F,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute BTST.R uses source low five bits"
        );
        check_condition(
            !execute_register_file &&
            execute_source_index == 4'd1 &&
            execute_destination_index == 4'd0,
            "register execute BTST.R A-file selectors"
        );
        check_register_execute(
            16'h4A30, 32'hFFFF_FF8F, 32'hFFFF_7FFF,
            32'hD020_001F,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute BTST.R ignores source upper bits"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd1 &&
            execute_destination_index == 4'd0,
            "register execute BTST.R B-file selectors"
        );
        check_register_execute(
            16'h4A42, 32'h8000_001F, 32'h8000_001F,
            32'hF020_001F,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute BTST.R same-register operands"
        );
        check_xy_register_execute(
            16'hE020, 32'h0001_0002, 32'h0003_0004,
            32'h0004_0006, 4'b0000,
            "register execute ADDXY independent halves"
        );
        check_xy_register_execute(
            16'hE220, 32'h0001_0002, 32'h0003_0004,
            32'h0002_0002, 4'b0000,
            "register execute SUBXY comparisons"
        );
        check_xy_register_execute(
            16'hE052, 32'h0001_0002, 32'h0001_0002,
            32'h0002_0004, 4'b0000,
            "register execute ADDXY B-file same-register prewrite"
        );
        check_xy_register_execute(
            16'hE252, 32'h0001_0002, 32'h0001_0002,
            32'd0, 4'b1010,
            "register execute SUBXY B-file same-register prewrite"
        );
        check_xy_register_execute(
            16'hE1E0, 32'h0003_0004, 32'h0000_0000,
            32'h0003_0004, 4'b0000,
            "register execute ADDXY shared-SP source selector"
        );
        check_xy_register_execute(
            16'hE23F, 32'h0001_0001, 32'h0003_0004,
            32'h0002_0003, 4'b0000,
            "register execute SUBXY shared-SP destination selector"
        );

        commit_jr_long_instruction(
            16'hC000, 16'h0002, 32'h0000_1020,
            1'b1, 32'h0000_1040,
            TMS34020_ST_RESET, 32'd0,
            "register commit unconditional JR.L redirect"
        );
        commit_jr_long_instruction(
            16'hC800, 16'h0002, 32'h0000_1020,
            1'b0, 32'd0,
            TMS34020_ST_RESET, 32'd0,
            "register commit false JR.C preserves state"
        );

        commit_jacc_instruction(
            16'hC080, 32'h1234_567F, 32'h0000_1030,
            1'b1, 32'h1234_5670,
            TMS34020_ST_RESET, 32'd0,
            "register commit unconditional JACC redirect"
        );
        commit_jacc_instruction(
            16'hC880, 32'hFFFF_FFFF, 32'h0000_1030,
            1'b0, 32'd0,
            TMS34020_ST_RESET, 32'd0,
            "register commit false JA.C preserves state"
        );

        commit_register_instruction(
            16'h0D60, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0020_0000, 32'h0020_0000,
            32'h0020_0010, 32'd0,
            "register commit EINT"
        );
        commit_register_instruction(
            16'h0DE0, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h4000_0000, 32'h4000_0000,
            32'h4020_0010, 32'd0,
            "register commit SETC"
        );
        commit_register_instruction(
            16'h0192, 1'b1,
            1'b1, 1'b1, 4'd2, 32'h4020_0010,
            1'b0, 32'd0, 32'd0,
            32'h4020_0010, 32'd0,
            "register commit GETST B2"
        );
        commit_register_instruction(
            16'hE452, 1'b1,
            1'b0, 1'b1, 4'd2, 32'd0,
            1'b1, 32'hA000_0000, 32'hF000_0000,
            32'hA020_0010, 32'd0,
            "register commit CMPXY B2,B2 is nondestructive"
        );
        commit_register_instruction(
            16'h1032, 1'b1,
            1'b1, 1'b1, 4'd2, 32'h4020_0011,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0020_0010, 32'd0,
            "register commit ADDK/INC reads prior B2"
        );
        commit_register_instruction(
            16'h0360, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'd0, 32'h0020_0000,
            32'h0000_0010, 32'd0,
            "register commit DINT"
        );
        commit_register_instruction(
            16'h1420, 1'b1,
            1'b1, 1'b0, 4'd0, 32'hFFFF_FFFF,
            1'b1, 32'hC000_0000, 32'hF000_0000,
            32'hC000_0010, 32'd0,
            "register commit SUBK/DEC A0"
        );
        commit_immediate_move_instruction(
            16'h09D3, 3'd2, 32'hF00D_8000,
            1'b1, 4'd3, 32'hFFFF_8000,
            1'b1, 1'b0, 32'hC000_0010, 32'd0,
            "register commit MOVI.W preserves carry"
        );
        commit_immediate_move_instruction(
            16'h09FF, 3'd3, 32'd0,
            1'b1, 4'd15, 32'd0,
            1'b0, 1'b1, 32'h6000_0010, 32'd0,
            "register commit MOVI.L updates shared SP and preserves carry"
        );
        commit_register_instruction(
            16'hEC01, 1'b1,
            1'b1, 1'b0, 4'd1, 32'h0000_FFFF,
            1'b0, 32'd0, 32'd0,
            32'h6000_0010, 32'd0,
            "register commit MOVX preserves destination Y and ST"
        );
        commit_register_instruction(
            16'hEE01, 1'b1,
            1'b1, 1'b0, 4'd1, 32'hFFFF_FFFF,
            1'b0, 32'd0, 32'd0,
            32'h6000_0010, 32'd0,
            "register commit MOVY observes prior MOVX"
        );
        commit_register_instruction(
            16'h4E01, 1'b1,
            1'b1, 1'b1, 4'd1, 32'hFFFF_FFFF,
            1'b1, 32'h8000_0000, 32'hB000_0000,
            32'hC000_0010, 32'd0,
            "register commit MOVE A0 to B1"
        );
        commit_register_instruction(
            16'h4E32, 1'b1,
            1'b1, 1'b0, 4'd2, 32'hFFFF_FFFF,
            1'b1, 32'h8000_0000, 32'hB000_0000,
            32'hC000_0010, 32'd0,
            "register commit MOVE B1 to A2"
        );
        commit_register_instruction(
            16'h3002, 1'b1,
            1'b1, 1'b0, 4'd2, 32'hFFFF_FFFF,
            1'b1, 32'd0, 32'h6000_0000,
            32'h8000_0010, 32'd0,
            "register commit RL.K count zero clears carry"
        );
        commit_register_instruction(
            16'h6840, 1'b1,
            1'b1, 1'b0, 4'd0, 32'hFFFF_FFFF,
            1'b1, 32'h4000_0000, 32'h6000_0000,
            32'hC000_0010, 32'd0,
            "register commit RL.R observes source count and preserves N"
        );
        commit_register_instruction(
            16'h0380, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b1, 32'd0, 32'hB000_0000,
            32'h4000_0010, 32'd0,
            "register commit ABS preserves carry"
        );
        commit_register_instruction(
            16'h102F, 1'b1,
            1'b1, 1'b0, 4'd15, 32'd1,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd1,
            "register commit ADDK/INC shared SP"
        );
        commit_register_instruction(
            16'h41E0, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd2,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd1,
            "register commit ADD reads SP"
        );
        commit_register_instruction(
            16'h4800, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'd1,
            "register commit CMP is nondestructive"
        );
        commit_register_instruction(
            16'h7A01, 1'b1,
            1'b1, 1'b0, 4'd1, 32'd1,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit RMO clears zero"
        );
        commit_register_instruction(
            16'h6BFE, 1'b1,
            1'b1, 1'b1, 4'd14, 32'd31,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit LMO reads shared SP"
        );
        commit_register_instruction(
            16'h4BE1, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit BTST.R reads shared-SP count"
        );
        commit_register_instruction(
            16'h1FFF, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit BTST.K reads shared-SP destination"
        );
        commit_register_instruction(
            16'h00F0, 1'b0,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit rejects unsupported BLMOVE"
        );
        commit_register_instruction(
            16'h01C0, 1'b0,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit rejects decode-only POPST"
        );
        commit_register_instruction(
            16'h01E0, 1'b0,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit rejects decode-only PUSHST"
        );
        commit_dsj_instruction(
            16'h0D9F, 16'h0002, 32'h0000_1000,
            1'b1, 32'd0, 1'b0, 32'd0,
            32'h0000_0010, 32'd0,
            "register commit DSJ decrement-to-zero shared SP"
        );
        commit_dsj_instruction(
            16'h0D9F, 16'hFFFE, 32'h0000_1000,
            1'b1, 32'hFFFF_FFFF, 1'b1, 32'h0000_0FE0,
            32'h0000_0010, 32'hFFFF_FFFF,
            "register commit DSJ wrapping decrement and backward redirect"
        );
        commit_dsj_instruction(
            16'h0DAF, 16'h0002, 32'h0000_1000,
            1'b0, 32'd0, 1'b0, 32'd0,
            32'h0000_0010, 32'hFFFF_FFFF,
            "register commit DSJEQ suppresses decrement when Z clear"
        );
        commit_register_instruction(
            16'h4800, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'hFFFF_FFFF,
            "register commit prepares Z for DSJEQ"
        );
        commit_dsj_instruction(
            16'h0DBF, 16'h0002, 32'h0000_1000,
            1'b1, 32'hFFFF_FFFE, 1'b1, 32'h0000_1020,
            32'h2000_0010, 32'hFFFF_FFFE,
            "register commit DSJEQ enabled shared SP"
        );
        commit_dsj_instruction(
            16'h0DCF, 16'h0002, 32'h0000_1000,
            1'b0, 32'd0, 1'b0, 32'd0,
            32'h2000_0010, 32'hFFFF_FFFE,
            "register commit DSJNE suppresses decrement when Z set"
        );
        commit_immediate_move_instruction(
            16'h09FF, 3'd3, 32'h0000_0009,
            1'b1, 4'd15, 32'h0000_0009,
            1'b0, 1'b0,
            32'h0000_0010, 32'h0000_0009,
            "register commit prepares clear Z and SP for DSJNE"
        );
        commit_dsj_instruction(
            16'h0DDF, 16'h0002, 32'hFFFF_FFF0,
            1'b1, 32'h0000_0008, 1'b1, 32'h0000_0010,
            32'h0000_0010, 32'h0000_0008,
            "register commit DSJNE enabled with PC wrap"
        );
        commit_immediate_move_instruction(
            16'h09FF, 3'd3, 32'h0000_0001,
            1'b1, 4'd15, 32'h0000_0001,
            1'b0, 1'b0,
            32'h0000_0010, 32'd1,
            "register commit restores shared SP after DSJ matrix"
        );
        commit_immediate_move_instruction(
            16'h09F2, 3'd3, 32'h0000_0002,
            1'b1, 4'd2, 32'h0000_0002,
            1'b0, 1'b0,
            32'h0000_0010, 32'd1,
            "register commit prepares B2 for DSJS"
        );
        commit_dsjs_instruction(
            16'h3852, 32'h0000_1000,
            32'h0000_0001, 1'b1, 32'h0000_1020,
            32'h0000_0010, 32'd1,
            "register commit DSJS forward B2"
        );
        commit_dsjs_instruction(
            16'h3BFF, 32'h0000_1000,
            32'd0, 1'b0, 32'd0,
            32'h0000_0010, 32'd0,
            "register commit DSJS decrement-to-zero shared SP"
        );
        commit_immediate_move_instruction(
            16'h09FF, 3'd3, 32'h0000_0002,
            1'b1, 4'd15, 32'h0000_0002,
            1'b0, 1'b0,
            32'h0000_0010, 32'd2,
            "register commit prepares shared SP for backward DSJS"
        );
        commit_dsjs_instruction(
            16'h3FFF, 32'h0000_0090,
            32'h0000_0001, 1'b1, 32'hFFFF_FEA0,
            32'h0000_0010, 32'd1,
            "register commit DSJS backward shared SP and PC wrap"
        );
        commit_register_instruction(
            16'h0300, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit accepts NOP without state write"
        );
        commit_register_instruction(
            16'h5020, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit AND reads A1 and A0"
        );
        commit_register_instruction(
            16'h5420, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit OR observes preceding AND"
        );
        commit_register_instruction(
            16'h5620, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit XOR observes preceding OR"
        );
        commit_register_instruction(
            16'h5220, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit ANDN preserves zero result"
        );
        commit_register_instruction(
            16'h0B80, 1'b0,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h2000_0010, 32'd1,
            "register commit rejects incomplete ANDNI packet"
        );
        commit_immediate_instruction(
            16'h0BA0, 32'hA5A5_5A5A,
            1'b0, 4'd0, 32'hA5A5_5A5A, 1'b0,
            32'h0000_0010, 32'd1,
            "register commit ORI packet"
        );
        commit_immediate_instruction(
            16'h0BC0, 32'hA5A5_5A5A,
            1'b0, 4'd0, 32'd0, 1'b1,
            32'h2000_0010, 32'd1,
            "register commit XORI observes ORI"
        );
        commit_immediate_instruction(
            16'h0B92, 32'hFFFF_FFFF,
            1'b1, 4'd2, 32'd0, 1'b1,
            32'h2000_0010, 32'd1,
            "register commit ANDNI B2 packet"
        );
        commit_addxyi_instruction(
            16'h0C00, 32'hFFFF_0000,
            1'b0, 4'd0, 32'hFFFF_0000, 4'b1100,
            32'hC000_0010, 32'd1,
            "register commit ADDXYI packet"
        );
        commit_addxyi_instruction(
            16'h0C00, 32'h0001_FFFF,
            1'b0, 4'd0, 32'h0000_FFFF, 4'b0011,
            32'h3000_0010, 32'd1,
            "register commit ADDXYI observes prior result"
        );
        commit_addxyi_instruction(
            16'h0C1F, 32'hFFFF_FFFF,
            1'b1, 4'd15, 32'hFFFF_0000, 4'b1100,
            32'hC000_0010, 32'hFFFF_0000,
            "register commit ADDXYI updates shared SP"
        );
        commit_immediate_arithmetic_instruction(
            16'h0B00, 3'd2, 32'h0000_0001,
            1'b0, 4'd0, 32'h0001_0000, 4'b0000,
            32'h0000_0010, 32'hFFFF_0000,
            "register commit ADDI.W packet"
        );
        commit_immediate_arithmetic_instruction(
            16'h0B00, 3'd2, 32'h0000_FFFF,
            1'b0, 4'd0, 32'h0000_FFFF, 4'b0100,
            32'h4000_0010, 32'hFFFF_0000,
            "register commit ADDI.W observes prior result"
        );
        commit_immediate_arithmetic_instruction(
            16'h0B20, 3'd3, 32'h7FFF_0001,
            1'b0, 4'd0, 32'h8000_0000, 4'b1001,
            32'h9000_0010, 32'hFFFF_0000,
            "register commit ADDI.L packet"
        );
        commit_immediate_arithmetic_instruction(
            16'h0B3F, 3'd3, 32'h0001_0000,
            1'b1, 4'd15, 32'd0, 4'b0110,
            32'h6000_0010, 32'd0,
            "register commit ADDI.L updates shared SP"
        );
        commit_immediate_arithmetic_instruction(
            16'h0BE0, 3'd2, 32'h0000_FFFE,
            1'b0, 4'd0, 32'h7FFF_FFFF, 4'b0001,
            32'h1000_0010, 32'd0,
            "register commit SUBI.W complemented packet"
        );
        commit_immediate_arithmetic_instruction(
            16'h0BE0, 3'd2, 32'h0000_0000,
            1'b0, 4'd0, 32'h8000_0000, 4'b1101,
            32'hD000_0010, 32'd0,
            "register commit SUBI.W observes prior result"
        );
        commit_immediate_arithmetic_instruction(
            16'h0D00, 3'd3, 32'hFFFF_7FFE,
            1'b0, 4'd0, 32'h7FFF_7FFF, 4'b0001,
            32'h1000_0010, 32'd0,
            "register commit SUBI.L complemented packet"
        );
        commit_immediate_arithmetic_instruction(
            16'h0D1F, 3'd3, 32'h0000_0001,
            1'b1, 4'd15, 32'd2, 4'b0100,
            32'h4000_0010, 32'd2,
            "register commit SUBI.L updates shared SP"
        );
        commit_immediate_compare_instruction(
            16'h0B40, 3'd2, 32'h0000_0000,
            4'b0100, 32'h4000_0010, 32'd2,
            "register commit CMPI.W suppresses A0 write"
        );
        commit_immediate_compare_instruction(
            16'h0B60, 3'd3, 32'h8000_8000,
            4'b0010, 32'h2000_0010, 32'd2,
            "register commit CMPI.L observes unchanged A0"
        );
        commit_immediate_compare_instruction(
            16'h0B5F, 3'd2, 32'h0000_FFFD,
            4'b0010, 32'h2000_0010, 32'd2,
            "register commit CMPI.W preserves shared SP"
        );
        commit_register_instruction(
            16'h101F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'd34,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd34,
            "register commit ADDK encoded-zero shared SP"
        );
        commit_register_instruction(
            16'h181F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'd32,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd32,
            "register commit MOVK encoded-zero shared SP"
        );
        commit_pc_instruction(
            16'h0152, 32'h0000_1C20,
            1'b1, 4'd2, 32'h0000_1C20,
            1'b0, 32'd0,
            32'h0000_0010, 32'd32,
            "register commit GETPC B2"
        );
        commit_immediate_move_instruction(
            16'h09E1, 3'd3, 32'h1234_567F,
            1'b0, 4'd1, 32'h1234_567F,
            1'b0, 1'b0, 32'h0000_0010, 32'd32,
            "register commit seeds EXGPC A1 target"
        );
        commit_pc_instruction(
            16'h0121, 32'h0000_2090,
            1'b0, 4'd1, 32'h0000_2090,
            1'b1, 32'h1234_5670,
            32'h0000_0010, 32'd32,
            "register commit EXGPC captures old A1"
        );
        commit_immediate_move_instruction(
            16'h09FF, 3'd3, 32'hCAFE_BABF,
            1'b1, 4'd15, 32'hCAFE_BABF,
            1'b1, 1'b0, 32'h8000_0010, 32'hCAFE_BABF,
            "register commit seeds EXGPC shared-SP target"
        );
        commit_pc_instruction(
            16'h013F, 32'h0000_4000,
            1'b1, 4'd15, 32'h0000_4000,
            1'b1, 32'hCAFE_BAB0,
            32'h8000_0010, 32'h0000_4000,
            "register commit EXGPC shared SP"
        );
        commit_jump_instruction(
            16'h0161, 32'h0000_2090,
            32'h8000_0010, 32'h0000_4000,
            "register commit JUMP reads A1 without state write"
        );
        commit_jump_instruction(
            16'h017F, 32'h0000_4000,
            32'h8000_0010, 32'h0000_4000,
            "register commit JUMP reads shared SP without state write"
        );
        commit_register_instruction(
            16'h1820, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b0, 32'd0, 32'd0,
            32'h8000_0010, 32'h0000_4000,
            "register commit seeds ADDXY destination"
        );
        commit_register_instruction(
            16'h1841, 1'b1,
            1'b1, 1'b0, 4'd1, 32'd2,
            1'b0, 32'd0, 32'd0,
            32'h8000_0010, 32'h0000_4000,
            "register commit seeds ADDXY source"
        );
        commit_register_instruction(
            16'hE020, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd3,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'h0000_4000,
            "register commit ADDXY observes seeded registers"
        );
        commit_register_instruction(
            16'hE201, 1'b1,
            1'b1, 1'b0, 4'd1, 32'h0000_FFFF,
            1'b1, 32'h3000_0000, 32'hF000_0000,
            32'h3000_0010, 32'h0000_4000,
            "register commit SUBXY observes preceding ADDXY"
        );
        commit_register_instruction(
            16'hE1E0, 1'b1,
            1'b1, 1'b0, 4'd0, 32'h0000_4003,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'h0000_4000,
            "register commit ADDXY reads shared SP source"
        );
        commit_register_instruction(
            16'hE20F, 1'b1,
            1'b1, 1'b0, 4'd15, 32'h0000_FFFD,
            1'b1, 32'h3000_0000, 32'hF000_0000,
            32'h3000_0010, 32'h0000_FFFD,
            "register commit SUBXY updates shared SP destination"
        );
        commit_register_instruction(
            16'h0570, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0000_0030, 32'h0000_003F,
            32'h3000_0030, 32'h0000_FFFD,
            "register commit SETF selects field zero size sixteen"
        );
        commit_register_instruction(
            16'h053F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'h0000_FFFD,
            1'b1, 32'd0, 32'h2000_0000,
            32'h1000_0030, 32'h0000_FFFD,
            "register commit ZEXT field zero shared SP"
        );
        commit_register_instruction(
            16'h051F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'hFFFF_FFFD,
            1'b1, 32'h8000_0000, 32'hA000_0000,
            32'h9000_0030, 32'hFFFF_FFFD,
            "register commit SEXT field zero shared SP"
        );
        commit_register_instruction(
            16'h0750, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0000_0400, 32'h0000_0FC0,
            32'h9000_0430, 32'hFFFF_FFFD,
            "register commit SETF selects field one size sixteen"
        );
        commit_register_instruction(
            16'h073F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'h0000_FFFD,
            1'b1, 32'd0, 32'h2000_0000,
            32'h9000_0430, 32'h0000_FFFD,
            "register commit ZEXT field one shared SP"
        );
        commit_register_instruction(
            16'h071F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'hFFFF_FFFD,
            1'b1, 32'h8000_0000, 32'hA000_0000,
            32'h9000_0430, 32'hFFFF_FFFD,
            "register commit SEXT field one shared SP"
        );
        commit_register_instruction(
            16'hD50F, 1'b1,
            1'b1, 1'b0, 4'd15, 32'h0000_0030,
            1'b1, 32'h0000_003D, 32'h0000_003F,
            32'h9000_043D, 32'h0000_0030,
            "register commit EXGF field zero shared SP"
        );
        commit_register_instruction(
            16'hD71F, 1'b1,
            1'b1, 1'b1, 4'd15, 32'h0000_0010,
            1'b1, 32'h0000_0C00, 32'h0000_0FC0,
            32'h9000_0C3D, 32'h0000_0010,
            "register commit EXGF field one shared SP"
        );
        commit_register_instruction(
            16'hD505, 1'b1,
            1'b1, 1'b0, 4'd5, 32'h0000_003D,
            1'b1, 32'd0, 32'h0000_003F,
            32'h9000_0C00, 32'h0000_0010,
            "register commit EXGF field zero ordinary A register"
        );
        commit_register_instruction(
            16'h01A5, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0000_003D, 32'hFFFF_FFFF,
            32'h0000_003D, 32'h0000_0010,
            "register commit PUTST reads dependent ordinary A register"
        );
        commit_register_instruction(
            16'h01BF, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0000_0010, 32'hFFFF_FFFF,
            32'h0000_0010, 32'h0000_0010,
            "register commit PUTST reads B-file shared SP"
        );

        check_decode(16'h0040, TMS20_OP_IDLE, 3'd1, "IDLE exact decode");
        check_decode(16'h0080, TMS20_OP_MWAIT, 3'd1, "MWAIT exact decode");
        check_decode(16'h0020, TMS20_OP_REV, 3'd1,
                     "REV A-file lower-bound decode");
        check_decode(16'h003F, TMS20_OP_REV, 3'd1,
                     "REV B-file shared-SP decode");
        check_decode(16'h0900, TMS20_OP_TRAP, 3'd1,
                     "TRAP 0 lower-bound decode");
        check_decode(16'h091F, TMS20_OP_TRAP, 3'd1,
                     "TRAP 31 upper-bound decode");
        check_decode(16'h0860, TMS20_OP_RETM, 3'd1,
                     "RETM exact decode");
        check_decode(16'h0940, TMS20_OP_RETI, 3'd1,
                     "RETI exact decode");
        check_decode(16'h0920, TMS20_OP_CALL, 3'd1,
                     "CALL A0 lower-bound decode");
        check_decode(16'h093F, TMS20_OP_CALL, 3'd1,
                     "CALL B-file shared-SP upper-bound decode");
        check_decode(16'h0960, TMS20_OP_RETS, 3'd1,
                     "RETS 0 lower-bound decode");
        check_decode(16'h097F, TMS20_OP_RETS, 3'd1,
                     "RETS 31 upper-bound decode");
        check_decode(16'h0D3F, TMS20_OP_CALLR, 3'd2,
                     "CALLR consumes signed displacement word");
        check_decode(16'h0D5F, TMS20_OP_CALLA, 3'd3,
                     "CALLA consumes low/high absolute words");
        check_decode(16'h0300, TMS20_OP_NOP, 3'd1, "NOP exact decode");
        check_decode(16'h039F, TMS20_OP_ABS, 3'd1, "ABS masked decode");
        check_decode(16'h03BF, TMS20_OP_NEG, 3'd1, "NEG masked decode");
        check_decode(16'h03DF, TMS20_OP_NEGB, 3'd1, "NEGB masked decode");
        check_decode(16'h03FF, TMS20_OP_NOT, 3'd1, "NOT masked decode");
        check_decode(16'h0320, TMS20_OP_CLRC, 3'd1,
                     "CLRC exact decode");
        check_decode(16'h0360, TMS20_OP_DINT, 3'd1,
                     "DINT exact decode");
        check_decode(16'h0D60, TMS20_OP_EINT, 3'd1,
                     "EINT exact decode");
        check_decode(16'h0D80, TMS20_OP_DSJ, 3'd2,
                     "DSJ A-file lower-bound decode");
        check_decode(16'h0D9F, TMS20_OP_DSJ, 3'd2,
                     "DSJ B-file shared-SP decode");
        check_decode(16'h0DA0, TMS20_OP_DSJEQ, 3'd2,
                     "DSJEQ A-file lower-bound decode");
        check_decode(16'h0DBF, TMS20_OP_DSJEQ, 3'd2,
                     "DSJEQ B-file shared-SP decode");
        check_decode(16'h0DC0, TMS20_OP_DSJNE, 3'd2,
                     "DSJNE A-file lower-bound decode");
        check_decode(16'h0DDF, TMS20_OP_DSJNE, 3'd2,
                     "DSJNE B-file shared-SP decode");
        check_decode(16'h0DE0, TMS20_OP_SETC, 3'd1,
                     "SETC exact decode");
        check_decode(16'h3800, TMS20_OP_DSJS, 3'd1,
                     "DSJS forward-zero A-file lower-bound decode");
        check_decode(16'h3BFF, TMS20_OP_DSJS, 3'd1,
                     "DSJS forward-max B-file shared-SP decode");
        check_decode(16'h3C00, TMS20_OP_DSJS, 3'd1,
                     "DSJS backward-zero A-file lower-bound decode");
        check_decode(16'h3FFF, TMS20_OP_DSJS, 3'd1,
                     "DSJS backward-max B-file shared-SP decode");
        check_decode(16'hC000, TMS20_OP_JR_L, 3'd2,
                     "JR.L true-condition decode");
        check_decode(16'hC700, TMS20_OP_JR_L, 3'd2,
                     "JR.L greater-than condition decode");
        check_decode(16'hCF00, TMS20_OP_JR_L, 3'd2,
                     "JR.L nonnegative condition decode");
        check_decode(16'hC080, TMS20_OP_JACC, 3'd3,
                     "JACC true-condition decode");
        check_decode(16'hC780, TMS20_OP_JACC, 3'd3,
                     "JACC greater-than condition decode");
        check_decode(16'hCF80, TMS20_OP_JACC, 3'd3,
                     "JACC nonnegative condition decode");
        check_decode(16'h019F, TMS20_OP_GETST, 3'd1,
                     "GETST masked decode");
        check_decode(16'h01A0, TMS20_OP_PUTST, 3'd1,
                     "PUTST A-file lower-bound decode");
        check_decode(16'h01BF, TMS20_OP_PUTST, 3'd1,
                     "PUTST B-file shared-SP decode");
        check_decode(16'h01C0, TMS20_OP_POPST, 3'd1,
                     "POPST exact decode");
        check_decode(16'h01E0, TMS20_OP_PUSHST, 3'd1,
                     "PUSHST exact decode");
        check_decode(16'h0160, TMS20_OP_JUMP, 3'd1,
                     "JUMP A-file lower-bound decode");
        check_decode(16'h017F, TMS20_OP_JUMP, 3'd1,
                     "JUMP B-file shared-SP decode");
        check_decode(16'h0120, TMS20_OP_EXGPC, 3'd1,
                     "EXGPC masked decode");
        check_decode(16'h015F, TMS20_OP_GETPC, 3'd1,
                     "GETPC masked decode");
        check_decode(16'h1000, TMS20_OP_ADDK, 3'd1,
                     "ADDK encoded-zero decode");
        check_decode(16'h103F, TMS20_OP_ADDK, 3'd1,
                     "ADDK/INC alias decode");
        check_decode(16'h13FF, TMS20_OP_ADDK, 3'd1,
                     "ADDK upper-bound decode");
        check_decode(16'h1400, TMS20_OP_SUBK, 3'd1,
                     "SUBK encoded-zero decode");
        check_decode(16'h143F, TMS20_OP_SUBK, 3'd1,
                     "SUBK/DEC alias decode");
        check_decode(16'h17FF, TMS20_OP_SUBK, 3'd1,
                     "SUBK upper-bound decode");
        check_decode(16'h1800, TMS20_OP_MOVK, 3'd1,
                     "MOVK encoded-zero decode");
        check_decode(16'h1BFF, TMS20_OP_MOVK, 3'd1,
                     "MOVK upper-bound decode");
        check_decode(16'h09C0, TMS20_OP_MOVI_W, 3'd2,
                     "MOVI.W lower-bound decode");
        check_decode(16'h09DF, TMS20_OP_MOVI_W, 3'd2,
                     "MOVI.W upper-bound decode");
        check_decode(16'h09E0, TMS20_OP_MOVI_L, 3'd3,
                     "MOVI.L lower-bound decode");
        check_decode(16'h09FF, TMS20_OP_MOVI_L, 3'd3,
                     "MOVI.L upper-bound decode");
        check_decode(16'h4C00, TMS20_OP_MOVE, 3'd1,
                     "MOVE lower-bound decode");
        check_decode(16'h4FFF, TMS20_OP_MOVE, 3'd1,
                     "MOVE upper-bound decode");
        check_decode(16'h8000, TMS20_OP_MOVE_RM, 3'd1,
                     "MOVE.RM field-zero lower-bound decode");
        check_decode(16'h83FF, TMS20_OP_MOVE_RM, 3'd1,
                     "MOVE.RM field-one upper-bound decode");
        check_decode(16'h8400, TMS20_OP_MOVE_MR, 3'd1,
                     "MOVE.MR field-zero lower-bound decode");
        check_decode(16'h87FF, TMS20_OP_MOVE_MR, 3'd1,
                     "MOVE.MR field-one upper-bound decode");
        check_decode(16'h8800, TMS20_OP_MOVE_MM, 3'd1,
                     "MOVE.MM field-zero lower-bound decode");
        check_decode(16'h8BFF, TMS20_OP_MOVE_MM, 3'd1,
                     "MOVE.MM field-one upper-bound decode");
        check_decode(16'h9000, TMS20_OP_MOVE_RM_POST, 3'd1,
                     "MOVE.RM.POST field-zero lower-bound decode");
        check_decode(16'h93FF, TMS20_OP_MOVE_RM_POST, 3'd1,
                     "MOVE.RM.POST field-one upper-bound decode");
        check_decode(16'h9400, TMS20_OP_MOVE_MR_POST, 3'd1,
                     "MOVE.MR.POST field-zero lower-bound decode");
        check_decode(16'h97FF, TMS20_OP_MOVE_MR_POST, 3'd1,
                     "MOVE.MR.POST field-one upper-bound decode");
        check_decode(16'h9800, TMS20_OP_MOVE_MM_POST, 3'd1,
                     "MOVE.MM.POST field-zero lower-bound decode");
        check_decode(16'h9BFF, TMS20_OP_MOVE_MM_POST, 3'd1,
                     "MOVE.MM.POST field-one upper-bound decode");
        check_decode(16'hA000, TMS20_OP_MOVE_RM_PRE, 3'd1,
                     "MOVE.RM.PRE field-zero lower-bound decode");
        check_decode(16'hA3FF, TMS20_OP_MOVE_RM_PRE, 3'd1,
                     "MOVE.RM.PRE field-one upper-bound decode");
        check_decode(16'hA400, TMS20_OP_MOVE_MR_PRE, 3'd1,
                     "MOVE.MR.PRE field-zero lower-bound decode");
        check_decode(16'hA7FF, TMS20_OP_MOVE_MR_PRE, 3'd1,
                     "MOVE.MR.PRE field-one upper-bound decode");
        check_decode(16'hA800, TMS20_OP_MOVE_MM_PRE, 3'd1,
                     "MOVE.MM.PRE field-zero lower-bound decode");
        check_decode(16'hABFF, TMS20_OP_MOVE_MM_PRE, 3'd1,
                     "MOVE.MM.PRE field-one upper-bound decode");
        check_decode(16'hB000, TMS20_OP_MOVE_RM_OFFSET, 3'd2,
                     "MOVE.RM.OFFSET field-zero lower-bound decode");
        check_decode(16'hB3FF, TMS20_OP_MOVE_RM_OFFSET, 3'd2,
                     "MOVE.RM.OFFSET field-one upper-bound decode");
        check_decode(16'hB400, TMS20_OP_MOVE_MR_OFFSET, 3'd2,
                     "MOVE.MR.OFFSET field-zero lower-bound decode");
        check_decode(16'hB7FF, TMS20_OP_MOVE_MR_OFFSET, 3'd2,
                     "MOVE.MR.OFFSET field-one upper-bound decode");
        check_decode(16'hB800, TMS20_OP_MOVE_MM_OFFSET, 3'd3,
                     "MOVE.MM.OFFSET field-zero lower-bound decode");
        check_decode(16'hBBFF, TMS20_OP_MOVE_MM_OFFSET, 3'd3,
                     "MOVE.MM.OFFSET field-one upper-bound decode");
        check_decode(16'hD000, TMS20_OP_MOVE_MM_SOFF_POST, 3'd2,
                     "MOVE.MM.SOFF_POST field-zero lower-bound decode");
        check_decode(16'hD3FF, TMS20_OP_MOVE_MM_SOFF_POST, 3'd2,
                     "MOVE.MM.SOFF_POST field-one upper-bound decode");
        decode_word = 16'h8C00;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
            "unextracted 8C00 opcode family remains open");
        check_decode(16'h1C00, TMS20_OP_BTST_K, 3'd1,
                     "BTST.K lower-bound decode");
        check_decode(16'h1FFF, TMS20_OP_BTST_K, 3'd1,
                     "BTST.K upper-bound decode");
        check_decode(16'h0500, TMS20_OP_SEXT, 3'd1,
                     "SEXT field-0 A0 decode");
        check_decode(16'h051F, TMS20_OP_SEXT, 3'd1,
                     "SEXT field-0 B15 decode");
        check_decode(16'h0700, TMS20_OP_SEXT, 3'd1,
                     "SEXT field-1 A0 decode");
        check_decode(16'h071F, TMS20_OP_SEXT, 3'd1,
                     "SEXT field-1 B15 decode");
        check_decode(16'h0520, TMS20_OP_ZEXT, 3'd1,
                     "ZEXT field-0 A0 decode");
        check_decode(16'h053F, TMS20_OP_ZEXT, 3'd1,
                     "ZEXT field-0 B15 decode");
        check_decode(16'h0720, TMS20_OP_ZEXT, 3'd1,
                     "ZEXT field-1 A0 decode");
        check_decode(16'h073F, TMS20_OP_ZEXT, 3'd1,
                     "ZEXT field-1 B15 decode");
        check_decode(16'h0540, TMS20_OP_SETF, 3'd1,
                     "SETF field-0 zero-extension size-32 decode");
        check_decode(16'h057F, TMS20_OP_SETF, 3'd1,
                     "SETF field-0 sign-extension size-31 decode");
        check_decode(16'h0740, TMS20_OP_SETF, 3'd1,
                     "SETF field-1 zero-extension size-32 decode");
        check_decode(16'h077F, TMS20_OP_SETF, 3'd1,
                     "SETF field-1 sign-extension size-31 decode");
        check_decode(16'h4A00, TMS20_OP_BTST_R, 3'd1,
                     "BTST.R lower-bound decode");
        check_decode(16'h4BFF, TMS20_OP_BTST_R, 3'd1,
                     "BTST.R upper-bound decode");
        check_decode(16'h23FF, TMS20_OP_SLA_K, 3'd1,
                     "SLA.K masked decode");
        check_decode(16'h61FF, TMS20_OP_SLA_R, 3'd1,
                     "SLA.R masked decode");
        check_decode(16'h27FF, TMS20_OP_SLL_K, 3'd1,
                     "SLL.K masked decode");
        check_decode(16'h63FF, TMS20_OP_SLL_R, 3'd1,
                     "SLL.R masked decode");
        check_decode(16'h2BFF, TMS20_OP_SRA_K, 3'd1,
                     "SRA.K masked decode");
        check_decode(16'h65FF, TMS20_OP_SRA_R, 3'd1,
                     "SRA.R masked decode");
        check_decode(16'h2FFF, TMS20_OP_SRL_K, 3'd1,
                     "SRL.K masked decode");
        check_decode(16'h67FF, TMS20_OP_SRL_R, 3'd1,
                     "SRL.R masked decode");
        check_decode(16'hEC00, TMS20_OP_MOVX, 3'd1,
                     "MOVX lower-bound decode");
        check_decode(16'hEDFF, TMS20_OP_MOVX, 3'd1,
                     "MOVX upper-bound decode");
        check_decode(16'hEE00, TMS20_OP_MOVY, 3'd1,
                     "MOVY lower-bound decode");
        check_decode(16'hEFFF, TMS20_OP_MOVY, 3'd1,
                     "MOVY upper-bound decode");
        check_decode(16'h41FF, TMS20_OP_ADD, 3'd1, "ADD masked decode");
        check_decode(16'h43FF, TMS20_OP_ADDC, 3'd1,
                     "ADDC masked decode");
        check_decode(16'hE000, TMS20_OP_ADDXY, 3'd1,
                     "ADDXY base decode");
        check_decode(16'hE1FF, TMS20_OP_ADDXY, 3'd1,
                     "ADDXY masked decode");
        check_decode(16'h45FF, TMS20_OP_SUB, 3'd1, "SUB masked decode");
        check_decode(16'h47FF, TMS20_OP_SUBB, 3'd1,
                     "SUBB masked decode");
        check_decode(16'hE200, TMS20_OP_SUBXY, 3'd1,
                     "SUBXY base decode");
        check_decode(16'hE3FF, TMS20_OP_SUBXY, 3'd1,
                     "SUBXY masked decode");
        check_decode(16'h49FF, TMS20_OP_CMP, 3'd1, "CMP masked decode");
        check_decode(16'hE400, TMS20_OP_CMPXY, 3'd1,
                     "CMPXY base decode");
        check_decode(16'hE5FF, TMS20_OP_CMPXY, 3'd1,
                     "CMPXY masked decode");
        check_decode(16'hE600, TMS20_OP_CPW, 3'd1,
                     "CPW lower-bound decode");
        check_decode(16'hE7FF, TMS20_OP_CPW, 3'd1,
                     "CPW upper-bound decode");
        check_decode(16'h0A60, TMS20_OP_CVMXYL, 3'd1,
                     "CVMXYL lower-bound decode");
        check_decode(16'h0A7F, TMS20_OP_CVMXYL, 3'd1,
                     "CVMXYL upper-bound decode");
        check_decode(16'h0A80, TMS20_OP_CVDXYL, 3'd1,
                     "CVDXYL lower-bound decode");
        check_decode(16'h0A9F, TMS20_OP_CVDXYL, 3'd1,
                     "CVDXYL upper-bound decode");
        check_decode(16'hE800, TMS20_OP_CVXYL, 3'd1,
                     "CVXYL lower-bound decode");
        check_decode(16'hE9FF, TMS20_OP_CVXYL, 3'd1,
                     "CVXYL upper-bound decode");
        check_decode(16'h5800, TMS20_OP_DIVS, 3'd1,
                     "DIVS lower-bound decode");
        check_decode(16'h59FF, TMS20_OP_DIVS, 3'd1,
                     "DIVS upper-bound decode");
        check_decode(16'h5A00, TMS20_OP_DIVU, 3'd1,
                     "DIVU lower-bound decode");
        check_decode(16'h5BFF, TMS20_OP_DIVU, 3'd1,
                     "DIVU upper-bound decode");
        check_decode(16'h5C00, TMS20_OP_MPYS, 3'd1,
                     "MPYS lower-bound decode");
        check_decode(16'h5DFF, TMS20_OP_MPYS, 3'd1,
                     "MPYS upper-bound decode");
        check_decode(16'h5E00, TMS20_OP_MPYU, 3'd1,
                     "MPYU lower-bound decode");
        check_decode(16'h5FFF, TMS20_OP_MPYU, 3'd1,
                     "MPYU upper-bound decode");
        check_decode(16'h7E00, TMS20_OP_SWAPF, 3'd1,
                     "SWAPF lower-bound decode");
        check_decode(16'h7FFF, TMS20_OP_SWAPF, 3'd1,
                     "SWAPF upper-bound decode");
        check_decode(16'h0980, TMS20_OP_MMTM, 3'd2,
                     "MMTM lower-bound decode");
        check_decode(16'h099F, TMS20_OP_MMTM, 3'd2,
                     "MMTM upper-bound decode");
        check_decode(16'h09A0, TMS20_OP_MMFM, 3'd2,
                     "MMFM lower-bound decode");
        check_decode(16'h09BF, TMS20_OP_MMFM, 3'd2,
                     "MMFM upper-bound decode");
        check_decode(16'h6C00, TMS20_OP_MODS, 3'd1,
                     "MODS lower-bound decode");
        check_decode(16'h6DFF, TMS20_OP_MODS, 3'd1,
                     "MODS upper-bound decode");
        check_decode(16'h6E00, TMS20_OP_MODU, 3'd1,
                     "MODU lower-bound decode");
        check_decode(16'h6FFF, TMS20_OP_MODU, 3'd1,
                     "MODU upper-bound decode");
        check_decode(16'hEA00, TMS20_OP_CVSXYL, 3'd1,
                     "CVSXYL lower-bound decode");
        check_decode(16'hEBFF, TMS20_OP_CVSXYL, 3'd1,
                     "CVSXYL upper-bound decode");
        check_decode(16'h51FF, TMS20_OP_AND, 3'd1, "AND masked decode");
        check_decode(16'h53FF, TMS20_OP_ANDN, 3'd1, "ANDN masked decode");
        check_decode(16'h55FF, TMS20_OP_OR, 3'd1, "OR masked decode");
        check_decode(16'h57FF, TMS20_OP_XOR, 3'd1, "XOR masked decode");
        check_decode(16'h0B40, TMS20_OP_CMPI_W, 3'd2,
                     "CMPI.W exact decode");
        check_decode(16'h0B7F, TMS20_OP_CMPI_L, 3'd3,
                     "CMPI.L masked decode");
        check_decode(16'h0B9F, TMS20_OP_ANDNI, 3'd3,
                     "ANDNI masked three-word decode");
        check_decode(16'h0BBF, TMS20_OP_ORI, 3'd3,
                     "ORI masked three-word decode");
        check_decode(16'h0BDF, TMS20_OP_XORI, 3'd3,
                     "XORI masked three-word decode");
        check_decode(16'h0273, TMS20_OP_SETCDP, 3'd1,
                     "SETCDP exact decode");
        check_decode(16'h02FB, TMS20_OP_SETCMP, 3'd1,
                     "SETCMP exact decode");
        check_decode(16'h0251, TMS20_OP_SETCSP, 3'd1,
                     "SETCSP exact decode");
        check_decode(16'h080F, TMS20_OP_TRAPL, 3'd2,
                     "TRAPL consumes extension word");
        check_decode(16'h0A00, TMS20_OP_VLCOL, 3'd1, "VLCOL exact decode");
        check_decode(16'h00F3, TMS20_OP_BLMOVE, 3'd1,
                     "BLMOVE masked decode");
        check_decode(16'h0C1E, TMS20_OP_ADDXYI, 3'd3,
                     "ADDXYI masked decode");
        check_decode(16'h029E, TMS20_OP_RPIX, 3'd1, "RPIX masked decode");
        check_decode(16'h37FF, TMS20_OP_CMPK, 3'd1, "CMPK masked decode");
        check_decode(16'h02BF, TMS20_OP_EXGPS, 3'd1,
                     "EXGPS masked decode");
        check_decode(16'h02DF, TMS20_OP_GETPS, 3'd1,
                     "GETPS masked decode");
        check_decode(16'h6A00, TMS20_OP_LMO, 3'd1,
                     "LMO lower-bound decode");
        check_decode(16'h6BFF, TMS20_OP_LMO, 3'd1,
                     "LMO upper-bound decode");
        check_decode(16'h7BFF, TMS20_OP_RMO, 3'd1, "RMO masked decode");

        decode_word = 16'h080E;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
               "nearby unclassified word must not alias TRAPL");
        decode_word = 16'hC001;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
               "unextracted short JR offset cannot alias JR.L");
        decode_word = 16'hC081;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
               "unextracted short JR offset cannot alias JACC");

        add_destination = 32'h0001_0001;
        add_immediate = 32'hFFFF_FFFF;
        #1;
        check_condition(add_result == 32'h0000_0000,
               "ADDXYI independent half addition");
        check_condition({add_n, add_c, add_z, add_v} == 4'b1010,
               "ADDXYI TI-defined NCZV");

        add_destination = 32'h0002_0001;
        add_immediate = 32'h7FFF_7FFF;
        #1;
        check_condition(add_result == 32'h8001_8000, "ADDXYI sign cases");
        check_condition({add_n, add_c, add_z, add_v} == 4'b0101,
               "ADDXYI sign-derived flags");

        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_0000, 32'h0000_0000,
            32'h0000_0000, 4'b1010, "ADDXY primary row 0"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_0000, 32'h0000_0001,
            32'h0000_0001, 4'b0010, "ADDXY primary row 1"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_0000, 32'h0001_0000,
            32'h0001_0000, 4'b1000, "ADDXY primary row 2"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_0000, 32'h0001_0001,
            32'h0001_0001, 4'b0000, "ADDXY primary row 3"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_FFFF, 32'h0000_0001,
            32'h0000_0000, 4'b1010, "ADDXY primary row 4"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_FFFF, 32'h0001_0001,
            32'h0001_0000, 4'b1000, "ADDXY primary row 5"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_FFFF, 32'h0000_0002,
            32'h0000_0001, 4'b0010, "ADDXY primary row 6"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'h0000_FFFF, 32'h0001_0002,
            32'h0001_0001, 4'b0000, "ADDXY primary row 7"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_0000, 32'h0001_0000,
            32'h0000_0000, 4'b1010, "ADDXY primary row 8"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_0000, 32'h0001_0001,
            32'h0000_0001, 4'b0010, "ADDXY primary row 9"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_0000, 32'h0002_0000,
            32'h0001_0000, 4'b1000, "ADDXY primary row 10"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_0000, 32'h0002_0001,
            32'h0001_0001, 4'b0000, "ADDXY primary row 11"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_FFFF, 32'h0001_0001,
            32'h0000_0000, 4'b1010, "ADDXY primary row 12"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_FFFF, 32'h0001_0002,
            32'h0000_0001, 4'b0010, "ADDXY primary row 13"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_FFFF, 32'h0002_0001,
            32'h0001_0000, 4'b1000, "ADDXY primary row 14"
        );
        check_xy_arithmetic(
            TMS34020_XY_ADD, 32'hFFFF_FFFF, 32'h0002_0002,
            32'h0001_0001, 4'b0000, "ADDXY primary row 15"
        );

        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0001_0001, 32'h0009_0009,
            32'h0008_0008, 4'b0000, "SUBXY primary row 0"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0009_0001, 32'h0009_0009,
            32'h0000_0008, 4'b0010, "SUBXY primary row 1"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0001_0009, 32'h0009_0009,
            32'h0008_0000, 4'b1000, "SUBXY primary row 2"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0009_0009, 32'h0009_0009,
            32'h0000_0000, 4'b1010, "SUBXY primary row 3"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0000_0010, 32'h0009_0009,
            32'h0009_FFF9, 4'b0001, "SUBXY primary row 4"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0009_0010, 32'h0009_0009,
            32'h0000_FFF9, 4'b0011, "SUBXY primary row 5"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0010_0000, 32'h0009_0009,
            32'hFFF9_0009, 4'b0100, "SUBXY primary row 6"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0010_0009, 32'h0009_0009,
            32'hFFF9_0000, 4'b1100, "SUBXY primary row 7"
        );
        check_xy_arithmetic(
            TMS34020_XY_SUB, 32'h0010_0010, 32'h0009_0009,
            32'hFFF9_FFF9, 4'b0101, "SUBXY primary row 8"
        );

        check_cmpxy(
            32'h0009_0009, 32'h0001_0001,
            4'b0101, "CMPXY primary row 0"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0009_0001,
            4'b0011, "CMPXY primary row 1"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0001_0009,
            4'b1100, "CMPXY primary row 2"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0009_0009,
            4'b1010, "CMPXY primary row 3"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0000_0010,
            4'b0100, "CMPXY primary row 4"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0009_0010,
            4'b0010, "CMPXY primary row 5"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0010_0000,
            4'b0001, "CMPXY primary row 6"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0010_0009,
            4'b1000, "CMPXY primary row 7"
        );
        check_cmpxy(
            32'h0009_0009, 32'h0010_0010,
            4'b0000, "CMPXY primary row 8"
        );
        check_cmpxy(
            32'hFFFF_0000, 32'h0000_FFFF,
            4'b0001, "CMPXY result signs are not borrow flags"
        );

        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'hFFFF_FFFF, 32'h0000_0001, 1'b0,
            32'h0000_0000, 4'b0110, 1'b1,
            "ADD carry and zero"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'h7FFF_FFFF, 32'h0000_0001, 1'b0,
            32'h8000_0000, 4'b1001, 1'b1,
            "ADD signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'hFFFF_FFFF, 32'h8000_0000, 1'b0,
            32'h7FFF_FFFF, 4'b0101, 1'b1,
            "ADD carry with signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADDC, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            1'b1, 32'hFFFF_FFFF, 4'b1100, 1'b1,
            "ADDC carry input"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADDC, 32'h7FFF_FFFF, 32'h0000_0001,
            1'b1, 32'h8000_0001, 4'b1001, 1'b1,
            "ADDC carry across sign"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'h7FFF_FFF2, 32'h7FFF_FFF1, 1'b0,
            32'hFFFF_FFFF, 4'b1100, 1'b1,
            "SUB borrow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'hFFFF_FFFF, 32'h7FFF_FFFF, 1'b0,
            32'h8000_0000, 4'b1101, 1'b1,
            "SUB signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'h0000_0001, 32'h8000_0000, 1'b0,
            32'h7FFF_FFFF, 4'b0001, 1'b1,
            "SUB positive overflow result"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0001, 32'h0000_0002,
            1'b1, 32'h0000_0000, 4'b0010, 1'b1,
            "SUBB borrow input to zero"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0002, 32'h0000_0002,
            1'b1, 32'hFFFF_FFFF, 4'b1100, 1'b1,
            "SUBB borrow input underflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0001, 32'h8000_0001,
            1'b1, 32'h7FFF_FFFF, 4'b0001, 1'b1,
            "SUBB signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_CMP, 32'h0000_0001, 32'h0000_0001, 1'b1,
            32'h0000_0000, 4'b0010, 1'b0,
            "CMP nondestructive result indication"
        );

        check_logical(
            TMS34020_LOGICAL_AND,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'd0, 1'b1,
            "AND logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_ANDN,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'h5555_5555, 1'b0,
            "ANDN logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_OR,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'hFFFF_FFFF, 1'b0,
            "OR logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_XOR,
            32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'd0, 1'b1,
            "XOR logical leaf"
        );

        add_destination = 32'd0;
        compare_constant = 5'd0;
        #1;
        check_condition(compare_result == 32'hFFFF_FFE0,
                        "CMPK encoded zero means 32");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b1100,
                        "CMPK borrow flags");

        add_destination = 32'h8000_0000;
        compare_constant = 5'd1;
        #1;
        check_condition(compare_result == 32'h7FFF_FFFF,
                        "CMPK subtraction result");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b0001,
                        "CMPK signed overflow");

        lmo_source = 32'd0;
        #1;
        check_condition(lmo_z && lmo_result == 32'd0,
                        "LMO zero source");
        lmo_source = 32'h0000_0001;
        #1;
        check_condition(!lmo_z && lmo_result == 32'd31,
                        "LMO bit 0");
        lmo_source = 32'h0000_0010;
        #1;
        check_condition(!lmo_z && lmo_result == 32'd27,
                        "LMO bit 4");
        lmo_source = 32'h0800_0000;
        #1;
        check_condition(!lmo_z && lmo_result == 32'd4,
                        "LMO bit 27");
        lmo_source = 32'h8000_0000;
        #1;
        check_condition(!lmo_z && lmo_result == 32'd0,
                        "LMO bit 31");

        rmo_source = 32'd0;
        #1;
        check_condition(rmo_z && rmo_result == 32'd0, "RMO zero source");
        rmo_source = 32'h8000_0000;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd31, "RMO bit 31");
        rmo_source = 32'h0800_0010;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd4, "RMO rightmost bit");

        check_unary(TMS34020_UNARY_ABS, 32'h7FFF_FFFF, 1'b0,
                    32'h7FFF_FFFF, 4'b1000, 4'b1011,
                    "ABS maximum positive");
        check_unary(TMS34020_UNARY_ABS, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0000, 4'b1011,
                    "ABS negative one");
        check_unary(TMS34020_UNARY_ABS, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1001, 4'b1011,
                    "ABS minimum negative overflow");
        check_unary(TMS34020_UNARY_ABS, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0000, 4'b1011,
                    "ABS minimum negative plus one");
        check_unary(TMS34020_UNARY_ABS, 32'h0000_0001, 1'b0,
                    32'h0000_0001, 4'b1000, 4'b1011,
                    "ABS positive one");
        check_unary(TMS34020_UNARY_ABS, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1011,
                    "ABS zero");
        check_unary(TMS34020_UNARY_ABS, 32'hFFFA_0011, 1'b0,
                    32'h0005_FFEF, 4'b0000, 4'b1011,
                    "ABS TI nontrivial negative example");

        check_unary(TMS34020_UNARY_NEG, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1111,
                    "NEG zero");
        check_unary(TMS34020_UNARY_NEG, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAB, 4'b1100, 4'b1111,
                    "NEG alternating bits");
        check_unary(TMS34020_UNARY_NEG, 32'h7FFF_FFFF, 1'b0,
                    32'h8000_0001, 4'b1100, 4'b1111,
                    "NEG maximum positive");
        check_unary(TMS34020_UNARY_NEG, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1101, 4'b1111,
                    "NEG minimum negative overflow");
        check_unary(TMS34020_UNARY_NEG, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEG minimum negative plus one");
        check_unary(TMS34020_UNARY_NEG, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0100, 4'b1111,
                    "NEG negative one");

        check_unary(TMS34020_UNARY_NEGB, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1111,
                    "NEGB zero without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h0000_0000, 1'b1,
                    32'hFFFF_FFFF, 4'b1100, 4'b1111,
                    "NEGB zero with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAB, 4'b1100, 4'b1111,
                    "NEGB alternating without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h5555_5555, 1'b1,
                    32'hAAAA_AAAA, 4'b1100, 4'b1111,
                    "NEGB alternating with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h7FFF_FFFF, 1'b0,
                    32'h8000_0001, 4'b1100, 4'b1111,
                    "NEGB maximum positive without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h7FFF_FFFF, 1'b1,
                    32'h8000_0000, 4'b1100, 4'b1111,
                    "NEGB maximum positive with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1101, 4'b1111,
                    "NEGB minimum negative without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0000, 1'b1,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEGB minimum negative with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEGB negative near minimum without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0001, 1'b1,
                    32'h7FFF_FFFE, 4'b0100, 4'b1111,
                    "NEGB negative near minimum with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0100, 4'b1111,
                    "NEGB negative one without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'hFFFF_FFFF, 1'b1,
                    32'h0000_0000, 4'b0110, 4'b1111,
                    "NEGB negative one with borrow");

        check_unary(TMS34020_UNARY_NOT, 32'h0000_0000, 1'b0,
                    32'hFFFF_FFFF, 4'b0000, 4'b0010,
                    "NOT zero");
        check_unary(TMS34020_UNARY_NOT, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAA, 4'b0000, 4'b0010,
                    "NOT alternating bits");
        check_unary(TMS34020_UNARY_NOT, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b0010,
                    "NOT all ones");
        check_unary(TMS34020_UNARY_NOT, 32'h8000_0000, 1'b0,
                    32'h7FFF_FFFF, 4'b0000, 4'b0010,
                    "NOT minimum negative");

        pixel_size_register = 16'h0001;
        pixel_size_value = 16'd8;
        pixel_size_exchange = 1'b0;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            !pixel_size_write_enable &&
            pixel_size_write_data == 16'd0,
            "GETPS data path"
        );
        pixel_size_exchange = 1'b1;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            pixel_size_write_enable &&
            pixel_size_write_data == 16'd1,
            "EXGPS exchange data path"
        );

        pixel = 32'h89AB_CDEF;
        check_pixel_replicate(6'd1, 32'hFFFF_FFFF, 4'd8, "RPIX size 1");
        check_pixel_replicate(6'd2, 32'hFFFF_FFFF, 4'd7, "RPIX size 2");
        check_pixel_replicate(6'd4, 32'hFFFF_FFFF, 4'd6, "RPIX size 4");
        check_pixel_replicate(6'd8, 32'hEFEF_EFEF, 4'd5, "RPIX size 8");
        check_pixel_replicate(6'd16, 32'hCDEF_CDEF, 4'd4, "RPIX size 16");
        check_pixel_replicate(6'd32, 32'h89AB_CDEF, 4'd2, "RPIX size 32");

        pixel_size = 6'd3;
        #1;
        check_condition(!pixel_valid && pixel_states == 4'd0,
               "RPIX rejects reserved size");

        write_register(1'b0, 4'd2, 32'h1234_5678);
        register_read0_file = 1'b0;
        register_read0_index = 4'd2;
        #1;
        check_condition(register_read0_data == 32'h1234_5678, "A2 write/read");

        write_register(1'b1, 4'd2, 32'hCAFE_BABE);
        register_read1_file = 1'b1;
        register_read1_index = 4'd2;
        #1;
        check_condition(register_read1_data == 32'hCAFE_BABE, "B2 write/read");
        check_condition(register_read0_data == 32'h1234_5678,
               "A/B physical files remain distinct");

        write_register(1'b0, 4'd15, 32'h1020_3040);
        register_read0_file = 1'b0;
        register_read0_index = 4'd15;
        register_read1_file = 1'b1;
        register_read1_index = 4'd15;
        #1;
        check_condition(register_read0_data == 32'h1020_3040,
               "A15 reads shared SP");
        check_condition(register_read1_data == 32'h1020_3040,
               "B15 reads shared SP");
        check_condition(sp == 32'h1020_3040, "SP output");

        $display("PASS: tms34020 verified leaf RTL");
        $finish;
    end

endmodule

`default_nettype wire
