# A04 · Ca biên và ca góc (Corner Cases)

Tài liệu này giải thích **vì sao** từng ca được chọn. Danh sách thực thi nằm ở
`05_VERIFICATION/test_matrix.csv`; kết quả nằm ở `05_VERIFICATION/simulation.log`.

---

## 1. Yêu cầu của Charter mục 8

> *"Chạy đủ 8 phép với ít nhất 3 cặp toán hạng mỗi phép; kiểm cờ Z khi kết quả bằng 0.
> Bổ sung ít nhất hai ca tự xây dựng, trong đó có ca biên."*

Nghĩa là tối thiểu `8 × 3 = 24` ca bắt buộc + `≥ 2` ca tự xây dựng. Gói này có **24 + 6 = 30**
ca có tên, rồi **quét vét cạn** toàn bộ 2 048 tổ hợp.

## 2. 24 ca bắt buộc — 8 phép × 3 cặp toán hạng

Mỗi nhóm ba ca được chọn theo cùng một công thức: **một ca thường · một ca làm `Z=1` ·
một ca đẩy phép tới biên của nó**.

| TC | op | A | B | result | C | Z | Vì sao chọn ca này |
|---|---|---:|---:|---:|:-:|:-:|---|
| TC-001 | ADD | 0 | 0 | 0 | 0 | **1** | Nhỏ nhất ở cả hai toán hạng. Ca `Z=1` **không** đi qua tràn — bắt lỗi nối sai mạch dò zero |
| TC-002 | ADD | 5 | 3 | 8 | 0 | 0 | Ca thường ở giữa dải, không sinh carry ra |
| TC-003 | ADD | 9 | 7 | 0 | **1** | **1** | `9+7 = 16`: `C=1` và `Z=1` **cùng lúc**. Ca chứng minh `Z` nói về **result đã cắt**, không phải về tổng thật |
| TC-004 | SUB | 5 | 3 | 2 | **1** | 0 | Trừ không mượn. Chốt **quy ước cờ**: `C=1` nghĩa là **không** mượn |
| TC-005 | SUB | 3 | 5 | 14 | **0** | 0 | Trừ **có** mượn. Cặp phản chứng của TC-004 |
| TC-006 | SUB | 7 | 7 | 0 | **1** | **1** | Trừ hai số bằng nhau — `Z=1` của nhóm số học thứ hai |
| TC-007 | AND | 12 | 10 | 8 | 0 | 0 | `1100 ∧ 1010 = 1000`: mẫu bit làm lộ lỗi nối lệch bit |
| TC-008 | AND | 15 | 0 | 0 | 0 | **1** | Phần tử triệt tiêu của AND |
| TC-009 | AND | 15 | 15 | 15 | 0 | 0 | Phần tử đơn vị — kiểm đường dữ liệu đi qua nguyên vẹn |
| TC-010 | OR | 12 | 10 | 14 | 0 | 0 | Cùng cặp toán hạng với TC-007 và TC-013 — so ba phép logic trên **cùng** đầu vào |
| TC-011 | OR | 0 | 0 | 0 | 0 | **1** | Ca **duy nhất** làm `Z=1` cho phép OR (xem §4.2) |
| TC-012 | OR | 8 | 1 | 9 | 0 | 0 | Hai bit ở hai đầu từ — kiểm không có bit nào bị nuốt |
| TC-013 | XOR | 12 | 10 | 6 | 0 | 0 | Cùng cặp với TC-007/TC-010 |
| TC-014 | XOR | 5 | 5 | 0 | 0 | **1** | `x ⊕ x = 0` — tính chất đặc trưng của XOR |
| TC-015 | XOR | 15 | 0 | 15 | 0 | 0 | XOR với 0 là phép đồng nhất |
| TC-016 | NOT | 0 | 0 | 15 | 0 | 0 | Đảo toàn bộ từ |
| TC-017 | NOT | 15 | **9** | 0 | 0 | **1** | `B = 9 ≠ 0`: nếu RTL lỡ để `B` lọt vào nhánh NOT thì ca này sai ngay |
| TC-018 | NOT | 10 | **5** | 5 | 0 | 0 | `¬1010 = 0101`. `B = 5` **trùng** kết quả đúng — bẫy ngược: nếu ai đó viết `result = b` thì TC-018 vẫn qua, nên **phải có cả TC-017** |
| TC-019 | SHL | 1 | 0 | 2 | 0 | 0 | Dịch trái không mất bit |
| TC-020 | SHL | 8 | 0 | 0 | **1** | **1** | `1000 << 1`: bit duy nhất **rơi ra ngoài** vào `C`, kết quả rỗng → `C=1, Z=1` |
| TC-021 | SHL | 15 | 0 | 14 | **1** | 0 | Dịch trái toàn 1: kiểm bit 0 được chèn đúng |
| TC-022 | SHR | 2 | 0 | 1 | 0 | 0 | Dịch phải không mất bit |
| TC-023 | SHR | 1 | 0 | 0 | **1** | **1** | Đối xứng với TC-020 ở phía phải |
| TC-024 | SHR | 15 | 0 | 7 | **1** | 0 | Dịch phải **logic**: bit cao phải là 0, **không** nhân bản bit dấu |

> 🔎 **Cặp TC-017 / TC-018 là một cặp có chủ ý.** TC-018 một mình **không đủ** để chứng minh
> phép NOT đúng, vì `¬10 = 5` mà `B` cũng bằng 5 — một lỗi "trả về `B`" sẽ lọt. TC-017
> (`¬15 = 0` với `B = 9`) đóng lỗ hổng đó. Quét vét cạn tất nhiên cũng bắt được, nhưng cặp
> này cho thấy **cách nghĩ khi thiết kế ca kiểm thử có tên**.

## 3. 6 ca tự xây dựng (Charter mục 8 đòi ≥ 2)

| TC | op | A | B | result | C | Z | Loại | Vì sao thêm |
|---|---|---:|---:|---:|:-:|:-:|---|---|
| TC-025 | SUB | 0 | 1 | 15 | 0 | 0 | **Ca biên** | `0 − 1` — biên dưới tuyệt đối của phép trừ. Kết quả `1111` là biểu diễn bù 2 của `−1`. Bắt lỗi carry-in của phép trừ bị quên |
| TC-026 | ADD | 15 | 15 | 14 | **1** | 0 | **Ca biên** | Hai toán hạng lớn nhất. Mọi tầng **tự sinh** carry (`A[i]∧B[i]=1`) nên carry **không phải lan** — đối chứng của TC-027 |
| TC-027 | ADD | 15 | 1 | 0 | **1** | **1** | **Ca biên · ca tới hạn của phép cộng** | `1111 + 0001`: carry sinh ở bit 0 rồi phải **truyền qua cả ba tầng còn lại** — chuỗi dài nhất mà một phép **cộng** có thể tạo ra (xem §4.1) |
| TC-028 | ADD | 10 | 5 | 15 | 0 | 0 | Ca nhanh nhất | `1010 + 0101`: mỗi tầng có đúng một toán hạng bằng 1 ⟹ **không tầng nào sinh carry**. Đối lập hoàn toàn với TC-027 |
| TC-029 | SHL | 0 | 0 | 0 | **0** | **1** | **Ca biên** | Ca duy nhất trong nhóm dịch có `Z=1` mà `C=0`. Bắt lỗi nối `C` của phép dịch vào hằng số 1 |
| TC-030 | SUB | 8 | 8 | 0 | **1** | **1** | **Ca biên · ca tới hạn của cả ALU** | `1000 − 1000`: cả bốn tầng đều là "truyền tiếp", nên carry-in (sinh từ mã lệnh) phải đi qua **cả bốn tầng** — chuỗi carry **dài nhất** toàn khối. Xem §4.1 |

> 👉 **TC-026 là cái bẫy kinh điển.** Nhìn `15 + 15` ai cũng nghĩ đây là ca chậm nhất vì
> "toàn số 1". Thực ra **không phải**: mỗi tầng có `A[i] ∧ B[i] = 1` nên **tự sinh** carry
> tại chỗ, không phải chờ tầng trước. Ca chậm nhất là **TC-027** (`15 + 1`), nơi carry sinh
> ở bit 0 rồi phải **truyền tiếp** qua cả bốn tầng. Cùng một nhận xét đã xuất hiện ở A01 với
> cặp `127+127` / `255+1`.

## 4. Phân loại theo tiêu chí kỹ thuật của đề

### 4.1 Theo số tầng carry phải **lan** (chỉ áp dụng cho ADD/SUB)

Mỗi tầng `i` được phân loại theo ba vai trò quen thuộc, tính trên `b_eff` (tức `B` đã bị
đảo khi trừ):

* **G** (generate) — `A[i] ∧ b_eff[i] = 1`: tầng **tự sinh** carry, không cần chờ tầng dưới.
* **P** (propagate) — `A[i] ⊕ b_eff[i] = 1`: tầng **truyền tiếp** carry của tầng dưới.
* **K** (kill) — cả hai bằng 0: carry **chết** tại đây.

Cột "số tầng lan" = số tầng **P liên tiếp** nằm trên một nguồn carry (một tầng **G**, hoặc
carry-in `= sub`). Đây mới là đại lượng quyết định độ trễ của nhánh số học, **không** phải
số bit `carry` đang ở mức 1. Các con số dưới đây tính thẳng từ công thức RTL:

| TC | Phép | `b_eff` | Vai trò bit 3…0 | Chuỗi `carry[4:0]` | Số tầng lan | Ý nghĩa |
|---|---|---|---|---|---:|---|
| TC-001 | `0 + 0` | `0000` | `KKKK` | `00000` | **0** | Carry chết ở mọi tầng |
| TC-028 | `10 + 5` | `0101` | `PPPP` | `00000` | **0** | Toàn tầng truyền **nhưng không có gì để truyền** — nhanh nhất |
| TC-026 | `15 + 15` | `1111` | `GGGG` | `11110` | **0** | Mọi bit carry bằng 1 **nhưng** mỗi tầng tự sinh → bốn tầng chạy **song song** |
| TC-025 | `0 − 1` | `1110` | `PPPK` | `00001` | **0** | Carry-in bị **giết** ngay tại bit 0 |
| TC-004 | `5 − 3` | `1100` | `PGKP` | `11011` | **1** | Sinh ở bit 2, truyền 1 tầng |
| TC-002 | `5 + 3` | `0011` | `KPPG` | `01110` | **2** | Sinh ở bit 0, truyền 2 tầng rồi chết |
| TC-003 | `9 + 7` | `0111` | `PPPG` | `11110` | **3** | Sinh ở bit 0, truyền hết 3 tầng còn lại |
| TC-027 | `15 + 1` | `0001` | `PPPG` | `11110` | **3** | **Cùng cấu trúc G/P với TC-003** — hai ca tới hạn ngang nhau của phép cộng |
| **TC-006** | `7 − 7` | `1000` | `PPPP` | `11111` | **4** | **Carry-in `= sub` truyền qua CẢ BỐN tầng** |
| **TC-030** | `8 − 8` | `0111` | `PPPP` | `11111` | **4** | **Chuỗi dài nhất của toàn ALU — và nó thuộc về phép TRỪ** |

> 🔎 **Kết quả đáng chú ý nhất của bảng này:** chuỗi carry dài nhất **không** thuộc về phép
> cộng mà thuộc về phép **trừ** khi `A == B`. Lý do là cấu trúc: với phép trừ, nguồn carry
> là **carry-in** `= sub` — nó nằm ở **đáy** chuỗi, nên khi cả bốn tầng đều là P thì nó phải
> đi qua **cả bốn**. Với phép cộng, carry-in luôn bằng 0, nên nguồn carry sớm nhất có thể
> là một tầng G ở bit 0, và từ đó chỉ còn **ba** tầng để truyền.
>
> Hệ quả thực tế: `sub` — một tín hiệu **sinh ra từ mã lệnh `op`** — đứng ở đầu chuỗi carry
> dài nhất. Đây là manh mối cấu trúc đầu tiên cho kết quả STA ở
> `03_ARCHITECTURE/datapath.md` §5: đường tới hạn của A04 **xuất phát từ `op`, không phải
> từ toán hạng**.

> Chú ý thêm: TC-026 và TC-027 có **cùng** chuỗi `carry = 11110` nhưng độ trễ khác hẳn
> (0 tầng lan so với 3). "Carry bằng 1" ≠ "carry phải lan".

### 4.2 Bao phủ cờ `Z` theo từng phép

Số tổ hợp `(A,B)` cho `Z=1`, đếm bằng `reference_model.py` trên toàn bộ 256 cặp:

| Phép | Số tổ hợp cho `Z=1` | Ghi chú |
|---|---:|---|
| ADD | 16/256 | `A + B ≡ 0 (mod 16)` |
| SUB | 16/256 | `A == B` |
| AND | **81/256** | Nhiều nhất — chỉ cần không có bit nào trùng 1 |
| OR | **1/256** | **Ít nhất — chỉ duy nhất `(0,0)`** |
| XOR | 16/256 | `A == B` |
| NOT | 16/256 | `A == 15`, mọi `B` |
| SHL | 32/256 | `A ∈ {0, 8}` |
| SHR | 32/256 | `A ∈ {0, 1}` |

> 🔎 **Phép OR là phép khó kiểm cờ `Z` nhất**: chỉ **1 trên 256** tổ hợp cho `Z=1`. Một bộ
> kiểm thử ngẫu nhiên 100 vector có xác suất bỏ sót ca đó là `(255/256)^100 ≈ 68 %`. Đây là
> lý do cụ thể, đo được, giải thích vì sao đề này **phải** quét vét cạn chứ không kiểm ngẫu
> nhiên. TC-011 chính là ca đó.

### 4.3 Bao phủ cặp cờ `(C, Z)`

| C | Z | Có ca có tên? | TC |
|:-:|:-:|---|---|
| 0 | 0 | ✅ | TC-002, TC-007, TC-010, … |
| 0 | 1 | ✅ | TC-001, TC-008, TC-011, TC-014, TC-017, **TC-029** |
| 1 | 0 | ✅ | TC-004, TC-021, TC-024, TC-026 |
| 1 | 1 | ✅ | TC-003, TC-006, TC-020, TC-023, TC-027, TC-030 |

Cả bốn tổ hợp đều xảy ra ⟹ `C` và `Z` **độc lập** với nhau.

### 4.4 Ca **không** áp dụng cho A04

| Loại ca | Lý do không áp dụng |
|---|---|
| Reset assert / deassert | A04 không có reset |
| Clock gating, clock domain crossing | A04 không có clock |
| Ca mã lệnh không hợp lệ | **Không tồn tại**: 3 bit `op` phủ đúng 8 phép, không có mã dự phòng |
| Tràn có dấu (cờ `V`) | Charter mục 3 xếp **ngoài phạm vi** |
| Dịch nhiều bit trong một chu kỳ | Charter mục 3 xếp **ngoài phạm vi** |
| Back-to-back transaction | A04 không có giao thức |
| X-propagation từ trạng thái khởi tạo | A04 không có ô nhớ |

## 5. Quét vét cạn — vì sao đây là ca mạnh nhất

Không gian đầu vào là `16 × 16 × 8 = 2 048` tổ hợp. Testbench so khớp DUT với golden model
trên **toàn bộ** không gian này, đồng thời kiểm 4 bất biến tại mỗi vector.

Kết quả thật: **2 078 vector chạy · 0 lệch REF · 0 vi phạm bất biến** (30 ca có tên +
2 048 ca vét cạn).

Hệ quả logic:

> Nếu 2 048/2 048 tổ hợp đều khớp thì DUT **tương đương hàm** với golden model.
> Không còn ca nào khác để tìm ở mức hành vi.

Điều này **vẫn không** chứng minh:

- kiến trúc bên trong là "tám nhánh + một bộ cộng dùng chung" (phải đọc RTL + netlist);
- thời gian lan truyền đạt yêu cầu (phải chạy STA);
- mạch đúng sau khi place & route (phải mô phỏng gate-level có SDF).

## 6. Ca cần bổ sung ở gate-level / post-layout

| Ca | Vì sao chỉ làm được ở gate-level | Trạng thái |
|---|---|---|
| Mô phỏng gate-level trên netlist sau tổng hợp | Kiểm netlist tương đương RTL | ⬜ netlist đã có tại `06_GDSII/synthesis/netlist.v` |
| Vector kích hoạt đường tới hạn `op[2] → zflag` | Đường tới hạn thật **xuất phát từ bit chọn phép**, không từ toán hạng — chỉ thấy được sau khi có netlist + STA | ⬜ |
| Chuyển `op` từ `110` (SHL) sang `001` (SUB) giữ nguyên `A`,`B` | Ép **cả** bộ giải mã `sub`, **cả** chuỗi carry và **cả** bộ ghép kênh cùng đổi trạng thái — ca công suất động xấu nhất | ⬜ |
| Đo glitch trên `result` khi `op` đổi | `op` đổi làm cả 8 nhánh cùng tranh nhau trên mux | ⬜ |
| Mô phỏng có back-annotate SDF | Cần P&R | ⬜ chưa chạy P&R |

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: REQ-A04-020…023.*
