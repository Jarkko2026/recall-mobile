#!/bin/bash
# 一键推送到 GitHub 触发 APK 云端构建
# 用法：先在 GitHub 创建空仓库（私有/公开都行），然后：
#   bash push-to-github.sh git@github.com:你的账号/recall-mobile.git
# 或：
#   bash push-to-github.sh https://github.com/你的账号/recall-mobile.git

set -e

if [ -z "$1" ]; then
  echo "用法：bash push-to-github.sh <仓库 URL>"
  echo "示例：bash push-to-github.sh https://github.com/jarkko/recall-mobile.git"
  exit 1
fi

REPO_URL="$1"
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"

if [ ! -d .git ]; then
  echo "==> 初始化 git 仓库"
  git init -b main
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$REPO_URL"
else
  git remote set-url origin "$REPO_URL"
fi

git add .
if git diff --cached --quiet; then
  echo "无变更，跳过 commit"
else
  git commit -m "init: recall mobile v1.0.0 (with HTTP-backed CloudBase)"
fi

echo "==> 推送到 $REPO_URL"
git push -u origin main

echo ""
echo "✅ 已推送。打开仓库 → Actions 标签 → 等约 4-6 分钟。"
echo "   完成后在 Actions 任务详情底部 Artifacts 下载 recall-android-apk.zip"
echo ""
