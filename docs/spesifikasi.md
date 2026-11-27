# Spesifikasi Teknis: Signed Multiplier 32-Bit Berbasis Algoritma Booth

## 1. Deskripsi Fungsional
Modul inti (`booth32_core`) melakukan operasi perkalian bilangan bertanda (*signed*, representasi *two's complement*) selebar 32-bit × 32-bit dan menghasilkan keluaran 64-bit menggunakan algoritma **Booth Radix-2 iteratif** selama 32 siklus kalkulasi.

## 2. Antarmuka Port Modul Core (`booth32_core`)
| Nama Port | Arah | Lebar (Bit) | Deskripsi |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 | Sinyal *clock* sistem (sinkron *rising-edge*) |
| `rst_n` | Input | 1 | Sinyal *reset* sinkron aktif-rendah |
| `start` | Input | 1 | Pulsa 1 siklus untuk memulai operasi perkalian |
| `multiplicand` | Input | 32 | Bilangan yang dikalikan (*signed* 32-bit) |
| `multiplier` | Input | 32 | Bilangan pengali (*signed* 32-bit) |
| `product` | Output | 64 | Hasil perkalian (*signed* 64-bit) |
| `done` | Output | 1 | Penanda hasil pada `product` telah valid |

## 3. Arsitektur & Perilaku Siklus
* **Partisi Datapath & Control Path:**
  * *Datapath* terdiri atas register gabungan `{A, Q, Q_minus_1}` selebar 65-bit, unit penjumlah/pengurang (*adder/subtractor*) 32-bit, *arithmetic right shifter*, dan pencacah (*counter*) iterasi 32 siklus.
  * *Control path* diimplementasikan menggunakan *Finite State Machine* (FSM) berbasis `enum` dengan 4 *state*: `IDLE`, `INIT`, `CALC`, dan `DONE`.
* **Alur Eksekusi:** Saat `start = 1` pada *state* `IDLE`, operand dimuat pada `INIT`, diproses selama 32 siklus di `CALC`, lalu hasil akhir dikeluarkan dengan `done = 1` pada `DONE`.

## 4. Portabilitas & Strategi Pin I/O
* **Portabilitas RTL:** Kode *core* ditulis dalam SystemVerilog yang *synthesizable* tanpa instansiasi PLL, blok memori (BRAM/SRAM), maupun primitif khusus vendor sehingga dapat langsung dikompilasi untuk FPGA maupun alur ASIC LibreLane.
* **Penanganan Jumlah Pin (128-Bit Data):** Modul *core* mempertahankan antarmuka paralel penuh (`32 + 32 + 64` bit). Keterbatasan pin fisik pada *board* FPGA ditangani di dalam modul *top-level wrapper* terpisah (menggunakan UART atau *multiplexing* I/O).

## 5. Target PDK & Prioritas PPA
* **Open PDK Utama:** SkyWater 130nm (`sky130A`) melalui alur RTL-to-GDSII LibreLane.
* **Prioritas PPA (Power, Performance, Area):**
  1. **Area:** Meminimalkan luas *core* dan jumlah sel standar agar desain ringkas serta mudah lolos pemeriksaan DRC dan LVS.
  2. **Performance (Timing):** Memenuhi *setup/hold slack* positif pada periode *clock* target (diatur melalui file *constraint* FPGA dan `config.json` LibreLane, bukan di dalam kode RTL).
  3. **Power:** Efisiensi daya dinamis melalui arsitektur iteratif yang hemat gerbang logika.
