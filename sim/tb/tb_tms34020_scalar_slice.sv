`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_scalar_slice;

    import tms34020_pkg::*;

    logic clk;
    logic reset;
    logic pc_load_valid;
    logic pc_load_ready;
    logic [31:0] pc_load_bit_address;
    logic cache_disable;
    logic cache_flush;
    logic packet_valid;
    logic packet_supported;
    logic packet_blocked;
    tms34020_opcode_id_t packet_opcode_id;
    logic [2:0] packet_length_words;
    logic [79:0] packet_words;
    logic [31:0] packet_start_pc;
    logic commit_accepted;
    logic register_write_enable;
    logic register_write_file;
    logic [3:0] register_write_index;
    logic [31:0] register_write_data;
    logic status_write_enable;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;
    logic [31:0] status;
    logic [31:0] sp;
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
    integer commit_count;
    integer native_request_count;

    tms34020_scalar_slice dut (
        .clk_i(clk),
        .reset_i(reset),
        .pc_load_valid_i(pc_load_valid),
        .pc_load_ready_o(pc_load_ready),
        .pc_load_bit_address_i(pc_load_bit_address),
        .cache_disable_i(cache_disable),
        .cache_flush_i(cache_flush),
        .packet_valid_o(packet_valid),
        .packet_supported_o(packet_supported),
        .packet_blocked_o(packet_blocked),
        .packet_opcode_id_o(packet_opcode_id),
        .packet_length_words_o(packet_length_words),
        .packet_words_o(packet_words),
        .packet_start_pc_o(packet_start_pc),
        .commit_accepted_o(commit_accepted),
        .register_write_enable_o(register_write_enable),
        .register_write_file_o(register_write_file),
        .register_write_index_o(register_write_index),
        .register_write_data_o(register_write_data),
        .status_write_enable_o(status_write_enable),
        .status_write_data_o(status_write_data),
        .status_write_mask_o(status_write_mask),
        .status_o(status),
        .sp_o(sp),
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

    always_ff @(posedge clk) begin
        if (reset) begin
            commit_count <= 0;
            native_request_count <= 0;
        end else if (commit_accepted) begin
            commit_count <= commit_count + 1;
        end
        if (!reset &&
            memory_request_valid &&
            memory_request_ready) begin
            native_request_count <= native_request_count + 1;
        end
    end

    function automatic logic [15:0] memory_word(
        input logic [31:0] bit_address
    );
        begin
            unique case (bit_address)
                32'h0000_0000: memory_word = 16'h0D60;
                32'h0000_0010: memory_word = 16'h0DE0;
                32'h0000_0020: memory_word = 16'h0192;
                32'h0000_0030: memory_word = 16'h6A52;
                32'h0000_0040: memory_word = 16'h0360;
                32'h0000_0050: memory_word = 16'h1420;
                32'h0000_0060: memory_word = 16'h102F;
                32'h0000_0070: memory_word = 16'h41E0;
                32'h0000_0080: memory_word = 16'h0300;
                32'h0000_0090: memory_word = 16'h00F0;
                32'h0000_0100: memory_word = 16'h0BA0;
                32'h0000_0110: memory_word = 16'h5678;
                32'h0000_0120: memory_word = 16'h1234;
                32'h0000_0130: memory_word = 16'h0BC0;
                32'h0000_0140: memory_word = 16'h5678;
                32'h0000_0150: memory_word = 16'h1234;
                32'h0000_0160: memory_word = 16'h0B80;
                32'h0000_0170: memory_word = 16'hFFFF;
                32'h0000_0180: memory_word = 16'hFFFF;
                32'h0000_0190: memory_word = 16'h0C00;
                32'h0000_01A0: memory_word = 16'h0000;
                32'h0000_01B0: memory_word = 16'hFFFF;
                32'h0000_01C0: memory_word = 16'h0C00;
                32'h0000_01D0: memory_word = 16'hFFFF;
                32'h0000_01E0: memory_word = 16'h0001;
                32'h0000_01F0: memory_word = 16'h0B00;
                32'h0000_0200: memory_word = 16'h0001;
                32'h0000_0210: memory_word = 16'h0B20;
                32'h0000_0220: memory_word = 16'h0000;
                32'h0000_0230: memory_word = 16'h7FFF;
                32'h0000_0240: memory_word = 16'h0B00;
                32'h0000_0250: memory_word = 16'hFFFF;
                32'h0000_0260: memory_word = 16'h0BE0;
                32'h0000_0270: memory_word = 16'hFFFE;
                32'h0000_0280: memory_word = 16'h0D00;
                32'h0000_0290: memory_word = 16'hFFFF;
                32'h0000_02A0: memory_word = 16'h7FFF;
                32'h0000_02B0: memory_word = 16'h0B40;
                32'h0000_02C0: memory_word = 16'hFFFE;
                32'h0000_02D0: memory_word = 16'h0B60;
                32'h0000_02E0: memory_word = 16'h0001;
                32'h0000_02F0: memory_word = 16'h0000;
                32'h0000_0300: memory_word = 16'h101F;
                32'h0000_0310: memory_word = 16'h140F;
                32'h0000_0320: memory_word = 16'h1800;
                32'h0000_0330: memory_word = 16'h09C0;
                32'h0000_0340: memory_word = 16'h0000;
                32'h0000_0350: memory_word = 16'h09FF;
                32'h0000_0360: memory_word = 16'h5678;
                32'h0000_0370: memory_word = 16'h1234;
                32'h0000_0380: memory_word = 16'hEDE0;
                32'h0000_0390: memory_word = 16'hEFE0;
                32'h0000_03A0: memory_word = 16'h4E01;
                32'h0000_03B0: memory_word = 16'h4E32;
                32'h0000_03C0: memory_word = 16'h3082;
                32'h0000_03D0: memory_word = 16'h6840;
                32'h0000_03E0: memory_word = 16'h2022;
                32'h0000_03F0: memory_word = 16'h6202;
                32'h0000_0400: memory_word = 16'h2B02;
                32'h0000_0410: memory_word = 16'h6602;
                32'h0000_0420: memory_word = 16'h6002;
                32'h0000_0430: memory_word = 16'h2422;
                32'h0000_0440: memory_word = 16'h6402;
                32'h0000_0450: memory_word = 16'h2C22;
                32'h0000_0460: memory_word = 16'h6A43;
                32'h0000_0470: memory_word = 16'h0153;
                32'h0000_0480: memory_word = 16'h0120;
                32'h0000_0500: memory_word = 16'h1820;
                32'h0000_0510: memory_word = 16'h1841;
                32'h0000_0520: memory_word = 16'hE020;
                32'h0000_0530: memory_word = 16'hE201;
                32'h0000_0540: memory_word = 16'h1FE0;
                32'h0000_0550: memory_word = 16'h4A20;
                32'h2468_ACF0: memory_word = 16'h0154;
                default: memory_word = 16'hFFFF;
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

    task automatic serve_immediate_compare_and_commit(
        input logic [31:0] expected_pc,
        input tms34020_opcode_id_t expected_opcode,
        input logic [2:0] expected_length,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input string message
    );
        begin
            serve_word(expected_pc);
            serve_word(expected_pc + 32'd16);
            if (expected_length == 3'd3) begin
                serve_word(expected_pc + 32'd32);
            end
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == expected_opcode &&
                packet_length_words == expected_length &&
                packet_start_pc == expected_pc &&
                packet_words[15:0] == memory_word(expected_pc) &&
                packet_words[31:16] ==
                    memory_word(expected_pc + 32'd16) &&
                (
                    expected_length == 3'd2 ||
                    packet_words[47:32] ==
                        memory_word(expected_pc + 32'd32)
                ) &&
                packet_words[79:48] == 32'd0 &&
                !register_write_enable &&
                status_write_enable &&
                status_write_data == {expected_nczv, 28'd0} &&
                status_write_mask == 32'hF000_0000,
                message
            );
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == 32'd0,
                message
            );
        end
    endtask

    task automatic serve_immediate_arithmetic_and_commit(
        input logic [31:0] expected_pc,
        input tms34020_opcode_id_t expected_opcode,
        input logic [2:0] expected_length,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input string message
    );
        begin
            serve_word(expected_pc);
            serve_word(expected_pc + 32'd16);
            if (expected_length == 3'd3) begin
                serve_word(expected_pc + 32'd32);
            end
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == expected_opcode &&
                packet_length_words == expected_length &&
                packet_start_pc == expected_pc &&
                packet_words[15:0] == memory_word(expected_pc) &&
                packet_words[31:16] ==
                    memory_word(expected_pc + 32'd16) &&
                (
                    expected_length == 3'd2 ||
                    packet_words[47:32] ==
                        memory_word(expected_pc + 32'd32)
                ) &&
                packet_words[79:48] == 32'd0 &&
                register_write_enable &&
                !register_write_file &&
                register_write_index == 4'd0 &&
                register_write_data == expected_register_data &&
                status_write_enable &&
                status_write_data == {expected_nczv, 28'd0} &&
                status_write_mask == 32'hF000_0000,
                message
            );
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == 32'd0,
                message
            );
        end
    endtask

    task automatic serve_immediate_move_and_commit(
        input logic [31:0] expected_pc,
        input tms34020_opcode_id_t expected_opcode,
        input logic [2:0] expected_length,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_n,
        input logic expected_z,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        begin
            serve_word(expected_pc);
            serve_word(expected_pc + 32'd16);
            if (expected_length == 3'd3) begin
                serve_word(expected_pc + 32'd32);
            end
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == expected_opcode &&
                packet_length_words == expected_length &&
                packet_start_pc == expected_pc &&
                packet_words[15:0] == memory_word(expected_pc) &&
                packet_words[31:16] ==
                    memory_word(expected_pc + 32'd16) &&
                (
                    expected_length == 3'd2 ||
                    packet_words[47:32] ==
                        memory_word(expected_pc + 32'd32)
                ) &&
                packet_words[79:48] == 32'd0 &&
                register_write_enable &&
                register_write_file == expected_register_file &&
                register_write_index == expected_register_index &&
                register_write_data == expected_register_data &&
                status_write_enable &&
                status_write_data ==
                    {expected_n, 1'b0, expected_z, 1'b0, 28'd0} &&
                status_write_mask == 32'hB000_0000,
                message
            );
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == expected_sp,
                message
            );
        end
    endtask

    task automatic serve_addxyi_and_commit(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_register_data,
        input logic [3:0] expected_nczv,
        input logic [31:0] expected_status,
        input string message
    );
        begin
            serve_word(expected_pc);
            serve_word(expected_pc + 32'd16);
            serve_word(expected_pc + 32'd32);
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == TMS20_OP_ADDXYI &&
                packet_length_words == 3'd3 &&
                packet_start_pc == expected_pc &&
                packet_words[47:0] == {
                    memory_word(expected_pc + 32'd32),
                    memory_word(expected_pc + 32'd16),
                    memory_word(expected_pc)
                } &&
                packet_words[79:48] == 32'd0 &&
                register_write_enable &&
                !register_write_file &&
                register_write_index == 4'd0 &&
                register_write_data == expected_register_data &&
                status_write_enable &&
                status_write_data == {expected_nczv, 28'd0} &&
                status_write_mask == 32'hF000_0000,
                message
            );
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == 32'd0,
                message
            );
        end
    endtask

    task automatic serve_immediate_and_commit(
        input logic [31:0] expected_pc,
        input tms34020_opcode_id_t expected_opcode,
        input logic [31:0] expected_register_data,
        input logic [31:0] expected_status,
        input string message
    );
        begin
            serve_word(expected_pc);
            serve_word(expected_pc + 32'd16);
            serve_word(expected_pc + 32'd32);
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == expected_opcode &&
                packet_length_words == 3'd3 &&
                packet_start_pc == expected_pc &&
                packet_words[47:0] == {
                    memory_word(expected_pc + 32'd32),
                    memory_word(expected_pc + 32'd16),
                    memory_word(expected_pc)
                } &&
                packet_words[79:48] == 32'd0 &&
                register_write_enable &&
                !register_write_file &&
                register_write_index == 4'd0 &&
                register_write_data == expected_register_data &&
                status_write_enable &&
                status_write_data ==
                    {2'd0, expected_register_data == 32'd0, 29'd0} &&
                status_write_mask == 32'h2000_0000,
                message
            );
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == 32'd0,
                message
            );
        end
    endtask

    task automatic apply_reset;
        begin
            @(negedge clk);
            reset = 1'b1;
            repeat (2) @(posedge clk);
            @(negedge clk);
            reset = 1'b0;
            #1;
            check_condition(
                pc_load_ready &&
                status == TMS34020_ST_RESET &&
                sp == 32'd0 &&
                commit_count == 0 &&
                native_request_count == 0,
                "scalar slice reset state"
            );
        end
    endtask

    task automatic serve_long_word(
        input logic [31:0] expected_address,
        input logic [1:0] expected_sequence
    );
        begin
            while (!memory_request_valid) begin
                @(posedge clk);
                #1;
            end
            check_condition(
                memory_request_bit_address == expected_address &&
                memory_request_width_32 &&
                memory_request_cache_fill &&
                memory_request_sequence_index == expected_sequence,
                "scalar slice cache-refill request"
            );
            @(posedge clk);
            #1;
            while (!memory_response_ready) begin
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            memory_response_data = memory_long_word(expected_address);
            memory_response_completion = TMS34020_MEMORY_SUCCESS;
            memory_response_valid = 1'b1;
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
        end
    endtask

    task automatic load_pc(input logic [31:0] bit_address);
        begin
            @(negedge clk);
            check_condition(pc_load_ready, "scalar slice PC load ready");
            pc_load_bit_address = bit_address;
            pc_load_valid = 1'b1;
            @(posedge clk);
            #1;
            pc_load_valid = 1'b0;
        end
    endtask

    task automatic serve_word(input logic [31:0] expected_address);
        begin
            while (!memory_request_valid) begin
                @(posedge clk);
                #1;
            end
            check_condition(
                memory_request_bit_address == expected_address &&
                !memory_request_width_32 &&
                !memory_request_cache_fill &&
                memory_request_sequence_index == 2'd0,
                "scalar slice bypass request"
            );
            @(posedge clk);
            #1;
            while (!memory_response_ready) begin
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            memory_response_data = {
                16'd0,
                memory_word(expected_address)
            };
            memory_response_completion = TMS34020_MEMORY_SUCCESS;
            memory_response_valid = 1'b1;
            @(posedge clk);
            #1;
            memory_response_valid = 1'b0;
        end
    endtask

    task automatic serve_and_commit(
        input logic [31:0] expected_pc,
        input tms34020_opcode_id_t expected_opcode,
        input logic expected_register_write,
        input logic expected_register_file,
        input logic [3:0] expected_register_index,
        input logic [31:0] expected_register_data,
        input logic expected_status_write,
        input logic [31:0] expected_status_data,
        input logic [31:0] expected_status_mask,
        input logic [31:0] expected_status,
        input logic [31:0] expected_sp,
        input string message
    );
        begin
            serve_word(expected_pc);
            wait (commit_accepted);
            check_condition(
                packet_valid &&
                packet_supported &&
                !packet_blocked &&
                packet_opcode_id == expected_opcode &&
                packet_length_words == 3'd1 &&
                packet_start_pc == expected_pc &&
                packet_words[15:0] == memory_word(expected_pc) &&
                register_write_enable == expected_register_write &&
                status_write_enable == expected_status_write,
                message
            );
            if (expected_register_write) begin
                check_condition(
                    register_write_file == expected_register_file &&
                    register_write_index == expected_register_index &&
                    register_write_data == expected_register_data,
                    message
                );
            end
            if (expected_status_write) begin
                check_condition(
                    status_write_data == expected_status_data &&
                    status_write_mask == expected_status_mask,
                    message
                );
            end
            @(posedge clk);
            #1;
            check_condition(
                !commit_accepted &&
                status == expected_status &&
                sp == expected_sp,
                message
            );
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc_load_valid = 1'b0;
        pc_load_bit_address = 32'd0;
        cache_disable = 1'b1;
        cache_flush = 1'b0;
        memory_request_ready = 1'b1;
        memory_response_valid = 1'b0;
        memory_response_data = 32'd0;
        memory_response_completion = TMS34020_MEMORY_SUCCESS;
        fault_resume = 1'b0;
        fault_abort = 1'b0;

        apply_reset();
        load_pc(32'd0);

        serve_and_commit(
            32'h00, TMS20_OP_EINT,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0020_0000, 32'h0020_0000,
            32'h0020_0010, 32'd0,
            "scalar EINT commit"
        );
        serve_and_commit(
            32'h10, TMS20_OP_SETC,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h4000_0000, 32'h4000_0000,
            32'h4020_0010, 32'd0,
            "scalar SETC commit"
        );
        serve_and_commit(
            32'h20, TMS20_OP_GETST,
            1'b1, 1'b1, 4'd2, 32'h4020_0010,
            1'b0, 32'd0, 32'd0,
            32'h4020_0010, 32'd0,
            "scalar GETST commit"
        );
        serve_and_commit(
            32'h30, TMS20_OP_LMO,
            1'b1, 1'b1, 4'd2, 32'd1,
            1'b1, 32'd0, 32'h2000_0000,
            32'h4020_0010, 32'd0,
            "scalar LMO observes prior GETST"
        );
        serve_and_commit(
            32'h40, TMS20_OP_DINT,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'd0, 32'h0020_0000,
            32'h4000_0010, 32'd0,
            "scalar DINT preserves carry set before LMO"
        );
        serve_and_commit(
            32'h50, TMS20_OP_SUBK,
            1'b1, 1'b0, 4'd0, 32'hFFFF_FFFF,
            1'b1, 32'hC000_0000, 32'hF000_0000,
            32'hC000_0010, 32'd0,
            "scalar SUBK/DEC A0 commit"
        );
        serve_and_commit(
            32'h60, TMS20_OP_ADDK,
            1'b1, 1'b0, 4'd15, 32'd1,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd1,
            "scalar ADDK/INC shared SP"
        );
        serve_and_commit(
            32'h70, TMS20_OP_ADD,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h6000_0000, 32'hF000_0000,
            32'h6000_0010, 32'd1,
            "scalar ADD observes A0 and SP"
        );
        serve_and_commit(
            32'h80, TMS20_OP_NOP,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h6000_0010, 32'd1,
            "scalar NOP commit"
        );
        check_condition(commit_count == 9, "nine scalar commits");

        serve_word(32'h90);
        wait (packet_blocked);
        check_condition(
            packet_valid &&
            !packet_supported &&
            packet_opcode_id == TMS20_OP_BLMOVE &&
            packet_length_words == 3'd1 &&
            !commit_accepted &&
            !register_write_enable &&
            !status_write_enable,
            "unsupported one-word packet is blocked"
        );
        repeat (3) begin
            @(posedge clk);
            #1;
            check_condition(
                packet_blocked &&
                commit_count == 9 &&
                status == 32'h6000_0010 &&
                sp == 32'd1,
                "blocked one-word packet cannot mutate state"
            );
        end

        apply_reset();
        load_pc(32'h100);
        serve_immediate_and_commit(
            32'h100, TMS20_OP_ORI,
            32'h1234_5678, 32'h0000_0010,
            "scalar ORI packet commit"
        );
        serve_immediate_and_commit(
            32'h130, TMS20_OP_XORI,
            32'd0, 32'h2000_0010,
            "scalar XORI observes ORI"
        );
        serve_immediate_and_commit(
            32'h160, TMS20_OP_ANDNI,
            32'd0, 32'h2000_0010,
            "scalar ANDNI packet commit"
        );
        check_condition(
            commit_count == 3,
            "three immediate-logical packet commits"
        );

        serve_addxyi_and_commit(
            32'h190, 32'hFFFF_0000, 4'b1100,
            32'hC000_0010,
            "scalar ADDXYI packet commit"
        );
        serve_addxyi_and_commit(
            32'h1C0, 32'h0000_FFFF, 4'b0011,
            32'h3000_0010,
            "scalar ADDXYI observes prior result"
        );
        check_condition(
            commit_count == 5,
            "five three-word packet commits"
        );

        serve_immediate_arithmetic_and_commit(
            32'h1F0, TMS20_OP_ADDI_W, 3'd2,
            32'h0001_0000, 4'b0000, 32'h0000_0010,
            "scalar ADDI.W packet commit"
        );
        serve_immediate_arithmetic_and_commit(
            32'h210, TMS20_OP_ADDI_L, 3'd3,
            32'h8000_0000, 4'b1001, 32'h9000_0010,
            "scalar ADDI.L observes ADDI.W"
        );
        serve_immediate_arithmetic_and_commit(
            32'h240, TMS20_OP_ADDI_W, 3'd2,
            32'h7FFF_FFFF, 4'b0101, 32'h5000_0010,
            "scalar ADDI.W sign extension"
        );
        check_condition(
            commit_count == 8,
            "eight multiword packet commits"
        );

        serve_immediate_arithmetic_and_commit(
            32'h260, TMS20_OP_SUBI_W, 3'd2,
            32'h7FFF_FFFE, 4'b0000, 32'h0000_0010,
            "scalar SUBI.W complemented packet commit"
        );
        serve_immediate_arithmetic_and_commit(
            32'h280, TMS20_OP_SUBI_L, 3'd3,
            32'hFFFF_FFFE, 4'b1101, 32'hD000_0010,
            "scalar SUBI.L observes SUBI.W"
        );
        check_condition(
            commit_count == 10,
            "ten multiword packet commits"
        );

        serve_immediate_compare_and_commit(
            32'h2B0, TMS20_OP_CMPI_W, 3'd2,
            4'b1000, 32'h8000_0010,
            "scalar CMPI.W nondestructive packet commit"
        );
        serve_immediate_compare_and_commit(
            32'h2D0, TMS20_OP_CMPI_L, 3'd3,
            4'b0010, 32'h2000_0010,
            "scalar CMPI.L observes CMPI.W-preserved A0"
        );
        check_condition(
            commit_count == 12,
            "twelve multiword packet commits"
        );

        serve_and_commit(
            32'h300, TMS20_OP_ADDK,
            1'b1, 1'b1, 4'd15, 32'd32,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd32,
            "scalar ADDK encoded-zero shared SP"
        );
        check_condition(
            commit_count == 13,
            "thirteen multiword and constant packet commits"
        );

        serve_and_commit(
            32'h310, TMS20_OP_SUBK,
            1'b1, 1'b0, 4'd15, 32'd0,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'd0,
            "scalar SUBK encoded-zero shared SP"
        );
        check_condition(
            commit_count == 14,
            "fourteen multiword and constant packet commits"
        );

        serve_and_commit(
            32'h320, TMS20_OP_MOVK,
            1'b1, 1'b0, 4'd0, 32'd32,
            1'b0, 32'd0, 32'd0,
            32'h2000_0010, 32'd0,
            "scalar MOVK encoded-zero commit preserves status"
        );
        check_condition(
            commit_count == 15,
            "fifteen multiword and constant packet commits"
        );

        apply_reset();
        load_pc(32'h330);
        serve_immediate_move_and_commit(
            32'h330, TMS20_OP_MOVI_W, 3'd2,
            1'b0, 4'd0, 32'd0, 1'b0, 1'b1,
            32'h2000_0010, 32'd0,
            "scalar MOVI.W zero packet commit"
        );
        serve_immediate_move_and_commit(
            32'h350, TMS20_OP_MOVI_L, 3'd3,
            1'b1, 4'd15, 32'h1234_5678, 1'b0, 1'b0,
            32'h0000_0010, 32'h1234_5678,
            "scalar MOVI.L updates shared SP"
        );
        check_condition(
            commit_count == 2,
            "two immediate-move packet commits"
        );

        serve_and_commit(
            32'h380, TMS20_OP_MOVX,
            1'b1, 1'b0, 4'd0, 32'h0000_5678,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'h1234_5678,
            "scalar MOVX merges shared-SP X into A0"
        );
        serve_and_commit(
            32'h390, TMS20_OP_MOVY,
            1'b1, 1'b0, 4'd0, 32'h1234_5678,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'h1234_5678,
            "scalar MOVY observes MOVX and shared-SP Y"
        );
        check_condition(
            commit_count == 4,
            "four immediate and half-move packet commits"
        );

        serve_and_commit(
            32'h3A0, TMS20_OP_MOVE,
            1'b1, 1'b1, 4'd1, 32'h1234_5678,
            1'b1, 32'd0, 32'hB000_0000,
            32'h0000_0010, 32'h1234_5678,
            "scalar MOVE crosses A0 to B1"
        );
        serve_and_commit(
            32'h3B0, TMS20_OP_MOVE,
            1'b1, 1'b0, 4'd2, 32'h1234_5678,
            1'b1, 32'd0, 32'hB000_0000,
            32'h0000_0010, 32'h1234_5678,
            "scalar MOVE observes B1 and crosses to A2"
        );
        check_condition(
            commit_count == 6,
            "six immediate, half-move, and full-move packet commits"
        );

        serve_and_commit(
            32'h3C0, TMS20_OP_RL_K,
            1'b1, 1'b0, 4'd2, 32'h2345_6781,
            1'b1, 32'h4000_0000, 32'h6000_0000,
            32'h4000_0010, 32'h1234_5678,
            "scalar RL.K rotates prior cross-file MOVE result"
        );
        serve_and_commit(
            32'h3D0, TMS20_OP_RL_R,
            1'b1, 1'b0, 4'd0, 32'h2468_ACF0,
            1'b1, 32'd0, 32'h6000_0000,
            32'h0000_0010, 32'h1234_5678,
            "scalar RL.R observes rotated source low-five count"
        );
        check_condition(
            commit_count == 8,
            "eight move and rotate packet commits"
        );

        serve_and_commit(
            32'h3E0, TMS20_OP_SLA_K,
            1'b1, 1'b0, 4'd2, 32'h468A_CF02,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'h1234_5678,
            "scalar SLA.K shifts prior rotated destination"
        );
        serve_and_commit(
            32'h3F0, TMS20_OP_SLL_R,
            1'b1, 1'b0, 4'd2, 32'hCF02_0000,
            1'b1, 32'd0, 32'h6000_0000,
            32'h0000_0010, 32'h1234_5678,
            "scalar SLL.R uses prior A0 low-five count"
        );
        serve_and_commit(
            32'h400, TMS20_OP_SRA_K,
            1'b1, 1'b0, 4'd2, 32'hFFCF_0200,
            1'b1, 32'h8000_0000, 32'hE000_0000,
            32'h8000_0010, 32'h1234_5678,
            "scalar SRA.K sign-extends and preserves V"
        );
        serve_and_commit(
            32'h410, TMS20_OP_SRL_R,
            1'b1, 1'b0, 4'd2, 32'h0000_FFCF,
            1'b1, 32'd0, 32'h6000_0000,
            32'h8000_0010, 32'h1234_5678,
            "scalar SRL.R preserves N while shifting logically"
        );
        serve_and_commit(
            32'h420, TMS20_OP_SLA_R,
            1'b1, 1'b0, 4'd2, 32'hFFCF_0000,
            1'b1, 32'h9000_0000, 32'hF000_0000,
            32'h9000_0010, 32'h1234_5678,
            "scalar SLA.R detects sign overflow"
        );
        serve_and_commit(
            32'h430, TMS20_OP_SLL_K,
            1'b1, 1'b0, 4'd2, 32'hFF9E_0000,
            1'b1, 32'h4000_0000, 32'h6000_0000,
            32'hD000_0010, 32'h1234_5678,
            "scalar SLL.K preserves N and V"
        );
        serve_and_commit(
            32'h440, TMS20_OP_SRA_R,
            1'b1, 1'b0, 4'd2, 32'hFFFF_FF9E,
            1'b1, 32'h8000_0000, 32'hE000_0000,
            32'h9000_0010, 32'h1234_5678,
            "scalar SRA.R uses two's-complement source count"
        );
        serve_and_commit(
            32'h450, TMS20_OP_SRL_K,
            1'b1, 1'b0, 4'd2, 32'h0000_0001,
            1'b1, 32'h4000_0000, 32'h6000_0000,
            32'hD000_0010, 32'h1234_5678,
            "scalar SRL.K uses two's-complement object count"
        );
        check_condition(
            commit_count == 16,
            "sixteen move, rotate, and shift packet commits"
        );

        serve_and_commit(
            32'h460, TMS20_OP_LMO,
            1'b1, 1'b0, 4'd3, 32'd31,
            1'b1, 32'd0, 32'h2000_0000,
            32'hD000_0010, 32'h1234_5678,
            "scalar LMO observes shifted A2"
        );
        serve_and_commit(
            32'h470, TMS20_OP_GETPC,
            1'b1, 1'b1, 4'd3, 32'h0000_0480,
            1'b0, 32'd0, 32'd0,
            32'hD000_0010, 32'h1234_5678,
            "scalar GETPC uses packet sequential address"
        );
        serve_and_commit(
            32'h480, TMS20_OP_EXGPC,
            1'b1, 1'b0, 4'd0, 32'h0000_0490,
            1'b0, 32'd0, 32'd0,
            32'hD000_0010, 32'h1234_5678,
            "scalar EXGPC commits sequential PC before redirect"
        );
        serve_and_commit(
            32'h2468_ACF0, TMS20_OP_GETPC,
            1'b1, 1'b1, 4'd4, 32'h2468_AD00,
            1'b0, 32'd0, 32'd0,
            32'hD000_0010, 32'h1234_5678,
            "scalar EXGPC redirect reaches GETPC target"
        );
        check_condition(
            commit_count == 20,
            "twenty move, rotate, LMO, and direct-PC packet commits"
        );

        serve_word(32'h2468_AD00);
        wait (packet_blocked);
        check_condition(
            packet_valid &&
            !packet_supported &&
            packet_opcode_id == TMS20_OP_UNCLASSIFIED &&
            packet_length_words == 3'd1 &&
            !commit_accepted &&
            !register_write_enable &&
            !status_write_enable,
            "unclassified packet is blocked"
        );
        repeat (3) begin
            @(posedge clk);
            #1;
            check_condition(
                packet_blocked &&
                commit_count == 20 &&
                status == 32'hD000_0010 &&
                sp == 32'h1234_5678,
                "blocked packet cannot mutate shift sequence"
            );
        end

        check_condition(
            !faulted &&
            !fetch_aborted &&
            cache_present_debug == 32'd0 &&
            cache_lru_debug == 8'b00_01_10_11 &&
            cache_tag_valid_debug == 4'd0,
            "bypass scalar slice leaves cache invalid"
        );

        apply_reset();
        load_pc(32'h500);
        serve_and_commit(
            32'h500, TMS20_OP_MOVK,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd0,
            "scalar MOVK seeds ADDXY destination"
        );
        serve_and_commit(
            32'h510, TMS20_OP_MOVK,
            1'b1, 1'b0, 4'd1, 32'd2,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd0,
            "scalar MOVK seeds ADDXY source"
        );
        serve_and_commit(
            32'h520, TMS20_OP_ADDXY,
            1'b1, 1'b0, 4'd0, 32'd3,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'd0,
            "scalar ADDXY consumes dependent register state"
        );
        serve_and_commit(
            32'h530, TMS20_OP_SUBXY,
            1'b1, 1'b0, 4'd1, 32'h0000_FFFF,
            1'b1, 32'h3000_0000, 32'hF000_0000,
            32'h3000_0010, 32'd0,
            "scalar SUBXY consumes preceding ADDXY result"
        );
        check_condition(
            commit_count == 4,
            "four dependent MOVK and XY arithmetic commits"
        );

        apply_reset();
        load_pc(32'h540);
        serve_word(32'h540);
        wait (packet_blocked);
        check_condition(
            packet_valid &&
            !packet_supported &&
            packet_opcode_id == TMS20_OP_BTST_K &&
            !commit_accepted &&
            !register_write_enable &&
            !status_write_enable &&
            status == TMS34020_ST_RESET,
            "decode-only BTST.K remains atomically blocked"
        );

        apply_reset();
        load_pc(32'h550);
        serve_word(32'h550);
        wait (packet_blocked);
        check_condition(
            packet_valid &&
            !packet_supported &&
            packet_opcode_id == TMS20_OP_BTST_R &&
            !commit_accepted &&
            !register_write_enable &&
            !status_write_enable &&
            status == TMS34020_ST_RESET,
            "decode-only BTST.R remains atomically blocked"
        );

        apply_reset();
        cache_disable = 1'b0;
        load_pc(32'd0);
        serve_long_word(32'h20, 2'd0);
        serve_long_word(32'h40, 2'd1);
        serve_long_word(32'h60, 2'd2);
        serve_long_word(32'h00, 2'd3);
        while (commit_count != 8) begin
            @(posedge clk);
            #1;
        end
        check_condition(
            status == 32'h6000_0010 &&
            sp == 32'd1 &&
            native_request_count == 4 &&
            cache_present_debug != 32'd0 &&
            cache_tag_valid_debug != 4'd0 &&
            !memory_request_valid &&
            !packet_blocked,
            "cache refill feeds eight dependent scalar commits"
        );

        $display("PASS: tms34020 bounded scalar slice");
        $finish;
    end

endmodule

`default_nettype wire
