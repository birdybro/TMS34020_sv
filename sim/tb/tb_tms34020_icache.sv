`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_icache;

    import tms34020_pkg::*;

    logic clk;
    logic reset;

    logic request_valid;
    logic request_ready;
    logic [31:0] request_bit_address;
    logic cache_disable;
    logic cache_flush;

    logic response_valid;
    logic response_ready;
    logic [15:0] response_word;
    tms34020_cache_result_t response_result;

    logic memory_request_valid;
    logic memory_request_ready;
    logic [31:0] memory_request_bit_address;
    logic memory_request_width_32;
    logic memory_request_cache_fill;
    logic [1:0] memory_request_sequence_index;

    logic memory_response_valid;
    logic memory_response_ready;
    logic [31:0] memory_response_data;

    logic [31:0] present_debug;
    logic [7:0] lru_debug;
    logic [3:0] tag_valid_debug;

    tms34020_icache dut (
        .clk_i(clk),
        .reset_i(reset),
        .request_valid_i(request_valid),
        .request_ready_o(request_ready),
        .request_bit_address_i(request_bit_address),
        .cache_disable_i(cache_disable),
        .cache_flush_i(cache_flush),
        .response_valid_o(response_valid),
        .response_ready_i(response_ready),
        .response_word_o(response_word),
        .response_result_o(response_result),
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
        .present_debug_o(present_debug),
        .lru_debug_o(lru_debug),
        .tag_valid_debug_o(tag_valid_debug)
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

    task automatic start_request(
        input logic [31:0] bit_address,
        input logic disable_cache,
        input logic flush_cache
    );
        begin
            @(negedge clk);
            while (!request_ready) begin
                @(negedge clk);
            end
            request_bit_address = bit_address;
            cache_disable = disable_cache;
            cache_flush = flush_cache;
            request_valid = 1'b1;
            @(posedge clk);
            #1;
            request_valid = 1'b0;
            cache_disable = 1'b0;
            cache_flush = 1'b0;
        end
    endtask

    task automatic accept_memory_read(
        input logic [31:0] expected_bit_address,
        input logic expected_width_32,
        input logic expected_cache_fill,
        input logic [1:0] expected_sequence_index,
        input logic [31:0] response_data,
        input string message
    );
        logic [31:0] held_address;
        logic held_width;
        logic held_fill;
        logic [1:0] held_sequence;
        begin
            @(negedge clk);
            while (!memory_request_valid) begin
                @(negedge clk);
            end
            check_condition(
                memory_request_bit_address == expected_bit_address &&
                memory_request_width_32 == expected_width_32 &&
                memory_request_cache_fill == expected_cache_fill &&
                memory_request_sequence_index ==
                    expected_sequence_index,
                message
            );
            held_address = memory_request_bit_address;
            held_width = memory_request_width_32;
            held_fill = memory_request_cache_fill;
            held_sequence = memory_request_sequence_index;

            repeat (2) begin
                @(posedge clk);
                #1;
                check_condition(
                    memory_request_valid &&
                    memory_request_bit_address == held_address &&
                    memory_request_width_32 == held_width &&
                    memory_request_cache_fill == held_fill &&
                    memory_request_sequence_index == held_sequence,
                    "stalled memory request changed"
                );
            end

            @(negedge clk);
            memory_request_ready = 1'b1;
            @(posedge clk);
            #1;
            memory_request_ready = 1'b0;

            @(negedge clk);
            check_condition(
                memory_response_ready,
                "cache did not become ready for memory response"
            );
            memory_response_data = response_data;
            memory_response_valid = 1'b1;
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
            memory_response_data = 32'd0;
        end
    endtask

    task automatic accept_word_response(
        input logic [15:0] expected_word,
        input tms34020_cache_result_t expected_result,
        input string message
    );
        logic [15:0] held_word;
        tms34020_cache_result_t held_result;
        begin
            @(negedge clk);
            while (!response_valid) begin
                @(negedge clk);
            end
            check_condition(
                response_word == expected_word &&
                response_result == expected_result,
                message
            );
            held_word = response_word;
            held_result = response_result;

            repeat (2) begin
                @(posedge clk);
                #1;
                check_condition(
                    response_valid &&
                    response_word == held_word &&
                    response_result == held_result,
                    "stalled instruction response changed"
                );
            end

            @(negedge clk);
            response_ready = 1'b1;
            @(posedge clk);
            #1;
            response_ready = 1'b0;
        end
    endtask

    task automatic service_refill(
        input logic [31:0] bit_address,
        input tms34020_cache_result_t expected_result,
        input logic [15:0] expected_word
    );
        logic [31:0] subsegment_base;
        logic [1:0] requested_index;
        logic [1:0] refill_index;
        logic [31:0] expected_address;
        logic [31:0] refill_data;
        logic [31:0] present_before_refill;
        integer beat;
        begin
            start_request(bit_address, 1'b0, 1'b0);
            present_before_refill = present_debug;
            subsegment_base = {
                bit_address[31:7],
                7'd0
            };
            requested_index = bit_address[6:5];
            for (beat = 0; beat < 4; beat = beat + 1) begin
                if (beat == 3) begin
                    refill_index = requested_index;
                end else begin
                    refill_index =
                        requested_index + beat[1:0] + 2'd1;
                end
                expected_address = subsegment_base + {
                    25'd0,
                    refill_index,
                    5'd0
                };
                if (beat == 3) begin
                    refill_data = bit_address[4] ?
                        {expected_word, 16'h5A5A} :
                        {16'hA5A5, expected_word};
                end else begin
                    refill_data = 32'h6000_0000 |
                        expected_address;
                end
                accept_memory_read(
                    expected_address,
                    1'b1,
                    1'b1,
                    beat[1:0],
                    refill_data,
                    "cache refill request mismatch"
                );
                if (beat != 3) begin
                    check_condition(
                        present_debug == present_before_refill,
                        "present flag committed before final refill word"
                    );
                end
            end
            accept_word_response(
                expected_word,
                expected_result,
                "refill response mismatch"
            );
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        request_valid = 1'b0;
        request_bit_address = 32'd0;
        cache_disable = 1'b0;
        cache_flush = 1'b0;
        response_ready = 1'b0;
        memory_request_ready = 1'b0;
        memory_response_valid = 1'b0;
        memory_response_data = 32'd0;

        repeat (3) @(posedge clk);
        #1;
        reset = 1'b0;
        check_condition(
            present_debug == 32'd0 &&
            tag_valid_debug == 4'd0 &&
            lru_debug == 8'b00_01_10_11,
            "cache reset metadata mismatch"
        );

        start_request(32'h0000_0000, 1'b0, 1'b0);
        check_condition(
            present_debug == 32'd0 &&
            tag_valid_debug == 4'b1000,
            "segment miss did not allocate initial LRU segment"
        );
        accept_memory_read(
            32'h0000_0020,
            1'b1,
            1'b1,
            2'd0,
            32'h1003_1002,
            "first refill word"
        );
        accept_memory_read(
            32'h0000_0040,
            1'b1,
            1'b1,
            2'd1,
            32'h1005_1004,
            "second refill word"
        );
        accept_memory_read(
            32'h0000_0060,
            1'b1,
            1'b1,
            2'd2,
            32'h1007_1006,
            "third refill word"
        );
        check_condition(
            present_debug == 32'd0,
            "present flag asserted before demand word arrived"
        );
        accept_memory_read(
            32'h0000_0000,
            1'b1,
            1'b1,
            2'd3,
            32'h1001_1000,
            "demand refill word"
        );
        check_condition(
            present_debug == 32'h0100_0000 &&
            lru_debug == 8'b11_00_01_10,
            "completed refill metadata mismatch"
        );
        accept_word_response(
            16'h1000,
            TMS34020_CACHE_SEGMENT_MISS,
            "cold-miss response mismatch"
        );

        start_request(32'h0000_0010, 1'b0, 1'b0);
        check_condition(
            !memory_request_valid,
            "cache hit unexpectedly requested memory"
        );
        accept_word_response(
            16'h1001,
            TMS34020_CACHE_HIT,
            "cache-hit response mismatch"
        );

        start_request(32'h0000_0080, 1'b0, 1'b0);
        accept_memory_read(
            32'h0000_00A0, 1'b1, 1'b1, 2'd0,
            32'h1083_1082, "subsegment refill word 0"
        );
        accept_memory_read(
            32'h0000_00C0, 1'b1, 1'b1, 2'd1,
            32'h1085_1084, "subsegment refill word 1"
        );
        accept_memory_read(
            32'h0000_00E0, 1'b1, 1'b1, 2'd2,
            32'h1087_1086, "subsegment refill word 2"
        );
        accept_memory_read(
            32'h0000_0080, 1'b1, 1'b1, 2'd3,
            32'h1081_1080, "subsegment demand word"
        );
        check_condition(
            present_debug == 32'h0300_0000,
            "subsegment present flags mismatch"
        );
        accept_word_response(
            16'h1080,
            TMS34020_CACHE_SUBSEGMENT_MISS,
            "subsegment-miss response mismatch"
        );

        start_request(32'h0000_0400, 1'b1, 1'b0);
        accept_memory_read(
            32'h0000_0400,
            1'b0,
            1'b0,
            2'd0,
            32'h0000_BEEF,
            "cache-disable bypass request mismatch"
        );
        accept_word_response(
            16'hBEEF,
            TMS34020_CACHE_BYPASS,
            "cache-disable response mismatch"
        );
        check_condition(
            present_debug == 32'h0300_0000 &&
            tag_valid_debug == 4'b1000 &&
            lru_debug == 8'b11_00_01_10,
            "cache disable disturbed metadata"
        );

        start_request(32'h0000_0000, 1'b0, 1'b1);
        check_condition(
            present_debug == 32'd0 &&
            tag_valid_debug == 4'd0 &&
            lru_debug == 8'b00_01_10_11,
            "cache flush did not restore empty metadata"
        );
        accept_memory_read(
            32'h0000_0000,
            1'b0,
            1'b0,
            2'd0,
            32'h0000_CAFE,
            "cache-flush bypass request mismatch"
        );
        accept_word_response(
            16'hCAFE,
            TMS34020_CACHE_BYPASS,
            "cache-flush response mismatch"
        );

        service_refill(
            32'h0000_0040,
            TMS34020_CACHE_SEGMENT_MISS,
            16'h4444
        );
        check_condition(
            present_debug == 32'h0100_0000 &&
            lru_debug == 8'b11_00_01_10,
            "rotated refill metadata mismatch"
        );
        start_request(32'h0000_0050, 1'b0, 1'b0);
        accept_word_response(
            16'hA5A5,
            TMS34020_CACHE_HIT,
            "upper-half cache hit mismatch"
        );

        service_refill(
            32'h0000_0420,
            TMS34020_CACHE_SEGMENT_MISS,
            16'h4420
        );
        check_condition(
            lru_debug == 8'b10_11_00_01,
            "second segment LRU order mismatch"
        );
        service_refill(
            32'h0000_0860,
            TMS34020_CACHE_SEGMENT_MISS,
            16'h8860
        );
        check_condition(
            lru_debug == 8'b01_10_11_00,
            "third segment LRU order mismatch"
        );
        service_refill(
            32'h0000_0C00,
            TMS34020_CACHE_SEGMENT_MISS,
            16'hCC00
        );
        check_condition(
            tag_valid_debug == 4'b1111 &&
            lru_debug == 8'b00_01_10_11,
            "four-segment fill LRU order mismatch"
        );

        start_request(32'h0000_0420, 1'b0, 1'b0);
        accept_word_response(
            16'h4420,
            TMS34020_CACHE_HIT,
            "resident segment hit mismatch"
        );
        check_condition(
            lru_debug == 8'b10_00_01_11,
            "move-to-front LRU update mismatch"
        );

        service_refill(
            32'h0000_1000,
            TMS34020_CACHE_SEGMENT_MISS,
            16'hDEAD
        );
        check_condition(
            lru_debug == 8'b11_10_00_01,
            "least-recently-used replacement mismatch"
        );

        $display("PASS: tms34020 bounded instruction-cache RTL");
        $finish;
    end

endmodule

`default_nettype wire
