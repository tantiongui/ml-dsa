# Agent 交接日誌 (Handover Log) - NIST FIPS 204 ML-DSA

**紀錄時間**: 2026-08-20 (最新更新)  
**專案名稱**: `ml-dsa` / `clash-hash` / `my-clash-project` (NIST FIPS 204 ML-DSA 硬體/軟體協同設計)  
**GitHub 儲存庫**: `https://github.com/tantiongui/ml-dsa.git`  
**Commit Identity**: `tantiongui <mcmr.wei@gmail.com>`

---

## 1. 任務目標與目前進度 (Task Status & Progress)

本專案旨在完成 NIST FIPS 204 (ML-DSA) 標準中的 `SampleInBall` (Algorithm 29) 與 `CoeffFromHalfByte` (Algorithm 15) 演算法實作、規範對齊、儲存庫管理、Clash HDL 硬體設計合成與雙模型等價驗證作業。

### 目前已完成項目：
1. **GitHub 儲存庫同步**: 遠端與本地端分支同步 (`main`)。
2. **純軟體參考模型 (Golden Model)**: 
   - [SampleInBall.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/SampleInBall.hs)：輕量化 Haskell 參考實作，已進行 100% 變數與演算法邏輯對齊。
   - [clash-hash/src/Reference/SampleInBall.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/clash-hash/src/Reference/SampleInBall.hs)：整合 SHAKE256 XOF 與有限體 $Z_q$ 的黃金參考模型。
   - [clash-hash/reference/sample_in_ball.py](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/clash-hash/reference/sample_in_ball.py)：獨立 Python 參考實作，用於跨語言黃金向量比對。
3. **Clash 開發環境建置與工具鏈驗證**:
   - 修復 Windows Console / PowerShell UTF-8 編碼問題 (`chcp 65001` 及 `$OutputEncoding`)，解決 GHC 輸出 Unicode 時之 `commitAndReleaseBuffer` 例外。
   - 完成 `clash-prelude-1.10.0`、`clash-lib`、`clash-ghc` 與 [my-clash-project](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project) 構建。
4. **Algorithm 15 (`CoeffFromHalfByte`) Clash 實作與 Verilog 硬體合成**:
   - 實作 [CoeffFromHalfByte.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/CoeffFromHalfByte.hs)，支援 $\eta=2$ (ML-DSA-44/87) 與 $\eta=4$ (ML-DSA-65)。
   - 完成 `clashi` 全值域 $b \in [0..15]$ 模擬，輸出完全對齊 FIPS 204 規範（含 `Nothing` 拒絕抽樣）。
   - 成功合成出 Verilog-2001 硬體碼 [verilog/CoeffFromHalfByte.topEntity/topEntity.v](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/CoeffFromHalfByte.topEntity/topEntity.v)。
5. **Algorithm 29 (`SampleInBall`) Clash 實作、硬體狀態機與 Verilog 合成**:
   - 實作 [SampleInBall.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/src/SampleInBall.hs)，使用 Mealy 狀態機 (`sampleInBallT`) 處理拒絕抽樣 ($j \le i$) 與 256 個 24-bit 係數暫存器陣列 Fisher-Yates 換位。
   - 成功合成出 Verilog-2001 硬體代碼 [verilog/SampleInBall.topEntity/topEntity.v](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/my-clash-project/verilog/SampleInBall.topEntity/topEntity.v)。
6. **獨立等價性驗證套件與極端測資比對 (NEW)**:
   - 建立非侵入式獨立驗證套件 [misc/VerifyClashSampleInBall.hs](file:///c:/Users/capta/Documents/2026ete/ml_dsa_2/misc/VerifyClashSampleInBall.hs)。
   - 涵蓋 6 大特定邊界測資（交替符號、全正號、全負號、90% 超高拒絕率串流、強制碰撞置換、對角恆等置換）與 30 組隨機擬亂數串流壓力測試，硬體 FSM 與黃金模型比對達成 **100% 完全吻合 (30/30 PASSED)**。

---

## 2. 交付檔案結構 (Deliverables Breakdown)

```
ml_dsa_2/
├── .gitignore                                 # Git 忽略設定
├── README.md                                  # 專案說明與測試操作指引
├── SampleInBall.hs                            # 輕量化純 Haskell 參考實作
├── clash-hash/                                # Clash-HDL & Haskell ML-DSA 核心專案
│   ├── reference/
│   │   ├── sample_in_ball.py                  # Python 黃金標準參考模型
│   │   └── VerifySampleInBall.hs              # 純軟體模型驗證腳本
│   └── src/
│       └── Reference/
│           └── SampleInBall.hs                # 整合 SHAKE256 XOF 之黃金參考模型
└── misc/                                      # 輔助工具與驗證套件
    ├── AGENT_HANDOVER_LOG.md                  # 本交接日誌檔案
    └── VerifyClashSampleInBall.hs             # 獨立 SampleInBall 軟硬體雙模型比對套件 (NEW)
└── my-clash-project/                          # Clash 實作與合成測試專案
    ├── my-clash-project.cabal                 # Cabal 專案設定檔
    ├── src/
    │   ├── MAC.hs                             # 乘加器時序電路範例
    │   ├── CoeffFromHalfByte.hs               # Algorithm 15 Clash 組合電路
    │   └── SampleInBall.hs                    # Algorithm 29 Clash Mealy 狀態機
    ├── tests/
    │   ├── unittests.hs                       # Tasty 測試入口
    │   └── Tests/
    │       └── SampleInBallTest.hs            # SampleInBall 單元與屬性測試
    └── verilog/                               # Synthesizable Verilog 輸出目錄
        ├── MAC.topEntity/topEntity.v
        ├── CoeffFromHalfByte.topEntity/topEntity.v
        └── SampleInBall.topEntity/topEntity.v # SampleInBall Verilog 合成碼
```

---

## 3. 開發與測試指令速查 (Developer Guidelines)

工作目錄：`my-clash-project/`

* **執行獨立 6 大極端測資與 30 組隨機串流比對報告**:
  ```powershell
  stack exec clashi -- ../misc/VerifyClashSampleInBall.hs -e "main"
  ```
* **一鍵驗證表達式**:
  ```powershell
  stack exec clashi -- src/SampleInBall.hs -e "verifySampleInBall"
  ```
* **執行 Cabal 測試套件 (`stack test`)**:
  ```powershell
  stack test
  ```
* **合成生成 Verilog**:
  ```powershell
  stack exec clash -- --verilog src/SampleInBall.hs
  ```

---

## 4. 未來可接續的 Roadmap

1. **`SampleInBall` 與 SHAKE256 XOF 串流整合**:
   - 將 `SampleInBall.hs` 的 `needByte` 訊號與 SHAKE256 串流輸出連接，實現硬體自動 Squeeze & Sample 流水線。
2. **`clash-hash` 專案模組移轉與頂層晶片化**:
   - 將驗證完成的模組移植至 `clash-hash/src/Component/`，建構完整 ML-DSA 簽名引擎。
