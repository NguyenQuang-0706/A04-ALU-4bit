module a04_tb;
    logic [7:0] req;
    logic [2:0] index, ref_index;
    logic valid, ref_valid;

    a04_priority_encoder dut(.req(req),.index(index),.valid(valid));
    a04_reference ref_i(.req(req),.index(ref_index),.valid(ref_valid));

    task automatic check(input logic [7:0] r);
        logic [2:0] exp;
        logic ev;
        begin
            req=r; #1;
            ev = |r;
            exp = 3'd0;
            for (int i=0;i<8;i=i+1)
                if (r[i]) exp=i[2:0];

            assert(valid===ev) else $fatal(1,"valid mismatch req=%b",r);
            assert(index===exp) else $fatal(1,"index mismatch req=%b",r);
            assert(ref_valid===ev) else $fatal(1,"reference valid mismatch");
            assert(ref_index===exp) else $fatal(1,"reference index mismatch");
        end
    endtask

    initial begin
        // Charter cases should be applied exactly as specified in the Charter.
        // The cases below are explicit boundary/corner examples.
        check(8'b00000000);
        check(8'b00000001);
        check(8'b00000010);
        check(8'b10000000);
        check(8'b00101000);
        check(8'b10101010);
        check(8'b01000001);
        check(8'b11111111);

        // Exhaustive validation
        for (int unsigned r=0;r<256;r++)
            check(r[7:0]);

        $display("A04 exhaustive validation PASS");
        $finish;
    end
endmodule
