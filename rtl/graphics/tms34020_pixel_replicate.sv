`timescale 1ns/1ps
`default_nettype none

module tms34020_pixel_replicate (
    input  logic [31:0] pixel_i,
    input  logic [5:0]  pixel_size_i,
    output logic [31:0] result_o,
    output logic        valid_o,
    output logic [3:0]  machine_states_o
);

    always_comb begin
        result_o = 32'd0;
        valid_o = 1'b1;
        machine_states_o = 4'd0;

        unique case (pixel_size_i)
            6'd1: begin
                result_o = {32{pixel_i[0]}};
                machine_states_o = 4'd8;
            end
            6'd2: begin
                result_o = {16{pixel_i[1:0]}};
                machine_states_o = 4'd7;
            end
            6'd4: begin
                result_o = {8{pixel_i[3:0]}};
                machine_states_o = 4'd6;
            end
            6'd8: begin
                result_o = {4{pixel_i[7:0]}};
                machine_states_o = 4'd5;
            end
            6'd16: begin
                result_o = {2{pixel_i[15:0]}};
                machine_states_o = 4'd4;
            end
            6'd32: begin
                result_o = pixel_i;
                machine_states_o = 4'd2;
            end
            default: begin
                result_o = 32'd0;
                valid_o = 1'b0;
                machine_states_o = 4'd0;
            end
        endcase
    end

endmodule

`default_nettype wire
