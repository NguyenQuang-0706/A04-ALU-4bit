# A04 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> Charter mục 9 — **Phân tích riêng (bắt buộc trả lời bằng số liệu):**
> *"Từ báo cáo tổng hợp, ước lượng phần diện tích dành cho bộ ghép kênh chọn phép so với
> phần diện tích dành cho các phép tính. Bàn về chi phí của tính linh hoạt."*

Toàn bộ tài liệu này phục vụ việc trả lời câu đó bằng số đo, chứ không bằng cảm nhận.

## 2. Đo tách diện tích — cách làm và kết quả

### 2.1 Vì sao không đọc thẳng được từ một báo cáo

`stat` của Yosys cho **một** con số tổng cho cả module. Nó không nói phần nào là mux, phần
nào là phép tính. Vì vậy phải dùng cách của A01: **tổng hợp nhiều phiên bản, cùng thư
viện, cùng script, rồi so sánh**.

### 2.2 Ba biến thể đo

Ba biến thể dưới đây được chép **nguyên văn** từ các mục tương ứng của
`04_IMPLEMENTATION/rtl/a04_alu4.sv`, chỉ đổi phần cổng vào/ra:

| Biến thể | Nội dung | Tương ứng mục nào của RTL |
|---|---|---|
| **V-FUNC** | Tám nhánh chức năng, **không** có bộ ghép kênh; cả 8 kết quả đưa thẳng ra cổng | mục 2, 3, 4 |
| **V-SEL** | Giải mã `sub` + bộ ghép kênh 8→1 rộng 5 bit; tám ứng viên là **cổng vào** | mục 1, 5 |
| **V-FLAGZ** | Chỉ cây NOR sinh `zflag` | mục 6 |

Lệnh tổng hợp giống hệt lệnh dùng cho bản nộp bài (Yosys 0.33, `sky130_fd_sc_hd`,
`tt_025C_1v80`), chỉ đổi `-top`.

### 2.3 Kết quả đo

| Phần | Cell | Diện tích | Tỉ lệ trên A04 thật |
|---|---:|---:|---:|
| **V-FUNC** — tám phép tính | 30 | **216,4576 µm²** | **51,8 %** |
| **V-SEL** — giải mã + bộ ghép kênh | 27 | **193,9360 µm²** | **46,4 %** |
| **V-FLAGZ** — cờ `Z` | 1 | 6,2560 µm² | 1,5 % |
| *Tổng ba phần* | *58* | *416,6496 µm²* | *99,7 %* |
| **A04 thật (tổng hợp một lượt)** | **64** | **417,9008 µm²** | **100 %** |

Tổng ba phần rời (416,6496 µm²) chỉ lệch **0,3 %** so với thiết kế tổng hợp một lượt
(417,9008 µm²). Nghĩa là ba phần gần như **không chồng lấn**, và phép tách ở trên là
**phép tách hợp lệ**, không phải chia bừa.

### 2.4 Trả lời Charter mục 9

> **Bộ ghép kênh chọn phép chiếm 193,9360 µm² trên tổng 417,9008 µm², tức 46,4 % diện
> tích của cả ALU — gần bằng toàn bộ tám phép tính cộng lại (51,8 %).**
>
> Nói cách khác: cứ **1 µm² dùng để tính**, A04 phải trả thêm **0,90 µm² chỉ để chọn xem
> đang tính gì**.

Phân tích thêm cho thấy sự mất cân đối còn rõ hơn:

| Phần | Cell | Diện tích |
|---|---:|---:|
| Bộ cộng/trừ dùng chung (nhánh **đắt nhất** trong tám nhánh) | 14 | 128,8736 µm² |
| Bốn nhánh logic + hai nhánh dịch **cộng lại** | 16 | 100,0960 µm² |
| **Bộ ghép kênh chọn phép** | **27** | **193,9360 µm²** |

**Bộ ghép kênh một mình đắt hơn bộ cộng/trừ 50 %, và đắt gần gấp đôi cả sáu nhánh
logic + dịch cộng lại.**

### 2.5 Bàn về chi phí của tính linh hoạt

Ba nhận xét rút ra từ chính số liệu trên:

1. **Chi phí chọn tỉ lệ với số phép, chi phí tính thì không.** Thêm một phép logic mới
   chỉ tốn ~4 cổng ở nhánh, nhưng làm bộ ghép kênh rộng thêm một đường vào ×5 bit. Ở quy
   mô 4 bit, vế thứ hai mới là vế lớn.
2. **Nhánh rẻ nhất lại làm mux đắt nhất.** Hai nhánh dịch tốn **0 cell** (nối dây thuần)
   nhưng vẫn chiếm 2/8 đường vào của bộ ghép kênh — chúng "miễn phí khi tính" nhưng
   "phải trả tiền khi chọn". Đây là điểm phản trực giác đáng nói nhất khi bảo vệ.
3. **Linh hoạt còn tốn cả tốc độ, không chỉ diện tích.** Đường tới hạn của khối là
   `op[2] → zflag` (1,85 ns), dài hơn **78 %** so với đường đi hết chuỗi carry 4 tầng
   `a[0] → cflag` (1,04 ns). Tức là chi phí của tính linh hoạt xuất hiện ở **cả hai trục**.

## 3. Đánh đổi lớn nhất: **một** bộ cộng dùng chung hay **hai** đơn vị riêng

Đây là ràng buộc kiến trúc bắt buộc của đề, và là câu hỏi trọng tâm khi bảo vệ. Số liệu
đo được, cùng thư viện, cùng script:

| Biến thể đo | Cell | Diện tích |
|---|---:|---:|
| V-ADD — chỉ cộng, không có đường trừ | 13 | 95,0912 µm² |
| **V-ADDSUB — cộng/trừ dùng chung (A04 chọn)** | **14** | **128,8736 µm²** |
| V-TWO — hai đơn vị riêng (một cộng + một trừ) | 27 | 186,4288 µm² |
| **V-SEL — mux với 7 đường vào phân biệt (A04)** | **27** | **193,9360 µm²** |
| V-SEL8 — mux với 8 đường vào phân biệt | 37 | 290,2784 µm² |
| V-LOGSH — bốn nhánh logic + hai nhánh dịch | 16 | 100,0960 µm² |
| V-FLAGZ — cờ `Z` | 1 | 6,2560 µm² |

Ghép lại thành hai phương án ALU hoàn chỉnh (cộng các phần đo riêng, để so cùng cách đo):

| Phương án | Bộ số học | Logic+dịch | Ghép kênh | Cờ Z | **Tổng** |
|---|---:|---:|---:|---:|---:|
| **Một bộ cộng dùng chung (A04)** | 128,8736 | 100,0960 | 193,9360 | 6,2560 | **429,1616 µm² · 58 cell** |
| Hai đơn vị số học riêng | 186,4288 | 100,0960 | 290,2784 | 6,2560 | **583,0592 µm² · 81 cell** |

> **Dùng chung một bộ cộng tiết kiệm 153,8976 µm² — tức 26,4 % diện tích của cả ALU, và
> 23 trên 81 cell.**

Và nó tiết kiệm ở **hai chỗ cùng lúc**, điều mà sinh viên hay bỏ sót:

| Nơi tiết kiệm | Giảm | Vì sao |
|---|---:|---|
| Bộ số học | −57,5552 µm² (−30,9 %) | Chỉ một chuỗi carry thay vì hai |
| **Bộ ghép kênh** | **−96,3424 µm² (−33,2 %)** | ADD và SUB nối vào **cùng một dây**, nên mux 8 vào chỉ còn **7 nguồn phân biệt** |

Phần tiết kiệm ở bộ ghép kênh **lớn hơn** phần tiết kiệm ở chính bộ số học. Đó là lập luận
mạnh nhất cho ràng buộc "một bộ cộng dùng chung" của đề.

### Cái giá phải trả

| Giá | Số liệu |
|---|---|
| Mã lệnh chui vào đường dữ liệu số học | `sub` phải tính **xong** rồi bộ cộng mới bắt đầu |
| Đường tới hạn xuất phát từ `op[2]` chứ không từ `a`/`b` | 1,85 ns so với 1,36 ns (đường dữ liệu chậm nhất) |
| Cell đầu đường tới hạn là bộ giải mã `sub` | 0,43 ns — **23 %** toàn đường |
| Chuỗi carry dài nhất thuộc về phép **trừ** | 4 tầng (TC-006, TC-030) so với 3 tầng của phép cộng |

**Kết luận:** với một vi điều khiển 4 bit dạy học, đổi 0,49 ns độ trễ lấy 26,4 % diện tích
là đánh đổi **đúng**. Với một CPU cần tần số cao thì phải xem lại — nhưng đó là bài toán
khác, và Charter mục 3 không đặt ra.

## 4. So ba kiến trúc ALU (hai phương án thay thế đều **ngoài phạm vi**)

| Kiến trúc | Diện tích | Độ trễ | Độ phức tạp | Dùng khi |
|---|---|---|---|---|
| **Tính hết rồi chọn** (A04) | `O(số phép)` cho nhánh **cộng** `O(số phép)` cho mux | 1 lần lan truyền | Rất đơn giản | Ít phép, cần một chu kỳ, ưu tiên đơn giản |
| ALU lặp (một phép mỗi chu kỳ, dùng lại phần cứng) | Nhỏ hơn nhiều | `k` chu kỳ | Cần FSM + thanh ghi | Rất chặt diện tích, chịu được chậm |
| ALU dựa trên bit-slice 74181 kinh điển | Tương đương | 1 lần lan truyền | Mã hoá phép phức tạp, khó đọc | Khi cần > 8 phép trên cùng phần cứng |

> ⚠️ **Ràng buộc phạm vi:** phương án ALU lặp làm đổi loại mạch từ **Tổ hợp** sang
> **Tuần tự** — vi phạm phân loại Charter. Phương án 74181 hợp lệ về loại mạch nhưng phá
> yêu cầu "tám nhánh chức năng tường minh" của đề. Bảng này chỉ để **so sánh trên giấy**
> khi bảo vệ.

### Vì sao "tính hết rồi chọn" là lựa chọn đúng cho vi điều khiển dạy học

| Tiêu chí của ứng dụng | Kiến trúc đã chọn đáp ứng? |
|---|---|
| Mỗi lệnh phải xong trong **một** chu kỳ | ✅ Một lần lan truyền, 1,85 ns |
| Quy mô Charter ước lượng ~200–300 cell · 1×1 tile | ✅ **64 cell · 417,90 µm²** — nhỏ hơn cả cận dưới của ước lượng |
| Ngân sách 24 chân | ✅ Dùng 17/24 |
| Phải **đọc được** để dạy | ✅ Tám nhánh nằm rõ ràng, ánh xạ 1-1 với bảng mã lệnh |
| Cần tần số cao | ❌ Không cần |

## 5. Đánh đổi nhỏ hơn: tính `Z` trước hay sau bộ ghép kênh

Cả hai phương án đều đã được **tổng hợp thật** để so, không ước lượng:

| | Tính **sau** mux (A04 chọn) | Tính **trước** mux |
|---|---|---|
| Cây NOR4 | **1 cell · 6,2560 µm²** (V-FLAGZ) | **8 cell · 50,0480 µm²** (V-FLAGZ8) |
| Bề rộng mux | 5 bit — **27 cell · 193,9360 µm²** (V-SEL) | 6 bit — **31 cell · 223,9648 µm²** (V-SEL6) |
| **Cộng lại** | **28 cell · 200,1920 µm²** | **39 cell · 274,0128 µm²** |
| Độ trễ tới `zflag` | **dài hơn** — nối tiếp sau mux | ngắn hơn — tám cây NOR chạy song song với nhau |
| Đo được | `zflag` 1,85 ns so với `cflag` 1,35 ns ⟹ **+0,50 ns** | — |

A04 đổi **+0,50 ns độ trễ** lấy **−73,8208 µm² (−26,9 %) và −11 cell**. Với ứng dụng này là đúng;
nếu `zflag` không nằm trên đường tới hạn thì đây sẽ là lựa chọn hiển nhiên — nhưng STA cho
thấy nó **có** nằm trên đường tới hạn, nên đây là một đánh đổi có ý thức, không phải may.

## 6. Những đánh đổi **không** được phép trong đề này

| Cám dỗ | Vì sao không được |
|---|---|
| Viết `result = sub ? a - b : a + b` cho gọn | Công cụ sẽ sinh **hai** mạch số học riêng — mất đúng thứ Charter mục 2 câu 1 yêu cầu quan sát, và mất luôn 26,4 % diện tích |
| Viết `a << 1` thay cho `{a[2:0], 1'b0}` | Gợi ý bộ dịch tham số hoá; A04 chỉ có dịch 1 bit cố định |
| Thêm cờ `V` (tràn có dấu) cho "đầy đủ" | Charter mục 3 xếp **ngoài phạm vi** |
| Thêm phép nhân vào mã lệnh thứ 9 | Ngoài phạm vi, và `op` chỉ có 3 bit |
| Thêm thanh ghi để "chạy nhanh hơn" | Đổi loại mạch, vi phạm Charter mục 10 |
| Sửa netlist bằng tay | Ngoài phạm vi (Charter mục 3) |

## 7. Cách tái hiện toàn bộ số liệu ở tài liệu này

Mỗi biến thể là một file `.sv` độc lập chứa **đúng các dòng đã chép từ RTL nộp bài**, rồi
chạy cùng một lệnh:

```bash
LIB=<đường dẫn>/sky130hd.lib
yosys -Q -p "read_verilog -sv <bien_the>.sv; \
  hierarchy -check -top <ten_module>; proc; opt; fsm; opt; memory; opt; \
  techmap; opt; dfflibmap -liberty \$LIB; abc -liberty \$LIB; \
  setundef -zero; splitnets; opt_clean -purge; stat -liberty \$LIB"
```

Cột cần đọc: `Number of cells` và `Chip area for module`. Cách dựng từng biến thể được mô
tả ở §2.2 và §3; nội dung của chúng là trích nguyên văn từ
`04_IMPLEMENTATION/rtl/a04_alu4.sv`, nên không có chỗ nào để "chỉnh cho đẹp số".

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: Charter mục 2 câu 1, mục 9.*
