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
    tms34020_memory_completion_t memory_response_completion;

    logic faulted;
    logic fault_resume;
    logic fault_abort;
    logic request_aborted;

    logic [31:0] present_debug;
    logic [7:0] lru_debug;
    logic [3:0] tag_valid_debug;
    logic [31:0] present_checkpoint;

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
        .memory_response_completion_i(memory_response_completion),
        .faulted_o(faulted),
        .fault_resume_i(fault_resume),
        .fault_abort_i(fault_abort),
        .request_aborted_o(request_aborted),
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

    task automatic accept_memory_outcome(
        input logic [31:0] expected_bit_address,
        input logic expected_width_32,
        input logic expected_cache_fill,
        input logic [1:0] expected_sequence_index,
        input tms34020_memory_completion_t completion,
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
            repeat (2) begin
                @(posedge clk);
                #1;
                check_condition(
                    memory_response_ready &&
                    !memory_request_valid &&
                    !response_valid,
                    "absent native response did not preserve wait state"
                );
            end

            @(negedge clk);
            check_condition(
                memory_response_ready,
                "cache did not become ready for memory response"
            );
            memory_response_data = response_data;
            memory_response_completion = completion;
            memory_response_valid = 1'b1;
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
            memory_response_data = 32'd0;
            memory_response_completion = TMS34020_MEMORY_SUCCESS;
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
        begin
            accept_memory_outcome(
                expected_bit_address,
                expected_width_32,
                expected_cache_fill,
                expected_sequence_index,
                TMS34020_MEMORY_SUCCESS,
                response_data,
                message
            );
        end
    endtask

    task automatic pulse_fault_control(
        input logic resume_fault,
        input logic abort_fault
    );
        begin
            @(negedge clk);
            fault_resume = resume_fault;
            fault_abort = abort_fault;
            @(posedge clk);
            #1;
            fault_resume = 1'b0;
            fault_abort = 1'b0;
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

    task automatic apply_cache_reset;
        begin
            @(negedge clk);
            reset = 1'b1;
            repeat (2) @(posedge clk);
            #1;
            reset = 1'b0;
            check_condition(
                request_ready &&
                present_debug == 32'd0 &&
                tag_valid_debug == 4'd0 &&
                lru_debug == 8'b00_01_10_11,
                "cache reset task did not restore idle metadata"
            );
        end
    endtask

    task automatic service_refill_with_injected_completion(
        input logic [31:0] bit_address,
        input logic [1:0] injected_sequence,
        input tms34020_memory_completion_t injected_completion,
        input logic [15:0] expected_word
    );
        logic [31:0] subsegment_base;
        logic [1:0] requested_index;
        logic [1:0] refill_index;
        logic [31:0] expected_address;
        logic [31:0] refill_data;
        integer beat;
        begin
            start_request(bit_address, 1'b0, 1'b0);
            subsegment_base = {bit_address[31:7], 7'd0};
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
                    refill_data = {16'hA5A5, expected_word};
                end else begin
                    refill_data = 32'h6000_0000 | expected_address;
                end

                if (beat[1:0] == injected_sequence) begin
                    accept_memory_outcome(
                        expected_address,
                        1'b1,
                        1'b1,
                        beat[1:0],
                        injected_completion,
                        32'hFFFF_FFFF,
                        "injected refill completion mismatch"
                    );
                    check_condition(
                        present_debug == 32'd0 &&
                        !response_valid,
                        "injected completion exposed partial refill"
                    );
                    if (
                        injected_completion == TMS34020_MEMORY_FAULT
                    ) begin
                        check_condition(
                            faulted,
                            "fault injection did not pause cache"
                        );
                        pulse_fault_control(1'b1, 1'b0);
                    end else begin
                        check_condition(
                            !faulted,
                            "retry injection entered fault state"
                        );
                    end
                end

                accept_memory_read(
                    expected_address,
                    1'b1,
                    1'b1,
                    beat[1:0],
                    refill_data,
                    "injected completion did not reissue current beat"
                );
                if (beat != 3) begin
                    check_condition(
                        present_debug == 32'd0,
                        "refill committed present before final beat"
                    );
                end
            end
            accept_word_response(
                expected_word,
                TMS34020_CACHE_SEGMENT_MISS,
                "injected completion refill response mismatch"
            );
        end
    endtask

    task automatic reset_during_refill_beat(
        input logic [1:0] reset_sequence,
        input logic reset_after_request_accept
    );
        logic [31:0] bit_address;
        logic [31:0] expected_address;
        integer beat;
        begin
            bit_address = 32'h0001_0000;
            apply_cache_reset();
            start_request(bit_address, 1'b0, 1'b0);
            for (beat = 0; beat < reset_sequence; beat = beat + 1) begin
                if (beat == 3) begin
                    expected_address = bit_address;
                end else begin
                    expected_address =
                        bit_address + {
                            25'd0,
                            beat[1:0] + 2'd1,
                            5'd0
                        };
                end
                accept_memory_read(
                    expected_address,
                    1'b1,
                    1'b1,
                    beat[1:0],
                    32'h7000_0000 | expected_address,
                    "reset setup refill beat mismatch"
                );
            end

            if (reset_sequence == 2'd3) begin
                expected_address = bit_address;
            end else begin
                expected_address =
                    bit_address + {
                        25'd0,
                        reset_sequence + 2'd1,
                        5'd0
                    };
            end
            @(negedge clk);
            while (!memory_request_valid) begin
                @(negedge clk);
            end
            check_condition(
                memory_request_bit_address == expected_address &&
                memory_request_sequence_index == reset_sequence,
                "reset target refill beat mismatch"
            );

            if (reset_after_request_accept) begin
                memory_request_ready = 1'b1;
                @(posedge clk);
                #1;
                memory_request_ready = 1'b0;
                check_condition(
                    memory_response_ready,
                    "reset target did not enter response wait"
                );
            end

            apply_cache_reset();
            check_condition(
                !memory_request_valid &&
                !memory_response_ready &&
                !response_valid &&
                !faulted,
                "reset left a refill transaction observable"
            );
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
        memory_response_completion = TMS34020_MEMORY_SUCCESS;
        fault_resume = 1'b0;
        fault_abort = 1'b0;
        present_checkpoint = 32'd0;

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

        start_request(32'h0000_1400, 1'b0, 1'b0);
        accept_memory_read(
            32'h0000_1420, 1'b1, 1'b1, 2'd0,
            32'h1403_1402, "retry setup beat"
        );
        accept_memory_outcome(
            32'h0000_1440, 1'b1, 1'b1, 2'd1,
            TMS34020_MEMORY_RETRY,
            32'hDEAD_BEEF, "retry outcome beat"
        );
        check_condition(
            !response_valid && !faulted,
            "retry completed or faulted the instruction request"
        );
        accept_memory_read(
            32'h0000_1440, 1'b1, 1'b1, 2'd1,
            32'h1405_1404, "retried beat did not reissue"
        );
        accept_memory_read(
            32'h0000_1460, 1'b1, 1'b1, 2'd2,
            32'h1407_1406, "post-retry refill beat"
        );
        accept_memory_read(
            32'h0000_1400, 1'b1, 1'b1, 2'd3,
            32'h1401_1400, "post-retry demand beat"
        );
        accept_word_response(
            16'h1400,
            TMS34020_CACHE_SEGMENT_MISS,
            "retry refill response mismatch"
        );

        present_checkpoint = present_debug;
        start_request(32'h0000_1480, 1'b0, 1'b0);
        accept_memory_outcome(
            32'h0000_14A0, 1'b1, 1'b1, 2'd0,
            TMS34020_MEMORY_FAULT,
            32'hFFFF_FFFF, "faulted first refill beat"
        );
        check_condition(
            faulted && !memory_request_valid && !response_valid &&
            !request_ready && present_debug == present_checkpoint,
            "fault did not pause refill without present commit"
        );
        repeat (2) begin
            @(posedge clk);
            #1;
            check_condition(
                faulted && present_debug == present_checkpoint,
                "faulted refill state was not held"
            );
        end
        pulse_fault_control(1'b1, 1'b0);
        check_condition(
            !faulted && !request_aborted,
            "fault resume did not return to native request"
        );
        accept_memory_read(
            32'h0000_14A0, 1'b1, 1'b1, 2'd0,
            32'h1483_1482, "fault resume did not reissue current beat"
        );
        accept_memory_read(
            32'h0000_14C0, 1'b1, 1'b1, 2'd1,
            32'h1485_1484, "fault resume beat 1"
        );
        accept_memory_read(
            32'h0000_14E0, 1'b1, 1'b1, 2'd2,
            32'h1487_1486, "fault resume beat 2"
        );
        accept_memory_read(
            32'h0000_1480, 1'b1, 1'b1, 2'd3,
            32'h1481_1480, "fault resume demand beat"
        );
        accept_word_response(
            16'h1480,
            TMS34020_CACHE_SUBSEGMENT_MISS,
            "fault-resumed refill response mismatch"
        );

        present_checkpoint = present_debug;
        start_request(32'h0000_1500, 1'b0, 1'b0);
        accept_memory_read(
            32'h0000_1520, 1'b1, 1'b1, 2'd0,
            32'h1503_1502, "abort setup beat"
        );
        accept_memory_outcome(
            32'h0000_1540, 1'b1, 1'b1, 2'd1,
            TMS34020_MEMORY_FAULT,
            32'hFFFF_FFFF, "abort fault beat"
        );
        check_condition(
            faulted && present_debug == present_checkpoint,
            "fault exposed partial aborted subsegment"
        );
        pulse_fault_control(1'b0, 1'b1);
        check_condition(
            request_aborted && request_ready && !faulted &&
            present_debug == present_checkpoint,
            "fault abort did not cancel without present commit"
        );
        @(posedge clk);
        #1;
        check_condition(
            !request_aborted,
            "fault abort cancellation was not a one-cycle pulse"
        );
        start_request(32'h0000_1500, 1'b0, 1'b0);
        accept_memory_read(
            32'h0000_1520, 1'b1, 1'b1, 2'd0,
            32'h1503_1502, "aborted refill did not restart at beat zero"
        );
        accept_memory_read(
            32'h0000_1540, 1'b1, 1'b1, 2'd1,
            32'h1505_1504, "restarted refill beat 1"
        );
        accept_memory_read(
            32'h0000_1560, 1'b1, 1'b1, 2'd2,
            32'h1507_1506, "restarted refill beat 2"
        );
        accept_memory_read(
            32'h0000_1500, 1'b1, 1'b1, 2'd3,
            32'h1501_1500, "restarted refill demand beat"
        );
        accept_word_response(
            16'h1500,
            TMS34020_CACHE_SUBSEGMENT_MISS,
            "aborted refill restart response mismatch"
        );

        present_checkpoint = present_debug;
        start_request(32'h0000_1580, 1'b0, 1'b0);
        accept_memory_read(
            32'h0000_15A0, 1'b1, 1'b1, 2'd0,
            32'h1583_1582, "final-fault setup beat 0"
        );
        accept_memory_read(
            32'h0000_15C0, 1'b1, 1'b1, 2'd1,
            32'h1585_1584, "final-fault setup beat 1"
        );
        accept_memory_read(
            32'h0000_15E0, 1'b1, 1'b1, 2'd2,
            32'h1587_1586, "final-fault setup beat 2"
        );
        accept_memory_outcome(
            32'h0000_1580, 1'b1, 1'b1, 2'd3,
            TMS34020_MEMORY_FAULT,
            32'hFFFF_FFFF, "faulted final refill beat"
        );
        check_condition(
            faulted && present_debug == present_checkpoint,
            "final-beat fault committed present flag"
        );
        pulse_fault_control(1'b1, 1'b0);
        accept_memory_read(
            32'h0000_1580, 1'b1, 1'b1, 2'd3,
            32'h1581_1580, "final fault did not resume current beat"
        );
        check_condition(
            present_debug ==
                (present_checkpoint | 32'h0000_0800),
            "resumed final beat did not commit present flag"
        );
        accept_word_response(
            16'h1580,
            TMS34020_CACHE_SUBSEGMENT_MISS,
            "final-fault resume response mismatch"
        );

        start_request(32'h0000_2000, 1'b1, 1'b0);
        accept_memory_outcome(
            32'h0000_2000, 1'b0, 1'b0, 2'd0,
            TMS34020_MEMORY_RETRY,
            32'hFFFF_FFFF, "bypass retry outcome"
        );
        accept_memory_read(
            32'h0000_2000, 1'b0, 1'b0, 2'd0,
            32'h0000_2020, "bypass retry did not reissue"
        );
        accept_word_response(
            16'h2020,
            TMS34020_CACHE_BYPASS,
            "bypass retry response mismatch"
        );

        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_4000, 2'd0, TMS34020_MEMORY_RETRY, 16'h9000
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_4020, 2'd1, TMS34020_MEMORY_RETRY, 16'h9001
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_4040, 2'd2, TMS34020_MEMORY_RETRY, 16'h9002
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_4060, 2'd3, TMS34020_MEMORY_RETRY, 16'h9003
        );

        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_8000, 2'd0, TMS34020_MEMORY_FAULT, 16'hA000
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_8020, 2'd1, TMS34020_MEMORY_FAULT, 16'hA001
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_8040, 2'd2, TMS34020_MEMORY_FAULT, 16'hA002
        );
        apply_cache_reset();
        service_refill_with_injected_completion(
            32'h0000_8060, 2'd3, TMS34020_MEMORY_FAULT, 16'hA003
        );

        apply_cache_reset();
        start_request(32'h0000_C000, 1'b1, 1'b0);
        accept_memory_outcome(
            32'h0000_C000, 1'b0, 1'b0, 2'd0,
            TMS34020_MEMORY_FAULT,
            32'hFFFF_FFFF, "bypass fault-resume outcome"
        );
        check_condition(
            faulted && present_debug == 32'd0,
            "bypass fault changed cache metadata"
        );
        pulse_fault_control(1'b1, 1'b0);
        accept_memory_read(
            32'h0000_C000, 1'b0, 1'b0, 2'd0,
            32'h0000_CAFE, "bypass fault did not resume"
        );
        accept_word_response(
            16'hCAFE,
            TMS34020_CACHE_BYPASS,
            "bypass fault-resume response mismatch"
        );

        start_request(32'h0000_C020, 1'b1, 1'b0);
        accept_memory_outcome(
            32'h0000_C020, 1'b0, 1'b0, 2'd0,
            TMS34020_MEMORY_FAULT,
            32'hFFFF_FFFF, "bypass fault-abort outcome"
        );
        pulse_fault_control(1'b0, 1'b1);
        check_condition(
            request_aborted && request_ready &&
            present_debug == 32'd0,
            "bypass fault abort did not cancel cleanly"
        );

        reset_during_refill_beat(2'd0, 1'b0);
        reset_during_refill_beat(2'd1, 1'b0);
        reset_during_refill_beat(2'd2, 1'b0);
        reset_during_refill_beat(2'd3, 1'b0);
        reset_during_refill_beat(2'd0, 1'b1);
        reset_during_refill_beat(2'd1, 1'b1);
        reset_during_refill_beat(2'd2, 1'b1);
        reset_during_refill_beat(2'd3, 1'b1);

        $display(
            "PASS: tms34020 cache native completion RTL"
        );
        $finish;
    end

endmodule

`default_nettype wire
