# A04 · Đặc tả chức năng (Functional Specification)

Tài liệu này định nghĩa **hành vi đúng** của khối A04, độc lập với cách hiện thực.
Đây là văn bản chuẩn mà golden model và testbench đều phải tuân theo.

---

> ## ⚠️ Ghi chú truy vết nguồn — đọc trước
>
> Gói nguồn ban đầu của đề này (`A04_PriorityEncoder_Implementation_Validation`) **không**
> chứa thiết kế của đề A04. Nó chứa một **bộ mã hoá ưu tiên 8→3** (`a04_priority_encoder`),
> tức là mã nguồn của một **danh mục đề cũ**. Khi đó `REQ-A04-001` ở trạng thái
> **CHƯA THOẢ**: hồ sơ có bằng chứng cho một khối, nhưng Charter lại đòi một khối khác.
>
> Giảng viên đã duyệt phương án **viết lại RTL cho đúng đề**. Bản gốc được đóng băng
> nguyên trạng tại `08_ORIGINAL_SOURCE/`, và toàn bộ diễn biến được ghi ở
> `05_VERIFICATION/known_issues.md` cùng `08_ORIGINAL_SOURCE/PATCHLOG.md`.
>
> **Trạng thái hiện tại:** `REQ-A04-001` đã **THOẢ** — khối được đặc tả dưới đây là ALU
> 4-bit tám chức năng, đã mô phỏng vét cạn và tổng hợp thật. Phần mô tả bộ mã hoá ưu tiên
> chỉ còn tồn tại ở `08_ORIGINAL_SOURCE/` với tư cách **tư liệu**, không còn là đối tượng
> của hồ sơ này.

---

## 1. Khối làm gì

A04 là **đơn vị số học logic (ALU) 4-bit** cho một vi điều khiển 4 bit dạy học
(Charter mục 1). Nó nhận hai toán hạng 4 bit và một **mã lệnh 3 bit**, rồi trả về một kết
quả 4 bit kèm **hai cờ trạng thái** `C` và `Z`.

Tám phép — vừa đủ để chạy các lệnh số học và logic cơ bản của một tập lệnh tối giản:

| `op` | Tên | `result` | `cflag` (C) | Nhóm |
|:---:|---|---|---|---|
| `000` | **ADD** | `(A + B) mod 16` | `1` ⟺ `A + B ≥ 16` (tràn không dấu) | Số học |
| `001` | **SUB** | `(A − B) mod 16` | `1` ⟺ `A ≥ B` (**không** mượn) | Số học |
| `010` | **AND** | `A ∧ B` | `0` | Logic |
| `011` | **OR** | `A ∨ B` | `0` | Logic |
| `100` | **XOR** | `A ⊕ B` | `0` | Logic |
| `101` | **NOT** | `¬A` — `B` **bị bỏ qua** | `0` | Logic (một ngôi) |
| `110` | **SHL** | `{A[2:0], 0}` — dịch trái 1 bit | `A[3]` (bit bị đẩy ra) | Dịch |
| `111` | **SHR** | `{0, A[3:1]}` — dịch phải 1 bit, chèn 0 | `A[0]` (bit bị đẩy ra) | Dịch |

Và với **cả tám** phép:

```
zflag  =  1  ⟺  result == 4'b0000
```

### 1.1 Quy ước cờ `C` cho phép trừ — điểm dễ cãi nhau nhất

Có **hai** quy ước phổ biến, và chúng **ngược nhau**:

| Quy ước | `C` khi `A ≥ B` | `C` khi `A < B` | Ví dụ họ vi xử lý |
|---|:-:|:-:|---|
| **Carry = "không mượn"** ← **A04 chọn quy ước này** | `1` | `0` | ARM, 6502 |
| Borrow = "có mượn" | `0` | `1` | x86 (`CF` sau `SUB`) |

A04 chọn quy ước thứ nhất vì nó rơi ra **miễn phí**: nó **chính là** carry-out của phép
`A + (¬B) + 1` trên bộ cộng dùng chung — không tốn thêm một cổng đảo nào. Chọn quy ước kia
sẽ phải trả thêm một cổng `INV` nằm **trên** đường tới hạn.

> Firmware phải biết quy ước này. Nó được ghi trong bảng ở §1 và được kiểm bằng TC-004
> (`5−3`, `C=1`) và TC-005 (`3−5`, `C=0`).

## 2. Đặc tả cấu trúc bắt buộc — kiến trúc bị ràng buộc, không chỉ hành vi

Tên đề là **"ALU tám chức năng"** và Charter mục 2 hỏi *"tám phép dùng chung phần cứng
nào"*, mục 9 đòi *"ước lượng phần diện tích dành cho bộ ghép kênh so với phần dành cho các
phép tính"*. Vì vậy hành vi ở §1 **chưa đủ**: cách hiện thực cũng bị ràng buộc.

### RB-1 · Kiến trúc "tính hết rồi mới chọn"

```
   A, B ──▶ tám nhánh chức năng, tính SONG SONG và LUÔN LUÔN tính
                                │
   op   ──▶ bộ ghép kênh 8 → 1, rộng 5 bit ({C, result})
                                │
                         result, C ──▶ Z = NOR(result)
```

### RB-2 · Phép cộng và phép trừ dùng **chung một** bộ cộng

```
b_eff   = B ⊕ {4{sub}}          ← sub = 1 thì đảo bit B
carry_0 = sub                   ← sub = 1 thì cộng thêm 1
với i = 0..3:
    result_arith[i] = A[i] ⊕ b_eff[i] ⊕ carry_i
    carry_{i+1}     = (A[i] ∧ b_eff[i]) ∨ (A[i] ∧ carry_i) ∨ (b_eff[i] ∧ carry_i)
c_arith = carry_4
```

Nền tảng toán học là đồng nhất thức bù 2 — được kiểm trên **cả 256** cặp `(A,B)` bởi bất
biến INV-7 trong `reference_model.py`:

```
A + (¬B) + 1  ≡  A − B   (mod 16)
carry_out = 1 ⟺ A ≥ B
```

### RB-3 · Những gì **không** được viết trong RTL nộp bài

| Cấm | Vì sao |
|---|---|
| `result = a + b;` / `a - b;` | Xoá mất chuỗi carry tường minh, không đếm được tầng |
| `sub ? a - b : a + b` | Cho công cụ tự do sinh **hai** mạch số học riêng — mất đúng thứ Charter mục 2 câu 1 yêu cầu quan sát |
| `a << 1` / `a >> 1` | Gợi ý một bộ dịch tham số hoá; A04 chỉ dịch 1 bit cố định (nối dây) |

Các toán tử đó **chỉ** được dùng trong `05_VERIFICATION/golden_model/`, nơi chúng đóng vai
trò chuẩn so sánh **độc lập**.

## 3. Bảng ánh xạ cổng ↔ Charter mục 4

Charter mục 4 dùng tên chung của ô Tiny Tapeout. RTL dùng tên gợi nhớ:

| Cổng RTL | Hướng | Rộng | Chân Charter mục 4 | Ghi chú |
|---|---|---:|---|---|
| `a[3:0]` | vào | 4 | `ui_in[3:0]` | Toán hạng A |
| `b[3:0]` | vào | 4 | `ui_in[7:4]` | Toán hạng B |
| `op[2:0]` | vào | 3 | `uio_in[2:0]` | Mã phép |
| `result[3:0]` | ra | 4 | `uo_out[3:0]` | Kết quả |
| `zflag` | ra | 1 | `uo_out[4]` | `{C,Z}` — bit thấp là `Z` |
| `cflag` | ra | 1 | `uo_out[5]` | `{C,Z}` — bit cao là `C` |

**Ngân sách chân:** 11 bit vào + 6 bit ra = **17 trên 24 chân**. Ánh xạ đã khả thi,
**không có điểm mở** nào về giao diện (khác với A01, nơi 28 bit không vừa 24 chân).
Còn dư 7 chân — đủ chỗ nếu sau này muốn thêm cờ `N`/`V`, nhưng Charter mục 3 xếp
**cờ tràn có dấu** vào **ngoài phạm vi**, nên A04 **không** hiện thực chúng.

Ba chân `uio` dùng làm **đầu vào**, nên `uio_oe` phải đặt về chế độ input cho `uio[2:0]`.
Lớp vỏ vật lý đó **không** thuộc gói này — gói này chỉ có lõi tổ hợp.

## 4. Tính chất bất biến (invariants)

| ID | Bất biến | Kiểm ở đâu |
|---|---|---|
| INV-1 | `ADD`: `{C, result} == A + B` (ghép 5 bit) | `reference_model.py` |
| INV-2 | `SUB`: `result == (A−B) mod 16` **và** `C == (A ≥ B)` | `reference_model.py` |
| INV-3 | `Z == (result == 0)` — đúng cho **cả tám** phép | testbench + Python |
| INV-4 | Bốn phép logic (`AND/OR/XOR/NOT`) **luôn** cho `C == 0` | testbench + Python |
| INV-5 | Dịch 1 bit: bit bị đẩy ra luôn xuất hiện ở `C` | `reference_model.py` |
| INV-6 | `NOT` là phép **một ngôi**: kết quả không phụ thuộc `B` | testbench + Python |
| INV-7 | `A + (¬B) + 1 ≡ A − B` và carry-out `== (A ≥ B)` — **nền tảng của bộ cộng dùng chung** | `reference_model.py` |
| INV-8 | Không đầu ra nào ở trạng thái `X`/`Z` với đầu vào hợp lệ | testbench |
| INV-9 | Không tín hiệu nào phụ thuộc lịch sử đầu vào | 0 flip-flop + 0 chốt sau tổng hợp |

INV-7 là bất biến đáng chú ý nhất: nó **không** nói về hành vi của khối, mà nói về **giả
thiết mà kiến trúc dựa vào**. Nếu INV-7 sai thì kiến trúc "một bộ cộng dùng chung" sụp đổ,
dù bảng hành vi ở §1 vẫn có thể đúng.

## 5. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi quy định |
|---|---|
| `op` nhận cả 8 giá trị | **Toàn bộ 8 giá trị đều hợp lệ** — không có mã lệnh dự phòng, không có "lệnh cấm" |
| `A`, `B`, `op` có bit `X`/`Z` | **Không** đặc tả. A04 là lõi tổ hợp; tầng ngoài phải bảo đảm đầu vào hợp lệ. Nhánh `default` trong RTL chặn X lan sang đầu ra trong **mô phỏng**, nhưng đó là tiện ích gỡ lỗi, không phải bảo hành. |
| `op = 101` (NOT) với `B` bất kỳ | `B` **bị bỏ qua hoàn toàn** — INV-6 |
| Không có clock | Đúng như thiết kế. Không được thêm. |
| Không có reset | Đúng như thiết kế. Mạch tổ hợp không có trạng thái để reset. |
| Đầu vào đổi giá trị | Đầu ra có thể **glitch** trong thời gian lan truyền. Tầng ngoài phải lấy mẫu sau khi đã ổn định — xem `03_ARCHITECTURE/timing_diagram.md`. |
| Đổi `op` mà giữ nguyên `A`,`B` | Vẫn là mạch tổ hợp: kết quả chỉ phụ thuộc `(A,B,op)` hiện tại, **không** phụ thuộc phép trước đó. |

## 6. Không gian đầu vào

```
2^4 (A) × 2^4 (B) × 2^3 (op) = 16 × 16 × 8 = 2 048 tổ hợp
```

Đủ nhỏ để **quét vét cạn**. Vì vậy A04 không cần kiểm thử ngẫu nhiên có ràng buộc: kiểm
chứng vét cạn là **chứng minh hoàn chỉnh ở mức hành vi** đối với mô hình chuẩn.

Kết quả thật: **2 048/2 048 khớp, 0 lệch, 0 vi phạm bất biến** (tổng 2 078 vector kể cả
30 ca có tên) — xem `05_VERIFICATION/simulation.log`.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: REQ-A04-001…023.*
