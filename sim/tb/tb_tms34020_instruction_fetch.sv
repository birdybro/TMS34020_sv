`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_instruction_fetch;

    import tms34020_pkg::*;

    logic clk;
    logic reset;

    logic pc_load_valid;
    logic pc_load_ready;
    logic [31:0] pc_load_bit_address;

    logic cache_request_valid;
    logic cache_request_ready;
    logic [31:0] cache_request_bit_address;

    logic cache_response_valid;
    logic cache_response_ready;
    logic [15:0] cache_response_word;
    tms34020_cache_result_t cache_response_result;
    logic cache_request_aborted;

    logic packet_valid;
    logic packet_ready;
    logic packet_decode_valid;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [9:0] packet_cache_results;
    logic [31:0] packet_start_pc;
    logic [31:0] packet_sequential_next_pc;
    tms34020_cache_result_t packet_first_cache_result;

    logic completion_valid;
    logic completion_ready;
    logic completion_redirect;
    logic [31:0] completion_redirect_bit_address;

    logic fetch_aborted;

    tms34020_instruction_fetch dut (
        .clk_i(clk),
        .reset_i(reset),
        .pc_load_valid_i(pc_load_valid),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(pc_load_bit_address),
        .cache_request_valid_o(cache_request_valid),
        .cache_request_ready_i(cache_request_ready),
        .cache_request_bit_address_o(cache_request_bit_address),
        .cache_response_valid_i(cache_response_valid),
        .cache_response_ready_o(cache_response_ready),
        .cache_response_word_i(cache_response_word),
        .cache_response_result_i(cache_response_result),
        .cache_request_aborted_i(cache_request_aborted),
        .packet_valid_o(packet_valid),
        .packet_ready_i(packet_ready),
        .packet_decode_valid_o(packet_decode_valid),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_cache_results_o(packet_cache_results),
        .packet_start_pc_o(packet_start_pc),
        .packet_sequential_next_pc_o(packet_sequential_next_pc),
        .packet_first_cache_result_o(packet_first_cache_result),
        .completion_valid_i(completion_valid),
        .completion_ready_o(completion_ready),
        .completion_redirect_i(completion_redirect),
        .completion_redirect_bit_address_i(
            completion_redirect_bit_address
        ),
        .fetch_aborted_o(fetch_aborted)
    );

    always #5 clk = ~clk;

    task automatic check_condition(
        input logic condition,
        input string message
    );
        if (!condition) begin
            $display("FAIL: %s", message);
            $fatal(1);
        end
    endtask

    task automatic load_pc(input logic [31:0] bit_address);
        begin
            @(negedge clk);
            check_condition(pc_load_ready, "PC load not ready");
            pc_load_bit_address = bit_address;
            pc_load_valid = 1'b1;
            @(posedge clk);
            #1;
            pc_load_valid = 1'b0;
        end
    endtask

    task automatic accept_cache_request(
        input logic [31:0] expected_bit_address,
        input integer stall_cycles
    );
        logic [31:0] held_address;
        begin
            while (!cache_request_valid) begin
                @(posedge clk);
                #1;
            end
            held_address = cache_request_bit_address;
            check_condition(
                held_address == expected_bit_address,
                "cache request address"
            );
            repeat (stall_cycles) begin
                @(posedge clk);
                #1;
                check_condition(
                    cache_request_valid &&
                    cache_request_bit_address == held_address,
                    "stalled cache request stability"
                );
            end
            @(negedge clk);
            cache_request_ready = 1'b1;
            @(posedge clk);
            #1;
            cache_request_ready = 1'b0;
        end
    endtask

    task automatic send_cache_response(
        input logic [15:0] word,
        input tms34020_cache_result_t result
    );
        begin
            while (!cache_response_ready) begin
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            cache_response_word = word;
            cache_response_result = result;
            cache_response_valid = 1'b1;
            @(posedge clk);
            #1;
            cache_response_valid = 1'b0;
        end
    endtask

    task automatic check_packet(
        input logic expected_decode_valid,
        input tms34020_opcode_id_t expected_opcode_id,
        input logic [2:0] expected_length,
        input logic [79:0] expected_words,
        input logic [9:0] expected_cache_results,
        input logic [31:0] expected_start_pc,
        input logic [31:0] expected_next_pc,
        input tms34020_cache_result_t expected_first_result,
        input integer stall_cycles,
        input string message
    );
        logic [79:0] held_words;
        begin
            while (!packet_valid) begin
                @(posedge clk);
                #1;
            end
            check_condition(
                packet_decode_valid == expected_decode_valid &&
                packet_opcode_id == expected_opcode_id &&
                packet_length_words == expected_length &&
                packet_words == expected_words &&
                packet_cache_results == expected_cache_results &&
                packet_start_pc == expected_start_pc &&
                packet_sequential_next_pc == expected_next_pc &&
                packet_first_cache_result == expected_first_result,
                message
            );
            held_words = packet_words;
            repeat (stall_cycles) begin
                @(posedge clk);
                #1;
                check_condition(
                    packet_valid &&
                    packet_words == held_words &&
                    packet_start_pc == expected_start_pc &&
                    packet_sequential_next_pc == expected_next_pc,
                    "stalled packet stability"
                );
            end
            @(negedge clk);
            packet_ready = 1'b1;
            @(posedge clk);
            #1;
            packet_ready = 1'b0;
            check_condition(
                completion_ready && !cache_request_valid,
                "fetch waits for explicit instruction completion"
            );
        end
    endtask

    task automatic complete_instruction(
        input logic redirect,
        input logic [31:0] redirect_bit_address
    );
        begin
            @(negedge clk);
            check_condition(
                completion_ready,
                "instruction completion not ready"
            );
            completion_redirect = redirect;
            completion_redirect_bit_address = redirect_bit_address;
            completion_valid = 1'b1;
            @(posedge clk);
            #1;
            completion_valid = 1'b0;
            completion_redirect = 1'b0;
            completion_redirect_bit_address = 32'd0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc_load_valid = 1'b0;
        pc_load_bit_address = 32'd0;
        cache_request_ready = 1'b0;
        cache_response_valid = 1'b0;
        cache_response_word = 16'd0;
        cache_response_result = TMS34020_CACHE_HIT;
        cache_request_aborted = 1'b0;
        packet_ready = 1'b0;
        completion_valid = 1'b0;
        completion_redirect = 1'b0;
        completion_redirect_bit_address = 32'd0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;
        check_condition(
            pc_load_ready && !cache_request_valid && !packet_valid,
            "reset requires an explicit initial PC"
        );

        load_pc(32'h0000_0123);
        accept_cache_request(32'h0000_0120, 2);
        send_cache_response(16'h0300, TMS34020_CACHE_SEGMENT_MISS);
        check_packet(
            1'b1,
            TMS20_OP_NOP,
            3'd1,
            {64'd0, 16'h0300},
            {
                8'd0,
                TMS34020_CACHE_SEGMENT_MISS
            },
            32'h0000_0120,
            32'h0000_0130,
            TMS34020_CACHE_SEGMENT_MISS,
            2,
            "single-word NOP packet"
        );
        complete_instruction(1'b0, 32'd0);

        accept_cache_request(32'h0000_0130, 0);
        send_cache_response(16'h0BA1, TMS34020_CACHE_HIT);
        accept_cache_request(32'h0000_0140, 1);
        send_cache_response(16'hCDEF, TMS34020_CACHE_HIT);
        accept_cache_request(32'h0000_0150, 0);
        send_cache_response(16'h89AB, TMS34020_CACHE_HIT);
        check_packet(
            1'b1,
            TMS20_OP_ORI,
            3'd3,
            {32'd0, 16'h89AB, 16'hCDEF, 16'h0BA1},
            {
                4'd0,
                TMS34020_CACHE_HIT,
                TMS34020_CACHE_HIT,
                TMS34020_CACHE_HIT
            },
            32'h0000_0130,
            32'h0000_0160,
            TMS34020_CACHE_HIT,
            1,
            "three-word ORI packet"
        );
        complete_instruction(1'b1, 32'hABCD_EF12);

        accept_cache_request(32'hABCD_EF10, 0);
        send_cache_response(16'h0301, TMS34020_CACHE_BYPASS);
        check_packet(
            1'b0,
            TMS20_OP_UNCLASSIFIED,
            3'd1,
            {64'd0, 16'h0301},
            {8'd0, TMS34020_CACHE_BYPASS},
            32'hABCD_EF10,
            32'hABCD_EF20,
            TMS34020_CACHE_BYPASS,
            0,
            "unclassified word forms invalid one-word packet"
        );
        complete_instruction(1'b0, 32'd0);

        accept_cache_request(32'hABCD_EF20, 0);
        while (!cache_response_ready) begin
            @(posedge clk);
            #1;
        end
        @(negedge clk);
        cache_request_aborted = 1'b1;
        @(posedge clk);
        #1;
        cache_request_aborted = 1'b0;
        check_condition(
            fetch_aborted && pc_load_ready && !packet_valid,
            "cache abort discards partial packet and requires PC reload"
        );

        load_pc(32'hFFFF_FFF7);
        accept_cache_request(32'hFFFF_FFF0, 0);
        send_cache_response(16'h0300, TMS34020_CACHE_HIT);
        check_packet(
            1'b1,
            TMS20_OP_NOP,
            3'd1,
            {64'd0, 16'h0300},
            {8'd0, TMS34020_CACHE_HIT},
            32'hFFFF_FFF0,
            32'h0000_0000,
            TMS34020_CACHE_HIT,
            0,
            "sequential PC wraps in 32-bit bit-address space"
        );
        complete_instruction(1'b0, 32'd0);
        accept_cache_request(32'h0000_0000, 0);

        reset = 1'b1;
        @(posedge clk);
        #1;
        check_condition(
            pc_load_ready &&
            !cache_request_valid &&
            !packet_valid &&
            !completion_ready,
            "reset cancels fetch sequencing"
        );

        $display("PASS: tms34020 instruction packet fetch");
        $finish;
    end

endmodule

`default_nettype wire
