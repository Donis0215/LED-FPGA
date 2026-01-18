FPGA Logic Design & Digital System Implementation
🚀 從基礎門檻到系統整合的 Verilog 實作歷程
本倉庫紀錄了我學習 FPGA 與 Verilog HDL 的完整進階過程。從最基礎的 LED 移位控制，逐步發展到矩陣鍵盤掃描、多工顯示系統以及有限狀態機 (FSM) 的設計。

📂 專案導覽 (Project Roadmap)
🟢 第一階段：基礎序向邏輯與時脈管理 (Basics)
Lab 1: LED Scroller Series

Level 1 (Basic): 實作 8-bit 循環移位暫存器 ({shift_out[0], shift_out[7:1]})。

Level 2 (State Control): 加入 9-bit 狀態控制，實現 LED 「來回彈跳」效果。

Level 3 (Pattern Design): 擴充為 3-bit 「流星燈」圖案，強化視覺效果。

Level 4 (Dual-Color): 整合紅/綠雙色 LED，利用 MSB 作為顏色與方向的切換開關。

關鍵技術： Clock Divider, Concatenation Operators, Circular Shift Registers.

🟡 第二階段：資訊譯碼與計數系統 (Display & Counter)
Lab 2-1: BCD Decoder

建立靜態 7-Segment 譯碼器，將 4-bit BCD 碼映射至硬體各段 (a-g)。

Lab 2-2: Decade Counter

實作具備 Carry 進位信號的 0-9 計數器，這是數位時鐘的基礎單元。

Lab 2-3: 00-99 Multiplexed Counter

重大突破： 引入 時分多工 (TDM) 掃描技術。

使用單一譯碼器透過高頻切換同時驅動兩個顯示器，解決硬體腳位節省問題。

關鍵技術： Combinational MUX, Time-Division Multiplexing (TDM), Persistence of Vision.

🟠 第三階段：陣列掃描與字體視覺化 (Matrix Display)
Lab 4-1: 8x8 Dot Matrix Controller

實作 Font ROM (字體庫) 查表邏輯。

透過雙時脈系統 (clk_scan 與 clk_shift) 同時處理「高速行掃描」與「低速字元切換」。

關鍵技術： Memory Mapping (1D to 2D), Scanning Logic, ROM-based Lookup Tables.

🔴 第四階段：系統輸入整合與人機介面 (System Integration)
Lab 5 & 6: Matrix Keyboard System

矩陣掃描： 實作 3x4 鍵盤掃描電路，大幅減少鍵盤佔用的 I/O 數量。

硬體去彈跳 (Debouncing)： 使用多級移位暫存器過濾機械雜訊，確保輸入精準。

資料緩衝 (Shift Register Buffer)： 實作類似計算機的「由右向左位移」輸入邏輯 (Left-Shift Buffer)。

關鍵技術： Finite State Machine (FSM), Input Debouncing, Sequential Latching.

🔵 進階專題：有限狀態機 (FSM Theory)
FSM1: Mealy Machine Design

實作標準的 Two-Block Coding Style (Sequential + Combinational)。

展示了狀態轉移 (State Transition) 與輸入/輸出之間的即時邏輯反應。

關鍵技術： Mealy Machine, State Encoding, Asynchronous Reset.

🛠 使用工具與環境
開發語言： Verilog HDL

硬體平台： FPGA (支援 Altera/Intel Cyclone 系列)

開發環境： Quartus Prime / ModelSim

💡 技術核心總結
時序控制： 掌握了透過參數化除頻器管理多個時脈域 (Clock Domains) 的能力。

硬體優化： 懂得利用 MUX 與 TDM 技術在有限資源下實現多位數顯示。

穩健設計： 透過硬體去彈跳與同步序向電路設計，確保系統在實體開發板上的穩定性。
