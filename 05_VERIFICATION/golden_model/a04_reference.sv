// =====================================================================
//  A04 - MO HINH CHUAN (golden model) bang SystemVerilog
// ---------------------------------------------------------------------
//  Vai tro: chuan so sanh DOC LAP cho a04_alu4.
//
//  VI SAO FILE NAY DUOC PHEP VIET `+`, `-`, `<<`, `>>` CON RTL THI KHONG
//  ---------------------------------------------------------------------
//  RTL nop bai BI CAM dung cac toan tu tat do (xem khoi comment dau file
//  04_IMPLEMENTATION/rtl/a04_alu4.sv), vi de bai yeu cau mo ta TUONG MINH
//  tam nhanh chuc nang va bat buoc ADD/SUB dung CHUNG MOT bo cong ripple.
//  Mo hinh chuan thi phai nghi NGUOC LAI: neu no cung dung mot bo cong
//  dung chung, cung mot chuoi carry, thi hai ben se cung sai mot kieu va
//  phep so sanh mat sach gia tri.
//
//  Hai cach nghi dat canh nhau:
//    RTL  : "dieu kien hoa toan hang B roi day qua BON tang full-adder,
//            carry-in lay tu bit `sub`" - tuc la MOT mach dung chung.
//    REF  : "moi phep la mot bieu thuc so hoc doc lap" - tam bieu thuc
//            roi rac, khong he chia se phan cung nao voi nhau.
//  Hai duong gap nhau o dung mot cho: cap gia tri (result, C, Z).
//
//  Luu y ve cu phap: moi phep tinh nam trong `assign` lien tuc, chi
//  rieng bo ghep kenh nam trong `always_comb` va o do chi doc cac TEN
//  NGUYEN VE (khong cat bit). Viet vay de tranh thong bao
//  "sorry: constant selects in always_* processes" cua Icarus Verilog 12.0.
// =====================================================================

module a04_reference (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [2:0] op,
    output logic [3:0] result,
    output logic       cflag,
    output logic       zflag
);

    // Bang ma lenh - phai khop tung bit voi bang trong RTL.
    localparam logic [2:0] OP_ADD = 3'b000;
    localparam logic [2:0] OP_SUB = 3'b001;
    localparam logic [2:0] OP_AND = 3'b010;
    localparam logic [2:0] OP_OR  = 3'b011;
    localparam logic [2:0] OP_XOR = 3'b100;
    localparam logic [2:0] OP_NOT = 3'b101;
    localparam logic [2:0] OP_SHL = 3'b110;
    localparam logic [2:0] OP_SHR = 3'b111;

    // -----------------------------------------------------------------
    // NHANH SO HOC - hai bieu thuc HOAN TOAN ROI RAC
    // -----------------------------------------------------------------
    // Cong: noi rong len 5 bit roi cong. Bit thu 5 CHINH LA carry ra.
    logic [4:0] sum5;
    assign sum5 = {1'b0, a} + {1'b0, b};

    logic [3:0] r_add;
    logic       c_add;
    assign r_add = sum5[3:0];
    assign c_add = sum5[4];

    // Tru: lay hieu 4 bit (tu dong cuon vong mod 16) va tinh co C
    // bang phep SO SANH truc tiep `a >= b`, KHONG qua bu 2, KHONG qua
    // bat ky chuoi carry nao. Day la khac biet manh nhat so voi RTL:
    // RTL phai chung minh `A + (~B) + 1` cho dung ket qua, con o day
    // ta hoi thang ngon ngu.
    logic [3:0] r_sub;
    logic       c_sub;
    assign r_sub = a - b;
    assign c_sub = (a >= b);          // C = 1 nghia la KHONG muon

    // -----------------------------------------------------------------
    // BON NHANH LOGIC BIT
    // -----------------------------------------------------------------
    logic [3:0] r_and, r_or, r_xor, r_not;
    assign r_and = a & b;
    assign r_or  = a | b;
    assign r_xor = a ^ b;
    assign r_not = ~a;                // phep mot ngoi: B khong tham gia

    // -----------------------------------------------------------------
    // HAI NHANH DICH - dung toan tu dich, dung thu RTL bi cam
    // -----------------------------------------------------------------
    logic [3:0] r_shl, r_shr;
    logic       c_shl, c_shr;
    assign r_shl = a << 1;            // 4 bit -> bit cao roi ra ngoai
    assign c_shl = a[3];              // bit bi day ra
    assign r_shr = a >> 1;            // dich LOGIC, chen 0 o bit cao
    assign c_shr = a[0];              // bit bi day ra

    // -----------------------------------------------------------------
    // BO GHEP KENH CHON PHEP
    // -----------------------------------------------------------------
    always_comb begin
        result = 4'b0000;
        cflag  = 1'b0;
        case (op)
            OP_ADD : begin result = r_add; cflag = c_add; end
            OP_SUB : begin result = r_sub; cflag = c_sub; end
            OP_AND : begin result = r_and; cflag = 1'b0;  end
            OP_OR  : begin result = r_or;  cflag = 1'b0;  end
            OP_XOR : begin result = r_xor; cflag = 1'b0;  end
            OP_NOT : begin result = r_not; cflag = 1'b0;  end
            OP_SHL : begin result = r_shl; cflag = c_shl; end
            OP_SHR : begin result = r_shr; cflag = c_shr; end
            default: begin result = 4'b0000; cflag = 1'b0; end
        endcase
    end

    // Co Z - dung dinh nghia, khong quan tam mach thuc hien the nao.
    assign zflag = (result == 4'b0000);

endmodule
