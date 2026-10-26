// =====================================================================
//  A04 - TESTBENCH TU KIEM cho ALU 4-bit tam chuc nang
// ---------------------------------------------------------------------
//  Cau truc ba pha:
//    Pha 1 : 24 ca bat buoc cua Charter muc 8 - 8 phep x 3 cap toan hang
//            (TC-001 .. TC-024)
//    Pha 2 : 6 ca tu xay dung, trong do co ca bien (TC-025 .. TC-030)
//    Pha 3 : QUET VET CAN toan bo 16 x 16 x 8 = 2048 to hop
//
//  Moi vector so khop DUT voi mo hinh chuan a04_reference tren CA BA
//  dau ra (result, cflag, zflag), dong thoi kiem 4 bat bien:
//    INV-3  Z == (result == 0)          - dung cho ca tam phep
//    INV-4  AND/OR/XOR/NOT luon C == 0
//    INV-6  NOT la phep mot ngoi - ket qua khong phu thuoc B
//    INV-8  khong dau ra nao o trang thai X / Z
//  Bat ky sai lech nao cung goi $fatal(1, ...) kem du thong tin truy vet.
//
//  VCD chi ghi cho 30 ca CO TEN. Truoc vong quet vet can co $dumpoff de
//  file song khong phinh to vi 2048 vector khong ai xem tung cai mot.
//
//  Cu phap: tranh cac thu Icarus Verilog 12.0 chua ho tro - khong `bind`,
//  khong `assert property`, khong `string.getc()`, khong nhan sau
//  `always @(...) begin : ten`, khong khai bao bien sau cau lenh trong
//  `initial`, khong gan enum qua `? :`.
// =====================================================================

`timescale 1ns / 1ps

module a04_tb;

    // -----------------------------------------------------------------
    // Bang ma lenh - phai khop tung bit voi RTL va voi mo hinh chuan
    // -----------------------------------------------------------------
    localparam logic [2:0] OP_ADD = 3'b000;
    localparam logic [2:0] OP_SUB = 3'b001;
    localparam logic [2:0] OP_AND = 3'b010;
    localparam logic [2:0] OP_OR  = 3'b011;
    localparam logic [2:0] OP_XOR = 3'b100;
    localparam logic [2:0] OP_NOT = 3'b101;
    localparam logic [2:0] OP_SHL = 3'b110;
    localparam logic [2:0] OP_SHR = 3'b111;

    // -----------------------------------------------------------------
    // Tin hieu kich thich va quan sat
    // -----------------------------------------------------------------
    logic [3:0] a, b;
    logic [2:0] op;

    logic [3:0] r_dut;    // tu DUT - 8 nhanh + mux, mot bo cong dung chung
    logic       c_dut;
    logic       z_dut;

    logic [3:0] r_ref;    // tu REF - tam bieu thuc roi rac
    logic       c_ref;
    logic       z_ref;

    // -----------------------------------------------------------------
    // Bo dem va bien phu - khai bao HET o day, khong khai bao giua
    // than khoi `initial`
    // -----------------------------------------------------------------
    integer n_run;        // so vector da chay
    integer n_mismatch;   // so lan DUT lech REF
    integer n_inv;        // so lan vi pham bat bien
    integer n_named;      // so ca co ten da chay
    integer n_zset;       // so vector co Z = 1
    integer ia, ib, iop;  // bien lap cua vong quet vet can

    logic [3:0] r_nob;    // ket qua nhanh NOT khi ep B = 0 (dung cho INV-6)

    // -----------------------------------------------------------------
    // DUT - ten instance BAT BUOC la `dut`
    // -----------------------------------------------------------------
    a04_alu4 dut (
        .a      (a),
        .b      (b),
        .op     (op),
        .result (r_dut),
        .cflag  (c_dut),
        .zflag  (z_dut)
    );

    // -----------------------------------------------------------------
    // Mo hinh chuan. Ten instance la `ref_i` chu KHONG phai `ref`:
    // `ref` la tu khoa SystemVerilog (doi so truyen tham chieu) nen
    // Icarus tu choi bien dich. Ban goc cua ho so da vap dung loi nay -
    // xem 08_ORIGINAL_SOURCE/PATCHLOG.md.
    // -----------------------------------------------------------------
    a04_reference ref_i (
        .a      (a),
        .b      (b),
        .op     (op),
        .result (r_ref),
        .cflag  (c_ref),
        .zflag  (z_ref)
    );

    // =================================================================
    // Ten phep dang chuoi - dung de in log cho de doc
    // =================================================================
    function automatic string opname(input logic [2:0] o);
        begin
            case (o)
                OP_ADD : opname = "ADD";
                OP_SUB : opname = "SUB";
                OP_AND : opname = "AND";
                OP_OR  : opname = "OR ";
                OP_XOR : opname = "XOR";
                OP_NOT : opname = "NOT";
                OP_SHL : opname = "SHL";
                OP_SHR : opname = "SHR";
                default: opname = "???";
            endcase
        end
    endfunction

    // =================================================================
    // KIEM MOT VECTOR
    // -----------------------------------------------------------------
    // `verbose` = 1 cho ca co ten (in mot dong + so voi gia tri mong
    // doi viet tay), = 0 cho quet vet can.
    // =================================================================
    task automatic check_vector(input string tc, input logic [2:0] vop,
                                input logic [3:0] va, input logic [3:0] vb,
                                input logic [3:0] want_r, input logic want_c,
                                input logic want_z, input bit verbose);
        begin
            a  = va;
            b  = vb;
            op = vop;
            #1;                       // cho logic to hop on dinh

            n_run = n_run + 1;

            // ---- So khop chinh: DUT vs mo hinh chuan, CA BA dau ra ---
            if ((r_dut !== r_ref) || (c_dut !== c_ref) || (z_dut !== z_ref)) begin
                n_mismatch = n_mismatch + 1;
                $display("ERROR %s: op=%s A=%0d B=%0d | DUT(r=%0d C=%b Z=%b) REF(r=%0d C=%b Z=%b)",
                         tc, opname(vop), va, vb, r_dut, c_dut, z_dut,
                         r_ref, c_ref, z_ref);
                $fatal(1, "A04 MISMATCH tai %s: op=%s A=%0d B=%0d DUT(r=%0d,C=%b,Z=%b) REF(r=%0d,C=%b,Z=%b)",
                       tc, opname(vop), va, vb, r_dut, c_dut, z_dut,
                       r_ref, c_ref, z_ref);
            end

            // ---- So voi gia tri mong doi viet tay trong ca co ten ----
            if (verbose) begin
                if ((r_dut !== want_r) || (c_dut !== want_c) || (z_dut !== want_z)) begin
                    n_mismatch = n_mismatch + 1;
                    $fatal(1, "A04 SAI GIA TRI MONG DOI tai %s: op=%s A=%0d B=%0d DUT(r=%0d,C=%b,Z=%b) mong doi(r=%0d,C=%b,Z=%b)",
                           tc, opname(vop), va, vb, r_dut, c_dut, z_dut,
                           want_r, want_c, want_z);
                end
            end

            // ---- INV-8: khong dau ra nao duoc o trang thai X / Z -----
            if ((^r_dut === 1'bx) || (c_dut === 1'bx) || (z_dut === 1'bx)) begin
                n_inv = n_inv + 1;
                $fatal(1, "A04 VI PHAM INV-8 tai %s: op=%s A=%0d B=%0d r=%b C=%b Z=%b",
                       tc, opname(vop), va, vb, r_dut, c_dut, z_dut);
            end

            // ---- INV-3: Z == (result == 0), dung cho CA TAM phep -----
            if (z_dut !== (r_dut == 4'b0000)) begin
                n_inv = n_inv + 1;
                $fatal(1, "A04 VI PHAM INV-3 tai %s: op=%s A=%0d B=%0d result=%0d nhung Z=%b",
                       tc, opname(vop), va, vb, r_dut, z_dut);
            end

            // ---- INV-4: bon phep logic LUON cho C == 0 ---------------
            if (((vop == OP_AND) || (vop == OP_OR) ||
                 (vop == OP_XOR) || (vop == OP_NOT)) && (c_dut !== 1'b0)) begin
                n_inv = n_inv + 1;
                $fatal(1, "A04 VI PHAM INV-4 tai %s: phep logic %s nhung C=%b",
                       tc, opname(vop), c_dut);
            end

            // ---- INV-6: NOT la phep MOT NGOI ------------------------
            // Ep B ve 0 roi tinh lai: ket qua PHAI y nguyen. Bat loi de
            // toan hang B lot vao nhanh NOT.
            if (vop == OP_NOT) begin
                b = 4'b0000;
                #1;
                r_nob = r_dut;
                b = vb;
                #1;
                if (r_dut !== r_nob) begin
                    n_inv = n_inv + 1;
                    $fatal(1, "A04 VI PHAM INV-6 tai %s: NOT A=%0d cho %0d voi B=%0d nhung %0d voi B=0",
                           tc, va, r_dut, vb, r_nob);
                end
            end

            // ---- Thong ke co Z --------------------------------------
            if (z_dut === 1'b1) begin
                n_zset = n_zset + 1;
            end

            if (verbose) begin
                n_named = n_named + 1;
                $display("  %-8s %s A=%2d B=%2d -> result=%2d C=%b Z=%b  PASS",
                         tc, opname(vop), va, vb, r_dut, c_dut, z_dut);
            end
        end
    endtask

    // =================================================================
    // CHUONG TRINH CHINH
    // =================================================================
    initial begin
        // --- Khoi tao: moi khai bao da nam o tren, day chi con lenh ---
        n_run      = 0;
        n_mismatch = 0;
        n_inv      = 0;
        n_named    = 0;
        n_zset     = 0;
        a          = 4'd0;
        b          = 4'd0;
        op         = OP_ADD;

        $dumpfile("a04_waves.vcd");
        $dumpvars(0, a04_tb);

        $display("==============================================================");
        $display("A04 - ALU 4-bit tam chuc nang - TESTBENCH TU KIEM");
        $display("==============================================================");

        // -------------------------------------------------------------
        // PHA 1 - 24 ca bat buoc: 8 phep x 3 cap toan hang
        // -------------------------------------------------------------
        $display("\n[PHA 1] 24 ca bat buoc cua Charter muc 8 (8 phep x 3 cap)");
        check_vector("TC-001", OP_ADD,  4'd0,  4'd0,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-002", OP_ADD,  4'd5,  4'd3,  4'd8,  1'b0, 1'b0, 1);
        check_vector("TC-003", OP_ADD,  4'd9,  4'd7,  4'd0,  1'b1, 1'b1, 1);
        check_vector("TC-004", OP_SUB,  4'd5,  4'd3,  4'd2,  1'b1, 1'b0, 1);
        check_vector("TC-005", OP_SUB,  4'd3,  4'd5, 4'd14,  1'b0, 1'b0, 1);
        check_vector("TC-006", OP_SUB,  4'd7,  4'd7,  4'd0,  1'b1, 1'b1, 1);
        check_vector("TC-007", OP_AND, 4'd12, 4'd10,  4'd8,  1'b0, 1'b0, 1);
        check_vector("TC-008", OP_AND, 4'd15,  4'd0,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-009", OP_AND, 4'd15, 4'd15, 4'd15,  1'b0, 1'b0, 1);
        check_vector("TC-010", OP_OR,  4'd12, 4'd10, 4'd14,  1'b0, 1'b0, 1);
        check_vector("TC-011", OP_OR,   4'd0,  4'd0,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-012", OP_OR,   4'd8,  4'd1,  4'd9,  1'b0, 1'b0, 1);
        check_vector("TC-013", OP_XOR, 4'd12, 4'd10,  4'd6,  1'b0, 1'b0, 1);
        check_vector("TC-014", OP_XOR,  4'd5,  4'd5,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-015", OP_XOR, 4'd15,  4'd0, 4'd15,  1'b0, 1'b0, 1);
        check_vector("TC-016", OP_NOT,  4'd0,  4'd0, 4'd15,  1'b0, 1'b0, 1);
        check_vector("TC-017", OP_NOT, 4'd15,  4'd9,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-018", OP_NOT, 4'd10,  4'd5,  4'd5,  1'b0, 1'b0, 1);
        check_vector("TC-019", OP_SHL,  4'd1,  4'd0,  4'd2,  1'b0, 1'b0, 1);
        check_vector("TC-020", OP_SHL,  4'd8,  4'd0,  4'd0,  1'b1, 1'b1, 1);
        check_vector("TC-021", OP_SHL, 4'd15,  4'd0, 4'd14,  1'b1, 1'b0, 1);
        check_vector("TC-022", OP_SHR,  4'd2,  4'd0,  4'd1,  1'b0, 1'b0, 1);
        check_vector("TC-023", OP_SHR,  4'd1,  4'd0,  4'd0,  1'b1, 1'b1, 1);
        check_vector("TC-024", OP_SHR, 4'd15,  4'd0,  4'd7,  1'b1, 1'b0, 1);

        // -------------------------------------------------------------
        // PHA 2 - 6 ca tu xay dung, trong do co ca bien
        // -------------------------------------------------------------
        $display("\n[PHA 2] 6 ca tu xay dung (Charter doi >= 2, co ca bien)");
        check_vector("TC-025", OP_SUB,  4'd0,  4'd1, 4'd15,  1'b0, 1'b0, 1);
        check_vector("TC-026", OP_ADD, 4'd15, 4'd15, 4'd14,  1'b1, 1'b0, 1);
        check_vector("TC-027", OP_ADD, 4'd15,  4'd1,  4'd0,  1'b1, 1'b1, 1);
        check_vector("TC-028", OP_ADD, 4'd10,  4'd5, 4'd15,  1'b0, 1'b0, 1);
        check_vector("TC-029", OP_SHL,  4'd0,  4'd0,  4'd0,  1'b0, 1'b1, 1);
        check_vector("TC-030", OP_SUB,  4'd8,  4'd8,  4'd0,  1'b1, 1'b1, 1);

        // -------------------------------------------------------------
        // PHA 3 - QUET VET CAN 16 x 16 x 8 = 2048 to hop
        // -------------------------------------------------------------
        // Tat ghi song TRUOC vong nay: 2048 vector khong ai xem tung cai,
        // ma ghi het thi file VCD phinh to vo ich.
        $dumpoff;

        $display("\n[PHA 3] Quet vet can toan bo khong gian dau vao (16 x 16 x 8 = 2048)");
        for (ia = 0; ia < 16; ia = ia + 1) begin
            for (ib = 0; ib < 16; ib = ib + 1) begin
                for (iop = 0; iop < 8; iop = iop + 1) begin
                    check_vector("EXH", iop[2:0], ia[3:0], ib[3:0],
                                 4'd0, 1'b0, 1'b0, 0);
                end
            end
        end
        $display("  Quet vet can: 2048/2048 to hop khop mo hinh chuan.");

        $dumpon;

        // -------------------------------------------------------------
        // TONG KET
        // -------------------------------------------------------------
        $display("\n==============================================================");
        $display("TONG KET: chay=%0d  lech REF=%0d  vi pham bat bien=%0d  (Z=1: %0d vector)",
                 n_run, n_mismatch, n_inv, n_zset);
        $display("          ca co ten=%0d (24 bat buoc + 6 tu xay dung), vet can=2048",
                 n_named);

        if ((n_mismatch == 0) && (n_inv == 0) && (n_run == 2078)) begin
            $display("A04 exhaustive validation PASS - DUT khop REF tren toan bo khong gian dau vao.");
        end else begin
            $display("A04 exhaustive validation FAIL");
            $fatal(1, "A04 FAIL: chay=%0d lech=%0d bat bien=%0d",
                   n_run, n_mismatch, n_inv);
        end
        $display("==============================================================");

        $finish;
    end

endmodule
