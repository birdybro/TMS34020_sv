`timescale 1ns/1ps
`default_nettype none

module tms34020_frontend_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [15:0] control_i,
    input  logic [31:0] stimulus_i,
    output logic [31:0] result_digest_o
);

    import tms34020_pkg::*;

    logic pc_load_ready;
    logic packet_valid;
    logic packet_decode_valid;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [9:0] packet_cache_results;
    logic [31:0] packet_start_pc;
    logic [31:0] packet_sequential_next_pc;
    logic completion_ready;
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
            packet_sequential_next_pc ^
            memory_request_bit_address ^
            cache_present_debug ^
            {31'd0, ^control_i[15:12]} ^
            {28'd0, cache_tag_valid_debug} ^
            {16'd0, folded_packet_words} ^
            {22'd0, packet_cache_results} ^
            {
                1'd0,
                pc_load_ready,
                packet_valid,
                packet_decode_valid,
                packet_opcode_id,
                packet_length_words,
                completion_ready,
                memory_request_valid,
                memory_request_width_32,
                memory_request_cache_fill,
                memory_request_sequence_index,
                memory_response_ready,
                faulted,
                fetch_aborted,
                cache_lru_debug
            };
    end

    tms34020_frontend frontend (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_load_valid_i(control_i[0]),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(stimulus_i),
        .cache_disable_i(control_i[1]),
        .cache_flush_i(control_i[2]),
        .packet_valid_o(packet_valid),
        .packet_ready_i(control_i[3]),
        .packet_decode_valid_o(packet_decode_valid),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_cache_results_o(packet_cache_results),
        .packet_start_pc_o(packet_start_pc),
        .packet_sequential_next_pc_o(packet_sequential_next_pc),
        .completion_valid_i(control_i[4]),
        .completion_ready_o(completion_ready),
        .completion_redirect_i(control_i[5]),
        .completion_redirect_bit_address_i(stimulus_i),
        .memory_request_valid_o(memory_request_valid),
        .memory_request_ready_i(control_i[6]),
        .memory_request_bit_address_o(memory_request_bit_address),
        .memory_request_width_32_o(memory_request_width_32),
        .memory_request_cache_fill_o(memory_request_cache_fill),
        .memory_request_sequence_index_o(
            memory_request_sequence_index
        ),
        .memory_response_valid_i(control_i[7]),
        .memory_response_ready_o(memory_response_ready),
        .memory_response_data_i(stimulus_i),
        .memory_response_completion_i(
            tms34020_memory_completion_t'(control_i[9:8])
        ),
        .faulted_o(faulted),
        .fault_resume_i(control_i[10]),
        .fault_abort_i(control_i[11]),
        .fetch_aborted_o(fetch_aborted),
        .cache_present_debug_o(cache_present_debug),
        .cache_lru_debug_o(cache_lru_debug),
        .cache_tag_valid_debug_o(cache_tag_valid_debug)
    );

endmodule

`default_nettype wire
