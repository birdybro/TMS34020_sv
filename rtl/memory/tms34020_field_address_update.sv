`default_nettype none

module tms34020_field_address_update (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [31:0] pointer_i,
    input  logic        predecrement_i,
    input  logic        postincrement_i,
    output logic [5:0]  field_size_o,
    output logic [31:0] effective_address_o,
    output logic [31:0] final_pointer_o,
    output logic        pointer_write_o,
    output logic        mode_valid_o
);

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end

        mode_valid_o = !(predecrement_i && postincrement_i);
        effective_address_o = pointer_i;
        final_pointer_o = pointer_i;
        pointer_write_o = 1'b0;
        if (mode_valid_o && predecrement_i) begin
            effective_address_o = pointer_i - {26'd0, field_size_o};
            final_pointer_o = effective_address_o;
            pointer_write_o = 1'b1;
        end else if (mode_valid_o && postincrement_i) begin
            final_pointer_o = pointer_i + {26'd0, field_size_o};
            pointer_write_o = 1'b1;
        end
    end

endmodule

`default_nettype wire
