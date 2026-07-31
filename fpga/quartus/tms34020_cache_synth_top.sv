`timescale 1ns/1ps
`default_nettype none

module tms34020_cache_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic        request_valid_i,
    input  logic [31:0] request_bit_address_i,
    input  logic        cache_disable_i,
    input  logic        cache_flush_i,
    input  logic        response_ready_i,
    input  logic        memory_request_ready_i,
    input  logic        memory_response_valid_i,
    input  logic [31:0] memory_response_data_i,
    input  tms34020_pkg::tms34020_memory_completion_t
                        memory_response_completion_i,
    input  logic        fault_resume_i,
    input  logic        fault_abort_i,
    output logic [31:0] result_digest_o
);

    logic request_ready;
    logic response_valid;
    logic [15:0] response_word;
    tms34020_pkg::tms34020_cache_result_t response_result;
    logic memory_request_valid;
    logic [31:0] memory_request_bit_address;
    logic memory_request_width_32;
    logic memory_request_cache_fill;
    logic [1:0] memory_request_sequence_index;
    logic memory_response_ready;
    logic faulted;
    logic request_aborted;
    logic [31:0] present_debug;
    logic [7:0] lru_debug;
    logic [3:0] tag_valid_debug;

    assign result_digest_o =
        memory_request_bit_address ^
        present_debug ^
        {16'd0, response_word} ^
        {
            8'd0,
            request_ready,
            response_valid,
            response_result,
            memory_request_valid,
            memory_request_width_32,
            memory_request_cache_fill,
            memory_request_sequence_index,
            memory_response_ready,
            faulted,
            request_aborted,
            lru_debug,
            tag_valid_debug
        };

    tms34020_icache icache (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .request_valid_i(request_valid_i),
        .request_ready_o(request_ready),
        .request_bit_address_i(request_bit_address_i),
        .cache_disable_i(cache_disable_i),
        .cache_flush_i(cache_flush_i),
        .response_valid_o(response_valid),
        .response_ready_i(response_ready_i),
        .response_word_o(response_word),
        .response_result_o(response_result),
        .memory_request_valid_o(memory_request_valid),
        .memory_request_ready_i(memory_request_ready_i),
        .memory_request_bit_address_o(memory_request_bit_address),
        .memory_request_width_32_o(memory_request_width_32),
        .memory_request_cache_fill_o(memory_request_cache_fill),
        .memory_request_sequence_index_o(
            memory_request_sequence_index
        ),
        .memory_response_valid_i(memory_response_valid_i),
        .memory_response_ready_o(memory_response_ready),
        .memory_response_data_i(memory_response_data_i),
        .memory_response_completion_i(memory_response_completion_i),
        .faulted_o(faulted),
        .fault_resume_i(fault_resume_i),
        .fault_abort_i(fault_abort_i),
        .request_aborted_o(request_aborted),
        .present_debug_o(present_debug),
        .lru_debug_o(lru_debug),
        .tag_valid_debug_o(tag_valid_debug)
    );

endmodule

`default_nettype wire
