`timescale 1ns/1ps
`default_nettype none

module tms34020_fetch_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [7:0]  control_i,
    input  logic [31:0] stimulus_i,
    output logic [31:0] result_digest_o
);

    import tms34020_pkg::*;

    logic pc_load_ready;
    logic cache_request_valid;
    logic [31:0] cache_request_bit_address;
    logic cache_response_ready;
    logic packet_valid;
    logic packet_decode_valid;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [9:0] packet_cache_results;
    logic [31:0] packet_start_pc;
    logic [31:0] packet_sequential_next_pc;
    tms34020_cache_result_t packet_first_cache_result;
    logic completion_ready;
    logic fetch_aborted;
    logic [15:0] folded_packet_words;

    always_comb begin
        folded_packet_words =
            packet_words[15:0] ^
            packet_words[31:16] ^
            packet_words[47:32] ^
            packet_words[63:48] ^
            packet_words[79:64];
        result_digest_o =
            cache_request_bit_address ^
            packet_start_pc ^
            packet_sequential_next_pc ^
            {22'd0, packet_cache_results} ^
            {16'd0, folded_packet_words} ^
            {
                13'd0,
                pc_load_ready,
                cache_request_valid,
                cache_response_ready,
                packet_valid,
                packet_decode_valid,
                packet_opcode_id,
                packet_length_words,
                packet_first_cache_result,
                completion_ready,
                fetch_aborted
            };
    end

    tms34020_instruction_fetch instruction_fetch (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_load_valid_i(control_i[0]),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(stimulus_i),
        .cache_request_valid_o(cache_request_valid),
        .cache_request_ready_i(control_i[1]),
        .cache_request_bit_address_o(cache_request_bit_address),
        .cache_response_valid_i(control_i[2]),
        .cache_response_ready_o(cache_response_ready),
        .cache_response_word_i(stimulus_i[15:0]),
        .cache_response_result_i(
            tms34020_cache_result_t'(control_i[7:6])
        ),
        .cache_request_aborted_i(control_i[3]),
        .packet_valid_o(packet_valid),
        .packet_ready_i(control_i[4]),
        .packet_decode_valid_o(packet_decode_valid),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_cache_results_o(packet_cache_results),
        .packet_start_pc_o(packet_start_pc),
        .packet_sequential_next_pc_o(packet_sequential_next_pc),
        .packet_first_cache_result_o(packet_first_cache_result),
        .completion_valid_i(control_i[5]),
        .completion_ready_o(completion_ready),
        .completion_redirect_i(control_i[6]),
        .completion_redirect_bit_address_i(stimulus_i),
        .fetch_aborted_o(fetch_aborted)
    );

endmodule

`default_nettype wire
