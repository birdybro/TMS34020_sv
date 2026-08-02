`default_nettype none

module tms34020_field_pair_predecrement (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [31:0] source_pointer_i,
    input  logic [31:0] destination_pointer_i,
    input  logic        same_register_i,
    output logic [5:0]  field_size_o,
    output logic [31:0] source_effective_address_o,
    output logic [31:0] destination_effective_address_o,
    output logic [31:0] source_updated_pointer_o,
    output logic [31:0] destination_final_pointer_o
);

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end

        source_updated_pointer_o =
            source_pointer_i - {26'd0, field_size_o};
        source_effective_address_o = source_updated_pointer_o;
        if (same_register_i) begin
            destination_final_pointer_o =
                source_updated_pointer_o - {26'd0, field_size_o};
        end else begin
            destination_final_pointer_o =
                destination_pointer_i - {26'd0, field_size_o};
        end
        destination_effective_address_o = destination_final_pointer_o;
    end

endmodule

`default_nettype wire
