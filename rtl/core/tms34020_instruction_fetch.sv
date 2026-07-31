`timescale 1ns/1ps
`default_nettype none

module tms34020_instruction_fetch (
    input  logic        clk_i,
    input  logic        reset_i,

    input  logic        pc_load_valid_i,
    output logic        pc_load_ready_o,
    input  logic [31:0] pc_load_bit_address_i,

    output logic        cache_request_valid_o,
    input  logic        cache_request_ready_i,
    output logic [31:0] cache_request_bit_address_o,

    input  logic        cache_response_valid_i,
    output logic        cache_response_ready_o,
    input  logic [15:0] cache_response_word_i,
    input  tms34020_pkg::tms34020_cache_result_t
                       cache_response_result_i,
    input  logic        cache_request_aborted_i,

    output logic        packet_valid_o,
    input  logic        packet_ready_i,
    output logic        packet_decode_valid_o,
    output tms34020_pkg::tms34020_opcode_id_t packet_opcode_id_o,
    output logic [2:0]  packet_length_words_o,
    output logic [79:0] packet_words_o,
    output logic [9:0]  packet_cache_results_o,
    output logic [31:0] packet_start_pc_o,
    output logic [31:0] packet_sequential_next_pc_o,
    output tms34020_pkg::tms34020_cache_result_t
                       packet_first_cache_result_o,

    input  logic        completion_valid_i,
    output logic        completion_ready_o,
    input  logic        completion_redirect_i,
    input  logic [31:0] completion_redirect_bit_address_i,

    output logic        fetch_aborted_o
);

    import tms34020_pkg::*;

    typedef enum logic [2:0] {
        FETCH_NEEDS_PC,
        FETCH_REQUEST,
        FETCH_WAIT_RESPONSE,
        FETCH_PACKET,
        FETCH_WAIT_COMPLETION
    } fetch_state_t;

    fetch_state_t state_q;

    logic [31:0] instruction_start_pc_q;
    logic [2:0] word_index_q;
    logic [2:0] instruction_length_q;
    logic [79:0] instruction_words_q;
    logic [9:0] instruction_cache_results_q;
    logic packet_decode_valid_q;
    tms34020_opcode_id_t packet_opcode_id_q;
    tms34020_cache_result_t first_cache_result_q;
    logic [31:0] sequential_next_pc_q;

    logic response_decode_valid;
    tms34020_opcode_id_t response_opcode_id;
    logic [2:0] response_length_words;
    logic [2:0] response_effective_length;

    tms34020_decode response_decode (
        .first_word_i(cache_response_word_i),
        .valid_o(response_decode_valid),
        .opcode_id_o(response_opcode_id),
        .length_words_o(response_length_words)
    );

    always_comb begin
        response_effective_length =
            response_decode_valid ? response_length_words : 3'd1;

        pc_load_ready_o = state_q == FETCH_NEEDS_PC;

        cache_request_valid_o = state_q == FETCH_REQUEST;
        cache_request_bit_address_o =
            instruction_start_pc_q + {25'd0, word_index_q, 4'd0};
        cache_response_ready_o = state_q == FETCH_WAIT_RESPONSE;

        packet_valid_o = state_q == FETCH_PACKET;
        packet_decode_valid_o = packet_decode_valid_q;
        packet_opcode_id_o = packet_opcode_id_q;
        packet_length_words_o = instruction_length_q;
        packet_words_o = instruction_words_q;
        packet_cache_results_o = instruction_cache_results_q;
        packet_start_pc_o = instruction_start_pc_q;
        packet_sequential_next_pc_o = sequential_next_pc_q;
        packet_first_cache_result_o = first_cache_result_q;

        completion_ready_o = state_q == FETCH_WAIT_COMPLETION;
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            state_q <= FETCH_NEEDS_PC;
            instruction_start_pc_q <= 32'd0;
            word_index_q <= 3'd0;
            instruction_length_q <= 3'd0;
            instruction_words_q <= 80'd0;
            instruction_cache_results_q <= 10'd0;
            packet_decode_valid_q <= 1'b0;
            packet_opcode_id_q <= TMS20_OP_UNCLASSIFIED;
            first_cache_result_q <= TMS34020_CACHE_HIT;
            sequential_next_pc_q <= 32'd0;
            fetch_aborted_o <= 1'b0;
        end else begin
            fetch_aborted_o <= 1'b0;

            unique case (state_q)
                FETCH_NEEDS_PC: begin
                    if (pc_load_valid_i) begin
                        instruction_start_pc_q <=
                            pc_load_bit_address_i & 32'hFFFF_FFF0;
                        word_index_q <= 3'd0;
                        instruction_length_q <= 3'd0;
                        instruction_words_q <= 80'd0;
                        instruction_cache_results_q <= 10'd0;
                        packet_decode_valid_q <= 1'b0;
                        packet_opcode_id_q <= TMS20_OP_UNCLASSIFIED;
                        state_q <= FETCH_REQUEST;
                    end
                end

                FETCH_REQUEST: begin
                    if (cache_request_ready_i) begin
                        state_q <= FETCH_WAIT_RESPONSE;
                    end
                end

                FETCH_WAIT_RESPONSE: begin
                    if (cache_request_aborted_i) begin
                        instruction_words_q <= 80'd0;
                        instruction_cache_results_q <= 10'd0;
                        instruction_length_q <= 3'd0;
                        packet_decode_valid_q <= 1'b0;
                        packet_opcode_id_q <= TMS20_OP_UNCLASSIFIED;
                        word_index_q <= 3'd0;
                        fetch_aborted_o <= 1'b1;
                        state_q <= FETCH_NEEDS_PC;
                    end else if (cache_response_valid_i) begin
                        instruction_words_q[
                            word_index_q * 16 +: 16
                        ] <= cache_response_word_i;
                        instruction_cache_results_q[
                            word_index_q * 2 +: 2
                        ] <= cache_response_result_i;

                        if (word_index_q == 3'd0) begin
                            instruction_length_q <=
                                response_effective_length;
                            packet_decode_valid_q <=
                                response_decode_valid;
                            packet_opcode_id_q <= response_opcode_id;
                            first_cache_result_q <=
                                cache_response_result_i;
                            sequential_next_pc_q <=
                                instruction_start_pc_q +
                                {
                                    25'd0,
                                    response_effective_length,
                                    4'd0
                                };

                            if (response_effective_length == 3'd1) begin
                                state_q <= FETCH_PACKET;
                            end else begin
                                word_index_q <= 3'd1;
                                state_q <= FETCH_REQUEST;
                            end
                        end else if (
                            word_index_q + 3'd1 ==
                            instruction_length_q
                        ) begin
                            state_q <= FETCH_PACKET;
                        end else begin
                            word_index_q <= word_index_q + 3'd1;
                            state_q <= FETCH_REQUEST;
                        end
                    end
                end

                FETCH_PACKET: begin
                    if (packet_ready_i) begin
                        state_q <= FETCH_WAIT_COMPLETION;
                    end
                end

                FETCH_WAIT_COMPLETION: begin
                    if (completion_valid_i) begin
                        if (completion_redirect_i) begin
                            instruction_start_pc_q <=
                                completion_redirect_bit_address_i &
                                32'hFFFF_FFF0;
                        end else begin
                            instruction_start_pc_q <=
                                sequential_next_pc_q;
                        end
                        word_index_q <= 3'd0;
                        instruction_length_q <= 3'd0;
                        instruction_words_q <= 80'd0;
                        instruction_cache_results_q <= 10'd0;
                        packet_decode_valid_q <= 1'b0;
                        packet_opcode_id_q <= TMS20_OP_UNCLASSIFIED;
                        state_q <= FETCH_REQUEST;
                    end
                end

                default: begin
                    state_q <= FETCH_NEEDS_PC;
                    instruction_start_pc_q <= 32'd0;
                    word_index_q <= 3'd0;
                    instruction_length_q <= 3'd0;
                    instruction_words_q <= 80'd0;
                    instruction_cache_results_q <= 10'd0;
                    packet_decode_valid_q <= 1'b0;
                    packet_opcode_id_q <= TMS20_OP_UNCLASSIFIED;
                    first_cache_result_q <= TMS34020_CACHE_HIT;
                    sequential_next_pc_q <= 32'd0;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    property p_cache_request_stable_while_stalled;
        @(posedge clk_i) disable iff (reset_i)
            cache_request_valid_o && !cache_request_ready_i
            |=> cache_request_valid_o &&
                $stable(cache_request_bit_address_o);
    endproperty

    property p_packet_stable_while_stalled;
        @(posedge clk_i) disable iff (reset_i)
            packet_valid_o && !packet_ready_i
            |=> packet_valid_o &&
                $stable(packet_decode_valid_o) &&
                $stable(packet_opcode_id_o) &&
                $stable(packet_length_words_o) &&
                $stable(packet_words_o) &&
                $stable(packet_cache_results_o) &&
                $stable(packet_start_pc_o) &&
                $stable(packet_sequential_next_pc_o) &&
                $stable(packet_first_cache_result_o);
    endproperty

    property p_fetch_address_aligned;
        @(posedge clk_i) disable iff (reset_i)
            cache_request_valid_o
            |-> cache_request_bit_address_o[3:0] == 4'd0;
    endproperty

    property p_no_partial_packet_after_abort;
        @(posedge clk_i) disable iff (reset_i)
            cache_request_aborted_i && cache_response_ready_o
            |=> !packet_valid_o;
    endproperty

    assert property (p_cache_request_stable_while_stalled);
    assert property (p_packet_stable_while_stalled);
    assert property (p_fetch_address_aligned);
    assert property (p_no_partial_packet_after_abort);
`endif

endmodule

`default_nettype wire
