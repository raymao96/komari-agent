#!/bin/bash
set -e

UPSTREAM_BRANCH="${1:-upstream2/main}"

echo "正在從 $UPSTREAM_BRANCH 進行完整合併（採用上游優先策略）..."
git merge "$UPSTREAM_BRANCH" -X theirs --no-commit || true

echo "正在全面且安全地替換所有腳本、配置與測試檔中的上游倉庫路徑..."

# 1. 替換 update/update.go 內的 Repo 變數
if [ -f "update/update.go" ]; then
    sed -i '' '/Repo/s|[Nn]uomiiiii/[Ll]ite-agent|raymao96/komari-agent|g' update/update.go
fi

# 2. 替換 update/update_test.go 或其他測試檔案內的預期倉庫名稱
find . -name "*_test.go" -type f -exec sed -i '' 's|[Nn]uomiiiii/[Ll]ite-agent|raymao96/komari-agent|g' {} +

# 3. 替換 .github/workflows 內的組織與倉庫名稱
if [ -d ".github/workflows" ]; then
    find .github/workflows -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' 's|github.com/[Nn]uomiiiii/[Ll]ite-agent|github.com/raymao96/komari-agent|g' {} +
    find .github/workflows -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' 's|[Nn]uomiiiii/[Ll]ite-agent|raymao96/komari-agent|g' {} +
fi

# 4. 掃描根目錄下所有的 .sh 與 .ps1 腳本，精準替換帶有組織名稱的倉庫參考
for script in install.sh install.ps1 build_all.sh build_all.ps1 *.sh *.ps1; do
    if [ -f "$script" ]; then
        sed -i '' 's|github.com/[Nn]uomiiiii/[Ll]ite-agent|github.com/raymao96/komari-agent|g' "$script"
        sed -i '' 's|[Nn]uomiiiii/[Ll]ite-agent|raymao96/komari-agent|g' "$script"
    fi
done

# 5. 確保本地的 README 維持原樣，不被上游覆蓋
if [ -f "readme.md" ]; then
    git checkout --ours readme.md 2>/dev/null || true
    git add readme.md 2>/dev/null || true
fi
if [ -f ".github/workflows/README.md" ]; then
    git checkout --ours .github/workflows/README.md 2>/dev/null || true
    git add .github/workflows/README.md 2>/dev/null || true
fi

# 將所有變更加入暫存區
git add -A

echo "合併與替換完成！測試檔、安裝腳本與設定已同步更新完畢，請執行 git diff 檢查。"
