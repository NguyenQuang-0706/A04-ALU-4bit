# A04 · Sơ đồ khối (Block Diagram)

Mọi sơ đồ dưới đây vẽ theo **đúng** `04_IMPLEMENTATION/rtl/a04_alu4.sv`, mục 1 → 6.

---

## 1. Toàn cảnh: tám nhánh tính song song, một bộ ghép kênh chọn

```
  a[3:0] ═══╦══════════════════════════════════════════════════════════════╗
            ║                                                              ║
  b[3:0] ═╦═╬════════════════════════════════════╗                         ║
          ║ ║                                    ║                         ║
          ║ ║  ┌──────────────────────────────┐  ║                         ║
          ║ ╚═▶│ [2] BỘ CỘNG/TRỪ DÙNG CHUNG   │  ║                         ║
          ╚═══▶│     ripple-carry 4 tầng      │══╪═══▶ r_arith[3:0] ═══╗    ║
               │                              │──┼────▶ c_arith ────╗  ║    ║
               └───────────▲──────────────────┘  ║                  ║  ║    ║
                           │ sub                 ║                  ║  ║    ║
               ┌───────────┴──────────┐          ║                  ║  ║    ║
  op[2:0] ════▶│ [1] GIẢI MÃ  sub =   │          ║                  ║  ║    ║
          ║    │     (op == 3'b001)   │          ║                  ║  ║    ║
          ║    └──────────────────────┘          ║                  ║  ║    ║
          ║                                      ║                  ║  ║    ║
          ║    ┌──────────────────────────────┐  ║                  ║  ║    ║
          ║    │ [3] BỐN NHÁNH LOGIC          │◀═╩══════════════════╪══╪════╣
          ║    │   r_and = a & b              │═════▶ r_and ═══════╗║  ║    ║
          ║    │   r_or  = a | b              │═════▶ r_or  ══════╗║║  ║    ║
          ║    │   r_xor = a ^ b              │═════▶ r_xor ═════╗║║║  ║    ║
          ║    │   r_not = ~a                 │═════▶ r_not ════╗║║║║  ║    ║
          ║    └──────────────────────────────┘                 ║║║║║  ║    ║
          ║                                                     ║║║║║  ║    ║
          ║    ┌──────────────────────────────┐                 ║║║║║  ║    ║
          ║    │ [4] HAI NHÁNH DỊCH (nối dây) │◀════════════════╪╪╪╪╪══╪════╝
          ║    │   r_shl = {a[2:0], 1'b0}     │═════▶ r_shl ═══╗║║║║║  ║
          ║    │   r_shr = {1'b0, a[3:1]}     │═════▶ r_shr ══╗║║║║║║  ║
          ║    │   c_shl = a[3], c_shr = a[0] │──▶ c_shl,c_shr ║║║║║║  ║
          ║    └──────────────────────────────┘      ║       ║║║║║║║  ║
          ║                                          ║       ▼▼▼▼▼▼▼  ▼
          ║    ┌─────────────────────────────────────╨───────────────────┐
          ╚═══▶│ [5] BỘ GHÉP KÊNH 8 → 1, rộng 5 bit                      │
               │     case (op)  ·  8 nhánh  ·  có gán mặc định + default │
               └───────────────┬──────────────────────────┬──────────────┘
                               │ result[3:0]              │ cflag
                               ├────────────────────────────────────▶ result[3:0]
                               │                          └─────────▶ cflag (C)
                               ▼
                    ┌─────────────────────┐
                    │ [6] zflag = NOR4    │────────────────────────────▶ zflag (Z)
                    └─────────────────────┘
```

Ba điều đọc ra ngay từ sơ đồ:

1. **`op` chỉ chạm vào netlist ở đúng hai chỗ**: bộ giải mã `sub` (khối [1]) và bộ ghép
   kênh (khối [5]). Không có chỗ thứ ba.
2. **Tám nhánh luôn luôn tính**, kể cả nhánh không được chọn. Đó là bản chất của kiến trúc
   "tính hết rồi mới chọn", và cũng là lý do công suất động của ALU cao hơn một khối chỉ
   làm một phép.
3. **`zflag` nằm sau bộ ghép kênh**, nên nó là đầu ra **sâu nhất** của khối.

## 2. Bên trong bộ cộng/trừ dùng chung — chỗ trọng tâm khi bảo vệ

```
                      sub ────┬─────────────────────────────────────┐
                              │                                     │
        b[i] ──┐              │                                     │
               ▼              ▼                                     │
            ┌─────────────────────┐                                 │
            │   XOR   b[i] ⊕ sub  │   ← 4 cổng XOR này là TOÀN BỘ   │
            └──────────┬──────────┘     phần cứng riêng của phép trừ│
                       │ b_eff[i]                                   │
        a[i] ──┬───────┼──────────────┐                             │
               │       │              │                             ▼
               ▼       ▼              ▼                   carry[0] = sub
            ┌─────────────┐     ┌───────────────┐         (bù 2: cộng thêm 1)
            │ XOR  a⊕b_eff│     │ MAJORITY      │
            └──────┬──────┘     │ a, b_eff, c_i │
                   │            └───────┬───────┘
    carry[i] ──┬───┼────────────────────┘
               │   ▼
               │ ┌─────────────┐
               └▶│ XOR  ⊕ c_i  │
                 └──────┬──────┘
                        ▼                    ▼
                  r_arith[i]            carry[i+1]
```

Công thức tương ứng trong RTL:

```systemverilog
assign b_eff      = b ^ {4{sub}};
assign carry[0]   = sub;
assign r_arith[i] = a[i] ^ b_eff[i] ^ carry[i];
assign carry[i+1] = (a[i] & b_eff[i]) | (a[i] & carry[i]) | (b_eff[i] & carry[i]);
```

### Vì sao chỉ cần **một** bộ cộng

```
       A − B  =  A + (−B)  =  A + (¬B + 1)  =  A + ¬B + 1
                                   │       │
                          4 cổng XOR       carry-in = 1
```

Cả hai "nửa" của phép bù 2 đều **miễn phí về mặt cấu trúc**: nửa đầu là 4 cổng XOR trên
đường `B`, nửa sau **không tốn cổng nào** vì carry-in của tầng 0 vốn là một dây tự do.

Bằng chứng đo được (chi tiết ở `tradeoff.md` §3):

| Phương án | Cell | Diện tích |
|---|---:|---:|
| Chỉ bộ cộng, không có đường trừ | 13 | 95,0912 µm² |
| **Bộ cộng/trừ dùng chung (A04 chọn)** | **14** | **128,8736 µm²** |
| Hai đơn vị riêng (một cộng + một trừ) | 27 | 186,4288 µm² |

Thêm khả năng trừ vào bộ cộng tốn **+1 cell, +33,78 µm²**. Làm hai đơn vị riêng tốn
**+14 cell, +91,34 µm²** — đắt gấp gần **2,7 lần**.

## 3. Bên trong bộ ghép kênh — và vì sao nó chỉ có **bảy** đường vào

Sơ đồ khái niệm cho **một** bit kết quả (nhân lên 4 lần cho `result`, thêm 1 lần cho `C`):

```
                  op[2:0]
                     │
                     ▼  (3 bit chọn)
        ┌────────────────────────────────┐
  000 ─▶│                                │
  001 ─▶│                                │
  010 ─▶│                                │
  011 ─▶│        MUX  8 → 1              │──▶ result[i]
  100 ─▶│                                │
  101 ─▶│                                │
  110 ─▶│                                │
  111 ─▶│                                │
        └────────────────────────────────┘

  Nhưng thực tế nối dây là:

  000 ─┐
       ├── r_arith[i]     ← HAI đường vào chung MỘT dây
  001 ─┘
  010 ──── r_and[i]
  011 ──── r_or[i]
  100 ──── r_xor[i]
  101 ──── r_not[i]
  110 ──── r_shl[i]
  111 ──── r_shr[i]
              └── chỉ BẢY nguồn tín hiệu phân biệt
```

Với đường `C` thì còn ít hơn nữa — chỉ **bốn** nguồn phân biệt:

```
  000, 001 ──── c_arith
  010, 011, 100, 101 ──── hằng số 1'b0
  110 ──── a[3]
  111 ──── a[0]
```

Đây là hệ quả trực tiếp của ràng buộc "một bộ cộng dùng chung", và nó **tiết kiệm được đo
đếm được** ở chính bộ ghép kênh:

| Bộ ghép kênh | Cell | Diện tích |
|---|---:|---:|
| **7 đường vào phân biệt (A04)** | **27** | **193,9360 µm²** |
| 8 đường vào phân biệt (nếu ADD và SUB là hai đơn vị riêng) | 37 | 290,2784 µm² |

Tức bộ cộng dùng chung tiết kiệm **thêm 96,34 µm² (−33,2 %)** ở bộ ghép kênh — **ngoài**
phần đã tiết kiệm ở bộ số học. Đây là điểm mà sinh viên hay bỏ sót: dùng chung phần cứng
tiết kiệm ở **hai** chỗ, không phải một.

## 4. Hai lớp phòng vệ chống suy ra chốt

Charter mục 10 cảnh báo: *"Viết case 8 nhánh rồi quên nhánh default — công cụ tự sinh chốt
ngoài ý muốn."* RTL dùng ba lớp:

```
 always_comb begin                     ← (3) always_comb: biến lỗi thành LỖI DỪNG BIÊN DỊCH
     result = 4'b0000;                 ← (1) gán mặc định: phủ mọi đường đi
     cflag  = 1'b0;
     case (op)
         ... 8 nhánh, mỗi nhánh gán CẢ result LẪN cflag ...
         default: ...                  ← (2) nhánh default: phủ mọi giá trị op
     endcase
 end
```

Kết quả **đo thực nghiệm** (chi tiết + số liệu: `05_VERIFICATION/known_issues.md` §4):

| Biến thể | Gán mặc định | Số nhánh | Có `default` | Kiểu khối | Kết quả |
|---|:-:|:-:|:-:|---|---|
| **S0 — như nộp bài** | ✅ | 8 | ✅ | `always_comb` | **0 chốt** · 27 cell · 193,9360 µm² |
| S1 | ❌ | 8 | ✅ | `always_comb` | 0 chốt · 27 cell · 193,9360 µm² — **y hệt S0** |
| S5 | ✅ | 8 | ❌ | `always_comb` | 0 chốt · 27 cell · 193,9360 µm² — **cũng y hệt S0** |
| S2 | ✅ | 7 | ❌ | `always_comb` | 0 chốt · 27 cell · 187,6800 µm² |
| S3 | ❌ | 7 | ❌ | `always_comb` | **Yosys DỪNG: `ERROR: Latch inferred`** |
| S4 | ❌ | 7 | ❌ | `always @(*)` | **5 chốt `$_DLATCH_N_` lọt vào netlist** |

Đọc bảng này ngược lại thói quen thường gặp: **nhánh `default` một mình không phải là thứ
cứu bạn** — bỏ riêng nó (S5) vẫn 0 chốt, vì gán mặc định đã phủ; mà bỏ riêng gán mặc định
(S1) cũng vẫn 0 chốt. Chốt chỉ xuất hiện khi **mất cả hai**. Và cả hai lớp đều **miễn
phí**: S0, S1, S5 cho netlist giống hệt nhau. Khi đã mất cả hai, thứ quyết định bạn có
biết hay không lại là từ khoá `always_comb` (S3 dừng hẳn) so với `always @(*)` (S4 im
lặng cho chốt lọt qua).

## 5. Ánh xạ RTL → phần cứng

| Cấu trúc RTL | Phần cứng sinh ra | Ghi chú |
|---|---|---|
| `assign sub = (op == OP_SUB)` | 1 cổng 3 ngõ (`nor3b_1` trong netlist thật) | Điểm thứ nhất `op` chạm netlist |
| `b ^ {4{sub}}` | 4 cổng XOR | Toàn bộ chi phí riêng của phép trừ |
| `carry[0] = sub` | **0 cổng** — chỉ là dây | Nửa "+1" của bù 2 miễn phí |
| `generate for (i=0..3)` | 4 bản sao full-adder | **Nhân bản KHÔNG GIAN**, không phải vòng lặp thời gian |
| `carry[i+1] = majority(...)` | `maj3_1` / `a22oi` / `o21ai` … | `abc` tự chọn dạng hiện thực của hàm đa số |
| `{a[2:0], 1'b0}`, `{1'b0, a[3:1]}` | **0 cổng** — chỉ là dây | Dịch 1 bit cố định là nối dây thuần |
| `always_comb` + `case (op)` | Bộ ghép kênh 8→1 rộng 5 bit | 27 cell — **lớn nhất trong ba phần** |
| `~(\|result)` | Tổng hợp **riêng** cho đúng 1 cổng `nor4_1` (6,2560 µm²); trong thiết kế đầy đủ `abc` **hoà tan** nó vào chuỗi mux `a2111oi_0 → o2111ai_1 → a211oi_1` | Nằm **sau** mux → đầu ra sâu nhất |
| Không có `always_ff` | **0 flip-flop, 0 chốt** | Đã xác nhận: `06_GDSII/synthesis/synth_stat.txt` |

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #5 (artifact số có chú thích).*
