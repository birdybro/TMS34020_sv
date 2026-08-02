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
    logic [31:0] linit_decision_variable;
    logic [31:0] linit_dimensions;
    logic [31:0] linit_count;
    logic [31:0] linit_diagonal_increment;
    logic [31:0] linit_dominant_increment;
    logic [3:0] linit_nczv;
    logic [3:0] linit_visible_states;
    logic clip_geometry_valid;
    logic clip_intersection;
    logic [31:0] clip_adjusted_origin;
    logic [31:0] clip_adjusted_dimensions;
    logic clip_z;
    logic clip_v;
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
    logic [5:0] field_store_size;
    logic [2:0] field_store_alignment_case;
    logic [2:0] field_store_hidden_states;
    logic field_store_writes_word1;
    logic [31:0] field_store_word0;
    logic [31:0] field_store_word1;
    logic byte_store_mode_valid;
    logic [2:0] byte_store_destination_case;
    logic [2:0] byte_store_visible_states;
    logic [2:0] byte_store_hidden_states;
    logic [31:0] byte_store_word0;
    logic [31:0] byte_store_word1;
    logic byte_load_mode_valid;
    logic [2:0] byte_load_source_case;
    logic byte_load_reads_word1;
    logic [2:0] byte_load_visible_states;
    logic [31:0] byte_load_raw;
    logic [31:0] byte_load_result;
    logic byte_load_n;
    logic byte_load_z;
    logic byte_load_v;
    logic byte_move_mode_valid;
    logic [2:0] byte_move_source_case;
    logic [2:0] byte_move_destination_case;
    logic byte_move_reads_word1;
    logic byte_move_writes_word1;
    logic [2:0] byte_move_timing_column;
    logic byte_move_offset_case_e_override;
    logic [3:0] byte_move_visible_states;
    logic [2:0] byte_move_hidden_states;
    logic [31:0] byte_move_value;
    logic [31:0] byte_move_destination_word0;
    logic [31:0] byte_move_destination_word1;
    logic [5:0] field_address_size;
    logic [31:0] field_address_effective;
    logic [31:0] field_address_final;
    logic field_address_write;
    logic field_address_mode_valid;
    logic [5:0] field_pair_size;
    logic [31:0] field_pair_source_effective;
    logic [31:0] field_pair_destination_effective;
    logic [31:0] field_pair_source_final;
    logic [31:0] field_pair_destination_final;
    logic [5:0] field_pair_pre_size;
    logic [31:0] field_pair_pre_source_effective;
    logic [31:0] field_pair_pre_destination_effective;
    logic [31:0] field_pair_pre_source_updated;
    logic [31:0] field_pair_pre_destination_final;
    logic [31:0] field_offset_effective;
    logic [31:0] absolute_bit_address;
    logic [5:0] field_source_offset_post_size;
    logic [31:0] field_source_offset_post_source_effective;
    logic [31:0] field_source_offset_post_destination_effective;
    logic [31:0] field_source_offset_post_destination_final;
    logic [5:0] field_load_size;
    logic [2:0] field_load_alignment_case;
    logic field_load_reads_word1;
    logic [2:0] field_load_visible_states;
    logic [31:0] field_load_raw;
    logic [31:0] field_load_result;
    logic field_load_n;
    logic field_load_z;
    logic field_load_v;
    logic [5:0] field_move_size;
    logic [2:0] field_move_source_case;
    logic [2:0] field_move_destination_case;
    logic field_move_reads_word1;
    logic field_move_writes_word1;
    logic [2:0] field_move_visible_states;
    logic [2:0] field_move_hidden_states;
    logic [31:0] field_move_value;
    logic [31:0] field_move_destination_word0;
    logic [31:0] field_move_destination_word1;
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
    logic interrupt_return_force_bypass;
    logic interrupt_return_delay_recognition;
    logic [31:0] interrupt_return_post_st;
    logic coprocessor_command_supported;
    logic coprocessor_command_legal;
    logic coprocessor_command_long;
    logic [2:0] coprocessor_command_length;
    logic [2:0] coprocessor_command_id;
    logic [20:0] coprocessor_command_value;
    logic coprocessor_command_size_64;
    logic [31:0] coprocessor_command_lad;
    logic coprocessor_command_sf;
    logic [3:0] coprocessor_command_bus_status;
    logic coprocessor_command_parameter_index;
    logic coprocessor_command_word_select;
    logic [1:0] coprocessor_command_visible_states;
    logic coprocessor_command_hidden_state;
    logic coprocessor_write_supported;
    logic coprocessor_write_legal;
    logic coprocessor_write_two_registers;
    logic [2:0] coprocessor_write_length;
    logic coprocessor_write_source1_file;
    logic [3:0] coprocessor_write_source1_index;
    logic coprocessor_write_source2_file;
    logic [3:0] coprocessor_write_source2_index;
    logic [2:0] coprocessor_write_id;
    logic [20:0] coprocessor_write_command;
    logic coprocessor_write_size;
    logic [31:0] coprocessor_write_lad;
    logic [31:0] coprocessor_write_reissue_lad;
    logic coprocessor_write_sf;
    logic [3:0] coprocessor_write_bus_status;
    logic coprocessor_write_word_select;
    logic [31:0] coprocessor_write_data0;
    logic [31:0] coprocessor_write_data1;
    logic [1:0] coprocessor_write_count;
    logic coprocessor_write_reissue;
    logic [2:0] coprocessor_write_visible_states;
    logic coprocessor_write_hidden_state;
    logic coprocessor_read_supported;
    logic coprocessor_read_legal;
    logic coprocessor_read_status_only;
    logic [2:0] coprocessor_read_length;
    logic coprocessor_read_destination1_file;
    logic [3:0] coprocessor_read_destination1_index;
    logic coprocessor_read_destination2_file;
    logic [3:0] coprocessor_read_destination2_index;
    logic [2:0] coprocessor_read_id;
    logic [20:0] coprocessor_read_command;
    logic coprocessor_read_size;
    logic [31:0] coprocessor_read_lad;
    logic [31:0] coprocessor_read_reissue_lad;
    logic coprocessor_read_sf;
    logic [3:0] coprocessor_read_bus_status;
    logic coprocessor_read_word_select;
    logic [1:0] coprocessor_read_count;
    logic coprocessor_read_write0_enable;
    logic [31:0] coprocessor_read_write0_data;
    logic coprocessor_read_write1_enable;
    logic [31:0] coprocessor_read_write1_data;
    logic [3:0] coprocessor_read_status_mask;
    logic [3:0] coprocessor_read_status_value;
    logic coprocessor_read_reissue;
    logic [2:0] coprocessor_read_visible_states;
    logic coprocessor_memory_supported;
    logic coprocessor_memory_legal;
    logic coprocessor_memory_to_memory;
    logic coprocessor_memory_predecrement;
    logic coprocessor_memory_register_count_mode;
    logic [2:0] coprocessor_memory_length;
    logic coprocessor_memory_pointer_file;
    logic [3:0] coprocessor_memory_pointer_index;
    logic coprocessor_memory_count_file;
    logic [3:0] coprocessor_memory_count_index;
    logic [5:0] coprocessor_memory_transfer_count;
    logic [2:0] coprocessor_memory_id;
    logic [20:0] coprocessor_memory_command;
    logic coprocessor_memory_size;
    logic [31:0] coprocessor_memory_lad;
    logic coprocessor_memory_sf;
    logic [3:0] coprocessor_memory_bus_status;
    logic coprocessor_memory_word_select;
    logic [31:0] coprocessor_memory_first_address;
    logic [31:0] coprocessor_memory_final_pointer;
    logic coprocessor_memory_command_reissue;
    logic coprocessor_memory_turnaround_spacer;
    logic [5:0] coprocessor_memory_visible_states;

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
        linit_decision_variable ^
        linit_dimensions ^
        linit_count ^
        linit_diagonal_increment ^
        linit_dominant_increment ^
        {24'd0, linit_nczv, linit_visible_states} ^
        clip_adjusted_origin ^
        clip_adjusted_dimensions ^
        {28'd0, clip_geometry_valid, clip_intersection, clip_z, clip_v} ^
        xy_linear_result ^
        divider_quotient ^
        divider_remainder ^
        multiplier_product[63:32] ^
        multiplier_product[31:0] ^
        swap_memory_result ^
        swap_register_result ^
        field_store_word0 ^
        field_store_word1 ^
        {22'd0, byte_store_mode_valid, byte_store_destination_case,
         byte_store_visible_states, byte_store_hidden_states} ^
        byte_store_word0 ^
        byte_store_word1 ^
        {21'd0, byte_load_mode_valid, byte_load_source_case,
         byte_load_reads_word1, byte_load_visible_states,
         byte_load_n, byte_load_z, byte_load_v} ^
        byte_load_raw ^
        byte_load_result ^
        byte_move_value ^
        byte_move_destination_word0 ^
        byte_move_destination_word1 ^
        {12'd0, byte_move_mode_valid, byte_move_source_case,
         byte_move_destination_case, byte_move_reads_word1,
         byte_move_writes_word1, byte_move_timing_column,
         byte_move_offset_case_e_override, byte_move_visible_states,
         byte_move_hidden_states} ^
        field_address_effective ^
        field_address_final ^
        field_pair_source_effective ^
        field_pair_destination_effective ^
        field_pair_source_final ^
        field_pair_destination_final ^
        field_pair_pre_source_effective ^
        field_pair_pre_destination_effective ^
        field_pair_pre_source_updated ^
        field_pair_pre_destination_final ^
        field_offset_effective ^
        absolute_bit_address ^
        {26'd0, field_source_offset_post_size} ^
        field_source_offset_post_source_effective ^
        field_source_offset_post_destination_effective ^
        field_source_offset_post_destination_final ^
        field_load_raw ^
        field_load_result ^
        field_move_value ^
        field_move_destination_word0 ^
        field_move_destination_word1 ^
        {16'd0, multiple_normalized_mask} ^
        multiple_final_pointer ^
        {26'd0, xy_linear_pitch_class, xy_linear_visible_states} ^
        {20'd0, divider_busy, divider_done, divider_overflow,
         divider_n, divider_z, divider_v, divider_visible_states} ^
        {23'd0, multiplier_legal_field_size, multiplier_n,
         multiplier_z, multiplier_visible_states} ^
        {28'd0, swap_legal_in_word, swap_n, swap_z, swap_v} ^
        {19'd0, field_store_size, field_store_alignment_case,
         field_store_hidden_states, field_store_writes_word1} ^
        {24'd0, field_address_size, field_address_write,
         field_address_mode_valid} ^
        {26'd0, field_pair_size} ^
        {26'd0, field_pair_pre_size} ^
        {16'd0, field_load_size, field_load_alignment_case,
         field_load_reads_word1, field_load_visible_states,
         field_load_n, field_load_z, field_load_v} ^
        {12'd0, field_move_size, field_move_source_case,
         field_move_destination_case, field_move_reads_word1,
         field_move_writes_word1, field_move_visible_states,
         field_move_hidden_states} ^
        {17'd0, multiple_register_count, multiple_list_valid, multiple_n,
         multiple_visible_states, multiple_hidden_write_states} ^
        interrupt_return_final_sp ^
        interrupt_return_aligned_pc ^
        interrupt_return_post_st ^
        coprocessor_command_lad ^
        {11'd0, coprocessor_command_value} ^
        {12'd0, coprocessor_command_supported,
         coprocessor_command_legal, coprocessor_command_long,
         coprocessor_command_length, coprocessor_command_id,
         coprocessor_command_size_64, coprocessor_command_sf,
         coprocessor_command_bus_status,
         coprocessor_command_parameter_index,
         coprocessor_command_word_select,
         coprocessor_command_visible_states,
         coprocessor_command_hidden_state} ^
        coprocessor_write_lad ^
        coprocessor_write_reissue_lad ^
        coprocessor_write_data0 ^
        coprocessor_write_data1 ^
        {11'd0, coprocessor_write_command} ^
        {13'd0, coprocessor_write_supported, coprocessor_write_legal,
         coprocessor_write_two_registers, coprocessor_write_length,
         coprocessor_write_source1_file, coprocessor_write_source1_index,
         coprocessor_write_source2_file, coprocessor_write_source2_index,
         coprocessor_write_id} ^
        {18'd0, coprocessor_write_size,
         coprocessor_write_sf, coprocessor_write_bus_status,
         coprocessor_write_word_select, coprocessor_write_count,
         coprocessor_write_reissue, coprocessor_write_visible_states,
         coprocessor_write_hidden_state} ^
        coprocessor_read_lad ^
        coprocessor_read_reissue_lad ^
        coprocessor_read_write0_data ^
        coprocessor_read_write1_data ^
        {11'd0, coprocessor_read_command} ^
        {13'd0, coprocessor_read_supported, coprocessor_read_legal,
         coprocessor_read_status_only, coprocessor_read_length,
         coprocessor_read_destination1_file,
         coprocessor_read_destination1_index,
         coprocessor_read_destination2_file,
         coprocessor_read_destination2_index, coprocessor_read_id} ^
        {9'd0, coprocessor_read_size, coprocessor_read_sf,
         coprocessor_read_bus_status, coprocessor_read_word_select,
         coprocessor_read_count, coprocessor_read_write0_enable,
         coprocessor_read_write1_enable, coprocessor_read_status_mask,
         coprocessor_read_status_value, coprocessor_read_reissue,
         coprocessor_read_visible_states} ^
        coprocessor_memory_lad ^
        coprocessor_memory_first_address ^
        coprocessor_memory_final_pointer ^
        {11'd0, coprocessor_memory_command} ^
        {5'd0, coprocessor_memory_supported, coprocessor_memory_legal,
         coprocessor_memory_to_memory, coprocessor_memory_predecrement,
         coprocessor_memory_register_count_mode, coprocessor_memory_length,
         coprocessor_memory_pointer_file, coprocessor_memory_pointer_index,
         coprocessor_memory_count_file, coprocessor_memory_count_index,
         coprocessor_memory_transfer_count, coprocessor_memory_id} ^
        {17'd0, coprocessor_memory_size, coprocessor_memory_sf,
         coprocessor_memory_bus_status, coprocessor_memory_word_select,
         coprocessor_memory_command_reissue,
         coprocessor_memory_turnaround_spacer,
         coprocessor_memory_visible_states} ^
        {14'd0, interrupt_return_force_bypass,
         interrupt_return_delay_recognition,
         interrupt_return_saved_pc_misaligned,
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
        {24'd0, decoded_id};

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

    tms34020_line_initialize line_initialize (
        .start_point_i(operand_i),
        .end_point_i(immediate_i),
        .window_start_i({operand_i[31:16], immediate_i[15:0]}),
        .window_end_i({immediate_i[31:16], operand_i[15:0]}),
        .decision_variable_o(linit_decision_variable),
        .dimensions_o(linit_dimensions),
        .count_o(linit_count),
        .diagonal_increment_o(linit_diagonal_increment),
        .dominant_increment_o(linit_dominant_increment),
        .status_nczv_o(linit_nczv),
        .visible_states_o(linit_visible_states)
    );

    tms34020_array_clip array_clip (
        .origin_i(operand_i),
        .dimensions_i(immediate_i),
        .window_start_i({operand_i[31:16], immediate_i[15:0]}),
        .window_end_i({immediate_i[31:16], operand_i[15:0]}),
        .geometry_valid_o(clip_geometry_valid),
        .intersection_o(clip_intersection),
        .adjusted_origin_o(clip_adjusted_origin),
        .adjusted_dimensions_o(clip_adjusted_dimensions),
        .status_z_o(clip_z),
        .status_v_o(clip_v)
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

    tms34020_field_store field_store (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .bit_offset_i(operand_i[4:0]),
        .source_i(second_register_data),
        .word0_i(immediate_i),
        .word1_i(operand_i),
        .field_size_o(field_store_size),
        .alignment_case_o(field_store_alignment_case),
        .hidden_write_states_o(field_store_hidden_states),
        .writes_word1_o(field_store_writes_word1),
        .word0_o(field_store_word0),
        .word1_o(field_store_word1)
    );

    tms34020_byte_store byte_store (
        .address_mode_i(first_word_i[1:0]),
        .first_extension_aligned_i(first_word_i[2]),
        .destination_offset_i(operand_i[4:0]),
        .source_i(second_register_data),
        .destination_word0_i(immediate_i),
        .destination_word1_i(operand_i),
        .mode_valid_o(byte_store_mode_valid),
        .destination_case_o(byte_store_destination_case),
        .visible_states_o(byte_store_visible_states),
        .hidden_states_o(byte_store_hidden_states),
        .destination_word0_o(byte_store_word0),
        .destination_word1_o(byte_store_word1)
    );

    tms34020_byte_load byte_load (
        .address_mode_i(first_word_i[1:0]),
        .first_extension_aligned_i(first_word_i[2]),
        .source_offset_i(operand_i[4:0]),
        .source_word0_i(immediate_i),
        .source_word1_i(operand_i),
        .mode_valid_o(byte_load_mode_valid),
        .source_case_o(byte_load_source_case),
        .reads_word1_o(byte_load_reads_word1),
        .visible_states_o(byte_load_visible_states),
        .raw_byte_o(byte_load_raw),
        .result_o(byte_load_result),
        .n_o(byte_load_n),
        .z_o(byte_load_z),
        .v_o(byte_load_v)
    );

    tms34020_field_address_update field_address_update (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .pointer_i(second_register_data),
        .predecrement_i(first_word_i[13]),
        .postincrement_i(first_word_i[12]),
        .field_size_o(field_address_size),
        .effective_address_o(field_address_effective),
        .final_pointer_o(field_address_final),
        .pointer_write_o(field_address_write),
        .mode_valid_o(field_address_mode_valid)
    );

    tms34020_field_pair_postincrement field_pair_postincrement (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .source_pointer_i(second_register_data),
        .destination_pointer_i(operand_i),
        .same_register_i(first_word_i[8:5] == first_word_i[3:0]),
        .field_size_o(field_pair_size),
        .source_effective_address_o(field_pair_source_effective),
        .destination_effective_address_o(field_pair_destination_effective),
        .source_final_pointer_o(field_pair_source_final),
        .destination_final_pointer_o(field_pair_destination_final)
    );

    tms34020_field_pair_predecrement field_pair_predecrement (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .source_pointer_i(second_register_data),
        .destination_pointer_i(operand_i),
        .same_register_i(first_word_i[8:5] == first_word_i[3:0]),
        .field_size_o(field_pair_pre_size),
        .source_effective_address_o(field_pair_pre_source_effective),
        .destination_effective_address_o(
            field_pair_pre_destination_effective
        ),
        .source_updated_pointer_o(field_pair_pre_source_updated),
        .destination_final_pointer_o(field_pair_pre_destination_final)
    );

    tms34020_field_offset_address field_offset_address (
        .base_address_i(second_register_data),
        .signed_offset_i(operand_i[15:0]),
        .effective_address_o(field_offset_effective)
    );

    tms34020_absolute_address absolute_address (
        .address_low_i(operand_i[15:0]),
        .address_high_i(immediate_i[15:0]),
        .bit_address_o(absolute_bit_address)
    );

    tms34020_field_source_offset_postincrement field_source_offset_post (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .source_base_i(second_register_data),
        .signed_source_offset_i(immediate_i[15:0]),
        .destination_pointer_i(operand_i),
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

    tms34020_field_load field_load (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .sign_extend_i(
            first_word_i[9] ? status_value[11] : status_value[5]
        ),
        .bit_offset_i(operand_i[4:0]),
        .word0_i(immediate_i),
        .word1_i(operand_i),
        .field_size_o(field_load_size),
        .alignment_case_o(field_load_alignment_case),
        .reads_word1_o(field_load_reads_word1),
        .visible_states_o(field_load_visible_states),
        .raw_field_o(field_load_raw),
        .result_o(field_load_result),
        .n_o(field_load_n),
        .z_o(field_load_z),
        .v_o(field_load_v)
    );

    tms34020_field_move field_move (
        .field_size_encoded_i(
            first_word_i[9] ? status_value[10:6] : status_value[4:0]
        ),
        .source_bit_offset_i(operand_i[4:0]),
        .destination_bit_offset_i(second_register_data[4:0]),
        .source_word0_i(immediate_i),
        .source_word1_i(operand_i),
        .destination_word0_i(register_data),
        .destination_word1_i(second_register_data),
        .field_size_o(field_move_size),
        .source_alignment_case_o(field_move_source_case),
        .destination_alignment_case_o(field_move_destination_case),
        .reads_source_word1_o(field_move_reads_word1),
        .writes_destination_word1_o(field_move_writes_word1),
        .visible_states_o(field_move_visible_states),
        .hidden_write_states_o(field_move_hidden_states),
        .field_value_o(field_move_value),
        .destination_word0_o(field_move_destination_word0),
        .destination_word1_o(field_move_destination_word1)
    );

    tms34020_byte_move byte_move (
        .address_mode_i(first_word_i[1:0]),
        .first_extension_aligned_i(operand_i[5]),
        .source_bit_offset_i(operand_i[4:0]),
        .destination_bit_offset_i(second_register_data[4:0]),
        .source_word0_i(immediate_i),
        .source_word1_i(operand_i),
        .destination_word0_i(register_data),
        .destination_word1_i(second_register_data),
        .mode_valid_o(byte_move_mode_valid),
        .source_case_o(byte_move_source_case),
        .destination_case_o(byte_move_destination_case),
        .reads_source_word1_o(byte_move_reads_word1),
        .writes_destination_word1_o(byte_move_writes_word1),
        .timing_column_o(byte_move_timing_column),
        .offset_case_e_override_o(byte_move_offset_case_e_override),
        .visible_states_o(byte_move_visible_states),
        .hidden_write_states_o(byte_move_hidden_states),
        .byte_value_o(byte_move_value),
        .destination_word0_o(byte_move_destination_word0),
        .destination_word1_o(byte_move_destination_word1)
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
        .monitor_return_i(first_word_i == 16'h0860),
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

    tms34020_coprocessor_command coprocessor_command (
        .first_word_i(first_word_i),
        .extension_word1_i(immediate_i[15:0]),
        .extension_word2_i(operand_i[15:0]),
        .first_extension_aligned_i(operand_i[5]),
        .supported_o(coprocessor_command_supported),
        .legal_o(coprocessor_command_legal),
        .long_form_o(coprocessor_command_long),
        .instruction_length_words_o(coprocessor_command_length),
        .coprocessor_id_o(coprocessor_command_id),
        .command_o(coprocessor_command_value),
        .size_64_o(coprocessor_command_size_64),
        .lad_command_o(coprocessor_command_lad),
        .special_function_o(coprocessor_command_sf),
        .bus_status_o(coprocessor_command_bus_status),
        .parameter_index_o(coprocessor_command_parameter_index),
        .word_select_16_o(coprocessor_command_word_select),
        .visible_states_o(coprocessor_command_visible_states),
        .hidden_command_state_o(coprocessor_command_hidden_state)
    );

    tms34020_coprocessor_register_write coprocessor_register_write (
        .first_word_i(first_word_i),
        .extension_word1_i(immediate_i[15:0]),
        .extension_word2_i(operand_i[15:0]),
        .first_extension_aligned_i(operand_i[5]),
        .source1_value_i(operand_i),
        .source2_value_i(immediate_i),
        .supported_o(coprocessor_write_supported),
        .legal_o(coprocessor_write_legal),
        .two_registers_o(coprocessor_write_two_registers),
        .instruction_length_words_o(coprocessor_write_length),
        .source1_file_b_o(coprocessor_write_source1_file),
        .source1_index_o(coprocessor_write_source1_index),
        .source2_file_b_o(coprocessor_write_source2_file),
        .source2_index_o(coprocessor_write_source2_index),
        .coprocessor_id_o(coprocessor_write_id),
        .command_o(coprocessor_write_command),
        .size_64_o(coprocessor_write_size),
        .lad_command_o(coprocessor_write_lad),
        .lad_second_reissue_o(coprocessor_write_reissue_lad),
        .special_function_o(coprocessor_write_sf),
        .bus_status_o(coprocessor_write_bus_status),
        .word_select_16_o(coprocessor_write_word_select),
        .data_word0_o(coprocessor_write_data0),
        .data_word1_o(coprocessor_write_data1),
        .data_word_count_o(coprocessor_write_count),
        .second_reissue_if_no_page_o(coprocessor_write_reissue),
        .visible_states_o(coprocessor_write_visible_states),
        .hidden_transfer_state_o(coprocessor_write_hidden_state)
    );

    tms34020_coprocessor_register_read coprocessor_register_read (
        .first_word_i(first_word_i),
        .extension_word1_i(immediate_i[15:0]),
        .extension_word2_i(operand_i[15:0]),
        .first_extension_aligned_i(operand_i[5]),
        .inbound_word0_i(operand_i),
        .inbound_word1_i(immediate_i),
        .supported_o(coprocessor_read_supported),
        .legal_o(coprocessor_read_legal),
        .status_only_o(coprocessor_read_status_only),
        .instruction_length_words_o(coprocessor_read_length),
        .destination1_file_b_o(coprocessor_read_destination1_file),
        .destination1_index_o(coprocessor_read_destination1_index),
        .destination2_file_b_o(coprocessor_read_destination2_file),
        .destination2_index_o(coprocessor_read_destination2_index),
        .coprocessor_id_o(coprocessor_read_id),
        .command_o(coprocessor_read_command),
        .size_64_o(coprocessor_read_size),
        .lad_command_o(coprocessor_read_lad),
        .lad_second_reissue_o(coprocessor_read_reissue_lad),
        .special_function_o(coprocessor_read_sf),
        .bus_status_o(coprocessor_read_bus_status),
        .word_select_16_o(coprocessor_read_word_select),
        .data_word_count_o(coprocessor_read_count),
        .register_write0_enable_o(coprocessor_read_write0_enable),
        .register_write0_data_o(coprocessor_read_write0_data),
        .register_write1_enable_o(coprocessor_read_write1_enable),
        .register_write1_data_o(coprocessor_read_write1_data),
        .status_nczv_write_mask_o(coprocessor_read_status_mask),
        .status_nczv_value_o(coprocessor_read_status_value),
        .second_reissue_if_no_page_o(coprocessor_read_reissue),
        .visible_states_o(coprocessor_read_visible_states)
    );

    tms34020_coprocessor_memory_transfer coprocessor_memory_transfer (
        .first_word_i(first_word_i),
        .extension_word1_i(immediate_i[15:0]),
        .extension_word2_i(operand_i[15:0]),
        .first_extension_aligned_i(operand_i[5]),
        .pointer_value_i(operand_i),
        .register_count_value_i(immediate_i[4:0]),
        .supported_o(coprocessor_memory_supported),
        .legal_o(coprocessor_memory_legal),
        .coprocessor_to_memory_o(coprocessor_memory_to_memory),
        .predecrement_o(coprocessor_memory_predecrement),
        .register_count_mode_o(coprocessor_memory_register_count_mode),
        .instruction_length_words_o(coprocessor_memory_length),
        .pointer_file_b_o(coprocessor_memory_pointer_file),
        .pointer_index_o(coprocessor_memory_pointer_index),
        .count_file_b_o(coprocessor_memory_count_file),
        .count_index_o(coprocessor_memory_count_index),
        .transfer_count_o(coprocessor_memory_transfer_count),
        .coprocessor_id_o(coprocessor_memory_id),
        .command_o(coprocessor_memory_command),
        .size_64_o(coprocessor_memory_size),
        .lad_command_o(coprocessor_memory_lad),
        .special_function_o(coprocessor_memory_sf),
        .bus_status_o(coprocessor_memory_bus_status),
        .word_select_16_o(coprocessor_memory_word_select),
        .first_address_o(coprocessor_memory_first_address),
        .final_pointer_o(coprocessor_memory_final_pointer),
        .command_reissue_after_page_break_o(
            coprocessor_memory_command_reissue
        ),
        .write_turnaround_spacer_required_o(
            coprocessor_memory_turnaround_spacer
        ),
        .visible_states_o(coprocessor_memory_visible_states)
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
