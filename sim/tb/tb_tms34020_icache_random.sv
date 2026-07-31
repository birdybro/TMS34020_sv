`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_icache_random;

    import tms34020_pkg::*;

    localparam logic [1:0] FORCE_NONE         = 2'd0;
    localparam logic [1:0] FORCE_RETRY        = 2'd1;
    localparam logic [1:0] FORCE_FAULT_RESUME = 2'd2;
    localparam logic [1:0] FORCE_FAULT_ABORT  = 2'd3;

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

    logic [31:0] rng_state;
    logic [31:0] initial_seed;
    logic fetch_forced_used;
    integer fetch_perturbation_count;

    integer fetch_count;
    integer response_count;
    integer aborted_fetch_count;
    integer native_request_count;
    integer retry_count;
    integer fault_count;
    integer abort_count;
    integer hit_count;
    integer miss_count;
    integer bypass_count;

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

    function automatic logic [31:0] xorshift32(
        input logic [31:0] value
    );
        logic [31:0] shifted;
        begin
            shifted = value ^ (value << 13);
            shifted = shifted ^ (shifted >> 17);
            shifted = shifted ^ (shifted << 5);
            xorshift32 = shifted == 32'd0 ?
                32'h1BAD_F00D :
                shifted;
        end
    endfunction

    function automatic logic [15:0] memory_word(
        input logic [31:0] bit_address
    );
        begin
            memory_word =
                16'h5A00 ^
                bit_address[15:0] ^
                bit_address[31:16];
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
            $display(
                "FAIL: seed=%08x %s",
                initial_seed,
                message
            );
            $fatal(1);
        end
    endtask

    task automatic next_random(output logic [31:0] value);
        begin
            rng_state = xorshift32(rng_state);
            value = rng_state;
        end
    endtask

    task automatic next_random_5(output logic [4:0] value);
        begin
            rng_state = xorshift32(rng_state);
            value = rng_state[4:0];
        end
    endtask

    task automatic next_random_2(output logic [1:0] value);
        begin
            rng_state = xorshift32(rng_state);
            value = rng_state[1:0];
        end
    endtask

    task automatic send_memory_completion(
        input tms34020_memory_completion_t completion,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            memory_response_completion = completion;
            memory_response_data = data;
            memory_response_valid = 1'b1;
            #1;
            check_condition(
                memory_response_ready,
                "native completion was not accepted"
            );
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
            memory_response_completion = TMS34020_MEMORY_SUCCESS;
            memory_response_data = 32'd0;
        end
    endtask

    task automatic service_native_request(
        input logic [1:0] forced_mode,
        output logic aborted
    );
        logic [4:0] random_value;
        logic [31:0] held_address;
        logic held_width_32;
        logic held_cache_fill;
        logic [1:0] held_sequence;
        logic abort_this_fault;
        tms34020_memory_completion_t completion;
        integer stall_cycles;
        integer response_delay_cycles;
        integer fault_hold_cycles;
        begin
            aborted = 1'b0;
            held_address = memory_request_bit_address;
            held_width_32 = memory_request_width_32;
            held_cache_fill = memory_request_cache_fill;
            held_sequence = memory_request_sequence_index;
            check_condition(
                memory_request_valid,
                "native service started without a request"
            );
            check_condition(
                (held_width_32 && held_cache_fill) ||
                (!held_width_32 && !held_cache_fill),
                "native width and traffic class disagree"
            );
            if (!held_width_32) begin
                check_condition(
                    held_sequence == 2'd0,
                    "bypass request has nonzero sequence index"
                );
            end

            next_random_5(random_value);
            stall_cycles = {30'd0, random_value[1:0]};
            repeat (stall_cycles) begin
                @(posedge clk);
                #1;
                check_condition(
                    memory_request_valid &&
                    memory_request_bit_address == held_address &&
                    memory_request_width_32 == held_width_32 &&
                    memory_request_cache_fill == held_cache_fill &&
                    memory_request_sequence_index == held_sequence,
                    "randomly stalled native request changed"
                );
            end

            @(negedge clk);
            memory_request_ready = 1'b1;
            @(posedge clk);
            #1;
            memory_request_ready = 1'b0;
            native_request_count = native_request_count + 1;

            next_random_5(random_value);
            response_delay_cycles =
                {27'd0, random_value} % 32'd5;
            repeat (response_delay_cycles) begin
                @(posedge clk);
                #1;
                check_condition(
                    memory_response_ready &&
                    !memory_request_valid &&
                    !response_valid,
                    "random native response delay lost wait state"
                );
            end

            abort_this_fault = 1'b0;
            if (forced_mode != FORCE_NONE) begin
                if (!fetch_forced_used) begin
                    fetch_forced_used = 1'b1;
                    case (forced_mode)
                        FORCE_RETRY: begin
                            completion = TMS34020_MEMORY_RETRY;
                        end
                        FORCE_FAULT_RESUME: begin
                            completion = TMS34020_MEMORY_FAULT;
                        end
                        default: begin
                            completion = TMS34020_MEMORY_FAULT;
                            abort_this_fault = 1'b1;
                        end
                    endcase
                end else begin
                    completion = TMS34020_MEMORY_SUCCESS;
                end
            end else if (fetch_perturbation_count >= 12) begin
                completion = TMS34020_MEMORY_SUCCESS;
            end else begin
                next_random_5(random_value);
                case (random_value[4:0])
                    5'd0: completion = TMS34020_MEMORY_RETRY;
                    5'd1: completion = TMS34020_MEMORY_FAULT;
                    5'd2: begin
                        completion = TMS34020_MEMORY_FAULT;
                        abort_this_fault = 1'b1;
                    end
                    default: completion = TMS34020_MEMORY_SUCCESS;
                endcase
            end

            case (completion)
                TMS34020_MEMORY_RETRY: begin
                    fetch_perturbation_count =
                        fetch_perturbation_count + 1;
                    retry_count = retry_count + 1;
                    send_memory_completion(
                        TMS34020_MEMORY_RETRY,
                        32'hDEAD_BEEF
                    );
                    check_condition(
                        !faulted && !response_valid,
                        "random retry completed or faulted lookup"
                    );
                end

                TMS34020_MEMORY_FAULT: begin
                    fetch_perturbation_count =
                        fetch_perturbation_count + 1;
                    fault_count = fault_count + 1;
                    send_memory_completion(
                        TMS34020_MEMORY_FAULT,
                        32'hBAAD_F00D
                    );
                    check_condition(
                        faulted && !memory_request_valid &&
                        !response_valid,
                        "random fault did not quiesce cache"
                    );
                    next_random_5(random_value);
                    fault_hold_cycles = {
                        30'd0,
                        random_value[1:0]
                    };
                    repeat (fault_hold_cycles) begin
                        @(posedge clk);
                        #1;
                        check_condition(
                            faulted,
                            "random fault hold was not stable"
                        );
                    end

                    @(negedge clk);
                    fault_abort = abort_this_fault;
                    fault_resume = !abort_this_fault;
                    @(posedge clk);
                    #1;
                    fault_abort = 1'b0;
                    fault_resume = 1'b0;
                    if (abort_this_fault) begin
                        abort_count = abort_count + 1;
                        check_condition(
                            request_aborted && request_ready &&
                            !faulted && !response_valid,
                            "random fault abort did not cancel lookup"
                        );
                        aborted = 1'b1;
                    end else begin
                        check_condition(
                            !faulted && !request_aborted,
                            "random fault resume did not reissue"
                        );
                    end
                end

                default: begin
                    send_memory_completion(
                        TMS34020_MEMORY_SUCCESS,
                        held_width_32 ?
                            memory_long_word(held_address) :
                            {16'd0, memory_word(held_address)}
                    );
                end
            endcase
        end
    endtask

    task automatic issue_fetch(
        input logic [31:0] bit_address,
        input logic disable_cache,
        input logic flush_cache,
        input logic [1:0] forced_mode
    );
        logic [1:0] random_value;
        logic [15:0] held_response_word;
        tms34020_cache_result_t held_response_result;
        logic aborted;
        integer request_delay_cycles;
        integer response_stall_cycles;
        begin
            fetch_forced_used = 1'b0;
            fetch_perturbation_count = 0;
            next_random_2(random_value);
            request_delay_cycles = {
                30'd0,
                random_value[1:0]
            };
            repeat (request_delay_cycles) @(posedge clk);

            @(negedge clk);
            request_bit_address = bit_address;
            cache_disable = disable_cache;
            cache_flush = flush_cache;
            request_valid = 1'b1;
            while (!request_ready) begin
                @(posedge clk);
                #1;
                check_condition(
                    request_bit_address == bit_address &&
                    cache_disable == disable_cache &&
                    cache_flush == flush_cache,
                    "random lookup request changed while stalled"
                );
                @(negedge clk);
            end
            @(posedge clk);
            #1;
            request_valid = 1'b0;
            cache_disable = 1'b0;
            cache_flush = 1'b0;
            fetch_count = fetch_count + 1;

            forever begin
                @(negedge clk);
                if (memory_request_valid) begin
                    service_native_request(
                        forced_mode,
                        aborted
                    );
                    if (aborted) begin
                        aborted_fetch_count =
                            aborted_fetch_count + 1;
                        return;
                    end
                end else if (response_valid) begin
                    held_response_word = response_word;
                    held_response_result = response_result;
                    if (held_response_word != memory_word(bit_address)) begin
                        $display(
                            "FAIL: seed=%08x address=%08x expected=%04x actual=%04x",
                            initial_seed,
                            bit_address,
                            memory_word(bit_address),
                            held_response_word
                        );
                        $fatal(1);
                    end
                    if (disable_cache || flush_cache) begin
                        check_condition(
                            held_response_result ==
                                TMS34020_CACHE_BYPASS,
                            "cache control request did not bypass"
                        );
                    end else begin
                        check_condition(
                            held_response_result !=
                                TMS34020_CACHE_BYPASS,
                            "enabled cache request unexpectedly bypassed"
                        );
                    end

                    case (held_response_result)
                        TMS34020_CACHE_HIT:
                            hit_count = hit_count + 1;
                        TMS34020_CACHE_BYPASS:
                            bypass_count = bypass_count + 1;
                        default:
                            miss_count = miss_count + 1;
                    endcase

                    next_random_2(random_value);
                    response_stall_cycles = {
                        30'd0,
                        random_value[1:0]
                    };
                    repeat (response_stall_cycles) begin
                        @(posedge clk);
                        #1;
                        check_condition(
                            response_valid &&
                            response_word == held_response_word &&
                            response_result == held_response_result,
                            "randomly stalled lookup response changed"
                        );
                    end
                    @(negedge clk);
                    response_ready = 1'b1;
                    @(posedge clk);
                    #1;
                    response_ready = 1'b0;
                    response_count = response_count + 1;
                    return;
                end else begin
                    check_condition(
                        !faulted,
                        "fault state escaped native service task"
                    );
                end
            end
        end
    endtask

    initial begin
        logic [31:0] random_value;
        logic [31:0] bit_address;
        logic [31:0] previous_address;
        logic disable_cache;
        logic flush_cache;
        integer iteration;

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

        fetch_count = 0;
        response_count = 0;
        aborted_fetch_count = 0;
        native_request_count = 0;
        retry_count = 0;
        fault_count = 0;
        abort_count = 0;
        hit_count = 0;
        miss_count = 0;
        bypass_count = 0;

        rng_state = 32'h3402_0001;
        if ($value$plusargs("SEED=%h", rng_state)) begin
            check_condition(
                rng_state != 32'd0,
                "zero random seed is not supported"
            );
        end
        initial_seed = rng_state;
        previous_address = 32'd0;

        repeat (3) @(posedge clk);
        #1;
        reset = 1'b0;
        check_condition(
            request_ready &&
            present_debug == 32'd0 &&
            tag_valid_debug == 4'd0 &&
            lru_debug == 8'b00_01_10_11,
            "random test reset metadata mismatch"
        );

        issue_fetch(
            32'h0000_0000, 1'b0, 1'b0, FORCE_RETRY
        );
        issue_fetch(
            32'h0000_0000, 1'b0, 1'b0, FORCE_NONE
        );
        issue_fetch(
            32'h0000_0400, 1'b1, 1'b0, FORCE_FAULT_RESUME
        );
        issue_fetch(
            32'h0000_0800, 1'b0, 1'b0, FORCE_FAULT_ABORT
        );

        for (iteration = 0; iteration < 128;
             iteration = iteration + 1) begin
            next_random(random_value);
            if ((iteration % 5) == 0) begin
                bit_address = previous_address;
            end else begin
                bit_address = random_value & 32'h0000_7FF0;
            end
            previous_address = bit_address;

            flush_cache = (iteration % 29) == 28;
            disable_cache =
                !flush_cache &&
                ((iteration % 11) == 10);
            issue_fetch(
                bit_address,
                disable_cache,
                flush_cache,
                FORCE_NONE
            );
        end

        check_condition(
            fetch_count == response_count + aborted_fetch_count,
            "fetch accounting mismatch"
        );
        check_condition(
            abort_count == aborted_fetch_count,
            "fault-abort accounting mismatch"
        );
        check_condition(
            native_request_count > 0 &&
            retry_count > 0 &&
            fault_count > 0 &&
            abort_count > 0,
            "random completion coverage is incomplete"
        );
        check_condition(
            hit_count > 0 &&
            miss_count > 0 &&
            bypass_count > 0,
            "random lookup classification coverage is incomplete"
        );

        $display(
            "PASS: tms34020 cache randomized seed=%08x fetches=%0d native=%0d retries=%0d faults=%0d aborts=%0d",
            initial_seed,
            fetch_count,
            native_request_count,
            retry_count,
            fault_count,
            abort_count
        );
        $finish;
    end

endmodule

`default_nettype wire
