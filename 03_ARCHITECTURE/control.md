# A04 · Phần điều khiển (Control)

---

## 1. Kết luận: **A04 không có phần điều khiển — nhưng nó có một bộ giải mã lệnh**

Đây là chỗ A04 khác hẳn A01, và là chỗ dễ nhầm nhất của đề. Phải phân biệt hai khái niệm:

| | Là gì | A04 có? |
|---|---|:-:|
| **Điều khiển (control)** | Quyết định **bây giờ làm bước nào** — cần trạng thái, cần clock | ❌ **Không** |
| **Giải mã lệnh (decode)** | Biến mã lệnh thành tín hiệu chọn — thuần tổ hợp, không nhớ gì | ✅ **Có** |

A04 có `op[2:0]` đi vào, nhưng `op` **không** điều khiển thời gian, nó chỉ **chọn hàm**.
Toàn khối vẫn là một hàm tổ hợp `f(A, B, op)`.

| Thành phần điều khiển thông thường | Có trong A04? | Vì sao |
|---|:-:|---|
| Máy trạng thái (FSM) | ❌ | Không có trạng thái để nhớ |
| Thanh ghi điều khiển | ❌ | Không có ô nhớ |
| Tín hiệu `enable` / `start` / `done` | ❌ | Không có giao thức bắt tay |
| Tín hiệu `valid` / `ready` | ❌ | Không có luồng dữ liệu theo nhịp |
| Bộ đếm chu kỳ | ❌ | Tính xong trong một lần lan truyền |
| Clock, reset | ❌ | Mạch tổ hợp |
| **Giải mã mã lệnh** | ✅ | `sub = (op == 3'b001)` + bộ ghép kênh 8→1 — **tổ hợp thuần** |

## 2. Toàn bộ "phần điều khiển" của A04 gói gọn trong hai điểm

```
   op[2:0] ──┬──────────────────────────────────────────────────┐
             │                                                  │
             ▼  ĐIỂM 1                                          ▼  ĐIỂM 2
   ┌───────────────────────┐                     ┌──────────────────────────┐
   │ sub = (op == 3'b001)  │                     │ BỘ GHÉP KÊNH 8 → 1       │
   │ 1 cổng (nor3b_1)      │                     │ rộng 5 bit, 27 cell      │
   └───────────┬───────────┘                     └──────────────────────────┘
               │                                              ▲
               ▼                                              │
   nằm TRONG đường dữ liệu số học            nằm CUỐI đường dữ liệu
   (điều kiện hoá b, và carry-in)            (chọn một trong tám kết quả)
```

Trả lời trực tiếp **Charter mục 2 câu 2** (*"ba bit chọn phép đi vào đâu trong netlist —
chúng tạo ra bao nhiêu bộ ghép kênh?"*):

* **Đi vào đúng hai chỗ**, không có chỗ thứ ba.
* **Số bộ ghép kênh 8→1 sinh ra: 5** — bốn cái cho `result[3:0]`, một cái cho `cflag`.
  Không có bộ ghép kênh nào cho `zflag`, vì `zflag` được tính **sau** mux từ `result`
  đã chọn (đó là một quyết định thiết kế — xem §4).
* Diện tích thật của cả phần này: **27 cell · 193,9360 µm²**, bằng **46,4 %** tổng diện
  tích khối. Chi tiết cách đo: `tradeoff.md` §2.

## 3. Điều khiển thật nằm ở đâu trong hệ thống

Điều khiển **có tồn tại**, nhưng ở tầng ngoài:

```
 ┌──────────────────────── TẦNG NGOÀI (không thuộc A04) ──────────────────────┐
 │                                                                            │
 │   clk ──────┬──────────────┬───────────────┬──────────────┐                │
 │   rst_n ────┤              │               │              │                │
 │             ▼              ▼               ▼              ▼                │
 │      ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐           │
 │      │ PC         │ │ IR         │ │ ACC        │ │ FLAGS      │           │
 │      │ (có clock) │ │ (có clock) │ │ (có clock) │ │ (có clock) │           │
 │      └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────▲──────┘           │
 │            │              │ op[2:0]      │ A[3:0]       │ {C,Z}            │
 │            │              │              │              │                  │
 │      ┌─────▼──────────────┼──────────────┼──────────────┼───────┐          │
 │      │ FSM lấy lệnh / thực thi: quyết định khi nào chốt ACC,    │          │
 │      │ khi nào nạp PC tuần tự, khi nào nhảy theo cờ             │          │
 │      └──────────────────────────────────────────────────────────┘          │
 │  ──────────────────────────┼──────────────┼──────────────┼───────────────  │
 │                            ▼              ▼              │                 │
 │      ╔═════════════════════════════════════════════════════════╗           │
 │      ║   A04 — datapath + giải mã lệnh, 0 trạng thái, 0 clock   ║           │
 │      ╚═════════════════════════════════════════════════════════╝           │
 └────────────────────────────────────────────────────────────────────────────┘
```

Tầng ngoài chịu trách nhiệm:

1. Cấp clock và reset cho `PC`, `IR`, `ACC`, `FLAGS`.
2. Giữ `op` **ổn định** suốt cửa sổ tính của A04 (đây là nghĩa vụ hợp đồng quan trọng
   nhất — xem §5).
3. Quyết định **khi nào** chốt `result` và `{C,Z}` (phải sau khi A04 đã ổn định — số liệu
   từ STA: 1,85 ns).
4. Dùng cờ `C` (mở rộng nhiều nibble, so sánh) và `Z` (rẽ nhánh `JZ`).

## 4. Một quyết định thiết kế nhỏ nhưng phải giải thích được

`zflag` được tính **sau** bộ ghép kênh:

```
 Đã chọn :  8 nhánh → mux → result → NOR4 → zflag        (1 cây NOR4)
 Phương án khác:  8 nhánh → 8 cây NOR4 → mux 8→1 → zflag  (8 cây NOR4 + 1 bit mux nữa)
```

| Tiêu chí | Tính sau mux (**A04 chọn**) | Tính trước mux |
|---|---|---|
| Số cây NOR4 | **1** | 8 |
| Bề rộng bộ ghép kênh | 5 bit | 6 bit |
| Độ trễ tới `zflag` | mux **rồi** NOR4 — **dài hơn** | NOR4 song song với nhau, chỉ + mux |
| Diện tích | **nhỏ hơn rõ rệt** | lớn hơn |

A04 chọn phương án diện tích. Cái giá đã được đo: `zflag` chính là endpoint tới hạn
(1,85 ns), trong khi `cflag` chỉ 1,35 ns. Tức là quyết định này **làm đường tới hạn dài
thêm ~0,50 ns**. Với một vi điều khiển dạy học chạy ở tốc độ thấp, đây là đánh đổi đúng;
với một CPU cần tần số cao thì phải xem lại. Bàn đầy đủ: `tradeoff.md` §5.

## 5. Nghĩa vụ hợp đồng của tầng ngoài

| Nghĩa vụ | Nguồn số liệu |
|---|---|
| Chu kỳ clock hệ thống `≥ t_ckq + 1,85 ns + t_setup + t_skew` | `06_GDSII/sta/` |
| `op` phải **ổn định** trong suốt cửa sổ tính | Nếu `op` đổi giữa chừng, cả tám nhánh tranh nhau trên mux → chuỗi glitch dài |
| `a`, `b`, `op` không chứa `X`/`Z` | Thiết kế tầng ngoài |
| Không lấy mẫu `result`/`C`/`Z` trong cửa sổ glitch | `03_ARCHITECTURE/timing_diagram.md` §4 |
| Firmware phải dùng **đúng quy ước** `C` của phép trừ (`C=1` ⟺ **không** mượn) | `02_SPECIFICATION/functional_spec.md` §1.1 |

> ⚠️ Nghĩa vụ thứ hai đáng chú ý hơn ở A04 so với A01. Ở A01, đổi toán hạng chỉ làm carry
> lan lại. Ở A04, đổi `op` làm **đổi cả hàm đang tính**: bộ ghép kênh phải chuyển từ nguồn
> này sang nguồn khác, mà tám nguồn đó có thời gian ổn định rất khác nhau (nhánh dịch:
> 0 cổng; nhánh trừ: tới 4 tầng carry). Đây là kịch bản glitch tệ nhất của khối.

## 6. Nếu sau này cần thêm điều khiển thật

Hai hướng mở rộng thường gặp, **cả hai đều nằm ngoài phạm vi Charter**:

| Hướng | Điều gì xuất hiện | Hậu quả |
|---|---|---|
| Dịch nhiều bit bằng cách lặp dịch 1 bit | FSM đếm số lần dịch + thanh ghi tạm | Đổi loại mạch sang **Tuần tự** |
| Nhân bằng cộng–dịch lặp | FSM + thanh ghi tích luỹ | Đổi loại mạch sang **Tuần tự** |

Cả hai đều bị Charter mục 3 loại (*"Ngoài phạm vi: nhân, chia, dịch nhiều bit trong một
chu kỳ"*). Gói này **không** hiện thực chúng. Nếu hiện thực, toàn bộ tầng 02 và 03 phải
viết lại vì phân loại mạch đã đổi.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: Charter mục 2 câu 2.*
