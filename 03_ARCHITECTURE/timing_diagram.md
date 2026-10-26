# A04 · Giản đồ thời gian (Timing Diagram)

A04 không có clock, nên giản đồ ở đây là **giản đồ lan truyền tín hiệu**, không phải giản
đồ chu kỳ. Mọi con số lấy từ `06_GDSII/sta/timing_report_max.txt` (OpenSTA, góc
`tt_025C_1v80`, clock ảo `vclk` 10 ns).

---

## 1. Ca xấu nhất — **đổi `op`**, không phải đổi toán hạng

Đây là kết quả trái trực giác nhất của đề: đường tới hạn bắt đầu ở `op[2]`.

```
              t0       t1        t2        t3        t4        t5      t6
              │        │         │         │         │         │       │
 a, b   ──────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  giữ nguyên
              │
 op[2]  ──────┤‾‾‾ đổi (ví dụ 110 SHL → 001 SUB)
              │
              │   0,43 ns
 sub    ──────┴──────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
              │          │  ← nor3b_1: cell ĐẮT NHẤT trên cả đường
              │          │   0,26 ns
 b_eff  ──────┼──────────┴─────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
              │                    │  0,33 ns
 r_arith ─────┼────────────────────┴───────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
              │                            │   0,52 + 0,18 ns
 result ──────┤XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX├▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
              │                                        │  0,13 ns
 zflag  ──────┤XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX├▔▔▔▔▔▔▔▔▔▔▔▔
              │                                              │ ỔN ĐỊNH
              │◀──────── VÙNG GLITCH — KHÔNG ĐƯỢC LẤY MẪU ───▶│
              │                                              │
              │◀──────────────── t_A04_max = 1,85 ns ────────▶│
```

**Đọc giản đồ:**

* Cell đầu tiên (`nor3b_1`, giải mã `sub`) tiêu **0,43 ns — 23 %** toàn bộ đường tới hạn,
  chỉ để trả lời câu hỏi *"đây có phải phép trừ không?"*. Lý do: `op[2]` có **fanout 11**,
  cao nhất thiết kế, nên slew xấu.
* Sau đó tín hiệu còn phải đi **xuyên qua bộ cộng** rồi mới tới bộ ghép kênh — vì `sub`
  nằm **trước** bộ cộng, không phải sau.
* `zflag` ổn định **cuối cùng**, vì nó là đầu ra duy nhất nằm nối tiếp **sau** mux.

## 2. Ca tốt nhất — giữ `op`, chỉ đổi một bit toán hạng vào nhánh dịch

```
 op      ─────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  giữ nguyên = 111 (SHR)
              │
 a[1]    ─────┤‾‾‾ đổi
              │  0,10 ns
 result  ─────┤▒├──────── ổn định ────────────
              │◀▶│
              │  chỉ qua bộ ghép kênh, nhánh dịch KHÔNG có cổng logic nào
```

Đường nhanh nhất mà STA báo: `a[1] → result[2]` = **0,10 ns**.
So với đường tới hạn `1,85 ns` ⟹ chênh **≈ 18,5 lần** trên cùng một netlist.

## 3. So bốn kịch bản trên cùng netlist

| Kịch bản | Đường | Độ trễ | Vai trò |
|---|---|---:|---|
| Đổi mã lệnh | `op[2] → zflag` | **1,85 ns** | **Ca xác định `t_A04_max`** |
| Đổi toán hạng, phép logic/số học | `b[1] → zflag` | 1,36 ns | Ca xấu nhất của dữ liệu |
| Đổi toán hạng, đi hết chuỗi carry | `a[0] → cflag` | 1,04 ns | Chuỗi ripple 4 tầng đầy đủ |
| Đổi toán hạng, nhánh dịch | `a[1] → result[2]` | **0,10 ns** | Ca nhanh nhất |

> 👉 Khi chạy mô phỏng gate-level có SDF hoặc đo timing, **vector kích hoạt đường tới hạn
> là một phép chuyển `op`**, không phải một cặp toán hạng. Cụ thể: giữ `a`, `b` cố định
> (nên chọn `a = b = 8` để ép chuỗi carry dài nhất — TC-030) rồi chuyển `op` từ `110`
> sang `001`. Ca này **chưa** nằm trong 30 ca có tên vì testbench RTL là zero-delay nên
> không đo được gì; nó được ghi vào danh sách ca gate-level ở
> `02_SPECIFICATION/corner_cases.md` §6.

## 4. Vùng glitch — vì sao A04 nguy hiểm hơn A01

Ở A01, đổi toán hạng chỉ làm carry lan lại: các bit `sum` lần lượt đổi một lần.
Ở A04, đổi `op` làm **bộ ghép kênh chuyển nguồn**, mà tám nguồn có thời gian ổn định
rất khác nhau:

```
  nguồn của mux        độ sâu logic (ĐẾM TỪ RTL, chưa đo riêng bằng STA)
  ─────────────────    ──────────────────────────────────────────────────
  r_shl, r_shr         0 cổng            (nối dây thuần)
  r_and/or/xor/not     1 cổng
  r_arith (ADD)        1 XOR + tới 3 tầng carry
  r_arith (SUB)        1 giải mã + 1 XOR + tới 4 tầng carry   ← sâu nhất

  ⟹ khi op chuyển, mux lần lượt "nhìn thấy" các nguồn ổn định ở
    những thời điểm khác nhau ⟹ result có thể đổi giá trị NHIỀU LẦN
    trước khi ổn định.
```

> Bảng trên là **độ sâu đếm từ RTL**, không phải thời gian đo được. Con số STA duy nhất
> chắc chắn cho vùng này là **biên trên `t_A04_max = 1,85 ns`**; muốn biết từng nguồn ổn
> định lúc nào phải chạy mô phỏng gate-level có SDF — chưa làm.

```
 op     ──┤‾‾‾ đổi 110 → 001
          │
 result ──┤▒▒▒▒│▒▒▒▒▒▒│▒▒▒▒▒▒▒▒│────── giá trị đúng ──────
          │ giá trị │ giá trị  │
          │ cũ      │ trung gian
          │◀── nhiều lần chuyển mức ──▶│
```

Hệ quả thực tế:

1. **Tầng ngoài tuyệt đối không được lấy mẫu trong cửa sổ này** — phải chờ đủ
   `t_A04_max = 1,85 ns`.
2. **Công suất động của A04 cao hơn một khối một-phép**: mỗi lần `op` đổi, cả tám nhánh
   đều chuyển mạch dù chỉ một nhánh được dùng. Đây là mặt thứ hai của "cái giá của tính
   linh hoạt" mà Charter mục 9 hỏi — mặt diện tích được đo ở `tradeoff.md` §2, còn mặt
   công suất này **chưa** đo được vì `report_power` dùng activity mặc định, không lấy từ
   VCD. Ghi rõ là **chưa chứng minh** ở `07_TRACEABILITY/limitations.md`.

## 5. Công suất — bằng chứng độc lập cho "0 ô nhớ"

`report_power` của OpenSTA trên netlist sau tổng hợp:

| Nhóm | Internal | Switching | Leakage | Tổng | Tỉ lệ |
|---|---|---|---|---|---:|
| Sequential | 0,00e+00 | 0,00e+00 | 0,00e+00 | 0,00e+00 | **0,0 %** |
| Combinational | 9,71e-06 | 5,89e-06 | 1,71e-10 | 1,56e-05 | **100,0 %** |

Nhóm Sequential bằng **0** là bằng chứng thứ hai — khác nguồn với bảng cell của Yosys —
rằng khối không có ô nhớ.

> ⚠️ Con số `1,56e-05 W` chỉ cho biết **thứ tự độ lớn**. Nó dùng activity mặc định của
> công cụ, không phải activity thật lấy từ VCD, nên **không** phải công suất thật của ứng
> dụng.

## 6. Waveform thật đã thu được

File: `05_VERIFICATION/waveforms/a04_waves.vcd`
Công cụ tạo: Icarus Verilog 12.0
Nội dung: **30 ca có tên** (TC-001 … TC-030), mỗi ca cách nhau 1 ns. Testbench gọi
`$dumpoff` ngay trước vòng quét vét cạn 2 048 tổ hợp để file không phình to.

Mở bằng:

```bash
gtkwave 05_VERIFICATION/waveforms/a04_waves.vcd
```

> Lưu ý: waveform này là **mô phỏng RTL** (behavioral), nên **không có độ trễ cổng** —
> mọi tín hiệu đổi tức thời tại mốc `#1`. Vì vậy waveform này **không** chứng minh được
> các giản đồ ở §1–§4, và đặc biệt **không** nhìn thấy được vùng glitch ở §4. Để thấy độ
> trễ thật phải mô phỏng gate-level có back-annotate SDF, hoặc đọc số từ báo cáo STA.
> Xem `07_TRACEABILITY/limitations.md`.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: Charter mục 2 câu 3.*
