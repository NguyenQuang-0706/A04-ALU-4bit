#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
A04 - Mo hinh chuan Python cho ALU 4-bit tam chuc nang.

Vai tro trong ho so
-------------------
Chuan so sanh DOC LAP THU HAI (chuan thu nhat la a04_reference.sv).
File nay lam ba viec:

  [1] 30 ca co ten - 24 ca bat buoc cua Charter muc 8 (8 phep x 3 cap
      toan hang) + 6 ca tu xay dung, trong do co ca bien;
  [2] 7 bat bien INV-1..INV-7 tren TOAN BO 2048 to hop (16 x 16 x 8);
  [3] do vai con so ma tai lieu 02_SPECIFICATION/corner_cases.md vien
      dan - dac biet la so to hop cho Z=1 cua tung phep, con so giai
      thich vi sao de nay BAT BUOC quet vet can chu khong kiem ngau nhien.

Bat bien dang chu y nhat la INV-7. No khong noi ve hanh vi cua khoi ma
noi ve GIA THIET MA KIEN TRUC DUA VAO: rang `A + (~B) + 1` bang dung
`A - B`, va carry ra cua phep do bang dung `A >= B`. Neu INV-7 sai thi
kien truc "mot bo cong dung chung" cua RTL sup do.

Chay:  python3 reference_model.py
Thoat: 0 neu tat ca PASS, 1 neu co bat ky FAIL nao.
"""

import sys

WIDTH = 4
N = 1 << WIDTH          # 16 gia tri moi toan hang
MASK = N - 1            # 0xF
NOPS = 8                # tam phep

OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR = range(8)

OP_NAME = {
    OP_ADD: "ADD", OP_SUB: "SUB", OP_AND: "AND", OP_OR:  "OR",
    OP_XOR: "XOR", OP_NOT: "NOT", OP_SHL: "SHL", OP_SHR: "SHR",
}

# Bon phep logic bit - luon phai cho C = 0 (INV-4).
LOGIC_OPS = (OP_AND, OP_OR, OP_XOR, OP_NOT)


# ---------------------------------------------------------------------
# 1. MO HINH CHUAN - tam bieu thuc ROI RAC
# ---------------------------------------------------------------------

def alu(a, b, op):
    """Tra ve (result, cflag, zflag).

    Moi nhanh la mot bieu thuc doc lap. KHONG co bo cong dung chung,
    KHONG co chuoi carry - do la viec cua RTL, khong phai cua chuan.
    """
    if op == OP_ADD:
        total = a + b
        result = total & MASK
        cflag = 1 if total > MASK else 0        # tran khong dau
    elif op == OP_SUB:
        result = (a - b) & MASK
        cflag = 1 if a >= b else 0              # C=1 nghia la KHONG muon
    elif op == OP_AND:
        result, cflag = a & b, 0
    elif op == OP_OR:
        result, cflag = a | b, 0
    elif op == OP_XOR:
        result, cflag = a ^ b, 0
    elif op == OP_NOT:
        result, cflag = (~a) & MASK, 0          # phep mot ngoi, B bo qua
    elif op == OP_SHL:
        result = (a << 1) & MASK
        cflag = (a >> (WIDTH - 1)) & 1          # bit bi day ra ngoai
    elif op == OP_SHR:
        result = (a >> 1) & MASK
        cflag = a & 1                           # bit bi day ra ngoai
    else:
        raise ValueError("ma phep khong hop le: %r" % (op,))

    zflag = 1 if result == 0 else 0             # Z noi ve RESULT DA CAT
    return result, cflag, zflag


# ---------------------------------------------------------------------
# 2. BO DEM KET QUA
# ---------------------------------------------------------------------

class Tally(object):
    def __init__(self):
        self.checks = 0
        self.fails = 0

    def check(self, cond, label):
        self.checks += 1
        if not cond:
            self.fails += 1
            print("  FAIL: %s" % label)
        return cond


# ---------------------------------------------------------------------
# 3. CA CO TEN
#    (ten, op, A, B, result, C, Z, nhan)
# ---------------------------------------------------------------------

NAMED_CASES = [
    # --- 24 ca bat buoc: 8 phep x 3 cap toan hang -------------------
    ("TC-001", OP_ADD,  0,  0,  0, 0, 1, "nho nhat ca hai toan hang; Z=1 khong qua tran"),
    ("TC-002", OP_ADD,  5,  3,  8, 0, 0, "giua dai, khong sinh carry ra"),
    ("TC-003", OP_ADD,  9,  7,  0, 1, 1, "9+7=16: C=1 va Z=1 CUNG LUC"),
    ("TC-004", OP_SUB,  5,  3,  2, 1, 0, "tru khong muon -> chot quy uoc C=1 la KHONG muon"),
    ("TC-005", OP_SUB,  3,  5, 14, 0, 0, "tru CO muon - phan chung cua TC-004"),
    ("TC-006", OP_SUB,  7,  7,  0, 1, 1, "tru hai so bang nhau; carry-in lan het 4 tang"),
    ("TC-007", OP_AND, 12, 10,  8, 0, 0, "1100 & 1010 - mau bit lo loi noi lech bit"),
    ("TC-008", OP_AND, 15,  0,  0, 0, 1, "phan tu triet tieu cua AND"),
    ("TC-009", OP_AND, 15, 15, 15, 0, 0, "phan tu don vi - du lieu di qua nguyen ven"),
    ("TC-010", OP_OR,  12, 10, 14, 0, 0, "cung cap toan hang voi TC-007 va TC-013"),
    ("TC-011", OP_OR,   0,  0,  0, 0, 1, "ca DUY NHAT trong 256 cap cho Z=1 voi phep OR"),
    ("TC-012", OP_OR,   8,  1,  9, 0, 0, "hai bit o hai dau tu - khong bit nao bi nuot"),
    ("TC-013", OP_XOR, 12, 10,  6, 0, 0, "cung cap voi TC-007 / TC-010"),
    ("TC-014", OP_XOR,  5,  5,  0, 0, 1, "x XOR x = 0 - tinh chat dac trung cua XOR"),
    ("TC-015", OP_XOR, 15,  0, 15, 0, 0, "XOR voi 0 la phep dong nhat"),
    ("TC-016", OP_NOT,  0,  0, 15, 0, 0, "dao toan bo tu"),
    ("TC-017", OP_NOT, 15,  9,  0, 0, 1, "B=9 khac 0: bat loi de B lot vao nhanh NOT"),
    ("TC-018", OP_NOT, 10,  5,  5, 0, 0, "bay nguoc: B=5 TRUNG ket qua dung, can TC-017 bu"),
    ("TC-019", OP_SHL,  1,  0,  2, 0, 0, "dich trai khong mat bit"),
    ("TC-020", OP_SHL,  8,  0,  0, 1, 1, "1000<<1: bit duy nhat roi ra C, ket qua rong"),
    ("TC-021", OP_SHL, 15,  0, 14, 1, 0, "dich trai toan 1 - kiem bit 0 duoc chen dung"),
    ("TC-022", OP_SHR,  2,  0,  1, 0, 0, "dich phai khong mat bit"),
    ("TC-023", OP_SHR,  1,  0,  0, 1, 1, "doi xung voi TC-020 o phia phai"),
    ("TC-024", OP_SHR, 15,  0,  7, 1, 0, "dich phai LOGIC: bit cao phai la 0, khong nhan ban dau"),
    # --- 6 ca tu xay dung (Charter muc 8 doi >= 2, co ca bien) -------
    ("TC-025", OP_SUB,  0,  1, 15, 0, 0, "CA BIEN: 0-1, bien duoi tuyet doi cua phep tru"),
    ("TC-026", OP_ADD, 15, 15, 14, 1, 0, "CA BIEN: moi tang TU SINH carry -> khong phai lan"),
    ("TC-027", OP_ADD, 15,  1,  0, 1, 1, "CA BIEN: carry sinh o bit 0 roi lan het 3 tang"),
    ("TC-028", OP_ADD, 10,  5, 15, 0, 0, "ca NHANH NHAT: khong tang nao sinh carry"),
    ("TC-029", OP_SHL,  0,  0,  0, 0, 1, "CA BIEN: ca duy nhat nhom dich co Z=1 ma C=0"),
    ("TC-030", OP_SUB,  8,  8,  0, 1, 1, "CA BIEN: chuoi carry DAI NHAT toan ALU (4 tang)"),
]


def run_named_cases(t):
    print("[1] CA CO TEN - 24 ca Charter muc 8 + 6 ca tu xay dung")
    for name, op, a, b, wr, wc, wz, note in NAMED_CASES:
        r, c, z = alu(a, b, op)
        ok = t.check((r, c, z) == (wr, wc, wz),
                     "%s: %s A=%d B=%d cho (%d,%d,%d), mong doi (%d,%d,%d)"
                     % (name, OP_NAME[op], a, b, r, c, z, wr, wc, wz))
        print("    %-8s %-3s A=%2d B=%2d -> result=%2d C=%d Z=%d  %s  %s"
              % (name, OP_NAME[op], a, b, r, c, z,
                 "PASS" if ok else "FAIL", note))


# ---------------------------------------------------------------------
# 4. BAY BAT BIEN TREN TOAN BO 2048 TO HOP
#    Ten INV-x khop 02_SPECIFICATION/functional_spec.md muc 6.
# ---------------------------------------------------------------------

def run_invariants(t):
    total_combos = N * N * NOPS
    print("\n[2] BAT BIEN INV-1..INV-7 tren toan bo %d to hop (16 x 16 x 8)"
          % total_combos)

    inv_fail = dict((k, 0) for k in range(1, 8))
    combos = 0

    for a in range(N):
        for b in range(N):
            for op in range(NOPS):
                combos += 1
                r, c, z = alu(a, b, op)

                # INV-1: ADD - ghep {C, result} 5 bit phai bang dung A+B
                if op == OP_ADD and ((c << WIDTH) | r) != a + b:
                    inv_fail[1] += 1

                # INV-2: SUB - result == (A-B) mod 16 VA C == (A >= B)
                if op == OP_SUB:
                    if r != ((a - b) & MASK) or c != (1 if a >= b else 0):
                        inv_fail[2] += 1

                # INV-3: Z == (result == 0), dung cho CA TAM phep
                if z != (1 if r == 0 else 0):
                    inv_fail[3] += 1

                # INV-4: bon phep logic LUON cho C == 0
                if op in LOGIC_OPS and c != 0:
                    inv_fail[4] += 1

                # INV-5: dich 1 bit - bit bi day ra luon xuat hien o C
                if op == OP_SHL and c != ((a >> (WIDTH - 1)) & 1):
                    inv_fail[5] += 1
                if op == OP_SHR and c != (a & 1):
                    inv_fail[5] += 1

                # INV-6: NOT la phep MOT NGOI - ket qua khong phu thuoc B
                if op == OP_NOT:
                    r0, c0, z0 = alu(a, 0, OP_NOT)
                    if (r, c, z) != (r0, c0, z0):
                        inv_fail[6] += 1

    # INV-7: NEN TANG CUA BO CONG DUNG CHUNG.
    # `A + (~B) + 1` phai bang dung `A - B`, va carry ra cua chinh phep
    # cong do phai bang dung `A >= B`. Kiem tren ca 256 cap (A,B):
    # day la bat bien ve GIA THIET KIEN TRUC, khong phu thuoc `op`.
    for a in range(N):
        for b in range(N):
            raw = a + ((~b) & MASK) + 1
            if (raw & MASK) != ((a - b) & MASK):
                inv_fail[7] += 1
            if ((raw >> WIDTH) & 1) != (1 if a >= b else 0):
                inv_fail[7] += 1

    labels = {
        1: "ADD: {C, result} == A + B",
        2: "SUB: result == (A-B) mod 16 va C == (A >= B)",
        3: "Z == (result == 0) cho ca TAM phep",
        4: "AND/OR/XOR/NOT luon cho C == 0",
        5: "dich 1 bit: bit bi day ra luon xuat hien o C",
        6: "NOT la phep mot ngoi: ket qua khong phu thuoc B",
        7: "A + (~B) + 1 == A - B va carry ra == (A >= B)",
    }
    for k in range(1, 8):
        t.check(inv_fail[k] == 0, "INV-%d vi pham %d lan" % (k, inv_fail[k]))
        print("    INV-%d  %-4s  %s" % (k, "PASS" if inv_fail[k] == 0 else "FAIL",
                                        labels[k]))
    print("    (INV-7 la bat bien BIEN MINH cho kien truc 'mot bo cong dung chung')")
    return combos


# ---------------------------------------------------------------------
# 5. SO LIEU DOI CHIEU VOI corner_cases.md
# ---------------------------------------------------------------------

def report_stats():
    print("\n[3] SO LIEU DOI CHIEU VOI corner_cases.md muc 4.2")
    print("    So to hop (A,B) cho Z=1, tinh tren 256 cap cua TUNG phep:")

    grand = 0
    for op in range(NOPS):
        n = sum(1 for a in range(N) for b in range(N) if alu(a, b, op)[2] == 1)
        grand += n
        print("      %-3s : %3d/256" % (OP_NAME[op], n))
    print("    Tong tren toan khong gian 2048 to hop: %d vector co Z=1" % grand)

    n_or = sum(1 for a in range(N) for b in range(N) if alu(a, b, OP_OR)[2] == 1)
    print("    => Phep OR la phep KHO kiem co Z nhat: chi %d/256 to hop." % n_or)
    miss = (255.0 / 256.0) ** 100
    print("       Mot bo kiem NGAU NHIEN 100 vector bo sot ca do voi xac suat %.0f%%."
          % (miss * 100.0))
    print("       Day la ly do cu the, do duoc, giai thich vi sao de nay")
    print("       PHAI quet vet can chu khong kiem ngau nhien.")

    # Bao phu cap co (C, Z): ca bon to hop deu phai xay ra.
    seen = set()
    for a in range(N):
        for b in range(N):
            for op in range(NOPS):
                r, c, z = alu(a, b, op)
                seen.add((c, z))
    print("    Bao phu cap co (C,Z): %s -> %d/4 to hop deu xay ra"
          % (sorted(seen), len(seen)))


# ---------------------------------------------------------------------
# 6. CHUONG TRINH CHINH
# ---------------------------------------------------------------------

def main():
    print("=" * 74)
    print("A04 - MO HINH CHUAN PYTHON - ALU 4-bit tam chuc nang")
    print("=" * 74)

    t = Tally()
    run_named_cases(t)
    combos = run_invariants(t)
    report_stats()

    print("\n" + "=" * 74)
    print("TONG KET: %d phep kiem, %d loi, quet vet can %d/%d to hop"
          % (t.checks, t.fails, combos, N * N * NOPS))
    if t.fails == 0:
        print("A04 reference model PASS")
        print("=" * 74)
        return 0
    print("A04 reference model FAIL")
    print("=" * 74)
    return 1


if __name__ == "__main__":
    sys.exit(main())
