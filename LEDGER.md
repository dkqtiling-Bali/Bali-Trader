BALI TRADER LEDGER

V001 Project Brain created.

Status:
- GitHub connected
- Local repo path: C:\Bali\Bali-Trader
- Safety-first mission recorded
- Next patch direction recorded

Next recommended patch:
Create an AI handover report generator for ChatGPT/Copilot/Claude use.

AI HQ V1 added.

Added:
- BALI_AI_HQ_V1.bat
- README_BALI_AI_HQ_V1.md

Purpose:
Central command menu for AI handover, Git status, Git backup, and Project Brain access.

Next recommended patch:
Improve handover report to include folder map, latest logs, safety lock scan, and next patch recommendation.

AI HQ V2 added.

Added:
- BALI_AI_HQ_V2.bat
- tools/BALI_AI_HQ_V2_ANALYSE.ps1

Purpose:
Adds bundled project analysis, handover V2, safety scan, git clean check, mission alignment check, project score, and next patch recommendation.

Mission alignment:
This update improves maintainability, safety visibility, reporting quality, and AI-assisted patch selection. It supports the mission of safely discovering evidence-backed crypto strategies that may help generate profit in the market.

AI HQ V3 added.

Added:
- BALI_AI_HQ_V3.bat
- tools/BALI_AI_HQ_V3_ANALYSE.ps1

Purpose:
Adds automated project map generation, smarter mission-aligned next patch recommendation, risk/change classification, upgraded AI handover V3 reporting, safety scan visibility, and git/report summary tooling.

Mission alignment:
This update improves maintainability, safety visibility, reporting quality, and AI-assisted patch selection before any trading logic change. It supports the mission of safely discovering evidence-backed crypto strategies that may help generate profit in the market.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE

Next recommended patch after V3:
Use AI HQ V3 to generate a full handover, then prefer V4 Evidence Pack Index + Backtest Run Registry unless V3 finds a safety or health issue first.

Bali OS V4 added.

Added:
- BALI_MASTER_CONTROL.bat
- BALI_SAFE_GIT_SAVE.bat
- tools/BALI_OS_ENGINE.ps1
- CONSTITUTION.md
- BALI_OS_WORKFLOW.md
- DEFINITION_OF_DONE.md
- EVIDENCE_STANDARDS.md
- PATCH_APPROVAL_RULES.md
- AI_ENGINEER_QUEUE.md

Purpose:
Turns Bali AI HQ into Bali OS: a seamless operating workflow for analysis, handover, safety scans, project maps, evidence indexing, next-patch recommendations, and safe Git backup.

Mission alignment:
This update improves maintainability, AI alignment, patch discipline, reporting, project control, safety visibility, and future strategy discovery workflow. It supports the mission of safely discovering evidence-backed crypto strategies that may help generate profit in the market.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE

Next recommended patch after V4:
Use Bali OS to run Full Auto Analyse + Handover, then prefer V5 Evidence Pack Index + Backtest Run Registry unless Bali OS finds a safety or health issue first.

BALI OS V4B Safe Git Save Fix added.

Added:
- tools/BALI_OS_SAFETY_SCAN_V4B.ps1
- tools/BALI_SAFE_GIT_SAVE_V4B.ps1
- BALI_SAFE_GIT_SAVE.bat updated to call V4B safe save

Purpose:
Fixes false positive Git-save blocking caused by safety-rule wording such as NO_API_KEYS and NO live trading appearing in project documentation. V4B still blocks likely real secrets, tokens, live-trading enablement, champion unlock, and unsafe staged files.

Mission alignment:
Improves safe automation, source control reliability, project maintainability, and proof/report preservation without changing trading logic.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE

BALI OS V4C Menu Git Fix added.

Added:
- tools/BALI_OS_SAFETY_SCAN_V4C.ps1
- tools/BALI_SAFE_GIT_SAVE_V4C.ps1
- BALI_SAFE_GIT_SAVE.bat updated to V4C
- BALI_MASTER_CONTROL.bat option 8 rewired to call V4C safe Git directly

Purpose:
Fixes the remaining issue where Master Control option 8 still called the old Bali OS engine GitSafeSave action and blocked on false-positive safety-policy wording. V4C keeps Git save automated while preserving hard blockers for real-looking secrets, live-trading enablement, and champion unlock.

Mission alignment:
Improves safe automation, source control reliability, project maintainability, and proof/report preservation without changing trading logic.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE

BALI OS V4D Direct Menu Git Fix added.

Added:
- tools/BALI_OS_SAFETY_SCAN_V4D.ps1
- tools/BALI_SAFE_GIT_SAVE_V4D.ps1
- BALI_SAFE_GIT_SAVE.bat updated to V4D
- BALI_MASTER_CONTROL.bat rewritten with label-based direct calls

Purpose:
Fixes the Windows batch quoting issue from V4C where option 8 produced '""' is not recognized. V4D removes the nested call wrapper and runs the V4D PowerShell Git save script directly from a menu label.

Mission alignment:
Improves safe automation, source control reliability, project maintainability, and proof/report preservation without changing trading logic.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE

BALI OS V4E Hard-Path Git Save Fix added.

Added:
- tools/BALI_OS_SAFETY_SCAN_V4E.ps1
- tools/BALI_SAFE_GIT_SAVE_V4E.ps1
- BALI_SAFE_GIT_SAVE.bat updated to V4E
- BALI_MASTER_CONTROL.bat rewritten with fixed hard-coded safe paths

Purpose:
Fixes the Windows PowerShell -File '' issue from V4D by removing the empty script-path variable entirely. Option 8 now runs the V4E Git save script from a fixed known path: C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1.

Mission alignment:
Improves safe automation, source-control reliability, project maintainability, and proof/report preservation without changing trading logic.

Safety preserved:
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED
- NO TRADING LOGIC CHANGE
