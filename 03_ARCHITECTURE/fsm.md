# A04 · Máy trạng thái (FSM)

---

## 1. Kết luận: **A04 KHÔNG có FSM** — và đây là câu trả lời đúng

> Một mạch tổ hợp không có trạng thái. Không có trạng thái thì không có máy trạng thái.

Tài liệu này tồn tại trong form chuẩn để giữ cấu trúc thống nhất cho cả 80 đề. Với A04,
nội dung đúng là **giải thích vì sao không có**, chứ không phải vẽ một sơ đồ trạng thái giả.

## 2. Bẫy riêng của đề A04 — "tám phép" nghe rất giống "tám trạng thái"

Đây là chỗ sinh viên hay vẽ nhầm:

```
        ❌ SƠ ĐỒ SAI — ĐỪNG NỘP CÁI NÀY

        ┌─────┐ op=001 ┌─────┐ op=010 ┌─────┐
        │ ADD │───────▶│ SUB │───────▶│ AND │ ─── …
        └─────┘        └─────┘        └─────┘
```

Sơ đồ trên sai vì nó ngụ ý ba điều **đều không đúng** với A04:

| Sơ đồ ngụ ý | Thực tế A04 |
|---|---|
| ALU "đang ở" một phép nào đó | ALU tính **cả tám** phép **cùng lúc**, mọi lúc |
| Phải "chuyển" từ phép này sang phép kia | Chỉ đổi giá trị trên dây chọn — không có chuyển tiếp |
| Kết quả phụ thuộc phép **trước đó** | Kết quả chỉ phụ thuộc `(A, B, op)` **hiện tại** |

Tám giá trị của `op` là **tám nhãn trên một dây chọn**, không phải tám trạng thái được
ghi nhớ. Nhãn nằm trên dây; trạng thái nằm trong ô nhớ. A04 không có ô nhớ nào.

## 3. Ba bằng chứng A04 không có trạng thái

| # | Bằng chứng | Nơi kiểm |
|---|---|---|
| 1 | RTL **không có** `always_ff`, không có `posedge`, không có toán tử `<=` phi khối | `04_IMPLEMENTATION/rtl/a04_alu4.sv` |
| 2 | Tổng hợp cho **0 flip-flop và 0 chốt** — toàn bộ **64 cell** đều là cổng tổ hợp | `06_GDSII/synthesis/synth_stat.txt` |
| 3 | Module **không có cổng** `clk` hay `rst` | `02_SPECIFICATION/interface.md` |
| 4 | `report_power` cho **100,0 % công suất thuộc nhóm Combinational, 0,0 % Sequential** | `06_GDSII/power/power_report.txt` |

Bằng chứng 2 và 4 đến từ **hai nguồn độc lập** (bảng cell của Yosys và báo cáo công suất
của OpenSTA), nên chúng xác nhận lẫn nhau.

Trích bảng cell thật sau tổng hợp (Yosys 0.33 + `sky130_fd_sc_hd`): toàn bộ 64 cell đều
thuộc họ tổ hợp — `nand2_1` (8), `nor2_1` (8), `a21oi_1` (5), `nand2b_1` (5), `xnor2_1` (4),
`clkinv_1` (3), `o21ai_0` (3), `o22ai_1` (3), `maj3_1` (1), `xor3_1` (1), … **Không có một
cell `__df*`, `__dl*` hay `__sd*` nào.**

## 4. Thí nghiệm: FSM sẽ xuất hiện **như thế nào** nếu làm sai

Charter mục 10 nói: *"Dấu hiệu làm đúng: 0 ô nhớ. NẾU báo cáo có ô nhớ thì gần như chắc
chắn thiếu nhánh default."* Gói này đã **dựng lại đúng tình huống đó** để đo:

| Biến thể `case` | Kết quả tổng hợp |
|---|---|
| Có gán mặc định · 8 nhánh · có `default` (**bản nộp bài**) | **0 ô nhớ** |
| Chỉ còn **một** trong hai lớp phòng vệ (bỏ gán mặc định, **hoặc** bỏ `default`) | **0 ô nhớ** — netlist giống hệt bản nộp bài |
| Không gán mặc định · **7 nhánh** · không `default` · `always_comb` | Yosys **dừng hẳn**: `ERROR: Latch inferred for signal '\result'` |
| Không gán mặc định · **7 nhánh** · không `default` · `always @(*)` | **5 chốt `$_DLATCH_N_`** lọt vào netlist (4 cho `result`, 1 cho `cflag`) |

Trường hợp thứ ba chính là cái bẫy Charter cảnh báo: mạch **vẫn tổng hợp thành công**,
báo cáo vẫn ra, nhưng trong netlist đã có ô nhớ — và diện tích báo cáo còn **sai** (Yosys
in `Area for cell type $_DLATCH_N_ is unknown!` rồi bỏ qua chúng khi cộng diện tích).

Số liệu và cách tái hiện đầy đủ: `05_VERIFICATION/known_issues.md` §4.

## 5. Nếu buộc phải mô tả A04 bằng ngôn ngữ FSM

Có thể viết A04 như một FSM **một trạng thái duy nhất**, không có chuyển trạng thái:

```
        ┌──────────────────────────────────────┐
        │                                      │
        │   S0: TINH_TO_HOP                    │
   ────▶│   result, C, Z = f(a, b, op)         │
        │                                      │
        └──────────────────────────────────────┘
              (không có cạnh chuyển)
```

Cách mô tả này **đúng về mặt hình thức nhưng vô ích**: nó không thêm thông tin nào. Sinh
viên **không nên** nộp sơ đồ này như "artifact số có chú thích" — artifact hợp lệ cho A04
là **sơ đồ tám nhánh + bộ ghép kênh** (`block_diagram.md` §1) và **waveform**
(`05_VERIFICATION/waveforms/`).

## 6. FSM nằm ở đâu trong hệ thống

FSM thật của vi điều khiển nằm **ngoài** A04: nó là khối lấy lệnh / thực thi, quyết định
khi nào nạp `IR`, khi nào chốt `ACC`, khi nào nhảy theo cờ. Xem `control.md` §3.

## 7. Câu hỏi bảo vệ liên quan

> **Hỏi:** ALU có tám chế độ hoạt động — vậy sao lại nói nó không có trạng thái?
>
> **Đáp:** "Chế độ" ở đây không được **nhớ**. `op` là một đầu vào giống hệt `a` và `b`:
> đổi nó thì đầu ra đổi theo ngay, và không có chỗ nào trong khối ghi lại giá trị cũ của
> nó. Bằng chứng: nếu có, tổng hợp đã phải sinh flip-flop hoặc chốt — thực tế là 0.
>
> **Hỏi:** Vậy thanh ghi giữ `op` nằm ở đâu?
>
> **Đáp:** Ở thanh ghi lệnh `IR`, thuộc tầng ngoài. Đó cũng chính là lý do tầng ngoài phải
> giữ `op` ổn định suốt cửa sổ tính — xem `control.md` §5.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Trạng thái: KHÔNG ÁP DỤNG (có lý giải và bằng chứng).*
