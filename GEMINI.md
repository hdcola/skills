# GEMINI.md - Agent Skills Repository 指南

本文件为 Gemini CLI 提供关于此仓库的背景信息、架构说明及开发规范。

## 项目概览

这是一个 **Agent Skills 仓库**，包含了一系列可重用的技能模块，用于扩展 AI Agent 的功能。这些技能遵循标准规范，可应用于任何支持 Agent Skills 的开发工具。每个技能都是一个独立的目录，包含元数据、文档及可选的辅助脚本。

### 核心技术栈
- **文档驱动**: 技能的核心逻辑和触发条件定义在 `SKILL.md` 中。
- **Shell 脚本**: 许多技能（如 `oracle-sqlcl`）依赖 Bash 脚本执行底层操作。
- **JSON 配置**: 技能通常通过本地 JSON 文件进行参数化配置（如数据库连接信息）。

## 目录结构

```text
skills/
├── <skill-name>/           # 技能主目录
│   ├── SKILL.md            # 必选：技能元数据（YAML frontmatter）与详细说明
│   ├── scripts/            # 可选：该技能依赖的可执行脚本
│   ├── assets/             # 可选：配置示例、静态资源
│   └── references/         # 可选：参考文档、查询模板
├── .serena/                # 项目管理元数据
├── README.md               # 面向用户的安装与使用指南
└── CLAUDE.md               # 针对 AI 助手的项目级开发指南
```

## 技能开发规范

### 1. 创建新技能
1. 在 `skills/` 下创建新目录。
2. **必须** 包含 `SKILL.md` 文件，且必须包含 YAML 元数据头：
   ```markdown
   ---
   name: skill-identifier
   description: 简明扼要的描述，用于 Agent 识别何时触发该技能。
   ---
   # 技能标题
   ... 详细内容 ...
   ```
3. 如果技能涉及复杂逻辑，建议将代码逻辑封装在 `scripts/` 目录下的脚本中，并在 `SKILL.md` 中引用。

### 2. 最佳实践
- **双语支持**: 鼓励在输出中使用中英双语。
- **安全性**: 敏感配置（如密码、API Keys）应通过本地配置文件处理，并确保这些文件已列入 `.gitignore`。
- **环境无关**: 脚本应尽可能兼容 macOS 和 Linux 环境。

## 关键命令与操作

### 安装技能
推荐使用 `skills` CLI 进行安装：
```bash
npx skills add <skill-name>
```

用户也可以手动将技能目录复制到本地 Agent 配置目录（例如 Claude Code 的 `~/.claude/skills/`）：
```bash
cp -r skills/<skill-name>/ ~/.claude/skills/<skill-name>/
```

### 验证与调试
- 检查 `SKILL.md` 的 YAML 语法是否正确。
- 手动运行 `scripts/` 下的脚本以确保其在当前环境下可用。

## 现有技能示例
- **pr-comments**: 用于管理 GitHub PR 评审评论（获取和解决评论）。
- **oracle-sqlcl**: 用于连接并查询 Oracle 数据库。
