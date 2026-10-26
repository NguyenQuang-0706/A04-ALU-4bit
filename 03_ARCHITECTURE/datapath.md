# A04 · Đường dữ liệu (Datapath)

---

## 1. A04 có hai loại tín hiệu, không phải một

A01 (bộ cộng) là datapath thuần: mọi tín hiệu đều là dữ liệu. A04 **khác** — đây là điểm
phân biệt đầu tiên cần nắm:

```
  a[3:0] ═══╗                                                   ╔══▶ result[3:0]  (dữ liệu)
            ╠══▶ ┌───────────────────────────────────┐ ═════════╝
  b[3:0] ═══╝    │  8 nhánh chức năng                │ ────────────▶ cflag        (trạng thái)
                 │  + bộ ghép kênh 8→1               │ ────────────▶ zflag        (trạng thái)
  op[2:0] ──────▶│  + logic cờ                       │
      ▲          └───────────────────────────────────┘
      │
   ĐÂY KHÔNG PHẢI DỮ LIỆU — đây là LỆNH.
   Nó không bị biến đổi, nó quyết định phép biến đổi.
```

`op[2:0]` là tín hiệu **điều khiển được nhúng vào datapath**. Nó không mang giá trị cần
tính, nó chọn xem tính gì. Hệ quả sẽ thấy ở §5: chính tín hiệu này — chứ không phải toán
hạng — nằm trên đường tới hạn.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `a[3:0]` | 4 | cổng vào | bộ cộng · 4 nhánh logic · 2 nhánh dịch | Toán hạng — **fanout cao nhất** |
| `b[3:0]` | 4 | cổng vào | XOR điều kiện hoá · AND/OR/XOR | Toán hạng |
| `op[2:0]` | 3 | cổng vào | giải mã `sub` · bộ ghép kênh | **Lệnh** — không phải dữ liệu |
| `sub` | 1 | giải mã `op` | 4 cổng XOR + `carry[0]` | **Điều khiển len vào datapath số học** |
| `b_eff[3:0]` | 4 | `b ⊕ {4{sub}}` | 4 tầng full-adder | Toán hạng đã điều kiện hoá |
| `carry[4:0]` | 5 | nội bộ | nối tầng `i` → `i+1` | **Đường nối tiếp — nguồn gốc độ trễ số học** |
| `r_arith[3:0]` | 4 | 4 tầng FA | bộ ghép kênh (**vào 2 lần**: ADD và SUB) | Kết quả nhánh số học |
| `c_arith` | 1 | `carry[4]` | bộ ghép kênh (**vào 2 lần**) | Ứng viên cờ C |
| `r_and/r_or/r_xor/r_not` | 4×4 | cổng logic | bộ ghép kênh | Kết quả 4 nhánh logic |
| `r_shl/r_shr` | 2×4 | **dây nối** | bộ ghép kênh | Kết quả 2 nhánh dịch, **0 cổng** |
| `c_shl`, `c_shr` | 2×1 | `a[3]`, `a[0]` | bộ ghép kênh | Bit bị đẩy ra, **0 cổng** |
| `result[3:0]` | 4 | bộ ghép kênh | cổng ra + logic `Z` | Kết quả |
| `cflag` | 1 | bộ ghép kênh | cổng ra | Cờ |
| `zflag` | 1 | `NOR4(result)` | cổng ra | Cờ — **sâu nhất** |

Tổng bề rộng đi vào bộ ghép kênh: `8 × 4 = 32` bit kết quả + `8 × 1 = 8` bit carry = **40
bit**, nén xuống **5 bit** ra. Tỉ số nén `8:1` này chính là "cái giá của tính linh hoạt"
mà Charter mục 9 hỏi.

## 3. Đồ thị phụ thuộc

```
 mức 0    a[3:0]   b[3:0]                       op[2:0]
            │         │                            │
            │         │                            ├──────────────┐
            │         │                            ▼              │
 mức 1      │         │                      sub = (op==001)      │
            │         │                            │              │
            │         └──────────┬─────────────────┤              │
            │                    ▼                 │              │
 mức 2      │            b_eff = b ⊕ sub           │              │
            │                    │                 │              │
            ├────────┬───────────┤        carry[0] = sub          │
            │        │           │                 │              │
            │        │           ▼                 ▼              │
 mức 3..6   │        │      ┌──────────────────────────────┐      │
            │        │      │ FA0 → FA1 → FA2 → FA3        │      │
            │        │      │  (chuỗi carry 4 tầng)        │      │
            │        │      └──────┬──────────────┬────────┘      │
            │        │             │ r_arith      │ c_arith       │
            │        │             │              │               │
            ▼        ▼             │              │               │
 mức 1   r_and, r_or, r_xor, r_not │              │               │
         (độ sâu 1 cổng, SONG SONG với chuỗi carry)               │
            │                      │              │               │
 mức 0   r_shl, r_shr, c_shl, c_shr│              │               │
         (0 cổng — chỉ là dây)     │              │               │
            │                      │              │               │
            └──────────┬───────────┴──────────────┘               │
                       ▼                                          ▼
 mức 7..9        ┌────────────────────────────────────────────────────┐
                 │        BỘ GHÉP KÊNH 8 → 1, rộng 5 bit              │
                 └──────────────┬─────────────────────┬───────────────┘
                                │ result              │ cflag
 mức 10                         ▼                     ▼
                          zflag = NOR4(result)      (ra)
                                │
                                ▼
                              (ra)
```

**Điểm cần thấy:** `op` có **hai** đường đi song song xuống mux:

* đường **ngắn**: `op → mux` (chỉ là tín hiệu chọn);
* đường **dài**: `op → sub → b_eff → chuỗi carry → r_arith → mux`.

Đường dài đi **xuyên qua toàn bộ bộ cộng**. Đó là cái giá cấu trúc của việc dùng chung một
bộ cộng: mã lệnh trở thành **một phần của đường dữ liệu số học**.

## 4. Độ sâu logic của từng nhánh

| Nhánh | Độ sâu tính từ `a`/`b` | Độ sâu tính từ `op` |
|---|---|---|
| SHL / SHR | **0 cổng** (nối dây) | 1 (chỉ qua mux) |
| AND / OR / XOR / NOT | **1 cổng** | 1 (chỉ qua mux) |
| ADD | 1 XOR + `k` tầng carry (`k ≤ 3`) | 1 (chỉ qua mux) |
| **SUB** | 1 XOR + `k` tầng carry (`k ≤ 4`) | **1 (giải mã `sub`) + 1 XOR + tới 4 tầng carry** |

Và sau mọi nhánh:

| Đầu ra | Cộng thêm |
|---|---|
| `result` | + bộ ghép kênh (~2–3 tầng cổng) |
| `cflag` | + bộ ghép kênh |
| `zflag` | + bộ ghép kênh + **cây NOR4** |

> 🔎 **Dự đoán ghi TRƯỚC khi chạy STA:** endpoint tới hạn nhiều khả năng là `zflag`, vì nó
> là đầu ra duy nhất nằm **nối tiếp sau** bộ ghép kênh. Và startpoint tới hạn nhiều khả
> năng là `op[2]` chứ **không** phải `a[0]`, vì `op[2]` tham gia giải mã `sub` — tức là
> nó đứng **trước** cả chuỗi carry, trong khi `a[0]` chỉ đứng ở đầu chuỗi carry.
>
> Đây là dự đoán **có thể sai**; phải đối chiếu với báo cáo STA. Nếu STA cho kết quả khác,
> **tin STA**.

## 5. Kết quả STA thật — dự đoán ở §4 **đúng cả hai vế**

Đo bằng OpenSTA trên netlist sau tổng hợp, clock ảo `vclk` chu kỳ 10 ns, góc
`tt_025C_1v80`:

| Đường | Startpoint → Endpoint | Thời gian đến | Slack |
|---|---|---:|---:|
| **Tới hạn** | `op[2]` → `zflag` | **1,85 ns** | 8,15 ns |
| thứ 2 | `op[2]` → `result[1]` | 1,61 ns | 8,39 ns |
| thứ 3 | `op[2]` → `result[3]` | 1,47 ns | 8,53 ns |
| thứ 4 | `op[2]` → `cflag` | 1,35 ns | 8,65 ns |
| thứ 5 | `op[2]` → `result[2]` | 1,26 ns | 8,74 ns |
| thứ 6 | `op[0]` → `result[0]` | 0,77 ns | 9,23 ns |

> **Cả sáu đường chậm nhất của toàn khối đều xuất phát từ `op`, không một đường nào xuất
> phát từ `a` hay `b`.**

Hỏi riêng STA về các đường xuất phát từ cổng dữ liệu để so sánh:

| Đường | Thời gian đến | So với đường tới hạn |
|---|---:|---|
| `op[2] → zflag` (**tới hạn**) | **1,85 ns** | — |
| `b[1] → zflag` (dữ liệu, chậm nhất) | 1,36 ns | đường tới hạn dài hơn **36 %** |
| `a[0] → zflag` | 1,31 ns | đường tới hạn dài hơn **41 %** |
| `a[0] → cflag` (**đi hết chuỗi carry 4 tầng**) | **1,04 ns** | đường tới hạn dài hơn **78 %** |

Chi tiết từng cell trên đường tới hạn (`06_GDSII/sta/timing_report_max.txt`):

```
 op[2] ─▶ _070_ nor3b_1   0,43 ns   ← GIẢI MÃ `sub`
       ─▶ _077_ xor2_1    0,26 ns   ← b_eff = b ⊕ sub
       ─▶ _079_ xor3_1    0,33 ns   ← một tầng tổng của bộ cộng
       ─▶ _087_ a2111oi_0 0,52 ns   ┐
       ─▶ _120_ o2111ai_1 0,18 ns   ├─ bộ ghép kênh + cây NOR sinh Z
       ─▶ _121_ a211oi_1  0,13 ns   ┘
       ═▶ zflag                     tổng 1,85 ns
```

### Đọc kết quả này thế nào

1. **Đường tới hạn của A04 không thuộc về "phép nào" cả.** Nó thuộc về **hành động chọn
   phép**. Cell đầu tiên trên đường (`nor3b_1`, 0,43 ns — cell **đắt nhất** trên cả đường)
   là bộ giải mã `sub`, tức là chi phí của việc **một bộ cộng phải phục vụ hai phép**.
2. **Chuỗi carry 4 tầng không phải nút thắt.** `a[0] → cflag` đi hết cả bốn tầng chỉ mất
   1,04 ns — chỉ bằng **56 %** đường tới hạn. Ở `N = 4` bit, chuỗi ripple còn quá ngắn để
   cạnh tranh với chi phí ghép kênh. (Ở A01 với `N = 8` thì ngược lại: chuỗi carry thống
   trị.) **Độ rộng từ quyết định ai là nút thắt.**
3. `op[2]` có **fanout 11** — cao nhất trong thiết kế (báo cáo STA ghi `11` ở dòng
   `op[2] (in)`). Fanout cao làm slew xấu, và cell `nor3b_1` phải trả 0,43 ns cho việc đó.

## 6. Vì sao không có thanh ghi trong datapath

| Câu hỏi | Trả lời |
|---|---|
| Dữ liệu có cần giữ qua chu kỳ không? | Không — A04 tính xong trong một lần lan truyền |
| Kết quả tích luỹ giữ ở đâu? | Ở thanh ghi `ACC` **bên ngoài** — xem `system_diagram.md` §1 |
| Cờ `C`, `Z` giữ ở đâu? | Ở thanh ghi `FLAGS` **bên ngoài** |
| Mã lệnh giữ ở đâu? | Ở thanh ghi lệnh `IR` **bên ngoài** |
| Có pipeline không? | Không — Charter chốt loại mạch **Tổ hợp** |
| Nếu thêm thanh ghi thì sao? | Vi phạm phân loại Charter và dấu hiệu làm đúng mục 10 ("0 ô nhớ") |

## 7. Cơ hội tối ưu (chỉ để thảo luận — **ngoài phạm vi**)

Vì đường tới hạn đi qua bộ giải mã `sub` rồi mới vào bộ cộng, có một phép biến đổi quen
thuộc để rút ngắn nó:

```
 Hiện tại :  op ─▶ sub ─▶ b_eff ─▶ [bộ cộng] ─▶ mux
 Phương án:  tính SẴN cả A+B lẫn A+¬B+1 bằng HAI bộ cộng,
             rồi để mux chọn   ⟹  op không còn nằm trước bộ cộng
```

Phương án này rút `op` ra khỏi đường số học, nhưng **trả giá**: +14 cell ở bộ số học và
+10 cell ở bộ ghép kênh (đo được, xem `tradeoff.md` §3) — tức **đúng thứ mà ràng buộc
"một bộ cộng dùng chung" của đề muốn tránh**. Ghi ở đây chỉ để trả lời câu "có cách nào
nhanh hơn không" khi bảo vệ. **Không** được dùng trong RTL nộp bài.

---

*Phiên bản: v2.0 (viết lại cho đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: REQ-A04-010…023, Charter mục 2 câu 3.*
