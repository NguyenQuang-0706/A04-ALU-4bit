module a04_reference (
    input  logic [7:0] req,
    output logic [2:0] index,
    output logic       valid
);
    always_comb begin
        valid = |req;
        index = 3'd0;

        for (int i=0; i<8; i=i+1)
            if (req[i])
                index = i[2:0];
    end
endmodule
