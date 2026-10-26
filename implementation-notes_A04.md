# A04 — Đơn vị số học logic (ALU) 4-bit tám chức năng · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

Bề mặt: "làm tám phép trên bốn bit". Nghe như tám bài tập nhỏ ghép lại.

Thực chất, Charter chọn A04 để dạy một điều mà bộ cộng A01 không dạy được:
**phần cứng để *chọn* có thể đắt hơn phần cứng để *tính*.**

Câu hỏi riêng của đề (Charter mục 9) nói thẳng ra điều đó: *"ước lượng phần diện tích dành
cho bộ ghép kênh chọn phép so với phần diện tích dành cho các phép tính. Bàn về chi phí của
tính linh hoạt."* Toàn bộ hồ sơ này tồn tại để biến câu hỏi đó thành một **số đo**, và câu
trả lời đo được là:

> **Bộ ghép kênh chiếm 46,4 % diện tích. Tám phép tính cộng lại chiếm 51,8 %.**
> Cứ 1 µm² để tính, phải trả thêm 0,90 µm² chỉ để chọn xem đang tính gì.

Bối cảnh ứng dụng — vi điều khiển 4 bit dạy học — không phải trang trí. Nó quyết định vì
sao "tính hết rồi chọn" là kiến trúc đúng ở đây: mỗi lệnh phải xong trong **một** chu kỳ,
nên không được phép lặp; và vì chỉ có 4 bit nên chuỗi carry còn quá ngắn để trở thành nút
thắt.

> ⚠️ **Lưu ý truy vết:** gói nguồn ban đầu của đề này chứa một **bộ mã hoá ưu tiên 8→3**
> của một danh mục đề cũ, không phải ALU. RTL trong `04_IMPLEMENTATION/` là **bản viết
> mới cho đúng đề Charter**; bản gốc đóng băng tại `08_ORIGINAL_SOURCE/`. Chẩn đoán đầy
> đủ: `05_VERIFICATION/known_issues.md` §1.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

### 2.1 Kiến trúc "tính hết rồi mới chọn"

Tám nhánh chức năng **luôn luôn tính**, kể cả nhánh không được chọn:

```
   a, b  ──▶  ADD/SUB   AND   OR   XOR   NOT   SHL   SHR      (8 kết quả, 40 bit)
                 │       │     │    │     │     │     │
   op    ──────▶ └───────┴─────┴────┴─────┴─────┴─────┘
                          bộ ghép kênh 8 → 1
                                 │
                        result[3:0], C   ──▶  Z = NOR(result)
```

Đây không phải lãng phí — đó là **cách duy nhất** để mọi phép cùng xong trong một lần lan
truyền. Cái giá là công suất động: mỗi lần `op` đổi, cả tám nhánh đều chuyển mạch.

### 2.2 Một bộ cộng, hai phép

Điểm trọng tâm khi bảo vệ. Phép trừ **không có** mạch riêng:

```
   A − B  =  A + (−B)  =  A + (¬B + 1)  =  A + ¬B + 1
                              │            │
                    4 cổng XOR trên B      carry-in = 1
```

Trong RTL, cả hai "nửa" gói gọn trong hai dòng:

```systemverilog
assign b_eff    = b ^ {4{sub}};   // nửa đầu: đảo bit khi trừ  — 4 cổng XOR
assign carry[0] = sub;            // nửa sau: cộng thêm 1      — 0 cổng, chỉ là dây
```

Điều đáng nói là **nửa sau hoàn toàn miễn phí**: carry-in của tầng 0 vốn là một dây tự do
của bộ cộng, chỉ cần nối `sub` vào đó.

### 2.3 Ý nghĩa của `C` đổi theo phép

Cùng một dây `carry[4]`, hai cách đọc:

| `sub` | `C = 1` nghĩa là | Firmware dùng để |
|:-:|---|---|
| 0 (ADD) | `A + B ≥ 16` — **tràn không dấu** | Mở rộng nhiều nibble |
| 1 (SUB) | `A ≥ B` — **không mượn** | So sánh, rẽ nhánh |

Đây là quy ước kiểu ARM/6502. Nó được chọn vì nó **rơi ra miễn phí** từ bộ cộng dùng
chung; quy ước x86 (`C = 1` ⟺ **có** mượn) sẽ phải trả thêm một cổng đảo **nằm trên đường
tới hạn**.

## 3. Đọc mã nguồn: RTL làm gì

Toàn bộ kiến trúc nằm trong sáu mục của `a04_alu4.sv`. Ba đoạn cần giảng kỹ:

**① Bộ cộng dùng chung — chuỗi ripple tường minh**

```systemverilog
assign b_eff    = b ^ {4{sub}};
assign carry[0] = sub;

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : GEN_FA
        assign r_arith[i] = a[i] ^ b_eff[i] ^ carry[i];
        assign carry[i+1] = (a[i] & b_eff[i])
                          | (a[i] & carry[i])
                          | (b_eff[i] & carry[i]);
    end
endgenerate
```

* `generate for` là **nhân bản KHÔNG GIAN**: bốn bản sao phần cứng tồn tại đồng thời,
  không phải bốn lần chạy tuần tự. Sinh viên quen lập trình phần mềm gần như luôn hiểu
  nhầm chỗ này.
* `carry[i+1]` là **hàm đa số (majority)** của ba bit. Nhận ra điều này giải thích vì sao
  netlist có cell `maj3_1`.
* `b_eff` là toàn bộ chi phí riêng của phép trừ: **4 cổng XOR**.

**② Hai nhánh dịch không tốn một cổng nào**

```systemverilog
assign r_shl = {a[2:0], 1'b0};   // KHÔNG viết a << 1
assign c_shl = a[3];
assign r_shr = {1'b0, a[3:1]};   // KHÔNG viết a >> 1
assign c_shr = a[0];
```

Dịch **một bit cố định** là nối dây thuần. Tổng hợp riêng module này cho **0 cell**. Viết
bằng phép ghép bit làm điều đó hiển nhiên; viết `a << 1` lại gợi ý một bộ dịch có thể tham
số hoá — thứ A04 không có, và Charter mục 3 xếp vào ngoài phạm vi.

**③ Bộ ghép kênh — và chi tiết dễ bỏ qua nhất của cả bài**

```systemverilog
always_comb begin
    result = 4'b0000;                 // lớp phòng vệ 1
    cflag  = 1'b0;
    case (op)
        OP_ADD : begin result = r_arith; cflag = c_arith; end  // <-- cùng
        OP_SUB : begin result = r_arith; cflag = c_arith; end  // <-- một dây
        OP_AND : begin result = r_and;   cflag = 1'b0;    end
        ...
        default: begin result = 4'b0000; cflag = 1'b0;    end  // lớp phòng vệ 2
    endcase
end
```

Hai nhánh đầu lấy về **cùng một dây** `r_arith`. Vì thế bộ ghép kênh mang tiếng "8 vào"
nhưng chỉ có **bảy nguồn phân biệt**. Với đường `C` còn ít hơn — **bốn** nguồn
(`c_arith`, hằng số `0`, `a[3]`, `a[0]`). Đó là lý do vì sao "một bộ cộng dùng chung"
tiết kiệm ở **hai** chỗ chứ không phải một (§7 câu 1).

### Điều tuyệt đối không được viết

```systemverilog
assign result = sub ? a - b : a + b;   // ❌ CẤM trong RTL nộp bài
```

Viết vậy cho công cụ tự do sinh **hai** mạch số học riêng — đo được là **+26,4 % diện
tích** — và xoá mất đúng thứ Charter mục 2 câu 1 yêu cầu quan sát. Các toán tử `+`, `-`,
`<<`, `>>` chỉ được dùng trong `05_VERIFICATION/golden_model/`, nơi chúng đóng vai trò
chuẩn so sánh độc lập.

## 4. Vì sao chọn kiến trúc này

Không phải vì "tính hết rồi chọn" là tốt nhất nói chung, mà vì **ứng dụng ràng buộc như vậy**:

| Tiêu chí của vi điều khiển dạy học | Kiến trúc đã chọn đáp ứng? |
|---|---|
| Mỗi lệnh xong trong **một** chu kỳ | ✅ Một lần lan truyền, đo được 1,85 ns |
| Quy mô ~200–300 cell · 1×1 tile (Charter ước lượng) | ✅ **64 cell · 417,90 µm²** — nhỏ hơn cả cận dưới |
| Ngân sách 24 chân | ✅ Dùng 17/24, **không có điểm mở** |
| Phải **đọc được** để dạy | ✅ Tám nhánh ánh xạ 1-1 với bảng mã lệnh |
| Cần tần số cao | ❌ Không cần |

Còn ràng buộc "một bộ cộng dùng chung" thì không phải lựa chọn — đó là **yêu cầu của đề**.
Nhưng nó cũng là lựa chọn đúng, và §7 câu 1 chứng minh bằng số.

So sánh đầy đủ ba kiến trúc ALU: `03_ARCHITECTURE/tradeoff.md` §4 — lưu ý phương án ALU
lặp nằm **ngoài phạm vi** theo Charter mục 3 (nó đổi loại mạch sang Tuần tự).

## 5. Cách thực hiện — lộ trình 8 bước

| # | Bước | Công cụ | Bằng chứng sinh ra | Trạng thái |
|---|---|---|---|---|
| 1 | Phát hiện gói nguồn lệch đề, đối chiếu bảng cổng với Charter mục 4 | — | `05_VERIFICATION/known_issues.md` §1 | ✅ |
| 2 | Suy bảng hành vi 8 phép + 2 cờ từ Charter mục 1, 4, 8 | — | `02_SPECIFICATION/functional_spec.md` | ✅ |
| 3 | Viết mô hình chuẩn Python độc lập (30 ca + 7 bất biến) | CPython 3 | `python_reference_run.log` | ✅ PASS |
| 4 | Viết RTL: 8 nhánh tường minh + mux, **một** bộ cộng dùng chung | — | `04_IMPLEMENTATION/rtl/a04_alu4.sv` | ✅ |
| 5 | Viết testbench tự kiểm + quét vét cạn 2 048 tổ hợp | Icarus Verilog 12.0 | `simulation.log` | ✅ 2 078 vector / 0 lỗi |
| 6 | Tổng hợp lên sky130, **kiểm 0 flip-flop và 0 chốt** | Yosys 0.33 | `synth_stat.txt` | ✅ 64 cell, 0 FF |
| 7 | Đo tách diện tích mux / phép tính (7 biến thể) + thí nghiệm chốt (5 biến thể) | Yosys 0.33 | `tradeoff.md` §2–3, `known_issues.md` §4 | ✅ |
| 8 | STA với clock ảo, tìm đường tới hạn thật | OpenSTA | `06_GDSII/sta/` | ✅ 1,85 ns |
| 9 | Physical design RTL→GDSII | LibreLane + sky130A | `06_GDSII/` | ⬜ chưa chạy |

Chạy lại toàn bộ: `07_TRACEABILITY/evidence_index.md`.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Vector kiểm chứng | 2 078 chạy · **0 lệch REF** | Icarus Verilog 12.0 |
| Quét vét cạn | **2 048/2 048** tổ hợp khớp | như trên |
| Vi phạm bất biến | **0 / 2 078** | như trên |
| Số cell | **64** | Yosys 0.33 + sky130_fd_sc_hd |
| **Flip-flop** | **0** | như trên |
| **Chốt (latch)** | **0** | như trên |
| Diện tích | **417,9008 µm²** | như trên |
| — trong đó tám phép tính | 216,4576 µm² (51,8 %) | như trên, biến thể V-FUNC |
| — trong đó bộ ghép kênh | **193,9360 µm² (46,4 %)** | như trên, biến thể V-SEL |
| — trong đó cờ `Z` | 6,2560 µm² (1,5 %) | như trên, biến thể V-FLAGZ |
| Đường tới hạn | **`op[2] → zflag`** | OpenSTA |
| **Độ trễ tổ hợp** | **1,85 ns** (slack 8,15 ns) | như trên |
| WNS / TNS | 0,00 / 0,00 | như trên |
| Đường dữ liệu chậm nhất | `b[1] → zflag`, 1,36 ns | như trên |
| Chuỗi carry 4 tầng đầy đủ | `a[0] → cflag`, **1,04 ns** | như trên |
| Đường nhanh nhất | `a[1] → result[2]`, **0,10 ns** | như trên |
| Công suất | **1,56e-05 W** — 100,0 % tổ hợp, 0,0 % tuần tự | như trên |

### Từng con số chứng minh gì — và KHÔNG chứng minh gì

| Con số | **Chứng minh** | **KHÔNG chứng minh** |
|---|---|---|
| 2 048/2 048 khớp | Hàm của DUT **tương đương** golden model. Không còn ca hành vi nào chưa kiểm. | Kiến trúc là "8 nhánh + 1 bộ cộng dùng chung". Một ALU viết bằng `a+b`/`a-b` cũng PASS hết. |
| 0 flip-flop, 0 chốt | Đúng phân loại Tổ hợp của Charter, xác nhận bởi **hai nguồn độc lập** (bảng cell + công suất nhóm Sequential = 0 %) | Netlist tương đương RTL về chức năng — cần mô phỏng gate-level |
| 64 cell · 417,90 µm² | ALU này **nhỏ** — dưới cả cận dưới 200 cell của ước lượng Charter | Diện tích sau P&R — sẽ khác vì có dây |
| 46,4 % cho mux | Chi phí của tính linh hoạt, **đo bằng ba lần tổng hợp riêng biệt cộng lại lệch 0,3 % so với thiết kế thật** | Tỉ lệ này ở độ rộng từ khác — ở 8 hay 16 bit, phần "phép tính" tăng nhanh hơn phần "chọn" |
| 1,85 ns | Độ trễ **ở mức sau tổng hợp**, góc `tt_025C_1v80` | Độ trễ thật sau routing (sẽ **lớn hơn**, chưa có RC dây) |
| 1,56e-05 W | Thứ tự độ lớn công suất | Công suất thật — dùng activity mặc định, không lấy từ VCD |

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

### Câu 1 — Tám phép dùng chung phần cứng nào, và phần nào phải riêng cho mỗi phép?

**Dùng chung ba thứ:**

| Dùng chung | Phục vụ | Bằng chứng |
|---|---|---|
| **Một bộ cộng ripple 4 tầng** | ADD **và** SUB | RTL chỉ có **một** khối `generate GEN_FA` và **một** mảng `carry[4:0]`. Bằng chứng định lượng: tổng hợp biến thể hai bộ riêng (V-TWO) cho 27 cell / 186,4288 µm², so với 14 cell / 128,8736 µm² của bản dùng chung |
| **Một bộ ghép kênh 8→1** | Cả tám phép | Mục 5 của RTL |
| **Một cây NOR sinh `Z`** | Cả tám phép | Mục 6 của RTL, đặt **sau** mux |

**Riêng cho từng phép:**

| Phép | Phần cứng riêng | Chi phí đo được |
|---|---|---|
| SUB | 4 cổng XOR (`b_eff`) + 1 cổng giải mã `sub` | **+1 cell, +33,78 µm²** so với bộ cộng thuần |
| AND, OR, XOR, NOT | 4 cổng mỗi phép | 16 cell · 100,0960 µm² cho **cả sáu** nhánh logic + dịch |
| SHL, SHR | **0 cổng** — nối dây thuần | 0 |
| ADD | **0 cổng riêng** — là hành vi mặc định của bộ cộng khi `sub = 0` | 0 |

**Con số quan trọng nhất của câu này:** làm hai đơn vị số học riêng thay vì dùng chung sẽ
tốn thêm **153,8976 µm² — 26,4 % diện tích cả ALU**, và phần tăng đó chia làm hai:

| Nơi tăng | Tăng |
|---|---:|
| Bộ số học (2 chuỗi carry thay vì 1) | +57,5552 µm² |
| **Bộ ghép kênh** (8 nguồn phân biệt thay vì 7) | **+96,3424 µm²** |

Phần tăng ở **bộ ghép kênh lớn hơn** phần tăng ở chính bộ số học. Đây là chỗ sinh viên
hay bỏ sót khi trả lời câu này.

### Câu 2 — Ba bit chọn phép đi vào đâu trong netlist, và tạo ra bao nhiêu bộ ghép kênh?

**`op` chạm vào netlist ở đúng hai điểm:**

1. **Bộ giải mã `sub = (op == 3'b001)`** — một cổng, hiện thực thành `nor3b_1`. Điểm này
   nằm **trong** đường dữ liệu số học: `sub` điều khiển cả 4 cổng XOR của `b_eff` **và**
   `carry[0]`.
2. **Bộ ghép kênh chọn phép** — nằm cuối đường dữ liệu.

**Số bộ ghép kênh 8→1 sinh ra: 5.** Bốn cho `result[3:0]`, một cho `cflag`. Không có bộ
ghép kênh nào cho `zflag`, vì `zflag` được tính **sau** mux (xem `control.md` §4).

Nhưng "5 bộ ghép kênh 8→1" là cách nói của **RTL**, không phải của **netlist**. Netlist
thật không có cell `mux8`; `abc` đã hoà tan chúng thành 27 cell thuộc họ AOI/OAI
(`a2111oi_0`, `o2111ai_1`, `a22oi_1`, `nand4b_1`, …). Đây là bài học chung: **đếm cấu
trúc trong RTL, đo diện tích trong netlist — đừng trộn hai việc đó.**

Diện tích thật của toàn bộ phần này: **27 cell · 193,9360 µm² = 46,4 %** tổng diện tích.

### Câu 3 — Phép nào là đường tới hạn của cả ALU, và vì sao?

**Câu trả lời đo được đi ngược lại cách đặt câu hỏi: đường tới hạn không thuộc về "phép
nào" cả.**

Đường tới hạn là `op[2] → zflag`, **1,85 ns**:

```
 op[2] ─▶ nor3b_1   0,43 ns   ← GIẢI MÃ `sub` (cell ĐẮT NHẤT trên cả đường)
       ─▶ xor2_1    0,26 ns   ← b_eff = b ⊕ sub
       ─▶ xor3_1    0,33 ns   ← một tầng tổng của bộ cộng
       ─▶ a2111oi_0 0,52 ns   ┐
       ─▶ o2111ai_1 0,18 ns   ├─ bộ ghép kênh + cây NOR sinh Z
       ─▶ a211oi_1  0,13 ns   ┘
       ═▶ zflag                 tổng 1,85 ns
```

**Cả sáu đường chậm nhất của khối đều xuất phát từ `op`, không một đường nào từ `a` hay
`b`.** Ba lý do, theo thứ tự quan trọng:

1. **`sub` đứng TRƯỚC bộ cộng.** Vì cộng và trừ dùng chung một bộ cộng, mã lệnh phải được
   giải mã **xong** thì bộ cộng mới bắt đầu. Toán hạng `a`, `b` thì vào thẳng — chúng bỏ
   qua bước này.
2. **`op[2]` có fanout 11** — cao nhất thiết kế (nó vào cả bộ giải mã lẫn cả năm bộ ghép
   kênh). Slew xấu, nên cell đầu tiên tiêu 0,43 ns, bằng **23 %** cả đường.
3. **`zflag` nằm sau mux**, nên nó là endpoint sâu nhất.

Đối chứng trên **cùng một netlist**:

| Đường | Nội dung | Độ trễ |
|---|---|---:|
| `a[1] → result[2]` | nhánh dịch — 0 cổng logic | **0,10 ns** |
| `a[0] → cflag` | đi hết **cả 4 tầng carry** | **1,04 ns** |
| `b[1] → zflag` | đường dữ liệu chậm nhất | 1,36 ns |
| **`op[2] → zflag`** | **đường tới hạn** | **1,85 ns** |

Chuỗi carry 4 tầng — thứ mà trực giác từ A01 bảo phải là nút thắt — chỉ chiếm **56 %**
đường tới hạn. **Ở `N = 4` bit, chuỗi ripple còn quá ngắn để cạnh tranh với chi phí chọn
phép.** Ở A01 với `N = 8` thì ngược lại. Độ rộng từ quyết định ai là nút thắt.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Từ báo cáo tổng hợp, ước lượng phần diện tích dành cho bộ ghép kênh chọn phép so với
> phần diện tích dành cho các phép tính. Bàn về chi phí của tính linh hoạt."*

### Cách đo

`stat` cho **một** con số tổng cho cả module, không nói phần nào là mux. Nên phải tổng hợp
nhiều phiên bản — cùng thư viện, cùng script, chỉ đổi `-top` — rồi so. Ba biến thể chính
được chép **nguyên văn** từ các mục tương ứng của RTL nộp bài:

| Biến thể | Nội dung | Cell | Diện tích | Tỉ lệ |
|---|---|---:|---:|---:|
| **V-FUNC** | Tám nhánh chức năng, **không** mux | 30 | **216,4576 µm²** | **51,8 %** |
| **V-SEL** | Giải mã `sub` + bộ ghép kênh 8→1 rộng 5 bit | 27 | **193,9360 µm²** | **46,4 %** |
| **V-FLAGZ** | Cây NOR sinh `Z` | 1 | 6,2560 µm² | 1,5 % |
| *Tổng ba phần* | | *58* | *416,6496 µm²* | *99,7 %* |
| **A04 thật** | tổng hợp một lượt | **64** | **417,9008 µm²** | **100 %** |

Tổng ba phần rời chỉ lệch **0,3 %** so với thiết kế thật ⟹ phép tách là **hợp lệ**, ba
phần gần như không chồng lấn.

### Kết quả

> **Bộ ghép kênh chọn phép: 193,9360 µm² / 417,9008 µm² = 46,4 %.**
> **Tám phép tính: 216,4576 µm² = 51,8 %.**
> Tỉ số **chọn : tính ≈ 0,90 : 1**.

### Ba kết quả đáng nói

**① Bộ ghép kênh đắt hơn bộ cộng 50 %, và đắt gần gấp đôi cả sáu nhánh logic + dịch cộng lại.**

| Phần | Cell | Diện tích |
|---|---:|---:|
| Bộ cộng/trừ dùng chung — nhánh **đắt nhất** trong tám nhánh | 14 | 128,8736 µm² |
| Bốn nhánh logic + hai nhánh dịch **cộng lại** | 16 | 100,0960 µm² |
| **Bộ ghép kênh** | **27** | **193,9360 µm²** |

**② Nhánh rẻ nhất lại làm bộ ghép kênh đắt nhất.** Hai nhánh dịch tốn **0 cell** — tổng
hợp riêng cho đúng 0 cổng, vì dịch 1 bit cố định là nối dây. Nhưng chúng vẫn chiếm
**2 trên 8** đường vào của bộ ghép kênh. Chúng "miễn phí khi tính" nhưng **phải trả tiền
khi chọn**. Đây là hệ quả trực tiếp của việc chi phí chọn tỉ lệ với **số phép**, còn chi
phí tính tỉ lệ với **độ phức tạp từng phép** — hai đại lượng độc lập nhau.

**③ Tính linh hoạt tốn cả tốc độ, không chỉ diện tích.** Đường tới hạn `op[2] → zflag`
(1,85 ns) dài hơn **78 %** so với đường đi hết chuỗi carry 4 tầng `a[0] → cflag`
(1,04 ns). Cell đắt nhất trên đường tới hạn là **bộ giải mã `sub`** (0,43 ns) — tức là
một cell thuần "chọn", không tính gì cả.

### Bàn về chi phí của tính linh hoạt

Một ALU 4-bit tám chức năng **về bản chất** là một khối mà gần một nửa diện tích không
dùng để tính. Ba hệ quả thiết kế rút ra từ số liệu này:

1. **Thêm phép thứ 9 rẻ hơn ta tưởng ở nhánh, đắt hơn ta tưởng ở mux.** Một phép logic mới
   tốn ~4 cổng ở nhánh, nhưng làm mux rộng thêm một đường vào × 5 bit. Ở quy mô 4 bit, vế
   thứ hai lớn hơn.
2. **Càng rộng từ, tỉ lệ này càng có lợi cho tính linh hoạt.** Diện tích nhánh số học tăng
   theo `O(N)`, còn diện tích mux cũng tăng theo `O(N)` nhưng với hệ số nhỏ hơn nhiều — và
   số phép thì không đổi. Con số 46,4 % là con số của **4 bit**, không được suy ra cho 8
   hay 16 bit.
3. **Cách rẻ nhất để giảm chi phí chọn là làm cho các nhánh dùng chung nguồn.** Đó chính
   là điều mà ràng buộc "một bộ cộng dùng chung" của đề làm được: nó biến mux 8 nguồn
   thành mux 7 nguồn, tiết kiệm **96,3424 µm² (−33,2 %)** ở riêng bộ ghép kênh.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Viết `result = sub ? a - b : a + b` cho gọn | Sinh **hai** mạch số học riêng; +26,4 % diện tích; mất đúng thứ mục 2 câu 1 cần quan sát | Đọc RTL; netlist có **hai** chuỗi carry, số cell `maj3`/`a22oi` tăng gấp đôi |
| 2 | Quên nhánh `default` **và** quên gán mặc định | Chốt xuất hiện trong mạch tổ hợp | `synth_stat.txt` có `$_DLATCH_*`; với `always_comb` thì Yosys **dừng hẳn** (xem #3) |
| 3 | Dùng `always @(*)` thay cho `always_comb` | Lỗi trên **im lặng lọt qua**, và diện tích báo cáo còn **sai** | `known_issues.md` §4: S3 cho ERROR, S4 cho 5 chốt + dòng `Area for cell type $_DLATCH_N_ is unknown!` |
| 4 | Tin rằng `default` là thứ cứu mình | Bỏ gán mặc định vì "đã có default" | Đo: bỏ riêng `default` (S5) vẫn 0 chốt; bỏ riêng gán mặc định (S1) cũng 0 chốt. Phải mất **cả hai** mới sinh chốt — và cả hai đều **miễn phí** (S0/S1/S5 đều 27 cell · 193,9360 µm²) |
| 5 | Nghĩ đường tới hạn phải là chuỗi carry | Chọn sai vector đo timing, tối ưu sai chỗ | STA: `a[0] → cflag` chỉ 1,04 ns, trong khi `op[2] → zflag` 1,85 ns |
| 6 | Nhầm `C` sau phép trừ là cờ "mượn" | Firmware so sánh sai dấu | TC-004 (`5−3`, `C=1`) và TC-005 (`3−5`, `C=0`) — cặp phản chứng |
| 7 | Để `B` lọt vào nhánh `NOT` | Phép một ngôi biến thành hai ngôi | TC-017 (`¬15` với `B=9`); lưu ý TC-018 một mình **không** bắt được lỗi này |
| 8 | Viết `a << 1` cho nhánh dịch | Gợi ý bộ dịch tham số hoá; mất tính hiển nhiên "0 cổng" | Tổng hợp riêng nhánh dịch: phải ra **0 cell** |
| 9 | Nghĩ `15+15` là ca chậm nhất vì "toàn số 1" | Chọn sai vector | `corner_cases.md` §4.1: `15+15` có `GGGG` ⟹ **0 tầng lan**. Ca dài nhất là `8−8` với `PPPP` ⟹ **4 tầng** |
| 10 | Kết luận "mô phỏng PASS ⟹ kiến trúc đúng" | Kiểm chứng chức năng mù về cấu trúc | Một ALU viết bằng `a+b`/`a-b` cũng PASS 2 048/2 048 |
| 11 | Đếm "5 bộ ghép kênh 8→1" rồi tra diện tích mux8 trong liberty | Sai số lớn | Netlist **không có** cell mux8 nào; `abc` hoà tan thành 27 cell họ AOI/OAI |
| 12 | Diễn giải "period 10 ns" thành "chạy ở 100 MHz" | Khẳng định vượt mức | `02_SPECIFICATION/timing.md` — `vclk` là mốc quy chiếu, A04 không có clock |
| 13 | Dùng waveform RTL để chứng minh độ trễ | Waveform hành vi là zero-delay | Mở VCD: mọi tín hiệu đổi tức thời tại `#1` |
| 14 | So số cell của A04 với đề khác | Hai đề có thể chạy môi trường khác | `02_SPECIFICATION/parameters.md` — điều kiện tạo bằng chứng |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Chỉ cho tôi thấy **chỗ nào** trong RTL nói rằng cộng và trừ dùng chung một bộ cộng. | Chỉ vào khối `generate GEN_FA` — chỉ có **một** khối; và hai dòng `b_eff = b ^ {4{sub}}` với `carry[0] = sub`. Nếu có hai bộ cộng thì phải có hai khối `generate` hoặc hai chuỗi `carry`. |
| 2 | Phép trừ tốn thêm bao nhiêu so với một bộ cộng thuần? | **+1 cell, +33,78 µm²** (13 → 14 cell; 95,0912 → 128,8736 µm²). Làm hai đơn vị riêng thì tốn +14 cell / +91,34 µm² — đắt gấp gần 2,7 lần. |
| 3 | Vì sao bộ ghép kênh "8 vào" lại chỉ có 7 nguồn? | Vì nhánh ADD và nhánh SUB **là cùng một dây** `r_arith`. Đo được: mux 7 nguồn 193,9360 µm² so với mux 8 nguồn 290,2784 µm² — chênh **33,2 %**. |
| 4 | `C` sau phép `SUB 3−5` bằng mấy? Vì sao? | Bằng **0**. A04 dùng quy ước "carry = không mượn": `C = 1` ⟺ `A ≥ B`. Đây là carry-out của `A + ¬B + 1`, lấy thẳng, không đảo — nên miễn phí. |
| 5 | Đường tới hạn của khối là phép nào? | **Không phải phép nào cả** — nó là `op[2] → zflag`, 1,85 ns, xuất phát từ **bit chọn phép**. Cell đầu tiên là bộ giải mã `sub`, tốn 0,43 ns = 23 % cả đường. |
| 6 | Chuỗi carry 4 tầng có phải nút thắt không? | **Không.** `a[0] → cflag` đi hết 4 tầng chỉ mất 1,04 ns — bằng 56 % đường tới hạn. Ở `N = 4` chuỗi ripple còn quá ngắn. Ở A01 (`N = 8`) thì ngược lại. |
| 7 | Bộ ghép kênh tốn bao nhiêu phần diện tích? Đo thế nào? | **46,4 %** (193,9360 / 417,9008 µm²). Đo bằng cách tổng hợp riêng ba phần (V-FUNC / V-SEL / V-FLAGZ) cùng thư viện cùng script; tổng ba phần lệch thiết kế thật chỉ **0,3 %**. |
| 8 | Nhánh nào tốn nhiều cell nhất? Nhánh nào tốn ít nhất? | Nhiều nhất: bộ cộng/trừ (14 cell). Ít nhất: **hai nhánh dịch — 0 cell**, vì dịch 1 bit cố định là nối dây thuần. |
| 9 | Vì sao khối này có đúng 0 flip-flop? | Vì là mạch tổ hợp: đầu ra chỉ là hàm của `(a, b, op)` hiện tại. `ACC`, `IR`, `FLAGS` đều nằm **ngoài** A04. |
| 10 | Tám phép nghe như tám trạng thái — sao lại nói không có FSM? | Tám giá trị của `op` là **tám nhãn trên dây chọn**, không phải tám trạng thái được nhớ. ALU tính **cả tám** phép cùng lúc, mọi lúc; kết quả không phụ thuộc phép trước đó. |
| 11 | Nếu quên nhánh `default` thì sao? | Chưa chắc sao cả — đã đo: bỏ riêng `default` (S5) vẫn **0 chốt** vì gán mặc định đã phủ, và bỏ riêng gán mặc định (S1) cũng vậy. Phải mất **cả hai** mới sinh chốt. Cả hai lớp đều miễn phí: S0/S1/S5 đều cho 27 cell · 193,9360 µm². Khi mất cả hai thì `always_comb` cho **ERROR dừng hẳn**, còn `always @(*)` cho **5 chốt lọt qua âm thầm**. |
| 12 | Vì sao `zflag` chậm hơn `cflag`? | Vì `zflag` tính **sau** bộ ghép kênh (1 cây NOR thay vì 8). Đo được: 1,85 ns so với 1,35 ns — đổi **+0,50 ns** lấy **−73,82 µm²**. |
| 13 | 2 048/2 048 PASS — chứng minh kiến trúc đúng chưa? | Chưa. Kiểm chứng chức năng **mù về cấu trúc**. Một ALU viết bằng `a+b`/`a-b` cũng PASS hết. Bằng chứng kiến trúc phải đọc từ RTL và netlist. |
| 14 | Con số 1,85 ns có phải độ trễ thật của chip không? | Không. Đây là độ trễ **sau tổng hợp**, chưa có RC dây, chỉ một góc PVT. Sau routing sẽ lớn hơn. |
| 15 | Vấn đề ngân sách chân giải quyết ra sao? | **Không có vấn đề** — 17/24 chân, Charter mục 4 ghi rõ "ánh xạ đã khả thi, không phải đổi gì". Còn dư 7 chân. |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

### Đã chứng minh

1. Hàm của A04 đúng trên **toàn bộ** không gian đầu vào (2 048/2 048, 0 lệch).
2. Chín bất biến của đặc tả luôn giữ (0 vi phạm / 2 078 vector), kể cả **INV-7** — đồng
   nhất thức bù 2 mà kiến trúc "một bộ cộng dùng chung" dựa vào.
3. Ba hiện thực độc lập (Python, SV reference, RTL) đồng ý với nhau.
4. **0 ô nhớ** — xác nhận bởi hai bằng chứng độc lập (bảng cell + báo cáo công suất).
5. ALU này **nhỏ**: 64 cell · 417,9008 µm², dưới cả cận dưới 200 cell của ước lượng Charter.
6. **Bộ ghép kênh chọn phép chiếm 46,4 % diện tích**, tám phép tính chiếm 51,8 % — đo bằng
   ba lần tổng hợp riêng, tổng lại lệch thiết kế thật 0,3 %.
7. **Một bộ cộng dùng chung tiết kiệm 26,4 % diện tích cả ALU** so với hai đơn vị riêng, và
   phần tiết kiệm ở bộ ghép kênh (96,34 µm²) **lớn hơn** phần tiết kiệm ở bộ số học
   (57,56 µm²).
8. **Đường tới hạn xuất phát từ bit chọn phép**, không từ toán hạng: `op[2] → zflag`
   1,85 ns so với `a[0] → cflag` 1,04 ns.
9. Rủi ro chốt của Charter mục 10 đã được **dựng lại và đo**: chốt chỉ xuất hiện khi mất
   **cả hai** lớp phòng vệ, và `always_comb` biến lỗi đó thành lỗi dừng biên dịch.

### Chưa chứng minh

1. Netlist tương đương RTL về chức năng — cần mô phỏng gate-level.
2. Độ trễ **thật sau routing** — 1,85 ns chưa tính ký sinh dây.
3. Biên an toàn qua các góc PVT — mới chạy `tt_025C_1v80`.
4. Công suất thật của ứng dụng — 1,56e-05 W dùng activity mặc định, không lấy từ VCD.
5. **Chi phí công suất của kiến trúc "tính hết rồi chọn"** — biết chắc về mặt cấu trúc là
   cả tám nhánh đều chuyển mạch, nhưng **chưa đo** được bằng bao nhiêu.
6. Độ lớn và độ dài của vùng glitch khi `op` đổi — cần mô phỏng có SDF.
7. Layout tuân thủ quy tắc chế tạo (DRC), khớp netlist (LVS), và có file GDSII.
8. Tỉ lệ 46,4 % có giữ ở độ rộng từ khác hay không — chỉ đo ở 4 bit.

### Ngoài phạm vi — không được khẳng định

"Đã sign-off", "đã tape-out", "đã chế tạo", "đã kiểm tra sau chế tạo", "chạy được ở XXX MHz".
Charter mục 3 loại tất cả khỏi phạm vi đề tài, cùng với nhân, chia, dịch nhiều bit trong
một chu kỳ, và cờ tràn có dấu.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24*
