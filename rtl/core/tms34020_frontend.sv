`timescale 1ns/1ps
`default_nettype none

module tms34020_frontend (
    input  logic        clk_i,
    input  logic        reset_i,

    input  logic        pc_load_valid_i,
    output logic        pc_load_ready_o,
    input  logic [31:0] pc_load_bit_address_i,

    input  logic        cache_disable_i,
    input  logic        cache_flush_i,

    output logic        packet_valid_o,
    input  logic        packet_ready_i,
    output logic        packet_decode_valid_o,
    output tms34020_pkg::tms34020_opcode_id_t packet_opcode_id_o,
    output logic [2:0]  packet_length_words_o,
    output logic [79:0] packet_words_o,
    output logic [9:0]  packet_cache_results_o,
    output logic [31:0] packet_start_pc_o,
    output logic [31:0] packet_sequential_next_pc_o,

    input  logic        completion_valid_i,
    output logic        completion_ready_o,
    input  logic        completion_redirect_i,
    input  logic [31:0] completion_redirect_bit_address_i,

    output logic        memory_request_valid_o,
    input  logic        memory_request_ready_i,
    output logic [31:0] memory_request_bit_address_o,
    output logic        memory_request_width_32_o,
    output logic        memory_request_cache_fill_o,
    output logic [1:0]  memory_request_sequence_index_o,

    input  logic        memory_response_valid_i,
    output logic        memory_response_ready_o,
    input  logic [31:0] memory_response_data_i,
    input  tms34020_pkg::tms34020_memory_completion_t
                       memory_response_completion_i,

    output logic        faulted_o,
    input  logic        fault_resume_i,
    input  logic        fault_abort_i,
    output logic        fetch_aborted_o,

    output logic [31:0] cache_present_debug_o,
    output logic [7:0]  cache_lru_debug_o,
    output logic [3:0]  cache_tag_valid_debug_o
);

    import tms34020_pkg::*;

    logic fetch_cache_request_valid;
    logic fetch_cache_request_ready;
    logic [31:0] fetch_cache_request_bit_address;
    logic fetch_cache_response_valid;
    logic fetch_cache_response_ready;
    logic [15:0] fetch_cache_response_word;
    tms34020_cache_result_t fetch_cache_response_result;
    logic cache_request_aborted;
    tms34020_cache_result_t packet_first_cache_result_unused;

    tms34020_instruction_fetch instruction_fetch (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_load_valid_i(pc_load_valid_i),
        .pc_load_ready_o(pc_load_ready_o),
        .pc_load_bit_address_i(pc_load_bit_address_i),
        .cache_request_valid_o(fetch_cache_request_valid),
        .cache_request_ready_i(fetch_cache_request_ready),
        .cache_request_bit_address_o(
            fetch_cache_request_bit_address
        ),
        .cache_response_valid_i(fetch_cache_response_valid),
        .cache_response_ready_o(fetch_cache_response_ready),
        .cache_response_word_i(fetch_cache_response_word),
        .cache_response_result_i(fetch_cache_response_result),
        .cache_request_aborted_i(cache_request_aborted),
        .packet_valid_o(packet_valid_o),
        .packet_ready_i(packet_ready_i),
        .packet_decode_valid_o(packet_decode_valid_o),
        .packet_opcode_id_o(packet_opcode_id_o),
        .packet_length_words_o(packet_length_words_o),
        .packet_words_o(packet_words_o),
        .packet_cache_results_o(packet_cache_results_o),
        .packet_start_pc_o(packet_start_pc_o),
        .packet_sequential_next_pc_o(
            packet_sequential_next_pc_o
        ),
        .packet_first_cache_result_o(
            packet_first_cache_result_unused
        ),
        .completion_valid_i(completion_valid_i),
        .completion_ready_o(completion_ready_o),
        .completion_redirect_i(completion_redirect_i),
        .completion_redirect_bit_address_i(
            completion_redirect_bit_address_i
        ),
        .fetch_aborted_o(fetch_aborted_o)
    );

    tms34020_icache instruction_cache (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .request_valid_i(fetch_cache_request_valid),
        .request_ready_o(fetch_cache_request_ready),
        .request_bit_address_i(fetch_cache_request_bit_address),
        .cache_disable_i(cache_disable_i),
        .cache_flush_i(cache_flush_i),
        .response_valid_o(fetch_cache_response_valid),
        .response_ready_i(fetch_cache_response_ready),
        .response_word_o(fetch_cache_response_word),
        .response_result_o(fetch_cache_response_result),
        .memory_request_valid_o(memory_request_valid_o),
        .memory_request_ready_i(memory_request_ready_i),
        .memory_request_bit_address_o(
            memory_request_bit_address_o
        ),
        .memory_request_width_32_o(memory_request_width_32_o),
        .memory_request_cache_fill_o(
            memory_request_cache_fill_o
        ),
        .memory_request_sequence_index_o(
            memory_request_sequence_index_o
        ),
        .memory_response_valid_i(memory_response_valid_i),
        .memory_response_ready_o(memory_response_ready_o),
        .memory_response_data_i(memory_response_data_i),
        .memory_response_completion_i(
            memory_response_completion_i
        ),
        .faulted_o(faulted_o),
        .fault_resume_i(fault_resume_i),
        .fault_abort_i(fault_abort_i),
        .request_aborted_o(cache_request_aborted),
        .present_debug_o(cache_present_debug_o),
        .lru_debug_o(cache_lru_debug_o),
        .tag_valid_debug_o(cache_tag_valid_debug_o)
    );

endmodule

`default_nettype wire
