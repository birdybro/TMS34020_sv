`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_verified_leaves;

    import tms34020_pkg::*;

    logic clk;
    logic reset;

    logic [15:0] decode_word;
    logic decode_valid;
    tms34020_opcode_id_t decode_id;
    logic [2:0] decode_length;

    logic [31:0] add_destination;
    logic [31:0] add_immediate;
    logic [31:0] add_result;
    logic add_n;
    logic add_c;
    logic add_z;
    logic add_v;

    tms34020_binary_op_t binary_operation;
    logic [31:0] binary_source;
    logic [31:0] binary_destination;
    logic binary_carry_or_borrow;
    logic [31:0] binary_result;
    logic [3:0] binary_nczv;
    logic binary_register_write_enable;

    tms34020_logical_op_t logical_operation;
    logic [31:0] logical_source;
    logic [31:0] logical_destination;
    logic [31:0] logical_result;
    logic logical_z;

    logic [31:0] pixel;
    logic [5:0] pixel_size;
    logic [31:0] pixel_result;
    logic pixel_valid;
    logic [3:0] pixel_states;

    logic [4:0] compare_constant;
    logic [31:0] compare_result;
    logic compare_n;
    logic compare_c;
    logic compare_z;
    logic compare_v;

    logic [31:0] rmo_source;
    logic [31:0] rmo_result;
    logic rmo_z;

    tms34020_unary_op_t unary_operation;
    logic [31:0] unary_destination;
    logic unary_borrow;
    logic [31:0] unary_result;
    logic [3:0] unary_nczv;
    logic [3:0] unary_status_write_mask;

    logic [15:0] pixel_size_register;
    logic [15:0] pixel_size_value;
    logic pixel_size_exchange;
    logic [31:0] pixel_size_register_result;
    logic pixel_size_write_enable;
    logic [15:0] pixel_size_write_data;

    logic register_write_enable;
    logic register_write_file;
    logic [3:0] register_write_index;
    logic [31:0] register_write_data;
    logic register_read0_file;
    logic [3:0] register_read0_index;
    logic [31:0] register_read0_data;
    logic register_read1_file;
    logic [3:0] register_read1_index;
    logic [31:0] register_read1_data;
    logic [31:0] sp;

    logic status_write_enable;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;
    logic [31:0] status_value;

    logic [15:0] execute_first_word;
    logic [31:0] execute_source;
    logic [31:0] execute_destination;
    logic [31:0] execute_status;
    logic execute_supported;
    logic execute_register_file;
    logic [3:0] execute_source_index;
    logic [3:0] execute_destination_index;
    logic execute_register_write_enable;
    logic [31:0] execute_register_write_data;
    logic execute_status_write_enable;
    logic [31:0] execute_status_write_data;
    logic [31:0] execute_status_write_mask;

    logic commit_valid;
    logic [15:0] commit_first_word;
    logic commit_supported;
    logic commit_accepted;
    logic commit_register_write_enable;
    logic commit_register_write_file;
    logic [3:0] commit_register_write_index;
    logic [31:0] commit_register_write_data;
    logic commit_status_write_enable;
    logic [31:0] commit_status_write_data;
    logic [31:0] commit_status_write_mask;
    logic [31:0] commit_status;
    logic [31:0] commit_sp;

    tms34020_decode decode_dut (
        .first_word_i(decode_word),
        .valid_o(decode_valid),
        .opcode_id_o(decode_id),
        .length_words_o(decode_length)
    );

    tms34020_addxyi addxyi_dut (
        .destination_i(add_destination),
        .immediate_i(add_immediate),
        .result_o(add_result),
        .status_n_o(add_n),
        .status_c_o(add_c),
        .status_z_o(add_z),
        .status_v_o(add_v)
    );

    tms34020_binary_arithmetic binary_arithmetic_dut (
        .operation_i(binary_operation),
        .source_i(binary_source),
        .destination_i(binary_destination),
        .carry_or_borrow_i(binary_carry_or_borrow),
        .result_o(binary_result),
        .status_nczv_o(binary_nczv),
        .register_write_enable_o(binary_register_write_enable)
    );

    tms34020_logical logical_dut (
        .operation_i(logical_operation),
        .source_i(logical_source),
        .destination_i(logical_destination),
        .result_o(logical_result),
        .status_z_o(logical_z)
    );

    tms34020_pixel_replicate pixel_dut (
        .pixel_i(pixel),
        .pixel_size_i(pixel_size),
        .result_o(pixel_result),
        .valid_o(pixel_valid),
        .machine_states_o(pixel_states)
    );

    tms34020_cmpk cmpk_dut (
        .destination_i(add_destination),
        .encoded_constant_i(compare_constant),
        .compare_result_o(compare_result),
        .status_n_o(compare_n),
        .status_c_o(compare_c),
        .status_z_o(compare_z),
        .status_v_o(compare_v)
    );

    tms34020_rmo rmo_dut (
        .source_i(rmo_source),
        .result_o(rmo_result),
        .status_z_o(rmo_z)
    );

    tms34020_unary unary_dut (
        .operation_i(unary_operation),
        .destination_i(unary_destination),
        .borrow_i(unary_borrow),
        .result_o(unary_result),
        .status_nczv_o(unary_nczv),
        .status_write_mask_o(unary_status_write_mask)
    );

    tms34020_pixel_size_ops pixel_size_ops_dut (
        .register_low_i(pixel_size_register),
        .psize_i(pixel_size_value),
        .exchange_i(pixel_size_exchange),
        .register_result_o(pixel_size_register_result),
        .psize_write_enable_o(pixel_size_write_enable),
        .psize_write_data_o(pixel_size_write_data)
    );

    tms34020_regfile regfile_dut (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(register_write_enable),
        .write_file_i(register_write_file),
        .write_index_i(register_write_index),
        .write_data_i(register_write_data),
        .read0_file_i(register_read0_file),
        .read0_index_i(register_read0_index),
        .read0_data_o(register_read0_data),
        .read1_file_i(register_read1_file),
        .read1_index_i(register_read1_index),
        .read1_data_o(register_read1_data),
        .sp_o(sp)
    );

    tms34020_status status_dut (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(status_write_enable),
        .write_data_i(status_write_data),
        .write_mask_i(status_write_mask),
        .status_o(status_value)
    );

    tms34020_register_execute register_execute_dut (
        .first_word_i(execute_first_word),
        .source_i(execute_source),
        .destination_i(execute_destination),
        .status_i(execute_status),
        .supported_o(execute_supported),
        .register_file_o(execute_register_file),
        .source_index_o(execute_source_index),
        .destination_index_o(execute_destination_index),
        .register_write_enable_o(execute_register_write_enable),
        .register_write_data_o(execute_register_write_data),
        .status_write_enable_o(execute_status_write_enable),
        .status_write_data_o(execute_status_write_data),
        .status_write_mask_o(execute_status_write_mask)
    );

    tms34020_register_commit register_commit_dut (
        .clk_i(clk),
        .reset_i(reset),
        .commit_i(commit_valid),
        .first_word_i(commit_first_word),
        .supported_o(commit_supported),
        .commit_accepted_o(commit_accepted),
        .register_write_enable_o(commit_register_write_enable),
        .register_write_file_o(commit_register_write_file),
        .register_write_index_o(commit_register_write_index),
        .register_write_data_o(commit_register_write_data),
        .status_write_enable_o(commit_status_write_enable),
        .status_write_data_o(commit_status_write_data),
        .status_write_mask_o(commit_status_write_mask),
        .status_o(commit_status),
        .sp_o(commit_sp)
    );

    always #5 clk = ~clk;

    task automatic check_condition(input logic condition, input string message);
        if (!condition) begin
            $display("FAIL: %s", message);
            $fatal(1);
        end
    endtask

    task automatic check_decode(
        input logic [15:0] first_word,
        input tms34020_opcode_id_t expected_id,
        input logic [2:0] expected_length,
        input string message
    );
        decode_word = first_word;
        #1;
        check_condition(
            decode_valid &&
            decode_id == expected_id &&
            decode_length == expected_length,
            message
        );
    endtask

    task automatic check_pixel_replicate(
        input logic [5:0] size,
        input logic [31:0] expected_result,
        input logic [3:0] expected_states,
        input string message
    );
        pixel_size = size;
        #1;
        check_condition(
            pixel_valid &&
            pixel_result == expected_result &&
            pixel_states == expected_states,
            message
        );
    endtask

    task automatic check_unary(
        input tms34020_unary_op_t operation,
        input logic [31:0] destination,
        input logic borrow,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input logic [3:0] expected_write_mask,
        input string message
    );
        unary_operation = operation;
        unary_destination = destination;
        unary_borrow = borrow;
        #1;
        check_condition(
            unary_result == expected_result &&
            unary_nczv == expected_nczv &&
            unary_status_write_mask == expected_write_mask,
            message
        );
    endtask

    task automatic check_binary_arithmetic(
        input tms34020_binary_op_t operation,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic carry_or_borrow,
        input logic [31:0] expected_result,
        input logic [3:0] expected_nczv,
        input logic expected_register_write_enable,
        input string message
    );
        binary_operation = operation;
        binary_source = source;
        binary_destination = destination;
        binary_carry_or_borrow = carry_or_borrow;
        #1;
        check_condition(
            binary_result == expected_result &&
            binary_nczv == expected_nczv &&
            binary_register_write_enable ==
                expected_register_write_enable,
            message
        );
    endtask

    task automatic check_logical(
        input tms34020_logical_op_t operation,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] expected_result,
        input logic expected_z,
        input string message
    );
        logical_operation = operation;
        logical_source = source;
        logical_destination = destination;
        #1;
        check_condition(
            logical_result == expected_result &&
            logical_z == expected_z,
            message
        );
    endtask

    task automatic write_register(
        input logic register_file,
        input logic [3:0] register_index_value,
        input logic [31:0] register_value
    );
        register_write_file = register_file;
        register_write_index = register_index_value;
        register_write_data = register_value;
        register_write_enable = 1'b1;
        @(posedge clk);
        #1;
        register_write_enable = 1'b0;
    endtask

    task automatic write_status(
        input logic [31:0] write_data,
        input logic [31:0] write_mask
    );
        status_write_data = write_data;
        status_write_mask = write_mask;
        status_write_enable = 1'b1;
        @(posedge clk);
        #1;
        status_write_enable = 1'b0;
    endtask

    task automatic check_register_execute(
        input logic [15:0] first_word,
        input logic [31:0] source,
        input logic [31:0] destination,
        input logic [31:0] status,
        input logic expected_supported,
        input logic expected_register_write,
        input logic [31:0] expected_register_data,
        input logic expected_status_write,
        input logic [31:0] expected_status_data,
        input logic [31:0] expected_status_mask,
        input string message
    );
        execute_first_word = first_word;
        execute_source = source;
        execute_destination = destination;
        execute_status = status;
        #1;
        check_condition(
            execute_supported == expected_supported &&
            execute_register_write_enable == expected_register_write &&
            execute_register_write_data == expected_register_data &&
            execute_status_write_enable == expected_status_write &&
            execute_status_write_data == expected_status_data &&
            execute_status_write_mask == expected_status_mask,
            message
        );
    endtask

    task automatic commit_register_instruction(
        input logic [15:0] first_word,
        input logic expected_supported,
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
        commit_first_word = first_word;
        commit_valid = 1'b1;
        #1;
        check_condition(
            commit_supported == expected_supported &&
            commit_accepted == expected_supported &&
            commit_register_write_enable == expected_register_write &&
            commit_status_write_enable == expected_status_write,
            message
        );
        if (expected_register_write) begin
            check_condition(
                commit_register_write_file == expected_register_file &&
                commit_register_write_index == expected_register_index &&
                commit_register_write_data == expected_register_data,
                message
            );
        end
        if (expected_status_write) begin
            check_condition(
                commit_status_write_data == expected_status_data &&
                commit_status_write_mask == expected_status_mask,
                message
            );
        end
        @(posedge clk);
        #1;
        check_condition(
            commit_status == expected_status &&
            commit_sp == expected_sp,
            message
        );
        commit_valid = 1'b0;
        #1;
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        decode_word = 16'd0;
        add_destination = 32'd0;
        add_immediate = 32'd0;
        binary_operation = TMS34020_BINARY_ADD;
        binary_source = 32'd0;
        binary_destination = 32'd0;
        binary_carry_or_borrow = 1'b0;
        logical_operation = TMS34020_LOGICAL_AND;
        logical_source = 32'd0;
        logical_destination = 32'd0;
        pixel = 32'd0;
        pixel_size = 6'd0;
        compare_constant = 5'd0;
        rmo_source = 32'd0;
        unary_operation = TMS34020_UNARY_ABS;
        unary_destination = 32'd0;
        unary_borrow = 1'b0;
        pixel_size_register = 16'd0;
        pixel_size_value = 16'd0;
        pixel_size_exchange = 1'b0;
        register_write_enable = 1'b0;
        register_write_file = 1'b0;
        register_write_index = 4'd0;
        register_write_data = 32'd0;
        register_read0_file = 1'b0;
        register_read0_index = 4'd0;
        register_read1_file = 1'b1;
        register_read1_index = 4'd0;
        status_write_enable = 1'b0;
        status_write_data = 32'd0;
        status_write_mask = 32'd0;
        execute_first_word = 16'd0;
        execute_source = 32'd0;
        execute_destination = 32'd0;
        execute_status = 32'd0;
        commit_valid = 1'b0;
        commit_first_word = 16'd0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;

        check_condition(TMS34020_DATA_WIDTH == 32,
                        "architectural data width constant");
        check_condition(TMS34020_WORD_BITS == 16,
                        "instruction word width constant");
        check_condition(TMS34020_ST_N_BIT == 31 &&
                        TMS34020_ST_C_BIT == 30 &&
                        TMS34020_ST_Z_BIT == 29 &&
                        TMS34020_ST_V_BIT == 28,
                        "status bit positions");
        check_condition(
            TMS34020_ST_IE_BIT == 21 &&
            TMS34020_ST_SS_BIT == 22 &&
            TMS34020_ST_IX_BIT == 25 &&
            TMS34020_ST_BF_BIT == 26,
            "status control and fault bit positions"
        );
        check_condition(TMS34020_ST_RESET == 32'h0000_0010,
                        "status reset constant");
        check_condition(
            TMS34020_ST_RESERVED_MASK == 32'h099F_F000,
            "status reserved-bit mask"
        );
        check_condition(status_value == 32'h0000_0010,
                        "status state reset value");

        write_status(32'hF000_0000, 32'hF000_0000);
        check_condition(status_value == 32'hF000_0010,
                        "status full NCZV update");
        write_status(32'h2000_0000, 32'hB000_0000);
        check_condition(status_value == 32'h6000_0010,
                        "status partial NZV update preserves C");
        write_status(32'd0, 32'h2000_0000);
        check_condition(status_value == 32'h4000_0010,
                        "status Z-only update preserves NCV");
        write_status(32'h0020_0000, 32'h0020_0000);
        check_condition(status_value == 32'h4020_0010,
                        "status IE set without collateral changes");
        write_status(32'd0, 32'h4000_0000);
        check_condition(status_value == 32'h0020_0010,
                        "status carry clear without collateral changes");

        status_write_enable = 1'b1;
        status_write_data = 32'hFFFF_FFFF;
        status_write_mask = 32'hFFFF_FFFF;
        reset = 1'b1;
        @(posedge clk);
        #1;
        check_condition(status_value == 32'h0000_0010,
                        "status reset dominates masked write");
        reset = 1'b0;
        status_write_enable = 1'b0;
        @(posedge clk);
        #1;
        check_condition(status_value == 32'h0000_0010,
                        "status holds without write enable");

        check_register_execute(
            16'h0300, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "register execute NOP"
        );
        check_register_execute(
            16'h0392, 32'd0, 32'hFFFF_FFFF, 32'h4000_0000,
            1'b1, 1'b1, 32'h0000_0001, 1'b1,
            32'd0, 32'hB000_0000,
            "register execute ABS partial flags"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute unary operand selectors"
        );
        check_register_execute(
            16'h03C0, 32'd0, 32'd0, 32'h4000_0000,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'hC000_0000, 32'hF000_0000,
            "register execute NEGB consumes carry as borrow"
        );
        check_register_execute(
            16'h4074, 32'd1, 32'd2, 32'd0,
            1'b1, 1'b1, 32'd3, 1'b1,
            32'd0, 32'hF000_0000,
            "register execute binary ADD"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd3 &&
            execute_destination_index == 4'd4,
            "register execute binary operand selectors"
        );
        check_register_execute(
            16'h4820, 32'd1, 32'd1, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'hF000_0000,
            "register execute nondestructive CMP"
        );
        check_register_execute(
            16'h5020, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hD000_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute AND only writes zero"
        );
        check_register_execute(
            16'h5220, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hF000_0010,
            1'b1, 1'b1, 32'h5555_5555, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute ANDN only clears zero"
        );
        check_register_execute(
            16'h5420, 32'hAAAA_AAAA, 32'h5555_5555,
            32'hF000_0010,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute OR only clears zero"
        );
        check_register_execute(
            16'h5620, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'hD000_0010,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h2000_0000, 32'h2000_0000,
            "register execute XOR only writes zero"
        );
        check_register_execute(
            16'h3400, 32'd0, 32'd32, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h2000_0000, 32'hF000_0000,
            "register execute CMPK"
        );
        check_register_execute(
            16'h7A21, 32'h0000_0010, 32'd0, 32'd0,
            1'b1, 1'b1, 32'd4, 1'b1,
            32'd0, 32'h2000_0000,
            "register execute RMO"
        );
        check_register_execute(
            16'h0320, 32'd0, 32'd0, 32'hF000_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'd0, 32'h4000_0000,
            "register execute CLRC partial status write"
        );
        check_register_execute(
            16'h0DE0, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h4000_0000, 32'h4000_0000,
            "register execute SETC partial status write"
        );
        check_register_execute(
            16'h0360, 32'd0, 32'd0, 32'h0020_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'd0, 32'h0020_0000,
            "register execute DINT partial status write"
        );
        check_register_execute(
            16'h0D60, 32'd0, 32'd0, 32'h0000_0010,
            1'b1, 1'b0, 32'd0, 1'b1,
            32'h0020_0000, 32'h0020_0000,
            "register execute EINT partial status write"
        );
        check_register_execute(
            16'h0192, 32'd0, 32'd0, 32'hF020_0010,
            1'b1, 1'b1, 32'hF020_0010, 1'b0,
            32'd0, 32'd0,
            "register execute GETST"
        );
        check_condition(
            execute_register_file &&
            execute_source_index == 4'd2 &&
            execute_destination_index == 4'd2,
            "register execute GETST operand selector"
        );
        check_register_execute(
            16'h1031, 32'd0, 32'hFFFF_FFFF, 32'd0,
            1'b1, 1'b1, 32'd0, 1'b1,
            32'h6000_0000, 32'hF000_0000,
            "register execute INC carry and zero"
        );
        check_register_execute(
            16'h1421, 32'd0, 32'd0, 32'd0,
            1'b1, 1'b1, 32'hFFFF_FFFF, 1'b1,
            32'hC000_0000, 32'hF000_0000,
            "register execute DEC borrow and negative"
        );
        check_register_execute(
            16'h00F0, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "decoded but unsupported register execute instruction"
        );
        check_register_execute(
            16'h0B80, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "three-word ANDNI cannot enter one-word register execute"
        );
        check_register_execute(
            16'hFFFF, 32'd0, 32'd0, 32'd0,
            1'b0, 1'b0, 32'd0, 1'b0, 32'd0, 32'd0,
            "unclassified register execute instruction"
        );

        commit_register_instruction(
            16'h0D60, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h0020_0000, 32'h0020_0000,
            32'h0020_0010, 32'd0,
            "register commit EINT"
        );
        commit_register_instruction(
            16'h0DE0, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h4000_0000, 32'h4000_0000,
            32'h4020_0010, 32'd0,
            "register commit SETC"
        );
        commit_register_instruction(
            16'h0192, 1'b1,
            1'b1, 1'b1, 4'd2, 32'h4020_0010,
            1'b0, 32'd0, 32'd0,
            32'h4020_0010, 32'd0,
            "register commit GETST B2"
        );
        commit_register_instruction(
            16'h1032, 1'b1,
            1'b1, 1'b1, 4'd2, 32'h4020_0011,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0020_0010, 32'd0,
            "register commit INC reads prior B2"
        );
        commit_register_instruction(
            16'h0360, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'd0, 32'h0020_0000,
            32'h0000_0010, 32'd0,
            "register commit DINT"
        );
        commit_register_instruction(
            16'h1420, 1'b1,
            1'b1, 1'b0, 4'd0, 32'hFFFF_FFFF,
            1'b1, 32'hC000_0000, 32'hF000_0000,
            32'hC000_0010, 32'd0,
            "register commit DEC A0"
        );
        commit_register_instruction(
            16'h0380, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b1, 32'd0, 32'hB000_0000,
            32'h4000_0010, 32'd0,
            "register commit ABS preserves carry"
        );
        commit_register_instruction(
            16'h102F, 1'b1,
            1'b1, 1'b0, 4'd15, 32'd1,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd1,
            "register commit INC shared SP"
        );
        commit_register_instruction(
            16'h41E0, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd2,
            1'b1, 32'd0, 32'hF000_0000,
            32'h0000_0010, 32'd1,
            "register commit ADD reads SP"
        );
        commit_register_instruction(
            16'h4800, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'hF000_0000,
            32'h2000_0010, 32'd1,
            "register commit CMP is nondestructive"
        );
        commit_register_instruction(
            16'h7A01, 1'b1,
            1'b1, 1'b0, 4'd1, 32'd1,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit RMO clears zero"
        );
        commit_register_instruction(
            16'h00F0, 1'b0,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit rejects unsupported BLMOVE"
        );
        commit_register_instruction(
            16'h0300, 1'b1,
            1'b0, 1'b0, 4'd0, 32'd0,
            1'b0, 32'd0, 32'd0,
            32'h0000_0010, 32'd1,
            "register commit accepts NOP without state write"
        );
        commit_register_instruction(
            16'h5020, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit AND reads A1 and A0"
        );
        commit_register_instruction(
            16'h5420, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd1,
            1'b1, 32'd0, 32'h2000_0000,
            32'h0000_0010, 32'd1,
            "register commit OR observes preceding AND"
        );
        commit_register_instruction(
            16'h5620, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit XOR observes preceding OR"
        );
        commit_register_instruction(
            16'h5220, 1'b1,
            1'b1, 1'b0, 4'd0, 32'd0,
            1'b1, 32'h2000_0000, 32'h2000_0000,
            32'h2000_0010, 32'd1,
            "register commit ANDN preserves zero result"
        );

        check_decode(16'h0040, TMS20_OP_IDLE, 3'd1, "IDLE exact decode");
        check_decode(16'h0080, TMS20_OP_MWAIT, 3'd1, "MWAIT exact decode");
        check_decode(16'h0300, TMS20_OP_NOP, 3'd1, "NOP exact decode");
        check_decode(16'h039F, TMS20_OP_ABS, 3'd1, "ABS masked decode");
        check_decode(16'h03BF, TMS20_OP_NEG, 3'd1, "NEG masked decode");
        check_decode(16'h03DF, TMS20_OP_NEGB, 3'd1, "NEGB masked decode");
        check_decode(16'h03FF, TMS20_OP_NOT, 3'd1, "NOT masked decode");
        check_decode(16'h0320, TMS20_OP_CLRC, 3'd1,
                     "CLRC exact decode");
        check_decode(16'h0360, TMS20_OP_DINT, 3'd1,
                     "DINT exact decode");
        check_decode(16'h0D60, TMS20_OP_EINT, 3'd1,
                     "EINT exact decode");
        check_decode(16'h0DE0, TMS20_OP_SETC, 3'd1,
                     "SETC exact decode");
        check_decode(16'h019F, TMS20_OP_GETST, 3'd1,
                     "GETST masked decode");
        check_decode(16'h103F, TMS20_OP_INC, 3'd1,
                     "INC masked decode");
        check_decode(16'h143F, TMS20_OP_DEC, 3'd1,
                     "DEC masked decode");
        check_decode(16'h41FF, TMS20_OP_ADD, 3'd1, "ADD masked decode");
        check_decode(16'h43FF, TMS20_OP_ADDC, 3'd1,
                     "ADDC masked decode");
        check_decode(16'h45FF, TMS20_OP_SUB, 3'd1, "SUB masked decode");
        check_decode(16'h47FF, TMS20_OP_SUBB, 3'd1,
                     "SUBB masked decode");
        check_decode(16'h49FF, TMS20_OP_CMP, 3'd1, "CMP masked decode");
        check_decode(16'h51FF, TMS20_OP_AND, 3'd1, "AND masked decode");
        check_decode(16'h53FF, TMS20_OP_ANDN, 3'd1, "ANDN masked decode");
        check_decode(16'h55FF, TMS20_OP_OR, 3'd1, "OR masked decode");
        check_decode(16'h57FF, TMS20_OP_XOR, 3'd1, "XOR masked decode");
        check_decode(16'h0B9F, TMS20_OP_ANDNI, 3'd3,
                     "ANDNI masked three-word decode");
        check_decode(16'h0BBF, TMS20_OP_ORI, 3'd3,
                     "ORI masked three-word decode");
        check_decode(16'h0BDF, TMS20_OP_XORI, 3'd3,
                     "XORI masked three-word decode");
        check_decode(16'h0273, TMS20_OP_SETCDP, 3'd1,
                     "SETCDP exact decode");
        check_decode(16'h02FB, TMS20_OP_SETCMP, 3'd1,
                     "SETCMP exact decode");
        check_decode(16'h0251, TMS20_OP_SETCSP, 3'd1,
                     "SETCSP exact decode");
        check_decode(16'h080F, TMS20_OP_TRAPL, 3'd2,
                     "TRAPL consumes extension word");
        check_decode(16'h0A00, TMS20_OP_VLCOL, 3'd1, "VLCOL exact decode");
        check_decode(16'h00F3, TMS20_OP_BLMOVE, 3'd1,
                     "BLMOVE masked decode");
        check_decode(16'h0C1E, TMS20_OP_ADDXYI, 3'd3,
                     "ADDXYI masked decode");
        check_decode(16'h029E, TMS20_OP_RPIX, 3'd1, "RPIX masked decode");
        check_decode(16'h37FF, TMS20_OP_CMPK, 3'd1, "CMPK masked decode");
        check_decode(16'h02BF, TMS20_OP_EXGPS, 3'd1,
                     "EXGPS masked decode");
        check_decode(16'h02DF, TMS20_OP_GETPS, 3'd1,
                     "GETPS masked decode");
        check_decode(16'h7BFF, TMS20_OP_RMO, 3'd1, "RMO masked decode");

        decode_word = 16'h080E;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
               "nearby unclassified word must not alias TRAPL");

        add_destination = 32'h0001_0001;
        add_immediate = 32'hFFFF_FFFF;
        #1;
        check_condition(add_result == 32'h0000_0000,
               "ADDXYI independent half addition");
        check_condition({add_n, add_c, add_z, add_v} == 4'b1010,
               "ADDXYI TI-defined NCZV");

        add_destination = 32'h0002_0001;
        add_immediate = 32'h7FFF_7FFF;
        #1;
        check_condition(add_result == 32'h8001_8000, "ADDXYI sign cases");
        check_condition({add_n, add_c, add_z, add_v} == 4'b0101,
               "ADDXYI sign-derived flags");

        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'hFFFF_FFFF, 32'h0000_0001, 1'b0,
            32'h0000_0000, 4'b0110, 1'b1,
            "ADD carry and zero"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'h7FFF_FFFF, 32'h0000_0001, 1'b0,
            32'h8000_0000, 4'b1001, 1'b1,
            "ADD signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADD, 32'hFFFF_FFFF, 32'h8000_0000, 1'b0,
            32'h7FFF_FFFF, 4'b0101, 1'b1,
            "ADD carry with signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADDC, 32'hFFFF_FFFF, 32'hFFFF_FFFF,
            1'b1, 32'hFFFF_FFFF, 4'b1100, 1'b1,
            "ADDC carry input"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_ADDC, 32'h7FFF_FFFF, 32'h0000_0001,
            1'b1, 32'h8000_0001, 4'b1001, 1'b1,
            "ADDC carry across sign"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'h7FFF_FFF2, 32'h7FFF_FFF1, 1'b0,
            32'hFFFF_FFFF, 4'b1100, 1'b1,
            "SUB borrow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'hFFFF_FFFF, 32'h7FFF_FFFF, 1'b0,
            32'h8000_0000, 4'b1101, 1'b1,
            "SUB signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUB, 32'h0000_0001, 32'h8000_0000, 1'b0,
            32'h7FFF_FFFF, 4'b0001, 1'b1,
            "SUB positive overflow result"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0001, 32'h0000_0002,
            1'b1, 32'h0000_0000, 4'b0010, 1'b1,
            "SUBB borrow input to zero"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0002, 32'h0000_0002,
            1'b1, 32'hFFFF_FFFF, 4'b1100, 1'b1,
            "SUBB borrow input underflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_SUBB, 32'h0000_0001, 32'h8000_0001,
            1'b1, 32'h7FFF_FFFF, 4'b0001, 1'b1,
            "SUBB signed overflow"
        );
        check_binary_arithmetic(
            TMS34020_BINARY_CMP, 32'h0000_0001, 32'h0000_0001, 1'b1,
            32'h0000_0000, 4'b0010, 1'b0,
            "CMP nondestructive result indication"
        );

        check_logical(
            TMS34020_LOGICAL_AND,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'd0, 1'b1,
            "AND logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_ANDN,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'h5555_5555, 1'b0,
            "ANDN logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_OR,
            32'hAAAA_AAAA, 32'h5555_5555,
            32'hFFFF_FFFF, 1'b0,
            "OR logical leaf"
        );
        check_logical(
            TMS34020_LOGICAL_XOR,
            32'hFFFF_FFFF, 32'hFFFF_FFFF,
            32'd0, 1'b1,
            "XOR logical leaf"
        );

        add_destination = 32'd0;
        compare_constant = 5'd0;
        #1;
        check_condition(compare_result == 32'hFFFF_FFE0,
                        "CMPK encoded zero means 32");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b1100,
                        "CMPK borrow flags");

        add_destination = 32'h8000_0000;
        compare_constant = 5'd1;
        #1;
        check_condition(compare_result == 32'h7FFF_FFFF,
                        "CMPK subtraction result");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b0001,
                        "CMPK signed overflow");

        rmo_source = 32'd0;
        #1;
        check_condition(rmo_z && rmo_result == 32'd0, "RMO zero source");
        rmo_source = 32'h8000_0000;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd31, "RMO bit 31");
        rmo_source = 32'h0800_0010;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd4, "RMO rightmost bit");

        check_unary(TMS34020_UNARY_ABS, 32'h7FFF_FFFF, 1'b0,
                    32'h7FFF_FFFF, 4'b1000, 4'b1011,
                    "ABS maximum positive");
        check_unary(TMS34020_UNARY_ABS, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0000, 4'b1011,
                    "ABS negative one");
        check_unary(TMS34020_UNARY_ABS, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1001, 4'b1011,
                    "ABS minimum negative overflow");
        check_unary(TMS34020_UNARY_ABS, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0000, 4'b1011,
                    "ABS minimum negative plus one");
        check_unary(TMS34020_UNARY_ABS, 32'h0000_0001, 1'b0,
                    32'h0000_0001, 4'b1000, 4'b1011,
                    "ABS positive one");
        check_unary(TMS34020_UNARY_ABS, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1011,
                    "ABS zero");
        check_unary(TMS34020_UNARY_ABS, 32'hFFFA_0011, 1'b0,
                    32'h0005_FFEF, 4'b0000, 4'b1011,
                    "ABS TI nontrivial negative example");

        check_unary(TMS34020_UNARY_NEG, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1111,
                    "NEG zero");
        check_unary(TMS34020_UNARY_NEG, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAB, 4'b1100, 4'b1111,
                    "NEG alternating bits");
        check_unary(TMS34020_UNARY_NEG, 32'h7FFF_FFFF, 1'b0,
                    32'h8000_0001, 4'b1100, 4'b1111,
                    "NEG maximum positive");
        check_unary(TMS34020_UNARY_NEG, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1101, 4'b1111,
                    "NEG minimum negative overflow");
        check_unary(TMS34020_UNARY_NEG, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEG minimum negative plus one");
        check_unary(TMS34020_UNARY_NEG, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0100, 4'b1111,
                    "NEG negative one");

        check_unary(TMS34020_UNARY_NEGB, 32'h0000_0000, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b1111,
                    "NEGB zero without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h0000_0000, 1'b1,
                    32'hFFFF_FFFF, 4'b1100, 4'b1111,
                    "NEGB zero with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAB, 4'b1100, 4'b1111,
                    "NEGB alternating without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h5555_5555, 1'b1,
                    32'hAAAA_AAAA, 4'b1100, 4'b1111,
                    "NEGB alternating with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h7FFF_FFFF, 1'b0,
                    32'h8000_0001, 4'b1100, 4'b1111,
                    "NEGB maximum positive without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h7FFF_FFFF, 1'b1,
                    32'h8000_0000, 4'b1100, 4'b1111,
                    "NEGB maximum positive with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0000, 1'b0,
                    32'h8000_0000, 4'b1101, 4'b1111,
                    "NEGB minimum negative without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0000, 1'b1,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEGB minimum negative with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0001, 1'b0,
                    32'h7FFF_FFFF, 4'b0100, 4'b1111,
                    "NEGB negative near minimum without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'h8000_0001, 1'b1,
                    32'h7FFF_FFFE, 4'b0100, 4'b1111,
                    "NEGB negative near minimum with borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0001, 4'b0100, 4'b1111,
                    "NEGB negative one without borrow");
        check_unary(TMS34020_UNARY_NEGB, 32'hFFFF_FFFF, 1'b1,
                    32'h0000_0000, 4'b0110, 4'b1111,
                    "NEGB negative one with borrow");

        check_unary(TMS34020_UNARY_NOT, 32'h0000_0000, 1'b0,
                    32'hFFFF_FFFF, 4'b0000, 4'b0010,
                    "NOT zero");
        check_unary(TMS34020_UNARY_NOT, 32'h5555_5555, 1'b0,
                    32'hAAAA_AAAA, 4'b0000, 4'b0010,
                    "NOT alternating bits");
        check_unary(TMS34020_UNARY_NOT, 32'hFFFF_FFFF, 1'b0,
                    32'h0000_0000, 4'b0010, 4'b0010,
                    "NOT all ones");
        check_unary(TMS34020_UNARY_NOT, 32'h8000_0000, 1'b0,
                    32'h7FFF_FFFF, 4'b0000, 4'b0010,
                    "NOT minimum negative");

        pixel_size_register = 16'h0001;
        pixel_size_value = 16'd8;
        pixel_size_exchange = 1'b0;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            !pixel_size_write_enable &&
            pixel_size_write_data == 16'd0,
            "GETPS data path"
        );
        pixel_size_exchange = 1'b1;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            pixel_size_write_enable &&
            pixel_size_write_data == 16'd1,
            "EXGPS exchange data path"
        );

        pixel = 32'h89AB_CDEF;
        check_pixel_replicate(6'd1, 32'hFFFF_FFFF, 4'd8, "RPIX size 1");
        check_pixel_replicate(6'd2, 32'hFFFF_FFFF, 4'd7, "RPIX size 2");
        check_pixel_replicate(6'd4, 32'hFFFF_FFFF, 4'd6, "RPIX size 4");
        check_pixel_replicate(6'd8, 32'hEFEF_EFEF, 4'd5, "RPIX size 8");
        check_pixel_replicate(6'd16, 32'hCDEF_CDEF, 4'd4, "RPIX size 16");
        check_pixel_replicate(6'd32, 32'h89AB_CDEF, 4'd2, "RPIX size 32");

        pixel_size = 6'd3;
        #1;
        check_condition(!pixel_valid && pixel_states == 4'd0,
               "RPIX rejects reserved size");

        write_register(1'b0, 4'd2, 32'h1234_5678);
        register_read0_file = 1'b0;
        register_read0_index = 4'd2;
        #1;
        check_condition(register_read0_data == 32'h1234_5678, "A2 write/read");

        write_register(1'b1, 4'd2, 32'hCAFE_BABE);
        register_read1_file = 1'b1;
        register_read1_index = 4'd2;
        #1;
        check_condition(register_read1_data == 32'hCAFE_BABE, "B2 write/read");
        check_condition(register_read0_data == 32'h1234_5678,
               "A/B physical files remain distinct");

        write_register(1'b0, 4'd15, 32'h1020_3040);
        register_read0_file = 1'b0;
        register_read0_index = 4'd15;
        register_read1_file = 1'b1;
        register_read1_index = 4'd15;
        #1;
        check_condition(register_read0_data == 32'h1020_3040,
               "A15 reads shared SP");
        check_condition(register_read1_data == 32'h1020_3040,
               "B15 reads shared SP");
        check_condition(sp == 32'h1020_3040, "SP output");

        $display("PASS: tms34020 verified leaf RTL");
        $finish;
    end

endmodule

`default_nettype wire
