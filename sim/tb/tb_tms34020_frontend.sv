`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_frontend;

    import tms34020_pkg::*;

    logic clk;
    logic reset;
    logic pc_load_valid;
    logic pc_load_ready;
    logic [31:0] pc_load_bit_address;
    logic cache_disable;
    logic cache_flush;
    logic packet_valid;
    logic packet_ready;
    logic packet_decode_valid;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [9:0] packet_cache_results;
    logic [31:0] packet_start_pc;
    logic [31:0] packet_sequential_next_pc;
    logic completion_valid;
    logic completion_ready;
    logic completion_redirect;
    logic [31:0] completion_redirect_bit_address;
    logic memory_request_valid;
    logic memory_request_ready;
    logic [31:0] memory_request_bit_address;
    logic memory_request_width_32;
    logic memory_request_cache_fill;
    logic [1:0] memory_request_sequence_index;
    logic memory_response_valid;
    logic memory_response_ready;
    logic [31:0] memory_response_data;
    tms34020_memory_completion_t memory_response_completion;
    logic faulted;
    logic fault_resume;
    logic fault_abort;
    logic fetch_aborted;
    logic [31:0] cache_present_debug;
    logic [7:0] cache_lru_debug;
    logic [3:0] cache_tag_valid_debug;

    tms34020_frontend dut (
        .clk_i(clk),
        .reset_i(reset),
        .pc_load_valid_i(pc_load_valid),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(pc_load_bit_address),
        .cache_disable_i(cache_disable),
        .cache_flush_i(cache_flush),
        .packet_valid_o(packet_valid),
        .packet_ready_i(packet_ready),
        .packet_decode_valid_o(packet_decode_valid),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_cache_results_o(packet_cache_results),
        .packet_start_pc_o(packet_start_pc),
        .packet_sequential_next_pc_o(packet_sequential_next_pc),
        .completion_valid_i(completion_valid),
        .completion_ready_o(completion_ready),
        .completion_redirect_i(completion_redirect),
        .completion_redirect_bit_address_i(
            completion_redirect_bit_address
        ),
        .memory_request_valid_o(memory_request_valid),
        .memory_request_ready_i(memory_request_ready),
        .memory_request_bit_address_o(memory_request_bit_address),
        .memory_request_width_32_o(memory_request_width_32),
        .memory_request_cache_fill_o(memory_request_cache_fill),
        .memory_request_sequence_index_o(
            memory_request_sequence_index
        ),
        .memory_response_valid_i(memory_response_valid),
        .memory_response_ready_o(memory_response_ready),
        .memory_response_data_i(memory_response_data),
        .memory_response_completion_i(memory_response_completion),
        .faulted_o(faulted),
        .fault_resume_i(fault_resume),
        .fault_abort_i(fault_abort),
        .fetch_aborted_o(fetch_aborted),
        .cache_present_debug_o(cache_present_debug),
        .cache_lru_debug_o(cache_lru_debug),
        .cache_tag_valid_debug_o(cache_tag_valid_debug)
    );

    always #5 clk = ~clk;

    function automatic logic [15:0] memory_word(
        input logic [31:0] bit_address
    );
        begin
            unique case (bit_address)
                32'h0000_0000: memory_word = 16'h0300;
                32'h0000_0010: memory_word = 16'h0BA1;
                32'h0000_0020: memory_word = 16'hCDEF;
                32'h0000_0030: memory_word = 16'h89AB;
                default: memory_word = 16'h0300;
            endcase
        end
    endfunction

    function automatic logic [31:0] memory_long_word(
        input logic [31:0] bit_address
    );
        begin
            memory_long_word = {
                memory_word(bit_address + 32'd16),
                memory_word(bit_address)
            };
        end
    endfunction

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
            check_condition(pc_load_ready, "frontend PC load ready");
            pc_load_bit_address = bit_address;
            pc_load_valid = 1'b1;
            @(posedge clk);
            #1;
            pc_load_valid = 1'b0;
        end
    endtask

    task automatic wait_native_request(
        input logic [31:0] expected_address,
        input logic expected_width_32,
        input logic expected_cache_fill,
        input logic [1:0] expected_sequence
    );
        begin
            while (!memory_request_valid) begin
                @(posedge clk);
                #1;
            end
            check_condition(
                memory_request_bit_address == expected_address &&
                memory_request_width_32 == expected_width_32 &&
                memory_request_cache_fill == expected_cache_fill &&
                memory_request_sequence_index == expected_sequence,
                "frontend native request"
            );
            @(posedge clk);
            #1;
        end
    endtask

    task automatic send_native_completion(
        input tms34020_memory_completion_t completion
    );
        logic [31:0] request_address;
        logic request_width_32;
        begin
            request_address = memory_request_bit_address;
            request_width_32 = memory_request_width_32;
            while (!memory_response_ready) begin
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            memory_response_data =
                request_width_32 ?
                memory_long_word(request_address) :
                {16'd0, memory_word(request_address)};
            memory_response_completion = completion;
            memory_response_valid = 1'b1;
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
            memory_response_completion = TMS34020_MEMORY_SUCCESS;
        end
    endtask

    task automatic accept_packet;
        begin
            @(negedge clk);
            packet_ready = 1'b1;
            @(posedge clk);
            #1;
            packet_ready = 1'b0;
            check_condition(completion_ready, "frontend completion ready");
        end
    endtask

    task automatic complete_instruction(
        input logic redirect,
        input logic [31:0] redirect_address
    );
        begin
            @(negedge clk);
            completion_redirect = redirect;
            completion_redirect_bit_address = redirect_address;
            completion_valid = 1'b1;
            @(posedge clk);
            #1;
            completion_valid = 1'b0;
            completion_redirect = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc_load_valid = 1'b0;
        pc_load_bit_address = 32'd0;
        cache_disable = 1'b0;
        cache_flush = 1'b0;
        packet_ready = 1'b0;
        completion_valid = 1'b0;
        completion_redirect = 1'b0;
        completion_redirect_bit_address = 32'd0;
        memory_request_ready = 1'b1;
        memory_response_valid = 1'b0;
        memory_response_data = 32'd0;
        memory_response_completion = TMS34020_MEMORY_SUCCESS;
        fault_resume = 1'b0;
        fault_abort = 1'b0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;

        load_pc(32'd0);
        wait_native_request(32'h20, 1'b1, 1'b1, 2'd0);
        send_native_completion(TMS34020_MEMORY_SUCCESS);
        wait_native_request(32'h40, 1'b1, 1'b1, 2'd1);
        send_native_completion(TMS34020_MEMORY_SUCCESS);
        wait_native_request(32'h60, 1'b1, 1'b1, 2'd2);
        send_native_completion(TMS34020_MEMORY_SUCCESS);
        wait_native_request(32'h00, 1'b1, 1'b1, 2'd3);
        send_native_completion(TMS34020_MEMORY_SUCCESS);

        while (!packet_valid) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            packet_decode_valid &&
            packet_opcode_id == TMS20_OP_NOP &&
            packet_length_words == 3'd1 &&
            packet_words[15:0] == 16'h0300 &&
            packet_words[79:16] == 64'd0 &&
            packet_cache_results[1:0] ==
                TMS34020_CACHE_SEGMENT_MISS &&
            packet_cache_results[9:2] == 8'd0 &&
            packet_start_pc == 32'd0 &&
            packet_sequential_next_pc == 32'h10 &&
            cache_present_debug != 32'd0 &&
            cache_tag_valid_debug != 4'd0 &&
            cache_lru_debug == 8'b11_00_01_10,
            "frontend cold-miss NOP packet"
        );
        accept_packet();
        complete_instruction(1'b0, 32'd0);

        while (!packet_valid) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            packet_decode_valid &&
            packet_opcode_id == TMS20_OP_ORI &&
            packet_length_words == 3'd3 &&
            packet_words[47:0] ==
                {16'h89AB, 16'hCDEF, 16'h0BA1} &&
            packet_words[79:48] == 32'd0 &&
            packet_cache_results[5:0] ==
                {
                    TMS34020_CACHE_HIT,
                    TMS34020_CACHE_HIT,
                    TMS34020_CACHE_HIT
                } &&
            packet_cache_results[9:6] == 4'd0 &&
            !memory_request_valid,
            "frontend cache-hit ORI packet"
        );
        accept_packet();
        cache_disable = 1'b1;
        complete_instruction(1'b1, 32'h100);

        wait_native_request(32'h100, 1'b0, 1'b0, 2'd0);
        send_native_completion(TMS34020_MEMORY_RETRY);
        wait_native_request(32'h100, 1'b0, 1'b0, 2'd0);
        send_native_completion(TMS34020_MEMORY_SUCCESS);
        while (!packet_valid) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            packet_opcode_id == TMS20_OP_NOP &&
            packet_cache_results[1:0] == TMS34020_CACHE_BYPASS,
            "frontend disabled-cache retry"
        );
        accept_packet();
        complete_instruction(1'b0, 32'd0);

        wait_native_request(32'h110, 1'b0, 1'b0, 2'd0);
        send_native_completion(TMS34020_MEMORY_FAULT);
        check_condition(faulted, "frontend exposes cache fault hold");
        @(negedge clk);
        fault_abort = 1'b1;
        @(posedge clk);
        #1;
        fault_abort = 1'b0;
        @(posedge clk);
        #1;
        check_condition(
            fetch_aborted && pc_load_ready && !packet_valid,
            "frontend abort propagates to PC reload boundary"
        );

        cache_disable = 1'b0;
        load_pc(32'd0);
        while (!packet_valid) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            packet_opcode_id == TMS20_OP_NOP &&
            packet_cache_results[1:0] == TMS34020_CACHE_HIT &&
            !memory_request_valid,
            "frontend preserves cache across disable and bypass abort"
        );

        $display("PASS: tms34020 cache/fetch frontend");
        $finish;
    end

endmodule

`default_nettype wire
