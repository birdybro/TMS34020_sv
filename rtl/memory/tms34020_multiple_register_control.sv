`default_nettype none

module tms34020_multiple_register_control (
    input  logic        memory_to_registers_i,
    input  logic [15:0] register_list_i,
    input  logic [3:0]  pointer_index_i,
    input  logic [31:0] pointer_i,
    input  logic        instruction_misaligned_i,
    output logic [15:0] normalized_register_mask_o,
    output logic [4:0]  register_count_o,
    output logic        list_valid_o,
    output logic [31:0] final_pointer_o,
    output logic        n_o,
    output logic [5:0]  visible_states_o,
    output logic [1:0]  hidden_write_states_o
);

    logic [31:0] pointer_delta;
    integer register_index;

    always_comb begin
        normalized_register_mask_o = 16'd0;
        for (register_index = 0; register_index < 16;
             register_index = register_index + 1) begin
            if (memory_to_registers_i) begin
                normalized_register_mask_o[register_index] =
                    register_list_i[register_index];
            end else begin
                normalized_register_mask_o[register_index] =
                    register_list_i[15 - register_index];
            end
        end

        register_count_o = 5'd0;
        for (register_index = 0; register_index < 16;
             register_index = register_index + 1) begin
            register_count_o = register_count_o +
                {4'd0, normalized_register_mask_o[register_index]};
        end
        list_valid_o = (register_count_o != 5'd0) &&
            !normalized_register_mask_o[pointer_index_i];

        pointer_delta = {22'd0, register_count_o, 5'd0};
        n_o = ~pointer_i[31];
        visible_states_o = {1'b0, register_count_o} + 6'd5;
        hidden_write_states_o = 2'd0;
        final_pointer_o = pointer_i + pointer_delta;

        if (!memory_to_registers_i) begin
            final_pointer_o = pointer_i - pointer_delta;
            hidden_write_states_o = 2'd1;
            if (register_count_o == 5'd1) begin
                visible_states_o = 6'd4;
                if (pointer_i[2:0] != 3'd0) begin
                    hidden_write_states_o = 2'd2;
                end
            end else if (pointer_i[2:0] != 3'd0) begin
                visible_states_o =
                    {1'b0, register_count_o} + 6'd7;
                if (register_count_o <= 5'd4) begin
                    hidden_write_states_o = 2'd2;
                end
            end else if (pointer_i[4:3] != 2'd0) begin
                visible_states_o =
                    {1'b0, register_count_o} + 6'd6;
            end else begin
                visible_states_o =
                    {1'b0, register_count_o} + 6'd4;
            end
            if (instruction_misaligned_i) begin
                visible_states_o = visible_states_o + 6'd1;
            end
        end
    end

endmodule

`default_nettype wire
