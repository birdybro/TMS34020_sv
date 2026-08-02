`timescale 1ns/1ps
`default_nettype none

module tms34020_scalar_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [15:0] control_i,
    input  logic [31:0] stimulus_i,
    output logic [31:0] result_digest_o
);

    import tms34020_pkg::*;

    logic pc_load_ready;
    logic packet_valid;
    logic packet_supported;
    logic packet_blocked;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [31:0] packet_start_pc;
    logic commit_accepted;
    logic register_write_enable;
    logic register_write_file;
    logic [3:0] register_write_index;
    logic [31:0] register_write_data;
    logic status_write_enable;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;
    logic [31:0] status;
    logic [31:0] sp;
    logic memory_request_valid;
    logic [31:0] memory_request_bit_address;
    logic memory_request_width_32;
    logic memory_request_cache_fill;
    logic [1:0] memory_request_sequence_index;
    logic memory_response_ready;
    logic faulted;
    logic fetch_aborted;
    logic [31:0] cache_present_debug;
    logic [7:0] cache_lru_debug;
    logic [3:0] cache_tag_valid_debug;
    logic [15:0] folded_packet_words;

    always_comb begin
        folded_packet_words =
            packet_words[15:0] ^
            packet_words[31:16] ^
            packet_words[47:32] ^
            packet_words[63:48] ^
            packet_words[79:64];
        result_digest_o =
            packet_start_pc ^
            register_write_data ^
            status_write_data ^
            status_write_mask ^
            status ^
            sp ^
            memory_request_bit_address ^
            cache_present_debug ^
            {31'd0, ^control_i[15:9]} ^
            {28'd0, cache_tag_valid_debug} ^
            {24'd0, cache_lru_debug} ^
            {16'd0, folded_packet_words} ^
            {
                1'd0,
                pc_load_ready,
                packet_valid,
                packet_supported,
                packet_blocked,
                packet_opcode_id,
                packet_length_words,
                commit_accepted,
                register_write_enable,
                register_write_file,
                register_write_index,
                status_write_enable,
                memory_request_valid,
                memory_request_width_32,
                memory_request_cache_fill,
                memory_request_sequence_index,
                memory_response_ready,
                faulted,
                fetch_aborted
            };
    end

    tms34020_scalar_slice scalar_slice (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_load_valid_i(control_i[0]),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(stimulus_i),
        .cache_disable_i(control_i[1]),
        .cache_flush_i(control_i[2]),
        .packet_valid_o(packet_valid),
        .packet_supported_o(packet_supported),
        .packet_blocked_o(packet_blocked),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_start_pc_o(packet_start_pc),
        .commit_accepted_o(commit_accepted),
        .register_write_enable_o(register_write_enable),
        .register_write_file_o(register_write_file),
        .register_write_index_o(register_write_index),
        .register_write_data_o(register_write_data),
        .status_write_enable_o(status_write_enable),
        .status_write_data_o(status_write_data),
        .status_write_mask_o(status_write_mask),
        .status_o(status),
        .sp_o(sp),
        .memory_request_valid_o(memory_request_valid),
        .memory_request_ready_i(control_i[3]),
        .memory_request_bit_address_o(memory_request_bit_address),
        .memory_request_width_32_o(memory_request_width_32),
        .memory_request_cache_fill_o(memory_request_cache_fill),
        .memory_request_sequence_index_o(
            memory_request_sequence_index
        ),
        .memory_response_valid_i(control_i[4]),
        .memory_response_ready_o(memory_response_ready),
        .memory_response_data_i(stimulus_i),
        .memory_response_completion_i(
            tms34020_memory_completion_t'(control_i[6:5])
        ),
        .faulted_o(faulted),
        .fault_resume_i(control_i[7]),
        .fault_abort_i(control_i[8]),
        .fetch_aborted_o(fetch_aborted),
        .cache_present_debug_o(cache_present_debug),
        .cache_lru_debug_o(cache_lru_debug),
        .cache_tag_valid_debug_o(cache_tag_valid_debug)
    );

endmodule

`default_nettype wire
