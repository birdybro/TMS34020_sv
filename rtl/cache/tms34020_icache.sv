`timescale 1ns/1ps
`default_nettype none

// Bounded portable instruction-cache leaf. A missing native response represents
// an outstanding/waiting transfer. Explicit success, retry, and fault outcomes
// operate at native-cycle granularity; pin phases remain outside this module.
module tms34020_icache (
    input  logic        clk_i,
    input  logic        reset_i,

    input  logic        request_valid_i,
    output logic        request_ready_o,
    input  logic [31:0] request_bit_address_i,
    input  logic        cache_disable_i,
    input  logic        cache_flush_i,

    output logic        response_valid_o,
    input  logic        response_ready_i,
    output logic [15:0] response_word_o,
    output tms34020_pkg::tms34020_cache_result_t response_result_o,

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
    output logic        request_aborted_o,

    output logic [31:0] present_debug_o,
    output logic [7:0]  lru_debug_o,
    output logic [3:0]  tag_valid_debug_o
);

    import tms34020_pkg::*;

    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_MEMORY_REQUEST,
        STATE_MEMORY_RESPONSE,
        STATE_FAULTED,
        STATE_CACHE_HIT_RESPONSE,
        STATE_WORD_RESPONSE
    } cache_state_t;

    cache_state_t state;

    logic [21:0] segment_tag [0:3];
    logic [3:0] tag_valid;
    logic [7:0] present [0:3];
    logic [31:0] cache_data [0:127];
    logic [7:0] lru_stack;

    logic [31:0] active_bit_address;
    logic [1:0] active_segment;
    logic [2:0] active_subsegment;
    logic [1:0] requested_long_index;
    logic requested_half_index;
    logic [1:0] refill_sequence_index;
    logic active_bypass;
    logic [15:0] response_word;
    tms34020_cache_result_t response_result;
    logic [31:0] cache_read_long_word;

    logic lookup_tag_match;
    logic lookup_hit;
    logic [1:0] lookup_segment;
    logic [1:0] active_refill_long_index;
    logic [6:0] active_refill_data_index;
    logic cache_ram_read_enable;
    logic [6:0] cache_ram_read_address;
    logic cache_ram_write_enable;

    integer lookup_segment_index;
    integer metadata_segment_index;

    function automatic logic [7:0] touch_lru(
        input logic [7:0] current_lru,
        input logic [1:0] touched_segment
    );
        begin
            if (current_lru[7:6] == touched_segment) begin
                touch_lru = current_lru;
            end else if (current_lru[5:4] == touched_segment) begin
                touch_lru = {
                    touched_segment,
                    current_lru[7:6],
                    current_lru[3:0]
                };
            end else if (current_lru[3:2] == touched_segment) begin
                touch_lru = {
                    touched_segment,
                    current_lru[7:4],
                    current_lru[1:0]
                };
            end else begin
                touch_lru = {
                    touched_segment,
                    current_lru[7:2]
                };
            end
        end
    endfunction

    function automatic logic [1:0] refill_long_index(
        input logic [1:0] requested_index,
        input logic [1:0] sequence_index
    );
        begin
            case (sequence_index)
                2'd0: refill_long_index = requested_index + 2'd1;
                2'd1: refill_long_index = requested_index + 2'd2;
                2'd2: refill_long_index = requested_index + 2'd3;
                default: refill_long_index = requested_index;
            endcase
        end
    endfunction

    always_comb begin
        lookup_tag_match = 1'b0;
        lookup_hit = 1'b0;
        lookup_segment = 2'd0;
        for (lookup_segment_index = 0;
             lookup_segment_index < 4;
             lookup_segment_index = lookup_segment_index + 1) begin
            if (!lookup_tag_match &&
                tag_valid[lookup_segment_index] &&
                segment_tag[lookup_segment_index] ==
                    request_bit_address_i[31:10]) begin
                lookup_tag_match = 1'b1;
                lookup_segment = lookup_segment_index[1:0];
                lookup_hit =
                    present[lookup_segment_index]
                        [request_bit_address_i[9:7]];
            end
        end

        active_refill_long_index = refill_long_index(
            requested_long_index,
            refill_sequence_index
        );
        active_refill_data_index = {
            active_segment,
            active_subsegment,
            active_refill_long_index
        };
        cache_ram_read_enable =
            state == STATE_IDLE &&
            request_valid_i &&
            !cache_disable_i &&
            !cache_flush_i &&
            lookup_hit;
        cache_ram_read_address = {
            lookup_segment,
            request_bit_address_i[9:5]
        };
        cache_ram_write_enable =
            state == STATE_MEMORY_RESPONSE &&
            memory_response_valid_i &&
            memory_response_completion_i == TMS34020_MEMORY_SUCCESS &&
            !active_bypass;

        request_ready_o = state == STATE_IDLE;
        response_valid_o =
            state == STATE_CACHE_HIT_RESPONSE ||
            state == STATE_WORD_RESPONSE;
        response_word_o = response_word;
        if (state == STATE_CACHE_HIT_RESPONSE) begin
            response_word_o = requested_half_index ?
                cache_read_long_word[31:16] :
                cache_read_long_word[15:0];
        end
        response_result_o = response_result;

        memory_request_valid_o = state == STATE_MEMORY_REQUEST;
        memory_request_bit_address_o = active_bit_address;
        memory_request_width_32_o = !active_bypass;
        memory_request_cache_fill_o = !active_bypass;
        memory_request_sequence_index_o =
            active_bypass ? 2'd0 : refill_sequence_index;
        if (!active_bypass) begin
            memory_request_bit_address_o = {
                active_bit_address[31:7],
                7'd0
            } + {
                25'd0,
                active_refill_long_index,
                5'd0
            };
        end

        memory_response_ready_o =
            state == STATE_MEMORY_RESPONSE &&
            (
                !memory_response_valid_i ||
                memory_response_completion_i != TMS34020_MEMORY_RESERVED
            );
        faulted_o = state == STATE_FAULTED;

        present_debug_o = {
            present[3],
            present[2],
            present[1],
            present[0]
        };
        lru_debug_o = lru_stack;
        tag_valid_debug_o = tag_valid;
    end

    always_ff @(posedge clk_i) begin
        if (cache_ram_write_enable) begin
            cache_data[active_refill_data_index] <=
                memory_response_data_i;
        end
        if (cache_ram_read_enable) begin
            cache_read_long_word <=
                cache_data[cache_ram_read_address];
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            state <= STATE_IDLE;
            tag_valid <= 4'd0;
            lru_stack <= 8'b00_01_10_11;
            active_bit_address <= 32'd0;
            active_segment <= 2'd0;
            active_subsegment <= 3'd0;
            requested_long_index <= 2'd0;
            requested_half_index <= 1'b0;
            refill_sequence_index <= 2'd0;
            active_bypass <= 1'b0;
            response_word <= 16'd0;
            response_result <= TMS34020_CACHE_HIT;
            request_aborted_o <= 1'b0;
            for (metadata_segment_index = 0;
                 metadata_segment_index < 4;
                 metadata_segment_index = metadata_segment_index + 1) begin
                segment_tag[metadata_segment_index] <= 22'd0;
                present[metadata_segment_index] <= 8'd0;
            end
        end else begin
            request_aborted_o <= 1'b0;
            if (cache_flush_i) begin
                tag_valid <= 4'd0;
                lru_stack <= 8'b00_01_10_11;
                for (metadata_segment_index = 0;
                     metadata_segment_index < 4;
                     metadata_segment_index =
                        metadata_segment_index + 1) begin
                    present[metadata_segment_index] <= 8'd0;
                end
            end

            case (state)
                STATE_IDLE: begin
                    if (request_valid_i) begin
                        active_bit_address <= request_bit_address_i;
                        active_subsegment <=
                            request_bit_address_i[9:7];
                        requested_long_index <=
                            request_bit_address_i[6:5];
                        requested_half_index <=
                            request_bit_address_i[4];
                        refill_sequence_index <= 2'd0;

                        if (cache_disable_i || cache_flush_i) begin
                            active_bypass <= 1'b1;
                            response_result <= TMS34020_CACHE_BYPASS;
                            state <= STATE_MEMORY_REQUEST;
                        end else if (lookup_hit) begin
                            active_bypass <= 1'b0;
                            active_segment <= lookup_segment;
                            response_result <= TMS34020_CACHE_HIT;
                            lru_stack <= touch_lru(
                                lru_stack,
                                lookup_segment
                            );
                            state <= STATE_CACHE_HIT_RESPONSE;
                        end else begin
                            active_bypass <= 1'b0;
                            if (lookup_tag_match) begin
                                active_segment <= lookup_segment;
                                response_result <=
                                    TMS34020_CACHE_SUBSEGMENT_MISS;
                            end else begin
                                active_segment <= lru_stack[1:0];
                                segment_tag[lru_stack[1:0]] <=
                                    request_bit_address_i[31:10];
                                tag_valid[lru_stack[1:0]] <= 1'b1;
                                present[lru_stack[1:0]] <= 8'd0;
                                response_result <=
                                    TMS34020_CACHE_SEGMENT_MISS;
                            end
                            state <= STATE_MEMORY_REQUEST;
                        end
                    end
                end

                STATE_MEMORY_REQUEST: begin
                    if (memory_request_ready_i) begin
                        state <= STATE_MEMORY_RESPONSE;
                    end
                end

                STATE_MEMORY_RESPONSE: begin
                    if (memory_response_valid_i) begin
                        case (memory_response_completion_i)
                            TMS34020_MEMORY_RETRY: begin
                                state <= STATE_MEMORY_REQUEST;
                            end

                            TMS34020_MEMORY_FAULT: begin
                                state <= STATE_FAULTED;
                            end

                            TMS34020_MEMORY_SUCCESS: begin
                                if (active_bypass) begin
                                    response_word <=
                                        memory_response_data_i[15:0];
                                    state <= STATE_WORD_RESPONSE;
                                end else if (
                                    refill_sequence_index == 2'd3
                                ) begin
                                    response_word <=
                                        requested_half_index ?
                                        memory_response_data_i[31:16] :
                                        memory_response_data_i[15:0];
                                    if (!cache_flush_i) begin
                                        present[active_segment]
                                            [active_subsegment] <= 1'b1;
                                        lru_stack <= touch_lru(
                                            lru_stack,
                                            active_segment
                                        );
                                    end
                                    state <= STATE_WORD_RESPONSE;
                                end else begin
                                    refill_sequence_index <=
                                        refill_sequence_index + 2'd1;
                                    state <= STATE_MEMORY_REQUEST;
                                end
                            end

                            default: begin
                                state <= STATE_MEMORY_RESPONSE;
                            end
                        endcase
                    end
                end

                STATE_FAULTED: begin
                    if (fault_abort_i) begin
                        request_aborted_o <= 1'b1;
                        state <= STATE_IDLE;
                    end else if (fault_resume_i) begin
                        state <= STATE_MEMORY_REQUEST;
                    end
                end

                STATE_WORD_RESPONSE: begin
                    if (response_ready_i) begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_CACHE_HIT_RESPONSE: begin
                    if (response_ready_i) begin
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    property native_request_stable_while_stalled;
        @(posedge clk_i) disable iff (reset_i)
            memory_request_valid_o && !memory_request_ready_i
            |=> memory_request_valid_o &&
                $stable(memory_request_bit_address_o) &&
                $stable(memory_request_width_32_o) &&
                $stable(memory_request_cache_fill_o) &&
                $stable(memory_request_sequence_index_o);
    endproperty

    property instruction_response_stable_while_stalled;
        @(posedge clk_i) disable iff (reset_i)
            response_valid_o && !response_ready_i
            |=> response_valid_o &&
                $stable(response_word_o) &&
                $stable(response_result_o);
    endproperty

    property retry_or_fault_does_not_commit_present;
        @(posedge clk_i) disable iff (reset_i)
            memory_response_valid_i &&
                memory_response_ready_o &&
                memory_response_completion_i != TMS34020_MEMORY_SUCCESS &&
                !cache_flush_i
            |=> cache_flush_i || $stable(present_debug_o);
    endproperty

    property fault_state_quiesces_ports;
        @(posedge clk_i) disable iff (reset_i)
            faulted_o
            |-> !request_ready_o &&
                !memory_request_valid_o &&
                !memory_response_ready_o &&
                !response_valid_o;
    endproperty

    assert property (native_request_stable_while_stalled)
        else $fatal(1, "stalled native request changed");
    assert property (instruction_response_stable_while_stalled)
        else $fatal(1, "stalled instruction response changed");
    assert property (retry_or_fault_does_not_commit_present)
        else $fatal(1, "retry or fault committed a present flag");
    assert property (fault_state_quiesces_ports)
        else $fatal(1, "faulted cache exposed an active port");

    always_ff @(posedge clk_i) begin
        if (!reset_i) begin
            if (request_valid_i && request_ready_o) begin
                assert (request_bit_address_i[3:0] == 4'd0)
                    else $fatal(1, "instruction request is not word aligned");
            end
            if (memory_response_valid_i &&
                state == STATE_MEMORY_RESPONSE) begin
                assert (
                    memory_response_completion_i !=
                        TMS34020_MEMORY_RESERVED
                ) else $fatal(1, "reserved memory completion accepted");
            end
            assert (!(fault_resume_i && fault_abort_i))
                else $fatal(1, "fault resume and abort asserted together");
            assert (
                lru_stack[7:6] != lru_stack[5:4] &&
                lru_stack[7:6] != lru_stack[3:2] &&
                lru_stack[7:6] != lru_stack[1:0] &&
                lru_stack[5:4] != lru_stack[3:2] &&
                lru_stack[5:4] != lru_stack[1:0] &&
                lru_stack[3:2] != lru_stack[1:0]
            ) else $fatal(1, "cache LRU stack is not a permutation");
        end
    end
`endif

endmodule

`default_nettype wire
