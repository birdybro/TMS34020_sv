`default_nettype none

module tms34020_swap_field (
    input  logic [4:0]  field_size_encoded_i,
    input  logic        sign_extend_i,
    input  logic [4:0]  bit_offset_i,
    input  logic [31:0] memory_word_i,
    input  logic [31:0] register_i,
    output logic        legal_in_word_o,
    output logic [31:0] memory_word_o,
    output logic [31:0] register_o,
    output logic        n_o,
    output logic        z_o,
    output logic        v_o
);

    logic [5:0] field_size;
    logic [5:0] field_end;
    logic [4:0] sign_bit_index;
    logic [31:0] field_mask;
    logic [31:0] positioned_mask;
    logic [31:0] old_field;

    always_comb begin
        field_size = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size = 6'd32;
        end
        field_end = {1'b0, bit_offset_i} + field_size;
        legal_in_word_o = field_end <= 6'd32;
        sign_bit_index = field_size[4:0] - 5'd1;

        field_mask = 32'hFFFF_FFFF;
        if (field_size != 6'd32) begin
            field_mask = 32'hFFFF_FFFF >> (6'd32 - field_size);
        end
        positioned_mask = field_mask << bit_offset_i;
        old_field = (memory_word_i >> bit_offset_i) & field_mask;

        memory_word_o =
            (memory_word_i & ~positioned_mask) |
            ((register_i & field_mask) << bit_offset_i);
        register_o = old_field;
        if (sign_extend_i && old_field[sign_bit_index]) begin
            register_o = old_field | ~field_mask;
        end
        n_o = register_o[31];
        z_o = register_o == 32'd0;
        v_o = 1'b0;
    end

endmodule

`default_nettype wire
