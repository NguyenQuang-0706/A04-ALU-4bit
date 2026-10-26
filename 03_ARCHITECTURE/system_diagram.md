# A04 · Sơ đồ hệ thống (System Diagram)

---

## 1. Sơ đồ khối hệ thống — vi điều khiển 4 bit dạy học

Bối cảnh Charter mục 1: A04 là **khối tính toán trung tâm** của một vi điều khiển 4 bit
dùng để dạy. Tám phép vừa đủ để chạy các lệnh số học và logic cơ bản của một tập lệnh
tối giản.

```
                     ┌──────────────────── MIỀN SỐ (toàn bộ) ────────────────────┐
                     │                                                           │
  ┌────────────┐     │   ┌──────────────┐         ┌───────────────────────┐      │
  │ Bộ nhớ     │─────┼──▶│ Thanh ghi    │  lệnh   │  Bộ giải mã lệnh      │      │
  │ chương     │     │   │ lệnh IR      │────────▶│  (tổ hợp)             │      │
  │ trình ROM  │     │   │ (có clock)   │         └───────┬───────────────┘      │
  └────────────┘     │   └──────────────┘                 │ op[2:0]              │
                     │                                    │                      │
                     │   ┌──────────────┐  A[3:0]         ▼                      │
                     │   │ Thanh ghi    │──────────▶╔═══════════════════════╗    │
                     │   │ tích luỹ ACC │           ║                       ║    │
                     │   │ (có clock)   │◀──────────╢      ►► A04 ◄◄        ║    │
                     │   └──────┬───────┘  result   ║  ALU 4-bit 8 chức năng║    │
                     │          │                   ║  (TỔ HỢP, 0 ô nhớ)    ║    │
                     │   ┌──────▼───────┐  B[3:0]   ║                       ║    │
                     │   │ Tệp thanh ghi│──────────▶╚═══════╤═══════════════╝    │
                     │   │ / toán hạng  │                   │ {C, Z}             │
                     │   │ (có clock)   │                   ▼                    │
                     │   └──────────────┘           ┌───────────────┐            │
                     │                              │ Thanh ghi cờ  │            │
                     │                              │ FLAGS (2 bit, │            │
                     │                              │  có clock)    │            │
                     │                              └───────┬───────┘            │
                     │                                      │                    │
                     │   ┌──────────────────────────────────▼────────────┐       │
                     │   │  Khối rẽ nhánh: lệnh JZ / JC đọc cờ để quyết   │       │
                     │   │  định nạp PC tuần tự hay nhảy                  │       │
                     │   └────────────────────────────────────────────────┘       │
                     └───────────────────────────────────────────────────────────┘
```

**Điểm cốt lõi của sơ đồ:** mọi ô nhớ của hệ thống — `IR`, `ACC`, tệp thanh ghi, `FLAGS`,
`PC` — đều nằm **ngoài** A04. A04 chỉ là hàm tổ hợp:

```
f : (A, B, op)  ⟶  (result, C, Z)
```

Chính vì `ACC` nằm ngoài mà A04 có thể **không có ô nhớ nào**: vòng phản hồi
`ACC → A04 → ACC` khép kín ở tầng trên, không đi qua bên trong khối.

## 2. Phân loại analog / digital / mixed

Đây là thành phần bắt buộc số 3 của hồ sơ (Charter mục 3).

| Khối | Phân loại | Lý do |
|---|---|---|
| **A04 (ALU)** | **Số thuần — tổ hợp** | Chỉ có cổng logic; mọi tín hiệu là mức logic 0/1; không có ô nhớ, không có phần tử analog |
| `ACC`, `IR`, `FLAGS`, tệp thanh ghi | Số — tuần tự | Có clock, có trạng thái |
| ROM chương trình | Số — bộ nhớ | Macro riêng, không phải standard cell |
| Mạch cấp nguồn, dao động thạch anh | Analog / mixed | **Không** thuộc phạm vi đề (Charter mục 3) |

A04 **không có** thành phần analog hay mixed-signal nào. Bằng chứng: bảng cell sau tổng hợp
gồm **toàn bộ 64 cell tổ hợp** của thư viện `sky130_fd_sc_hd`, không có cell tuần tự, không
có macro analog — xem `06_GDSII/synthesis/synth_stat.txt`.

## 3. Ranh giới khối A04

```
                 ╔═══════════════════════════════════════════════════╗
   a[3:0]  ─────▶║                                                   ║─────▶ result[3:0]
                 ║              a04_alu4                             ║
   b[3:0]  ─────▶║   8 nhánh chức năng + bộ ghép kênh 8→1            ║─────▶ cflag (C)
                 ║   cộng/trừ dùng CHUNG một bộ cộng ripple 4 tầng   ║
   op[2:0] ─────▶║   (tổ hợp thuần, 0 flip-flop, 0 chốt)             ║─────▶ zflag (Z)
                 ║                                                   ║
  (không clock)  ╚═══════════════════════════════════════════════════╝
  (không reset)       11 bit vào                        6 bit ra
                          └──── 17 bit trên ô 24 chân — VỪA, không phải đổi gì ────┘
```

## 4. Phân rã một tầng xuống dưới

Sơ đồ này vẽ theo **đúng** `04_IMPLEMENTATION/rtl/a04_alu4.sv`, theo thứ tự các mục
trong file:

```
 a04_alu4
 ├── [0] bảng mã lệnh  OP_ADD…OP_SHR  (localparam)
 ├── [1] giải mã `sub` = (op == 3'b001)          ← lần thứ NHẤT op chạm netlist
 ├── [2] NHÁNH SỐ HỌC — MỘT bộ cộng dùng chung
 │      ├── b_eff  = b ⊕ {4{sub}}                ← 4 cổng XOR: toàn bộ chi phí riêng của phép trừ
 │      ├── carry[0] = sub                       ← +1 của phép bù 2
 │      ├── GEN_FA[0..3] : 4 tầng full-adder nối tiếp
 │      │      r_arith[i] = a[i] ⊕ b_eff[i] ⊕ carry[i]
 │      │      carry[i+1] = majority(a[i], b_eff[i], carry[i])
 │      └── c_arith = carry[4]
 ├── [3] BỐN NHÁNH LOGIC : r_and, r_or, r_xor, r_not     (độ sâu 1 cổng)
 ├── [4] HAI NHÁNH DỊCH  : r_shl, r_shr + c_shl, c_shr   (0 cổng — nối dây)
 ├── [5] BỘ GHÉP KÊNH 8→1 rộng 5 bit                     ← lần thứ HAI op chạm netlist
 │        · vào ADD và vào SUB nối vào CÙNG một dây r_arith
 │        · bốn ứng viên C của nhánh logic là hằng số 0
 └── [6] zflag = NOR(result)                             ← nằm SAU bộ ghép kênh
```

## 5. Sơ đồ vòng đời (Lifecycle) — RTL đến GDSII

Đây là thành phần bắt buộc số 6 của hồ sơ (Charter mục 3). Trạng thái dưới đây là
**trạng thái thật** của gói này.

```
 ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
 │ 01 YÊU CẦU  │──▶│ 02 ĐẶC TẢ   │──▶│03 KIẾN TRÚC  │──▶│04 HIỆN THỰC│
 │  Charter    │   │ 8 phép +    │   │ 8 nhánh +    │   │  RTL .sv   │
 │             │   │ 2 cờ + ánh  │   │ mux; 1 bộ    │   │ a04_alu4   │
 │             │   │ xạ chân     │   │ cộng dùng chung  │            │
 └─────────────┘   └─────────────┘   └──────────────┘   └─────┬──────┘
                                                              │
        ┌─────────────────────────────────────────────────────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: Python reference PASS (exit 0)
 │05 KIỂM CHỨNG │        ✅ ĐÃ CHẠY: 2 078 vector · 0 lệch · 0 vi phạm bất biến
 │ sim + golden │        Icarus Verilog 12.0 · quét vét cạn 2 048/2 048
 └──────┬───────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: Yosys 0.33 + sky130_fd_sc_hd
 │ TỔNG HỢP     │        64 cell · 0 FF · 0 chốt · 417,9008 µm²
 │ (06/synth)   │
 └──────┬───────┘
        ▼
 ┌──────────────┐        ✅ ĐÃ CHẠY: OpenSTA, clock ảo `vclk` 10 ns
 │ STA          │        Đường tới hạn `op[2] → zflag` = 1,85 ns, slack 8,15 ns
 │ (06/sta)     │        wns 0,00 · tns 0,00 · công suất 100 % tổ hợp, 0 % tuần tự
 └──────┬───────┘
        ▼
 ┌──────────────┬──────────────┬──────────────┬──────────────┐
 │ FLOORPLAN    │  PLACEMENT   │ CTS (n/a)    │  ROUTING     │  ⬜ CHƯA CHẠY
 └──────────────┴──────────────┴──────┬───────┴──────────────┘
                                      ▼
                           ┌──────────────────┐
                           │  DRC · LVS · GDS │                  ⬜ CHƯA CHẠY
                           └────────┬─────────┘
                                    ▼
                           ┌──────────────────┐
                           │ 07 TRUY VẾT +    │
                           │ KẾT LUẬN/GIỚI HẠN│
                           └──────────────────┘

        ─────── NGOÀI PHẠM VI (Charter mục 3) ───────
        sign-off · tape-out · chế tạo · kiểm tra sau chế tạo
        nhân · chia · dịch nhiều bit một chu kỳ · cờ tràn có dấu
```

> **CTS ghi (n/a)** vì A04 không có clock — không có cây clock để dựng. Đây là một kết quả
> hợp lệ của tầng đó, không phải bước bị bỏ sót. Xem `06_GDSII/cts/README.md`.

## 6. A04 trong dòng chảy một lệnh

Để thấy A04 "tổ hợp" mà vẫn phục vụ được một máy có nhịp:

```
  chu kỳ N                                   chu kỳ N+1
  ├──────────────────────────────────────────┼─────────────────▶
  │                                          │
  │ cạnh lên: IR, ACC, toán hạng chốt giá trị│ cạnh lên: ACC và FLAGS
  │                                          │ chốt kết quả của A04
  │      ┌───── A04 lan truyền (tổ hợp) ─────┤
  │      │  op, a, b ổn định → result, C, Z  │
  │      │  đo được: xấu nhất 1,85 ns        │
  │      └───────────────────────────────────┤
  │◀──────────── chu kỳ hệ thống T ──────────▶│
```

Ràng buộc mà tầng ngoài phải thoả:

```
T  ≥  t_clk→q(ACC/IR)  +  t_A04_max(1,85 ns)  +  t_setup(ACC/FLAGS)  +  t_skew
```

Con số `1,85 ns` là kết quả STA **sau tổng hợp**, chưa có ký sinh dây — xem
`07_TRACEABILITY/limitations.md`.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Thành phần hồ sơ bắt buộc #2, #3 và #6.*
