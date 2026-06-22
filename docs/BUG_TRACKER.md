# Bug Tracker · 桌面海缸 V2

| ID | 现象 | 根因 | 修复方案 | 验收截图 | 状态 | 发现版本 |
|----|------|------|----------|----------|------|----------|
| 001 | 导航栏半透明区域显示灰白棋盘格 | GL Compatibility 渲染器不支持 Windows DWM 透明窗口合成，viewport/transparent_background=true 与 GL Compatibility 后端组合导致棋盘格 | 将 project.godot 中 viewport/transparent_background 改为 false（默认值），其余透明设置不变 | navbar_fix_verification.png | ✅ 已修复 | V1 |
| 002 | 海葵移动行为 — 摆动范围仅 4px，视觉上几乎不可见 | ANEMONE_SWAY_RADIUS 常量设为 4.0，对 56px 字号生物来说摆动幅度过小 | 待定（将 ANEMONE_SWAY_RADIUS 增大到合理值如 12-20px，或根据字号比例计算） | movement_obs_3.png | 🔴 待确认 | V1 |
