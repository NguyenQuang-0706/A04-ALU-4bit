// =====================================================================
//  A04 — Don vi so hoc logic (ALU) 4-bit tam chuc nang
// ---------------------------------------------------------------------
//  De         : A04 · Nhom A — So hoc to hop
//  Loai mach  : TO HOP THUAN (khong clock, khong reset, 0 flip-flop)
//  Nguon      : Project Charter A04 — muc 1 (boi canh), muc 2 (cau hoi
//               ky thuat), muc 4 (giao dien), muc 8 (ca kiem thu),
//               muc 9 (phan tich rieng), muc 10 (rui ro)
//  Truy vet   : REQ-A04-001 … REQ-A04-023
//
//  KIEN TRUC BAT BUOC — "tinh het roi moi chon"
//  --------------------------------------------
//     a,b --> [ 8 NHANH CHUC NANG tinh SONG SONG, LUON LUON tinh ]
//                 ADD  SUB   <-- DUNG CHUNG MOT BO CONG duy nhat
//                 AND OR XOR NOT
//                 SHL1 SHR1  <-- noi day thuan, 0 cong logic
//                              |
//     op  ----------------> [ BO GHEP KENH 8->1, rong 5 bit ]
//                              |
//                      result[3:0], cflag  -->  zflag = NOR(result)
//
//  BA RANG BUOC KHONG DUOC VI PHAM
//  -------------------------------
//  1. Phep CONG va phep TRU dung CHUNG MOT bo cong ripple 4 tang.
//     Tru = cong bu 2:  A - B = A + (~B) + 1.
//     KHONG duoc viet `sub ? a - b : a + b` — khong duoc thay bang toan
//     tu tat. Viet nhu vay cho cong cu tu do sinh HAI mach so hoc rieng,
//     lam mat dung thu Charter muc 2 cau 1 yeu cau quan sat.
//  2. KHONG duoc viet `a + b`, `a - b`, `a << 1`, `a >> 1` o bat ky dau
//     trong file nay. Cac toan tu do CHI duoc dung trong
//     05_VERIFICATION/golden_model/, noi chung dong vai tro chuan so
//     sanh DOC LAP voi RTL.
//  3. Khong `always_ff`, khong cong `clk`/`rst` => sau tong hop phai co
//     DUNG 0 flip-flop. Charter muc 10: "dau hieu lam dung: 0 o nho".
// =====================================================================

module a04_alu4 (
    input  logic [3:0] a,        // Toan hang A  — Charter muc 4: ui_in[3:0]
    input  logic [3:0] b,        // Toan hang B  — Charter muc 4: ui_in[7:4]
    input  logic [2:0] op,       // Ma phep      — Charter muc 4: uio_in[2:0]
    output logic [3:0] result,   // Ket qua      — Charter muc 4: uo_out[3:0]
    output logic       cflag,    // Co C         — Charter muc 4: uo_out[5]
    output logic       zflag     // Co Z         — Charter muc 4: uo_out[4]
);

    // =================================================================
    // 0. BANG MA LENH — ban sao duy nhat, moi tai lieu phai trich tu day
    // =================================================================
    localparam logic [2:0] OP_ADD = 3'b000;   // result = A + B
    localparam logic [2:0] OP_SUB = 3'b001;   // result = A - B
    localparam logic [2:0] OP_AND = 3'b010;   // result = A & B
    localparam logic [2:0] OP_OR  = 3'b011;   // result = A | B
    localparam logic [2:0] OP_XOR = 3'b100;   // result = A ^ B
    localparam logic [2:0] OP_NOT = 3'b101;   // result = ~A      (B bo qua)
    localparam logic [2:0] OP_SHL = 3'b110;   // result = A dich trai 1 bit
    localparam logic [2:0] OP_SHR = 3'b111;   // result = A dich phai 1 bit

    // =================================================================
    // 1. GIAI MA "TRU" — lan thu NHAT ma `op` cham vao netlist
    // =================================================================
    // Ba bit `op` chi di vao duong du lieu o DUNG HAI diem. Day la diem
    // thu nhat: mot cong AND 3 ngo giai ma ma lenh SUB. Diem thu hai la
    // bo ghep kenh o muc 6. Tra loi Charter muc 2 cau 2.
    logic sub;
    assign sub = (op == OP_SUB);

    // =================================================================
    // 2. NHANH SO HOC — MOT BO CONG DUNG CHUNG cho ca ADD lan SUB
    // =================================================================
    // Toan hang thu hai duoc DIEU KIEN HOA truoc khi vao bo cong:
    //   sub = 0 -> b_eff = b     (cong binh thuong)
    //   sub = 1 -> b_eff = ~b    (nua dau cua phep bu 2)
    // Bon cong XOR duoi day la TOAN BO phan cung rieng ma phep tru can.
    logic [3:0] b_eff;
    assign b_eff = b ^ {4{sub}};

    // Chuoi carry 5 bit. carry[0] la carry VAO:
    //   sub = 0 -> 0
    //   sub = 1 -> 1             (nua sau cua phep bu 2: cong them 1)
    // Day la chuoi phu thuoc NOI TIEP — nguon goc do tre cua nhanh so hoc.
    logic [4:0] carry;
    assign carry[0] = sub;

    logic [3:0] r_arith;   // A+B khi sub=0, A-B khi sub=1 — MOT day duy nhat
    logic       c_arith;   // carry ra khoi tang 4

    // 4 tang full-adder noi tiep, mo ta TUONG MINH.
    // 'generate' la NHAN BAN KHONG GIAN (4 ban sao phan cung ton tai dong
    // thoi), KHONG phai vong lap theo thoi gian.
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_FA
            // Tong tung bit: 1 tang XOR SAU KHI carry[i] da on dinh
            assign r_arith[i] = a[i] ^ b_eff[i] ^ carry[i];

            // Carry ra = ham da so (majority) cua 3 bit vao
            assign carry[i+1] = (a[i] & b_eff[i])
                              | (a[i] & carry[i])
                              | (b_eff[i] & carry[i]);
        end
    endgenerate

    // Y nghia cua carry ra PHU THUOC vao `sub` — xem functional_spec muc 3:
    //   sub = 0 : c_arith = 1 <=> A + B >= 16   (tran khong dau)
    //   sub = 1 : c_arith = 1 <=> A >= B        (KHONG muon vay)
    // Day la quy uoc carry/borrow kieu ARM, khong phai kieu 6502 dao bit.
    assign c_arith = carry[4];

    // =================================================================
    // 3. BON NHANH LOGIC BIT — do sau 1 cong, nhanh nhat trong tam nhanh
    // =================================================================
    logic [3:0] r_and, r_or, r_xor, r_not;
    assign r_and = a & b;
    assign r_or  = a | b;
    assign r_xor = a ^ b;
    assign r_not = ~a;          // phep mot ngoi: B khong tham gia

    // =================================================================
    // 4. HAI NHANH DICH MOT BIT — noi day thuan, 0 cong logic
    // =================================================================
    // Charter muc 3 xep "dich nhieu bit trong mot chu ky" (barrel shifter)
    // vao NGOAI PHAM VI, nen A04 chi co dich MOT bit co dinh.
    // Viet bang phep ghep bit chu KHONG bang toan tu `<<` / `>>`: cach
    // ghep bit noi ro day chi la day dien, con toan tu dich goi y mot bo
    // dich co the tham so hoa — thu ma A04 khong co.
    logic [3:0] r_shl, r_shr;
    logic       c_shl, c_shr;

    assign r_shl = {a[2:0], 1'b0};   // a3 a2 a1 a0 -> a2 a1 a0 0
    assign c_shl = a[3];             // bit bi day ra ngoai
    assign r_shr = {1'b0, a[3:1]};   // a3 a2 a1 a0 -> 0 a3 a2 a1 (dich LOGIC)
    assign c_shr = a[0];             // bit bi day ra ngoai

    // =================================================================
    // 5. BO GHEP KENH CHON PHEP — 8 vao, 1 ra, rong 5 bit (4 du lieu + C)
    // =================================================================
    // Day la lan thu HAI va cung la lan cuoi ma `op` cham vao netlist.
    //
    // Doc ky tam nhanh duoi day se thay: HAI nhanh dau (ADD, SUB) lay ve
    // CUNG MOT day `r_arith` / `c_arith`. Do la he qua truc tiep cua rang
    // buoc "mot bo cong dung chung", va la ly do bo ghep kenh mang tieng
    // la "8 vao" nhung chi co BAY duong vao phan biet ve mat dien.
    //
    // RUI RO CHINH cua de (Charter muc 10): viet `case` 8 nhanh roi quen
    // nhanh `default` => cong cu suy ra CHOT (latch) trong mach to hop.
    // O day dung BA lop phong ve, va da DO THUC NGHIEM vai tro tung lop
    // (bang so lieu o 05_VERIFICATION/known_issues.md muc 4):
    //   (1) GAN MAC DINH o dau khoi — phu moi duong di cua tin hieu ra;
    //   (2) nhanh `default`         — phu moi gia tri cua `op`;
    //   (3) tu khoa `always_comb`   — bien loi thanh LOI DUNG BIEN DICH.
    // Ket qua do duoc, KHAC voi truc giac thong thuong:
    //   · Chi can CON MOT trong hai lop (1) hoac (2) thi van 0 chot.
    //     Bo rieng (1) hay bo rieng (2) deu cho DUNG 27 cell, 0 chot.
    //   · Chot chi xuat hien khi MAT CA HAI. Luc do:
    //       - voi `always_comb` : Yosys DUNG HAN voi loi "Latch inferred";
    //       - voi `always @(*)` : Yosys chi CANH BAO, va 5 chot
    //         `$_DLATCH_N_` LOT vao netlist (4 cho result + 1 cho cflag).
    //   => Vi vay (3) moi la lop dang gia nhat: no doi im lang lay tieng no.
    always_comb begin
        // ---- LOP PHONG VE (1): gan mac dinh cho MOI tin hieu ra -------
        result = 4'b0000;
        cflag  = 1'b0;

        case (op)
            OP_ADD : begin result = r_arith; cflag = c_arith; end  // <-- cung
            OP_SUB : begin result = r_arith; cflag = c_arith; end  // <-- mot day
            OP_AND : begin result = r_and;   cflag = 1'b0;    end
            OP_OR  : begin result = r_or;    cflag = 1'b0;    end
            OP_XOR : begin result = r_xor;   cflag = 1'b0;    end
            OP_NOT : begin result = r_not;   cflag = 1'b0;    end
            OP_SHL : begin result = r_shl;   cflag = c_shl;   end
            OP_SHR : begin result = r_shr;   cflag = c_shr;   end

            // ---- LOP PHONG VE (2): nhanh default ----------------------
            // Voi `op` rong dung 3 bit, 8 nhanh tren da phu HET 8 gia tri
            // nen nhanh nay khong the dat toi trong mach that — va do do
            // no KHONG lam netlist to them mot cell nao: tong hop ban co
            // nhanh nay va ban bo di deu cho DUNG 27 cell / 193.9360 um2.
            // Gia bang 0 ma van viet, de: (a) giu thoi quen dung; (b) van
            // an toan neu sau nay ai do noi rong `op`; (c) chan
            // X-propagation trong mo phong khi `op` co bit X.
            default: begin result = 4'b0000; cflag = 1'b0; end
        endcase
    end

    // =================================================================
    // 6. CO Z — tinh SAU bo ghep kenh, dung chung cho ca tam phep
    // =================================================================
    // Dat SAU mux la co chu y: neu dat TRUOC thi phai co TAM mach do-zero
    // roi con phai ghep kenh them 1 bit nua. Dat sau => chi mot cay NOR.
    // Cai gia phai tra: cay NOR nay NOI TIEP sau mux nen keo dai duong
    // toi han. Danh doi nay duoc ban o 03_ARCHITECTURE/tradeoff.md muc 5.
    assign zflag = ~(|result);

endmodule
