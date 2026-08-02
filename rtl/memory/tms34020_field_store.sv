`default_nettype none

module tms34020_field_store (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [4:0]  bit_offset_i,
    input  logic [31:0] source_i,
    input  logic [31:0] word0_i,
    input  logic [31:0] word1_i,
    output logic [5:0]  field_size_o,
    output logic [2:0]  alignment_case_o,
    output logic [2:0]  hidden_write_states_o,
    output logic        writes_word1_o,
    output logic [31:0] word0_o,
    output logic [31:0] word1_o
);

    logic [6:0] field_end;
    logic start_byte_aligned;
    logic end_byte_aligned;
    logic [63:0] field_mask;
    logic [63:0] positioned_mask;
    logic [63:0] old_window;
    logic [63:0] new_window;

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end
        field_end = {2'd0, bit_offset_i} + {1'd0, field_size_o};
        start_byte_aligned = bit_offset_i[2:0] == 3'd0;
        end_byte_aligned = field_end[2:0] == 3'd0;
        writes_word1_o = field_end > 7'd32;

        if (!writes_word1_o) begin
            alignment_case_o =
                (start_byte_aligned && end_byte_aligned) ? 3'd1 : 3'd2;
        end else if (start_byte_aligned && end_byte_aligned) begin
            alignment_case_o = 3'd3;
        end else if (start_byte_aligned || end_byte_aligned) begin
            alignment_case_o = 3'd4;
        end else begin
            alignment_case_o = 3'd5;
        end

        unique case (alignment_case_o)
            3'd1: hidden_write_states_o = 3'd1;
            3'd2: hidden_write_states_o = 3'd2;
            3'd3: hidden_write_states_o = 3'd2;
            3'd4: hidden_write_states_o = 3'd3;
            default: hidden_write_states_o = 3'd4;
        endcase

        field_mask = 64'h0000_0000_FFFF_FFFF;
        if (field_size_o != 6'd32) begin
            field_mask = (64'd1 << field_size_o) - 64'd1;
        end
        positioned_mask = field_mask << bit_offset_i;
        old_window = {word1_i, word0_i};
        new_window =
            (old_window & ~positioned_mask) |
            (({32'd0, source_i} & field_mask) << bit_offset_i);
        word0_o = new_window[31:0];
        word1_o = new_window[63:32];
    end

endmodule

`default_nettype wire
