# A04 · Nhật ký vá (PATCHLOG)

Ghi lại **từng** thay đổi so với gói nguồn gốc, kèm lý do và bằng chứng trước/sau.
Chẩn đoán đầy đủ: [`../05_VERIFICATION/known_issues.md`](../05_VERIFICATION/known_issues.md).

---

## 0. Tóm tắt một dòng

> Gói nguồn chứa **bộ mã hoá ưu tiên 8→3** của một danh mục đề cũ. Charter A04 đòi
> **ALU 4-bit tám chức năng**. Đã **viết mới** RTL / mô hình chuẩn / testbench cho đúng đề;
> bản gốc đóng băng nguyên trạng tại thư mục này.

* **Ngày vá:** 2026-09-24
* **Người duyệt:** giảng viên (đã duyệt phương án viết lại RTL)
* **Loại vá:** thay thế thiết kế, **không** phải sửa lỗi
* **Quay lui được:** ✅ — xem §5

---

## 1. Vì sao phải vá

| | Charter A04 yêu cầu | Gói nguồn cung cấp |
|---|---|---|
| Tên đề | Đơn vị số học logic (ALU) 4-bit tám chức năng | Bộ mã hoá ưu tiên 8→3 |
| Top module | — | `a04_priority_encoder` |
| Cổng vào | `A[3:0]`, `B[3:0]`, `op[2:0]` | `req[7:0]` |
| Cổng ra | `result[3:0]`, `C`, `Z` | `index[2:0]`, `valid` |
| Ca kiểm thử mục 8 | "8 phép × ≥3 cặp toán hạng" | **Không chạy được** — khối không có phép nào |

Tên gói zip gốc — `A04_PriorityEncoder_Implementation_Validation` — nói thẳng ra vấn đề:
gói được lắp theo **một danh mục đề cũ**.

`a04_priority_encoder` **không sai**. Nó là một thiết kế đúng, mô phỏng PASS, tổng hợp
PASS. Nó chỉ **thuộc về một đề khác**.

---

## 2. Danh sách file bị thay

| # | Đường dẫn | Trước | Sau | Việc |
|---|---|---|---|---|
| 1 | `04_IMPLEMENTATION/rtl/a04_priority_encoder.sv` | 25 dòng, `casex` mã hoá ưu tiên | **xoá khỏi thư mục làm việc** | Đã đóng băng ở `rtl/` của thư mục này |
| 2 | `04_IMPLEMENTATION/rtl/a04_alu4.sv` | *(không tồn tại)* | **tạo mới** — ALU 4-bit, 8 nhánh + mux, 1 bộ cộng dùng chung | Hiện thực đúng đề |
| 3 | `05_VERIFICATION/golden_model/a04_reference.sv` | mô hình mã hoá ưu tiên | **viết mới** — 8 phép bằng toán tử ngôn ngữ | Chuẩn so sánh độc lập |
| 4 | `05_VERIFICATION/golden_model/reference_model.py` | mô hình Python của mã hoá ưu tiên | **viết mới** — 30 ca có tên + 7 bất biến trên 2 048 tổ hợp | Chuẩn so sánh độc lập thứ hai |
| 5 | `05_VERIFICATION/testbench/a04_tb.sv` | testbench mã hoá ưu tiên | **viết mới** — 24 ca Charter + 6 ca tự xây + quét vét cạn | Kiểm chứng đúng đề |

Các file trong `08_ORIGINAL_SOURCE/rtl|golden_model|testbench/` **không bị chạm tới**.

## 3. Danh sách tài liệu viết lại

| Đường dẫn | Lý do |
|---|---|
| `02_SPECIFICATION/functional_spec.md` | Đặc tả tám phép, hai cờ, ánh xạ chân, 9 bất biến |
| `02_SPECIFICATION/corner_cases.md` | 30 ca kèm lý do chọn, phân loại theo chuỗi carry và theo cờ |
| `03_ARCHITECTURE/system_diagram.md` | Bối cảnh vi điều khiển 4 bit + vòng đời với trạng thái thật |
| `03_ARCHITECTURE/block_diagram.md` | Sơ đồ vẽ theo đúng RTL mới |
| `03_ARCHITECTURE/datapath.md` | Đường dữ liệu, đồ thị phụ thuộc, độ sâu logic, kết quả STA |
| `03_ARCHITECTURE/control.md` | Phân biệt "điều khiển" và "giải mã lệnh" |
| `03_ARCHITECTURE/fsm.md` | Vì sao không có FSM, kèm bằng chứng 0 ô nhớ |
| `03_ARCHITECTURE/timing_diagram.md` | Giản đồ lan truyền, vùng glitch khi `op` đổi |
| `03_ARCHITECTURE/tradeoff.md` | Đo tách diện tích mux/phép tính, so bộ cộng dùng chung với hai bộ riêng |
| `implementation-notes_A04.md` | 11 mục ghi chú thực hiện |
| `05_VERIFICATION/known_issues.md` | **Tạo mới** — chẩn đoán sự cố + thí nghiệm chốt |
| `08_ORIGINAL_SOURCE/PATCHLOG.md` | **Tạo mới** — chính tài liệu này |

Không chạm vào: `01_REQUIREMENT/`, `06_GDSII/`, `07_TRACEABILITY/`, `README.md`,
`04_IMPLEMENTATION/scripts|constraints`,
`02_SPECIFICATION/{interface,timing,parameters}.md`, `implementation-notes_A04.html`.
Những file này được **sinh lại tự động** với số liệu mới.

---

## 4. Bằng chứng xác minh trước / sau

Cùng một chuỗi công cụ, cùng thư viện `sky130_fd_sc_hd` (`tt_025C_1v80`).

| Chỉ số | **TRƯỚC** (bộ mã hoá ưu tiên) | **SAU** (ALU 4-bit) |
|---|---|---|
| Đúng đề Charter | ❌ **KHÔNG** | ✅ **CÓ** |
| Mô hình chuẩn Python | PASS | **PASS** (exit 0) |
| Mô phỏng RTL | PASS | **PASS** — 2 078 vector, 0 lệch REF, 0 vi phạm bất biến |
| Quét vét cạn | 256 tổ hợp (`2^8`) | **2 048 tổ hợp** (`2^4 × 2^4 × 2^3`) |
| Ca Charter mục 8 | **không chạy được** | **24 ca bắt buộc + 6 ca tự xây dựng, tất cả PASS** |
| Tổng hợp | PASS | **PASS** |
| Số cell | 12 | **64** |
| **Flip-flop** | **0** | **0** ✅ |
| Chốt (latch) | 0 | **0** ✅ |
| Diện tích | 66,3136 µm² | **417,9008 µm²** |
| STA | PASS (`virtual_clock`) | **PASS** (`virtual_clock`, `vclk` 10 ns) |
| Đường tới hạn | `req[6] → valid` | **`op[2] → zflag`** |
| Thời gian đến | 0,71 ns | **1,85 ns** |
| Slack | 9,29 ns | **8,15 ns** |
| WNS / TNS | 0,00 / 0,00 | **0,00 / 0,00** |
| Công suất | 1,13e-06 W (tổ hợp 100 %) | **1,56e-05 W** (tổ hợp **100,0 %**, tuần tự **0,0 %**) |
| So với ước lượng Charter (~200–300 cell) | 12 — thấp bất thường | **64** — vẫn thấp hơn cận dưới, nhưng cùng bậc |

Lệnh xác minh đã chạy (đúng như `REDESIGN_SPEC.md` §2):

```bash
D=<thư mục đề>
LIB=<...>/sky130hd.lib

python3 $D/05_VERIFICATION/golden_model/reference_model.py          # exit 0

iverilog -g2012 -o sim.vvp $D/04_IMPLEMENTATION/rtl/*.sv \
    $D/05_VERIFICATION/golden_model/*.sv $D/05_VERIFICATION/testbench/*.sv
vvp sim.vvp                                                         # PASS

yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
  hierarchy -check -top a04_alu4; proc; opt; fsm; opt; memory; opt; techmap; opt; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; \
  opt_clean -purge; stat -liberty $LIB"                             # 64 cell, 0 FF
```

Kết quả cuối của mô phỏng:

```
TONG KET: chay=2078  lech REF=0  vi pham bat bien=0  (Z=1: 222 vector)
A04 exhaustive validation PASS — DUT khop REF tren toan bo khong gian dau vao.
```

---

## 5. Cách quay lui

```bash
cd <thư mục đề>
cp 08_ORIGINAL_SOURCE/rtl/*.sv          04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*    05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*.sv    05_VERIFICATION/testbench/
rm -f 04_IMPLEMENTATION/rtl/a04_alu4.sv
```

Sau khi quay lui, hồ sơ trở lại đúng trạng thái ban đầu — **kể cả** trạng thái
`REQ-A04-001` **CHƯA THOẢ**, vì khối được hiện thực lại không phải khối Charter yêu cầu.

Đối chiếu trước/sau từng file:

```bash
ls 08_ORIGINAL_SOURCE/rtl/          # a04_priority_encoder.sv  (bản gốc)
ls 04_IMPLEMENTATION/rtl/           # a04_alu4.sv              (bản mới)
```

Hai file này **không** so được bằng `diff` — chúng là hai thiết kế khác nhau, không phải
hai phiên bản của cùng một thiết kế. Đó cũng chính là bản chất của sự cố.

---

## 6. Giá trị dạy học của bản gốc

`08_ORIGINAL_SOURCE/rtl/a04_priority_encoder.sv` vẫn đáng đọc, vì hai lý do:

1. Nó là một **ví dụ sạch về `casex` có nhánh `default`** — cùng chủ đề rủi ro với Charter
   mục 10 của đề A04, nhưng ở một bài khác.
2. Nó là **bằng chứng vật lý** cho một tình huống có thật trong công việc kỹ thuật: mã
   nguồn đúng, chạy tốt, nhưng **trả lời sai câu hỏi**. Phát hiện ra điều đó là một kỹ năng
   riêng, và nó được luyện bằng việc đối chiếu bảng cổng với Charter mục 4 — chứ không
   bằng việc chạy thêm mô phỏng.

---

## 7. Dựng lại mô hình chuẩn và testbench (2026-09-24)

> **Ghi chú về cách đánh số.** Yêu cầu khôi phục gọi mục này là “§6”, nhưng tài liệu
> này đã có sẵn một mục §6 với nội dung khác, nên mục mới được đánh số **§7** để
> không tạo ra hai mục trùng số. Tiêu đề giữ nguyên như yêu cầu.

### 7.1 Vì sao phải dựng lại

Một bước sinh tài liệu tự động (`generate2.py`) đã **chép mã nguồn cũ từ `runs/<mã>/work/`
đè lên** ba thư mục `04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và
`05_VERIFICATION/testbench/`. Sau đó các file bị ghi đè được dọn đi cùng với file cũ.

Kết quả kiểm kê thực tế tại thời điểm khôi phục:

| Thư mục | Trạng thái |
|---|---|
| `04_IMPLEMENTATION/rtl/` | ✅ **Còn nguyên** — RTL mới không mất |
| `05_VERIFICATION/golden_model/` | ❌ **Mất trắng** — thư mục không tồn tại |
| `05_VERIFICATION/testbench/` | ❌ **Mất trắng** — thư mục không tồn tại |
| `08_ORIGINAL_SOURCE/{rtl,golden_model,testbench}/` | ✅ Còn nguyên, không bị chạm |

Lỗi của bộ sinh **đã được sửa**. Vì RTL còn nguyên nên đây **không phải** một lần thiết kế
lại: chỉ cần **dựng lại mô hình chuẩn và testbench cho khớp RTL đang có**.

### 7.2 Bằng chứng RTL không đổi

File `04_IMPLEMENTATION/rtl/a04_alu4.sv` còn nguyên và vẫn là bản đã được vá:
khối comment đầu file vẫn nêu đủ ba ràng buộc (một bộ cộng dùng chung, cấm toán
tử tắt, 0 flip-flop), `always_comb` vẫn đủ **ba lớp phòng vệ** chống suy ra chốt
(gán mặc định đầu khối · nhánh `default` · từ khoá `always_comb`).

Tổng hợp lại cho **đúng 64 cell / 0 flip-flop / 417,9008 µm²** — trùng khít con số
đã ghi ở §4, xác nhận RTL không hề bị sửa.

Vì RTL không đổi, **mọi số liệu tổng hợp trong §4 phải giữ nguyên** — và đó chính là
tiêu chí nghiệm thu của lần dựng lại này.

### 7.3 Ba file đã viết lại

| Đường dẫn | Dòng | md5 (bản mới) | Nội dung |
|---|---:|---|---|
| `05_VERIFICATION/golden_model/a04_reference.sv` | 110 | `b0618a13be11777b6904353d18b4ce61` | Mô hình chuẩn SV: **tám biểu thức rời rạc**, không dùng bộ cộng dùng chung; `C` của phép trừ lấy thẳng từ so sánh `a >= b` |
| `05_VERIFICATION/golden_model/reference_model.py` | 291 | `3a184fddd4688877629c2f74294f679e` | Python thuần: 30 ca có tên + 7 bất biến INV-1…INV-7 trên 2 048 tổ hợp + đo lại bảng phủ cờ `Z` |
| `05_VERIFICATION/testbench/a04_tb.sv` | 308 | `8434a3ba7e6e82e6960f62acafaf77ef` | Testbench: 24 ca Charter mục 8 + 6 ca tự xây + quét vét cạn 2 048, kiểm 4 bất biến mỗi vector |

Ba file này được **viết lại từ đầu** theo đúng RTL hiện có cùng các tài liệu còn nguyên
(`02_SPECIFICATION/functional_spec.md`, `02_SPECIFICATION/corner_cases.md` và chính
PATCHLOG này), **không** phải khôi phục theo từng byte. Do đó md5 của chúng **khác** md5
từng ghi ở các mục trên — điều này là bình thường và không ảnh hưởng tới kết quả, vì tiêu
chí nghiệm thu là **hành vi và số liệu**, không phải giá trị băm của file kiểm thử.

### 7.4 Kết quả xác minh lần này

Chạy đúng ba lệnh của `REDESIGN_SPEC.md` §2, cùng thư viện `sky130hd.lib`:

| Tầng | Kết quả lần này | Số ghi ở §4 | Khớp? |
|---|---|---|:-:|
| Mô hình chuẩn Python | **PASS**, thoát 0 | PASS (exit 0) | ✅ |
| Biên dịch Icarus Verilog 12.0 | **0 lỗi, 0 cảnh báo** | 0 lỗi | ✅ |
| Mô phỏng RTL | **PASS** — 2 078 vector, 0 lệch REF, 0 vi phạm bất biến | 2 078 vector, 0 lệch | ✅ |
| Quét vét cạn | **2 048/2 048** tổ hợp (`2⁴ × 2⁴ × 2³`) | 2 048 tổ hợp | ✅ |
| Ca Charter mục 8 | **24 bắt buộc + 6 tự xây dựng**, tất cả PASS | 24 + 6 | ✅ |
| Vector có `Z = 1` | **222** | 222 | ✅ |
| Tổng hợp Yosys | **PASS** | PASS | ✅ |
| Số cell | **64** | 64 | ✅ |
| **Flip-flop** | **0** | 0 | ✅ |
| Chốt (latch) | **0** — Yosys báo *“No latch inferred”* cho cả `result` lẫn `cflag` | 0 | ✅ |
| Diện tích | **417,9008 µm²** | 417,9008 µm² | ✅ |

Dòng tổng kết của mô phỏng, trùng khít dòng đã ghi ở §4:

```
TONG KET: chay=2078  lech REF=0  vi pham bat bien=0  (Z=1: 222 vector)
          ca co ten=30 (24 bat buoc + 6 tu xay dung), vet can=2048
A04 exhaustive validation PASS - DUT khop REF tren toan bo khong gian dau vao.
```

Con số **222** đáng chú ý vì nó kiểm chéo được bằng tay: 210 vector `Z=1` trong
vòng vét cạn (16+16+81+1+16+16+32+32, đúng bảng §4.2 của `corner_cases.md`) cộng
12 ca có tên có `Z=1` (TC-001, 003, 006, 008, 011, 014, 017, 020, 023, 027, 029,
030) — tổng **222**.

### 7.5 Kiểm chứng testbench mới **không rỗng**

Một testbench luôn báo PASS thì vô giá trị, nên bộ đột biến dưới đây được cấy vào RTL
trong thư mục tạm rồi chạy lại **cùng** testbench vừa dựng. RTL nộp bài **không** chứa
chúng.

| Đột biến cấy vào RTL | Bị bắt ở |
|---|---|
| Quên carry-in của phép trừ: `carry[0] = sub` → `carry[0] = 1'b0` | **TC-004** (`5−3`) — DUT trả 1 thay vì 2 |
| Nhánh NOT lấy nhầm toán hạng: `r_not = ~a` → `~b` | **TC-017** (`¬15`, `B=9`) — đúng cặp bẫy đã thiết kế ở `corner_cases.md` §2 |
| Cờ C của phép dịch phải nối cứng: `c_shr = a[0]` → `1'b1` | **TC-022** (`2 >> 1`) |
| Cờ Z kẹt ở 0: `zflag = ~(|result)` → `1'b0` | **TC-001** (`0+0`) |
| Dịch phải **số học** thay vì logic: `{1'b0, a[3:1]}` → `{a[3], a[3:1]}` | **TC-024** (`15 >> 1`) — đúng ca đã đặt ra để bắt lỗi này |

Đột biến cuối cùng đáng chú ý: nó chỉ sai khi `a[3] = 1`, nên một bộ ca chỉ dùng
toán hạng nhỏ sẽ **không** bắt được. TC-024 (`15 >> 1`, kỳ vọng 7 chứ không phải 15)
được đặt ra từ đầu đúng để đóng lỗ hổng đó — và nó đã làm đúng việc của mình.

### 7.6 Phạm vi thay đổi

**Đã sửa:** đúng ba file ở §7.3, cộng với chính mục này.
**Không chạm vào:** `04_IMPLEMENTATION/rtl/` (RTL giữ nguyên byte-by-byte),
`08_ORIGINAL_SOURCE/{rtl,golden_model,testbench}/`, `01_REQUIREMENT/`, `02_SPECIFICATION/`,
`03_ARCHITECTURE/`, `06_GDSII/`, `07_TRACEABILITY/`, `README.md`,
`implementation-notes_*`, `04_IMPLEMENTATION/{scripts,constraints}`.

Các file log trong `05_VERIFICATION/` (`simulation.log`, `python_reference_run.log`,
`iverilog_compile.log`, `test_matrix.csv`) **chưa được cập nhật** ở bước này — chúng nằm
ngoài ba thư mục mã nguồn được phép sửa và sẽ được **sinh lại tự động** ở lần chạy chuỗi
công cụ kế tiếp.

### 7.7 Điều lần dựng lại này **không** chứng minh

- Chưa mô phỏng gate-level trên netlist sau tổng hợp;
- Chưa chạy P&R, chưa có DRC/LVS/GDS, chưa mô phỏng có back-annotate SDF;
- Số liệu STA/công suất trích ở các mục trên là của lần chạy trước, **không** được đo lại
  ở bước này (bước này chỉ chạy ba lệnh bắt buộc của `REDESIGN_SPEC.md` §2).

---

*Phiên bản: v1.1 · Ngày: 2026-09-24 · Cập nhật: dựng lại mô hình chuẩn và testbench sau sự cố bộ sinh ghi đè.*
