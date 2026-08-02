`default_nettype none

module tms34020_field_pair_postincrement (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [31:0] source_pointer_i,
    input  logic [31:0] destination_pointer_i,
    input  logic        same_register_i,
    output logic [5:0]  field_size_o,
    output logic [31:0] source_effective_address_o,
    output logic [31:0] destination_effective_address_o,
    output logic [31:0] source_final_pointer_o,
    output logic [31:0] destination_final_pointer_o
);

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end

        source_effective_address_o = source_pointer_i;
        // For an alias, this is the intermediate value used as the write
        // address. The architectural shared-register result is the second
        // logical update reported on destination_final_pointer_o.
        source_final_pointer_o =
            source_pointer_i + {26'd0, field_size_o};
        if (same_register_i) begin
            destination_effective_address_o = source_final_pointer_o;
            destination_final_pointer_o =
                source_final_pointer_o + {26'd0, field_size_o};
        end else begin
            destination_effective_address_o = destination_pointer_i;
            destination_final_pointer_o =
                destination_pointer_i + {26'd0, field_size_o};
        end
    end

endmodule

`default_nettype wire
