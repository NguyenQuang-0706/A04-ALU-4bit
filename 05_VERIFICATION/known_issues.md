# A04 · Sự cố đã biết và cách xử lý (Known Issues)

Tài liệu này ghi lại các sự cố gặp trong quá trình làm hồ sơ A04, cách phát hiện và cách
xử lý. Mục đích là để người đọc sau **tái hiện được** chuỗi suy luận, không phải để che đi.

---

## 1. SỰ CỐ CHÍNH — gói nguồn chứa thiết kế của **một đề khác**

### 1.1 Hiện tượng

Charter đề A04 là **"Đơn vị số học logic (ALU) 4-bit tám chức năng"**. Nhưng RTL trong gói
nguồn ban đầu là:

```systemverilog
module a04_priority_encoder (
    input  logic [7:0] req,
    output logic [2:0] index,
    output logic       valid
);
```

— tức là một **bộ mã hoá ưu tiên 8→3**, không liên quan gì đến ALU.

### 1.2 Phát hiện thế nào

Bốn dấu hiệu độc lập, mỗi dấu hiệu một mình đã đủ để nghi ngờ:

| # | Dấu hiệu | Đối chiếu |
|---|---|---|
| 1 | **Tên gói zip gốc**: `A04_PriorityEncoder_Implementation_Validation` | Tên gói nói thẳng đây là bộ mã hoá ưu tiên |
| 2 | **Tên module**: `a04_priority_encoder` | Không phải `a04_alu*` |
| 3 | **Bảng cổng không khớp Charter mục 4** | Charter đòi `ui_in[3:0]=A`, `ui_in[7:4]=B`, `uio_in[2:0]=mã phép`, `uo_out[3:0]=kết quả`, `uo_out[5:4]={C,Z}`. RTL gốc chỉ có `req[7:0]`, `index[2:0]`, `valid` — **không có** toán hạng thứ hai, **không có** mã phép, **không có** cờ |
| 4 | **Ca kiểm thử Charter mục 8 không thể chạy** | "Chạy đủ 8 phép với ít nhất 3 cặp toán hạng mỗi phép" — khối gốc **không có** khái niệm "phép" nào để chạy |

Dấu hiệu 3 là dấu hiệu mang tính quyết định: **không có cách đọc lại nào** khiến ba cổng
`req/index/valid` khớp được với giao diện mà Charter mô tả.

### 1.3 Kết luận chẩn đoán

Gói nguồn được lắp theo **một danh mục đề cũ**, trong đó mã A04 trỏ tới bài "bộ mã hoá ưu
tiên". Danh mục đề hiện hành gán mã A04 cho bài "ALU 4-bit tám chức năng". Đây là **lệch
ánh xạ mã đề ↔ nội dung đề**, không phải lỗi của bản thân mã nguồn: `a04_priority_encoder`
tự nó là một thiết kế **đúng và chạy tốt** — nó chỉ thuộc về một đề khác.

### 1.4 Đã xử lý ra sao

Giảng viên duyệt phương án **viết lại RTL cho đúng đề Charter**.

| Việc | Chi tiết |
|---|---|
| Đóng băng bản gốc | `08_ORIGINAL_SOURCE/{rtl,golden_model,testbench}/` — giữ nguyên trạng, **không** sửa một ký tự |
| Viết mới RTL | `04_IMPLEMENTATION/rtl/a04_alu4.sv` |
| Viết mới mô hình chuẩn | `05_VERIFICATION/golden_model/a04_reference.sv` + `reference_model.py` |
| Viết mới testbench | `05_VERIFICATION/testbench/a04_tb.sv` |
| Viết lại tầng 02 và 03 | `02_SPECIFICATION/`, `03_ARCHITECTURE/` |
| Nhật ký đầy đủ | `08_ORIGINAL_SOURCE/PATCHLOG.md` |

### 1.5 Trạng thái sau xử lý

| Trước | Sau |
|---|---|
| `REQ-A04-001` **CHƯA THOẢ** — hồ sơ mô tả một khối, Charter đòi khối khác | `REQ-A04-001` **THOẢ** |
| Ca Charter mục 8 **không chạy được** | 24 ca bắt buộc + 6 ca tự xây dựng + quét vét cạn 2 048 tổ hợp, **tất cả PASS** |
| Mô phỏng PASS nhưng **không chứng minh gì cho đề A04** | Mô phỏng PASS **và** đúng đề |
| 12 cell · 0 FF · 66,3136 µm² (của bộ mã hoá ưu tiên) | **64 cell · 0 FF · 417,9008 µm²** (của ALU) |

### 1.6 Quay lui

```bash
cp 08_ORIGINAL_SOURCE/rtl/*.sv          04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*    05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*.sv    05_VERIFICATION/testbench/
rm -f 04_IMPLEMENTATION/rtl/a04_alu4.sv
```

Sau khi quay lui, hồ sơ trở về đúng trạng thái ban đầu — kể cả trạng thái **CHƯA THOẢ**
của `REQ-A04-001`.

---

## 2. Cú pháp SystemVerilog mà Icarus Verilog 12.0 không nhận

Gặp trong lúc viết testbench mới. Ghi lại vì rất dễ gặp lại ở đề khác.

| # | Cú pháp | Thông báo | Cách thay |
|---|---|---|---|
| 1 | `op inside {3'b010, 3'b011, …}` | `sorry: "inside" expressions not supported yet.` | Viết thành chuỗi `(op === …) \|\| (op === …)` |
| 2 | Chọn bit hằng số trong `always_*`: `result = t[3:0];` | `sorry: constant selects in always_* processes are not currently supported (all bits will be included).` | Gom thành vector: gán **nguyên** `y[4:0]` trong `always_comb`, rồi `assign result = y[3:0];` **ngoài** khối |
| 3 | Đặt tên instance là `ref` | Icarus từ chối — `ref` là **từ khoá** SystemVerilog (đối số truyền tham chiếu) | Đổi thành `ref_m` |

Mục 2 chỉ là **cảnh báo** (danh sách nhạy cảm bị lấy dư), không làm sai kết quả. Vẫn sửa
để log biên dịch sạch — hiện `05_VERIFICATION/iverilog_compile.log` **trống**, không còn
cảnh báo nào.

Mục 3 là lỗi đã có từ bản gốc và đã được ghi trong nhật ký sửa nguồn tối thiểu ban đầu;
testbench mới không dùng tên đó nữa.

---

## 3. Cảnh báo Yosys không ảnh hưởng kết quả

Khi đọc file liberty, Yosys 0.33 in ra 26 loại cảnh báo (234 lần), phần lớn dạng:

```
Warning: Found unsupported expression 'D&!SCE|SCD&SCE' in pin attribute of cell
         'sky130_fd_sc_hd__sdfxtp_1' - skipping.
ABC: Scl_LibertyReadGenlib() skipped sequential cell "sky130_fd_sc_hd__dfxtp_1".
```

Đây là Yosys/ABC **bỏ qua các cell tuần tự và ba trạng thái** khi dựng thư viện ánh xạ tổ
hợp. Với A04 — một mạch tổ hợp thuần — việc bỏ qua chúng **không ảnh hưởng gì**: thiết kế
không cần một cell nào trong số đó.

Thư viện đọc được: `sky130_fd_sc_hd__tt_025C_1v80`, **334 cell** dùng được (94 bị bỏ:
63 tuần tự, 13 ba trạng thái, 18 không có hàm logic, **0 cell `dont_use`**).

---

## 4. THÍ NGHIỆM — rủi ro "quên nhánh default" của Charter mục 10

Charter mục 10 ghi: *"Chỗ hay tắc: Viết case 8 nhánh rồi quên nhánh default — công cụ tự
sinh chốt ngoài ý muốn, ô nhớ xuất hiện trong một mạch tổ hợp. Dấu hiệu làm đúng: 0 ô nhớ."*

Thay vì chỉ chép lại lời cảnh báo, gói này **dựng lại đúng tình huống đó và đo**.

### 4.1 Sáu biến thể

Cả sáu đều xuất phát từ bộ ghép kênh của bản nộp bài, chỉ bỏ đi từng lớp phòng vệ:

| Biến thể | Gán mặc định đầu khối | Số nhánh `case` | Có `default` | Kiểu khối |
|---|:-:|:-:|:-:|---|
| **S0** — như nộp bài | ✅ | 8 | ✅ | `always_comb` |
| S1 | ❌ | 8 | ✅ | `always_comb` |
| S5 | ✅ | **8** | ❌ | `always_comb` |
| S2 | ✅ | 7 | ❌ | `always_comb` |
| S3 | ❌ | 7 | ❌ | `always_comb` |
| S4 | ❌ | 7 | ❌ | `always @(*)` |

### 4.2 Kết quả đo

| Biến thể | Kết quả tổng hợp | Cell | Diện tích | Số chốt |
|---|---|---:|---:|---:|
| **S0** | PASS | 27 | 193,9360 µm² | **0** |
| S1 | PASS | 27 | 193,9360 µm² | **0** |
| **S5** | PASS | **27** | **193,9360 µm²** | **0** |
| S2 | PASS | 27 | 187,6800 µm² | **0** |
| S3 | **Yosys DỪNG HẲN** — `ERROR: Latch inferred for signal '\result'` | — | — | — |
| S4 | PASS (chỉ **cảnh báo**) | 35 | 202,6944 µm² ⚠️ | **5 × `$_DLATCH_N_`** |

S0, S1 và S5 cho netlist **giống hệt nhau** (27 cell · 193,9360 µm²). S2 khác một chút
vì nó bỏ hẳn một nhánh chức năng nên **hàm đã khác**, không so trực tiếp được.

### 4.3 Ba kết luận — hai trong số đó trái với trực giác thông thường

**① Nhánh `default` một mình KHÔNG phải là thứ cứu bạn.**
S1 (bỏ gán mặc định, giữ `default`) và S2 (giữ gán mặc định, bỏ `default`) đều cho **0
chốt**. Chốt chỉ xuất hiện ở S3/S4 khi **mất cả hai**. Nói chính xác: chốt sinh ra khi tồn
tại **một đường đi qua khối mà một tín hiệu ra không được gán** — `default` và gán mặc
định là hai cách khác nhau để đóng cùng một lỗ hổng đó.

**② Cả hai lớp phòng vệ đều MIỄN PHÍ.**
S0, S1 và S5 cho netlist **giống hệt nhau**: 27 cell · 193,9360 µm².

* S0 so S1 ⟹ **gán mặc định** không tốn thêm cell nào khi `case` đã phủ đủ.
* S0 so S5 ⟹ **nhánh `default`** không tốn thêm cell nào khi `op` rộng đúng 3 bit.

Giá bằng 0, lợi là an toàn ⟹ **viết cả hai, luôn luôn**. Không có lý lẽ "tối ưu" nào
biện minh được cho việc bỏ chúng.

**③ Nguy hiểm thật nằm ở `always @(*)`, không nằm ở `default`.**
So S3 với S4 — hai biến thể có **cùng** lỗi logic, chỉ khác từ khoá:

| | `always_comb` (S3) | `always @(*)` (S4) |
|---|---|---|
| Yosys phản ứng | **ERROR — dừng ngay** | **Warning — chạy tiếp** |
| Chốt vào netlist | không có netlist | **5 chốt lọt qua** |
| Diện tích báo cáo | — | **SAI**: Yosys in `Area for cell type $_DLATCH_N_ is unknown!` rồi **bỏ qua** chúng khi cộng, nên 202,6944 µm² **không kể** phần diện tích của 5 ô nhớ |

Ý ③ chỉnh lại chính lời của Charter mục 10. Charter nói *"NẾU báo cáo có ô nhớ thì gần như
chắc chắn thiếu nhánh default"* — đúng, nhưng **chưa đủ**: nếu viết `always_comb` thì bạn
sẽ **không có báo cáo nào để đọc**, vì tổng hợp đã dừng trước đó. Và ngược lại, nếu viết
`always @(*)` thì báo cáo có ra, nhưng **con số diện tích trong đó không đáng tin**.

### 4.4 Cách tái hiện

Dựng sáu file `.sv` theo bảng §4.1 (nội dung chép từ mục 5 của
`04_IMPLEMENTATION/rtl/a04_alu4.sv`), rồi chạy đúng lệnh tổng hợp ở
`03_ARCHITECTURE/tradeoff.md` §7 với `-top` tương ứng. Với S4, tìm dòng
`$_DLATCH_N_` trong bảng cell của `stat`.

---

## 5. Điều **chưa** xử lý được

| Vấn đề | Trạng thái |
|---|---|
| Netlist tương đương RTL về chức năng | ⬜ Chưa mô phỏng gate-level |
| Độ trễ thật sau routing | ⬜ Chưa P&R; 1,85 ns là số **sau tổng hợp**, chưa có RC dây |
| Công suất thật của ứng dụng | ⬜ `1,56e-05 W` dùng activity mặc định, không lấy từ VCD |
| Biên an toàn qua các góc PVT | ⬜ Mới chạy `tt_025C_1v80` |
| DRC · LVS · GDSII | ⬜ Chưa chạy |
| Glitch khi `op` đổi | ⬜ Chỉ suy luận cấu trúc, chưa đo — cần mô phỏng có SDF |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24.*
