# MySQL OCP 练习题库 Docker 构建脚本
# PowerShell 脚本用于构建和管理 Docker 镜像

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "build",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "mysql-practice-exam:latest",
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = "ghcr.io",
    
    [Parameter(Mandatory=$false)]
    [switch]$Push = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Dev = $false
)

# 配置变量
$IMAGE_NAME = "mysql-8.0-ocp-1z0-908"
$REGISTRY = "registry.cn-hangzhou.aliyuncs.com"
$NAMESPACE = "your-namespace"  # 请替换为您的阿里云命名空间
$FULL_IMAGE_NAME = "$REGISTRY/$NAMESPACE/$IMAGE_NAME"
$CONTAINER_NAME = "mysql-practice-exam"
$DEV_CONTAINER_NAME = "mysql-practice-exam-dev"
$PORT = 8080
$DEV_PORT = 3000

# 获取脚本所在目录的父目录（项目根目录）
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "=== MySQL OCP 练习题库 Docker 构建工具 ===" -ForegroundColor Green
Write-Host "项目目录: $ProjectRoot" -ForegroundColor Yellow

switch ($Action.ToLower()) {
    "build" {
        Write-Host "🔨 构建生产环境 Docker 镜像..." -ForegroundColor Green
        docker build -t $IMAGE_NAME -t $FULL_IMAGE_NAME .
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 镜像构建成功！" -ForegroundColor Green
            Write-Host "📦 本地镜像: $IMAGE_NAME" -ForegroundColor Cyan
            Write-Host "📦 远程镜像: $FULL_IMAGE_NAME" -ForegroundColor Cyan
        } else {
            Write-Host "❌ 镜像构建失败！" -ForegroundColor Red
            exit 1
        }
    }
    
    "run" {
        Write-Host "🚀 启动生产环境容器..." -ForegroundColor Green
        # 先停止并删除已存在的容器
        docker stop $CONTAINER_NAME 2>$null
        docker rm $CONTAINER_NAME 2>$null
        
        docker run -d --name $CONTAINER_NAME -p "${PORT}:80" $IMAGE_NAME
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 生产环境启动成功！" -ForegroundColor Green
            Write-Host "🌐 访问地址: http://localhost:$PORT" -ForegroundColor Cyan
            Write-Host "🔍 健康检查: http://localhost:$PORT/health" -ForegroundColor Yellow
        } else {
            Write-Host "❌ 容器启动失败！" -ForegroundColor Red
            exit 1
        }
    }
    
    "build-dev" {
        Write-Host "🔨 构建开发环境 Docker 镜像..." -ForegroundColor Green
        docker build -f Dockerfile.dev -t "$IMAGE_NAME-dev" .
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 开发镜像构建成功！" -ForegroundColor Green
            Write-Host "📦 开发镜像: $IMAGE_NAME-dev" -ForegroundColor Cyan
        } else {
            Write-Host "❌ 开发镜像构建失败！" -ForegroundColor Red
            exit 1
        }
    }
    
    "run-dev" {
        Write-Host "🚀 启动开发环境容器..." -ForegroundColor Green
        # 先停止并删除已存在的容器
        docker stop $DEV_CONTAINER_NAME 2>$null
        docker rm $DEV_CONTAINER_NAME 2>$null
        
        docker run -d --name $DEV_CONTAINER_NAME -p "${DEV_PORT}:3000" -v "${ProjectRoot}:/app" -v "/app/node_modules" "$IMAGE_NAME-dev"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 开发环境启动成功！" -ForegroundColor Green
            Write-Host "🌐 访问地址: http://localhost:$DEV_PORT" -ForegroundColor Cyan
            Write-Host "📁 代码热重载已启用" -ForegroundColor Yellow
        } else {
            Write-Host "❌ 开发容器启动失败！" -ForegroundColor Red
            exit 1
        }
    }
    
    "push" {
        Write-Host "📤 推送镜像到阿里云镜像仓库..." -ForegroundColor Green
        docker push $FULL_IMAGE_NAME
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 镜像推送成功！" -ForegroundColor Green
            Write-Host "📦 远程镜像: $FULL_IMAGE_NAME" -ForegroundColor Cyan
        } else {
            Write-Host "❌ 镜像推送失败！" -ForegroundColor Red
            Write-Host "💡 请确保已登录阿里云镜像仓库: docker login $REGISTRY" -ForegroundColor Yellow
            exit 1
        }
    }
    
    "stop" {
        Write-Host "🛑 停止并删除容器..." -ForegroundColor Green
        docker stop $CONTAINER_NAME 2>$null
        docker rm $CONTAINER_NAME 2>$null
        docker stop $DEV_CONTAINER_NAME 2>$null
        docker rm $DEV_CONTAINER_NAME 2>$null
        Write-Host "✅ 所有容器已停止" -ForegroundColor Green
    }
    
    "clean" {
        Write-Host "清理 Docker 资源..." -ForegroundColor Blue
        docker stop mysql-exam mysql-exam-dev 2>$null
        docker rm mysql-exam mysql-exam-dev 2>$null
        docker rmi $Tag "$Tag-dev" 2>$null
        docker system prune -f
        Write-Host "✅ 清理完成" -ForegroundColor Green
    }
    
    "compose" {
        Write-Host "使用 Docker Compose 启动..." -ForegroundColor Blue
        
        if ($Dev) {
            docker-compose --profile dev up -d
            Write-Host "🌐 开发服务器: http://localhost:3000" -ForegroundColor Yellow
        } else {
            docker-compose up -d
            Write-Host "🌐 应用访问地址: http://localhost:8080" -ForegroundColor Yellow
        }
    }
    
    "help" {
        Write-Host @"
使用方法:
  .\scripts\build.ps1 [Action] [参数]

操作 (Action):
  build    - 构建 Docker 镜像
  run      - 运行容器
  stop     - 停止并删除容器
  clean    - 清理所有相关 Docker 资源
  compose  - 使用 Docker Compose
  help     - 显示此帮助信息

参数:
  -Tag <string>      镜像标签 (默认: mysql-practice-exam:latest)
  -Registry <string> 镜像注册表 (默认: ghcr.io)
  -Push              构建后推送到注册表
  -Dev               使用开发环境配置

示例:
  .\scripts\build.ps1 build -Tag "my-app:v1.0" -Push
  .\scripts\build.ps1 run -Dev
  .\scripts\build.ps1 compose -Dev
"@ -ForegroundColor Cyan
    }
    
    default {
        Write-Host "❌ 未知操作: $Action" -ForegroundColor Red
        Write-Host ""
        Write-Host "🚀 MySQL OCP 练习题库 Docker 构建脚本" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "可用操作:" -ForegroundColor Yellow
        Write-Host "  build      - 构建生产环境 Docker 镜像"
        Write-Host "  build-dev  - 构建开发环境 Docker 镜像"
        Write-Host "  run        - 运行生产环境容器"
        Write-Host "  run-dev    - 运行开发环境容器"
        Write-Host "  push       - 推送镜像到阿里云镜像仓库"
        Write-Host "  stop       - 停止所有容器"
        Write-Host "  clean      - 清理 Docker 资源"
        Write-Host "  compose    - 使用 Docker Compose"
        Write-Host ""
        Write-Host "示例:" -ForegroundColor Yellow
        Write-Host "  .\build.ps1 build          # 构建生产镜像"
        Write-Host "  .\build.ps1 build-dev      # 构建开发镜像"
        Write-Host "  .\build.ps1 run            # 运行生产环境 (http://localhost:8080)"
        Write-Host "  .\build.ps1 run-dev        # 运行开发环境 (http://localhost:3000)"
        Write-Host "  .\build.ps1 push           # 推送到阿里云镜像仓库"
        Write-Host "  .\build.ps1 compose up     # 使用 Docker Compose"
        Write-Host ""
        Write-Host "💡 提示:" -ForegroundColor Yellow
        Write-Host "  - 推送前请先登录阿里云镜像仓库: docker login $REGISTRY"
        Write-Host "  - 修改脚本中的 NAMESPACE 变量为您的阿里云命名空间"
        exit 1
    }
}