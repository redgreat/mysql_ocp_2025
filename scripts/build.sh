#!/bin/bash

# MySQL OCP 练习题库 Docker 构建脚本
# 支持构建、运行、停止、清理等操作

set -e

# 配置变量
IMAGE_NAME="mysql-8.0-ocp-1z0-908"
REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="your-namespace"  # 请替换为您的阿里云命名空间
FULL_IMAGE_NAME="$REGISTRY/$NAMESPACE/$IMAGE_NAME"
CONTAINER_NAME="mysql-practice-exam"
DEV_CONTAINER_NAME="mysql-practice-exam-dev"
PORT=8080
DEV_PORT=3000

# 默认参数
ACTION="build"
TAG="mysql-practice-exam:latest"
PUSH=false
DEV=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 帮助函数
show_help() {
    echo -e "${CYAN}使用方法:${NC}"
    echo -e "  ./scripts/build.sh [ACTION] [OPTIONS]"
    echo ""
    echo -e "${CYAN}操作 (ACTION):${NC}"
    echo "  build    - 构建 Docker 镜像"
    echo "  run      - 运行容器"
    echo "  stop     - 停止并删除容器"
    echo "  clean    - 清理所有相关 Docker 资源"
    echo "  compose  - 使用 Docker Compose"
    echo "  help     - 显示此帮助信息"
    echo ""
    echo -e "${CYAN}选项 (OPTIONS):${NC}"
    echo "  -t, --tag TAG        镜像标签 (默认: mysql-practice-exam:latest)"
    echo "  -r, --registry REG   镜像注册表 (默认: ghcr.io)"
    echo "  -p, --push           构建后推送到注册表"
    echo "  -d, --dev            使用开发环境配置"
    echo "  -h, --help           显示此帮助信息"
    echo ""
    echo -e "${CYAN}示例:${NC}"
    echo "  ./scripts/build.sh build -t my-app:v1.0 -p"
    echo "  ./scripts/build.sh run -d"
    echo "  ./scripts/build.sh compose -d"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        build|run|stop|clean|compose|help)
            ACTION="$1"
            shift
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -d|--dev)
            DEV=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${GREEN}=== MySQL OCP 练习题库 Docker 构建工具 ===${NC}"
echo -e "${YELLOW}项目目录: $PROJECT_ROOT${NC}"

case $ACTION in
    "build")
        echo "🔨 构建生产环境 Docker 镜像..."
        docker build -t "$IMAGE_NAME" -t "$FULL_IMAGE_NAME" .
        
        if [ $? -eq 0 ]; then
            echo "✅ 镜像构建成功！"
            echo "📦 本地镜像: $IMAGE_NAME"
            echo "📦 远程镜像: $FULL_IMAGE_NAME"
        else
            echo "❌ 镜像构建失败！"
            exit 1
        fi
        ;;
        
    "build-dev")
        echo "🔨 构建开发环境 Docker 镜像..."
        docker build -f Dockerfile.dev -t "$IMAGE_NAME-dev" .
        
        if [ $? -eq 0 ]; then
            echo "✅ 开发镜像构建成功！"
            echo "📦 开发镜像: $IMAGE_NAME-dev"
        else
            echo "❌ 开发镜像构建失败！"
            exit 1
        fi
        ;;
        
    "run")
        echo "🚀 启动生产环境容器..."
        # 先停止并删除已存在的容器
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        
        docker run -d --name "$CONTAINER_NAME" -p "$PORT:80" "$IMAGE_NAME"
        
        if [ $? -eq 0 ]; then
            echo "✅ 生产环境启动成功！"
            echo "🌐 访问地址: http://localhost:$PORT"
            echo "🔍 健康检查: http://localhost:$PORT/health"
        else
            echo "❌ 容器启动失败！"
            exit 1
        fi
        ;;
        
    "run-dev")
        echo "🚀 启动开发环境容器..."
        # 先停止并删除已存在的容器
        docker stop "$DEV_CONTAINER_NAME" 2>/dev/null || true
        docker rm "$DEV_CONTAINER_NAME" 2>/dev/null || true
        
        docker run -d --name "$DEV_CONTAINER_NAME" -p "$DEV_PORT:3000" -v "$(pwd):/app" -v "/app/node_modules" "$IMAGE_NAME-dev"
        
        if [ $? -eq 0 ]; then
            echo "✅ 开发环境启动成功！"
            echo "🌐 访问地址: http://localhost:$DEV_PORT"
            echo "📁 代码热重载已启用"
        else
            echo "❌ 开发容器启动失败！"
            exit 1
        fi
        ;;
        
    "push")
        echo "📤 推送镜像到阿里云镜像仓库..."
        docker push "$FULL_IMAGE_NAME"
        
        if [ $? -eq 0 ]; then
            echo "✅ 镜像推送成功！"
            echo "📦 远程镜像: $FULL_IMAGE_NAME"
        else
            echo "❌ 镜像推送失败！"
            echo "💡 请确保已登录阿里云镜像仓库: docker login $REGISTRY"
            exit 1
        fi
        ;;
        
    "stop")
        echo "🛑 停止并删除容器..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        docker stop "$DEV_CONTAINER_NAME" 2>/dev/null || true
        docker rm "$DEV_CONTAINER_NAME" 2>/dev/null || true
        echo "✅ 所有容器已停止"
        ;;
        
    "clean")
        echo -e "${BLUE}清理 Docker 资源...${NC}"
        docker stop mysql-exam mysql-exam-dev 2>/dev/null || true
        docker rm mysql-exam mysql-exam-dev 2>/dev/null || true
        docker rmi "$TAG" "$TAG-dev" 2>/dev/null || true
        docker system prune -f
        echo -e "${GREEN}✅ 清理完成${NC}"
        ;;
        
    "compose")
        echo -e "${BLUE}使用 Docker Compose 启动...${NC}"
        
        if [ "$DEV" = true ]; then
            docker-compose --profile dev up -d
            echo -e "${YELLOW}🌐 开发服务器: http://localhost:3000${NC}"
        else
            docker-compose up -d
            echo -e "${YELLOW}🌐 应用访问地址: http://localhost:8080${NC}"
        fi
        ;;
        
    "help")
        show_help
        ;;
        
    *)
        echo "❌ 未知操作: $ACTION"
        echo ""
        echo "🚀 MySQL OCP 练习题库 Docker 构建脚本"
        echo ""
        echo "可用操作:"
        echo "  build      - 构建生产环境 Docker 镜像"
        echo "  build-dev  - 构建开发环境 Docker 镜像"
        echo "  run        - 运行生产环境容器"
        echo "  run-dev    - 运行开发环境容器"
        echo "  push       - 推送镜像到阿里云镜像仓库"
        echo "  stop       - 停止所有容器"
        echo "  clean      - 清理 Docker 资源"
        echo "  compose    - 使用 Docker Compose"
        echo ""
        echo "示例:"
        echo "  ./build.sh build          # 构建生产镜像"
        echo "  ./build.sh build-dev      # 构建开发镜像"
        echo "  ./build.sh run            # 运行生产环境 (http://localhost:8080)"
        echo "  ./build.sh run-dev        # 运行开发环境 (http://localhost:3000)"
        echo "  ./build.sh push           # 推送到阿里云镜像仓库"
        echo "  ./build.sh compose up     # 使用 Docker Compose"
        echo ""
        echo "💡 提示:"
        echo "  - 推送前请先登录阿里云镜像仓库: docker login $REGISTRY"
        echo "  - 修改脚本中的 NAMESPACE 变量为您的阿里云命名空间"
        exit 1
        ;;
esac