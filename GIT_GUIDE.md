# 🚀 Git & GitHub 使用指南

## 📦 仓库信息

- **GitHub 地址**: https://github.com/qsswgl/JWT-Microservices
- **用户名**: qsswgl
- **分支**: main
- **协议**: HTTPS (使用 Access Token)

---

## 🔄 常用 Git 命令

### 查看状态
```powershell
# 查看当前状态
git status

# 查看提交历史
git log --oneline

# 查看远程仓库
git remote -v
```

### 提交更改
```powershell
# 查看修改的文件
git status

# 添加所有修改
git add .

# 或添加特定文件
git add src/AuthService/Program.cs

# 提交更改
git commit -m "描述本次修改"

# 推送到 GitHub
git push origin main
```

### 拉取更新
```powershell
# 从 GitHub 拉取最新代码
git pull origin main

# 查看远程更改但不合并
git fetch origin
```

### 分支管理
```powershell
# 查看所有分支
git branch -a

# 创建新分支
git branch feature/new-feature

# 切换分支
git checkout feature/new-feature

# 创建并切换分支（快捷方式）
git checkout -b feature/new-feature

# 合并分支
git checkout main
git merge feature/new-feature

# 推送分支到 GitHub
git push origin feature/new-feature
```

---

## 🔐 认证配置

### 当前配置
项目使用 **HTTPS + Access Token** 方式进行身份验证。

### 重新配置远程仓库（如果需要）
```powershell
# 查看当前远程配置
git remote -v

# 删除现有远程
git remote remove origin

# 重新添加（使用 token）
$token = "YOUR_GITHUB_ACCESS_TOKEN"
git remote add origin "https://${token}@github.com/qsswgl/JWT-Microservices.git"

# 或使用 SSH（需要配置 SSH 密钥）
git remote add origin "git@github.com:qsswgl/JWT-Microservices.git"
```

### Access Token 管理
⚠️ **重要提示**: Access Token 已在 `.git/config` 中配置，请勿将此文件上传到公共位置。

如需更新 token:
```powershell
# 编辑 Git 配置
git config --local credential.helper store
git config --local user.name "qsswgl"
git config --local user.email "your-email@example.com"
```

---

## 📝 提交规范

建议使用以下提交消息格式：

```
类型(范围): 简短描述

详细描述（可选）

破坏性变更说明（可选）
```

### 提交类型
- `feat`: 新功能
- `fix`: 错误修复
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 添加或修改测试
- `build`: 构建系统或依赖更新
- `ci`: CI/CD 配置更新
- `chore`: 其他杂项

### 示例
```powershell
git commit -m "feat(auth): 添加双因素认证支持"
git commit -m "fix(gateway): 修复 token 验证中的空指针异常"
git commit -m "docs(readme): 更新部署文档"
git commit -m "refactor(order): 重构订单服务数据访问层"
```

---

## 🌿 分支策略

### 推荐分支模型

```
main (生产环境)
  ↑
develop (开发环境)
  ↑
feature/* (功能分支)
  ↑
bugfix/* (错误修复分支)
  ↑
hotfix/* (紧急修复分支)
```

### 工作流程

1. **功能开发**
   ```powershell
   git checkout -b feature/user-management
   # 开发功能...
   git add .
   git commit -m "feat(user): 实现用户管理功能"
   git push origin feature/user-management
   ```

2. **创建 Pull Request**
   - 访问 GitHub 仓库
   - 点击 "Pull requests" → "New pull request"
   - 选择 `feature/user-management` → `main`
   - 填写描述并创建

3. **代码审查与合并**
   - 审查代码
   - 合并到 main 分支
   - 删除功能分支

---

## 🏷️ 标签管理

### 创建版本标签
```powershell
# 创建轻量标签
git tag v1.0.0

# 创建带注释的标签（推荐）
git tag -a v1.0.0 -m "版本 1.0.0 发布 - 初始功能完成"

# 推送标签到 GitHub
git push origin v1.0.0

# 推送所有标签
git push origin --tags

# 查看所有标签
git tag -l

# 删除标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

---

## 🔄 同步 Fork（如果适用）

如果你 fork 了别人的项目：

```powershell
# 添加上游仓库
git remote add upstream https://github.com/original-owner/original-repo.git

# 获取上游更新
git fetch upstream

# 合并到本地
git checkout main
git merge upstream/main

# 推送到自己的仓库
git push origin main
```

---

## 🧹 清理与维护

### 清理未跟踪的文件
```powershell
# 查看将被删除的文件（不会真正删除）
git clean -n

# 删除未跟踪的文件
git clean -f

# 删除未跟踪的文件和目录
git clean -fd
```

### 撤销更改
```powershell
# 撤销工作区的修改（未 add）
git checkout -- src/AuthService/Program.cs

# 撤销已 add 但未 commit 的文件
git reset HEAD src/AuthService/Program.cs

# 撤销最近一次 commit（保留更改）
git reset --soft HEAD~1

# 撤销最近一次 commit（丢弃更改）⚠️ 危险
git reset --hard HEAD~1
```

### 修改最后一次提交
```powershell
# 修改提交消息
git commit --amend -m "新的提交消息"

# 添加遗漏的文件到最后一次提交
git add forgotten-file.cs
git commit --amend --no-edit
```

---

## 📊 查看历史

### 查看提交历史
```powershell
# 简洁版本
git log --oneline

# 带图形的分支历史
git log --graph --oneline --all

# 查看某个文件的历史
git log --follow src/AuthService/Program.cs

# 查看特定作者的提交
git log --author="qsswgl"

# 查看最近 5 次提交
git log -5
```

### 查看文件差异
```powershell
# 查看工作区和暂存区的差异
git diff

# 查看暂存区和最后一次提交的差异
git diff --staged

# 查看两个分支的差异
git diff main..develop

# 查看特定文件的差异
git diff src/AuthService/Program.cs
```

---

## 🔍 搜索代码

### 在历史中搜索
```powershell
# 在所有提交中搜索字符串
git log -S "JwtTokenGenerator"

# 在提交消息中搜索
git log --grep="auth"

# 在代码中搜索
git grep "JwtTokenGenerator"
```

---

## 🚨 故障排查

### 推送被拒绝
```powershell
# 原因：远程有新提交
# 解决：先拉取再推送
git pull origin main --rebase
git push origin main
```

### 合并冲突
```powershell
# 1. 发现冲突
git merge feature/new-feature
# 输出: CONFLICT (content): Merge conflict in src/file.cs

# 2. 查看冲突文件
git status

# 3. 编辑冲突文件，解决冲突标记：
# <<<<<<< HEAD
# 当前分支的内容
# =======
# 另一个分支的内容
# >>>>>>> feature/new-feature

# 4. 标记为已解决
git add src/file.cs

# 5. 完成合并
git commit -m "merge: 解决与 feature/new-feature 的冲突"
```

### Token 失效
```powershell
# 更新 token
git remote set-url origin "https://YOUR_NEW_TOKEN@github.com/qsswgl/JWT-Microservices.git"
```

---

## 📚 有用的别名

将这些别名添加到 `.git/config` 或 `~/.gitconfig`:

```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --all
    amend = commit --amend --no-edit
```

使用：
```powershell
git st          # git status
git co main     # git checkout main
git visual      # git log --graph --oneline --all
```

---

## 🔗 相关链接

- **GitHub 仓库**: https://github.com/qsswgl/JWT-Microservices
- **GitHub 文档**: https://docs.github.com/
- **Git 官方文档**: https://git-scm.com/doc
- **Pro Git 书籍**: https://git-scm.com/book/zh/v2

---

## 🆘 获取帮助

```powershell
# 查看命令帮助
git help <command>
git <command> --help

# 示例
git help commit
git push --help
```

---

**最后更新**: 2025年11月4日  
**维护者**: qsswgl
