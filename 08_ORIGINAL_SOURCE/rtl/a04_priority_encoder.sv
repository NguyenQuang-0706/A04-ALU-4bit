module a04_priority_encoder (
    input  logic [7:0] req,
    output logic [2:0] index,
    output logic       valid
);
    always_comb begin
        index = 3'd0;
        valid = 1'b1;

        casex (req)
            8'b1xxxxxxx: index = 3'd7;
            8'b01xxxxxx: index = 3'd6;
            8'b001xxxxx: index = 3'd5;
            8'b0001xxxx: index = 3'd4;
            8'b00001xxx: index = 3'd3;
            8'b000001xx: index = 3'd2;
            8'b0000001x: index = 3'd1;
            8'b00000001: index = 3'd0;
            default: begin
                index = 3'd0;
                valid = 1'b0;
            end
        endcase
    end
endmodule
