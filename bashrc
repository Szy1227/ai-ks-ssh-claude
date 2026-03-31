# ai-ks-ssh-claude .bashrc
# 通用的 bash 配置，挂载到 SSH 容器中

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# PS1 提示符
export PS1='\[\033[01;32m\]\u@ai-ks\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# 工作目录快捷函数（函数在非交互式 shell 也可用）
cdfastapi() { cd /work/fastapi; }
cdvue() { cd /work/vue; }
cdwork() { cd /work; }

# 常用别名
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline -10'

# Python 环境
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Node.js 环境
alias ni='npm install'
alias nr='npm run'
alias nd='npm run dev'
alias nb='npm run build'

# 查看当前节点信息
node-info() {
    echo -e "${CYAN}=== AI-KS 节点信息 ===${NC}"
    echo -e "主机名: ${GREEN}$(hostname)${NC}"
    echo -e "用户: ${GREEN}$(whoami)${NC}"
    echo -e "工作目录:"
    echo -e "  - FastAPI: ${YELLOW}/work/fastapi${NC}"
    echo -e "  - Vue: ${YELLOW}/work/vue${NC}"
    echo ""
    echo -e "项目版本:"
    if [[ -f /work/fastapi/main.py ]]; then
        local version=$(grep -oP 'VERSION\s*=\s*"\K[^"]+' /work/fastapi/main.py 2>/dev/null || echo "未知")
        echo -e "  - 后端版本: ${GREEN}${version}${NC}"
    fi
    if [[ -f /work/vue/package.json ]]; then
        local version=$(grep -oP '"version":\s*"\K[^"]+' /work/vue/package.json 2>/dev/null || echo "未知")
        echo -e "  - 前端版本: ${GREEN}${version}${NC}"
    fi
}

# 显示帮助
ai-ks-help() {
    echo -e "${CYAN}=== AI-KS 快捷命令 ===${NC}"
    echo ""
    echo -e "${GREEN}目录导航:${NC}"
    echo "  cdwork      - 进入 /work 目录"
    echo "  cdfastapi   - 进入 FastAPI 项目"
    echo "  cdvue       - 进入 Vue 项目"
    echo ""
    echo -e "${GREEN}信息查看:${NC}"
    echo "  node-info   - 显示当前节点信息"
    echo "  ai-ks-help  - 显示此帮助"
    echo ""
    echo -e "${GREEN}Git 快捷键:${NC}"
    echo "  gs, ga, gc, gp, gl, gd, gb, gco, glog"
    echo ""
    echo -e "${GREEN}Python:${NC}"
    echo "  py, pip, venv, activate"
    echo ""
    echo -e "${GREEN}Node.js:${NC}"
    echo "  ni, nr, nd, nb"
}

# 欢迎信息
echo -e ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        AI-KS 开发环境 SSH 节点           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo -e ""
echo -e "输入 ${CYAN}ai-ks-help${NC} 查看快捷命令"
echo -e "输入 ${CYAN}node-info${NC} 查看节点信息"
echo -e ""
