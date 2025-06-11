# Docker 部署指南

本文档介绍如何使用 Docker 构建和部署 MySQL OCP 练习题库应用。

## 📁 目录结构

```
├── Dockerfile              # 生产环境 Docker 镜像构建文件
├── Dockerfile.dev          # 开发环境 Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置文件
├── .dockerignore           # Docker 构建忽略文件
├── docker/
│   └── nginx.conf          # Nginx 配置文件
├── scripts/
│   ├── build.ps1           # Windows PowerShell 构建脚本
│   └── build.sh            # Linux/macOS Bash 构建脚本
└── .github/workflows/
    ├── docker-build-push.yml  # Docker 镜像构建和推送工作流
    └── ci.yml                 # 持续集成工作流
```

## 🚀 快速开始

### 方式一：使用构建脚本（推荐）

#### Windows (PowerShell)
```powershell
# 构建并运行生产环境
.\scripts\build.ps1 build
.\scripts\build.ps1 run

# 构建并运行开发环境
.\scripts\build.ps1 build -Dev
.\scripts\build.ps1 run -Dev

# 使用 Docker Compose
.\scripts\build.ps1 compose
```

#### Linux/macOS (Bash)
```bash
# 构建并运行生产环境
./scripts/build.sh build
./scripts/build.sh run

# 构建并运行开发环境
./scripts/build.sh build -d
./scripts/build.sh run -d

# 使用 Docker Compose
./scripts/build.sh compose
```

### 方式二：直接使用 Docker 命令

#### 生产环境
```bash
# 构建镜像
docker build -t mysql-practice-exam:latest .

# 运行容器
docker run -d -p 8080:80 --name mysql-exam mysql-practice-exam:latest

# 访问应用
# http://localhost:8080
```

#### 开发环境
```bash
# 构建开发镜像
docker build -f Dockerfile.dev -t mysql-practice-exam:dev .

# 运行开发容器（支持热重载）
docker run -d -p 3000:3000 \
  -v $(pwd):/app \
  -v /app/node_modules \
  --name mysql-exam-dev \
  mysql-practice-exam:dev

# 访问开发服务器
# http://localhost:3000
```

### 方式三：使用 Docker Compose

```bash
# 启动生产环境
docker-compose up -d

# 启动开发环境
docker-compose --profile dev up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 🔧 配置说明

### Dockerfile（生产环境）
- 基于 Node.js 18 Alpine 构建
- 多阶段构建，最终镜像基于 Nginx Alpine
- 自动复制构建产物到 Nginx 目录
- 包含优化的 Nginx 配置

### Dockerfile.dev（开发环境）
- 基于 Node.js 18 Alpine
- 支持热重载开发
- 包含开发依赖
- 使用 dumb-init 进行信号处理

### nginx.conf
- 启用 gzip 压缩
- 支持单页应用路由
- 静态资源缓存优化
- 安全头配置
- 健康检查端点 `/health`

## 📊 镜像信息

### 生产镜像特点
- **大小**: ~25MB（基于 Nginx Alpine）
- **端口**: 80
- **健康检查**: `/health` 端点
- **多架构**: 支持 AMD64 和 ARM64

### 开发镜像特点
- **大小**: ~200MB（包含开发依赖）
- **端口**: 3000
- **热重载**: 支持代码实时更新
- **调试**: 包含开发工具

## 📦 镜像信息

- **基础镜像**: `node:18-alpine` (构建阶段), `nginx:alpine` (运行阶段)
- **镜像仓库**: `registry.cn-hangzhou.aliyuncs.com/your-namespace/mysql-8.0-ocp-1z0-908`
- **支持架构**: `linux/amd64`, `linux/arm64`
- **镜像大小**: 约 50MB (压缩后)

### 镜像标签说明

- `latest`: 最新稳定版本
- `v1.0.0`: 具体版本号 (通过 Git 标签触发构建)

## 🔄 CI/CD 集成

### GitHub Actions 自动化

项目包含完整的 CI/CD 流水线：

1. **持续集成** (`ci.yml`)
   - 代码质量检查
   - 类型检查
   - 构建测试
   - 多 Node.js 版本测试

2. **Docker 构建推送** (`docker-build-push.yml`)
   - 自动构建 Docker 镜像
   - 推送到阿里云容器镜像服务
   - 支持多架构构建
   - 缓存优化

### 阿里云镜像仓库配置

需要在 GitHub 仓库的 Settings > Secrets and variables > Actions 中配置以下密钥：

- `ALIYUN_USERNAME`: 阿里云容器镜像服务用户名
- `ALIYUN_PASSWORD`: 阿里云容器镜像服务密码
- `ALIYUN_NAMESPACE`: 阿里云容器镜像服务命名空间

### 触发条件

- **创建 Git 标签** (如 `v1.0.0`): 触发 Docker 镜像构建和推送
- **推送到主分支**: 触发持续集成检查
- **创建 Pull Request**: 触发 CI 检查

### 镜像标签策略
- `latest`: 最新版本标签构建
- `v*`: 版本标签（如 v1.0.0）

## 🛠️ 开发工作流

### 本地开发
```bash
# 1. 启动开发环境
./scripts/build.sh build -d
./scripts/build.sh run -d

# 2. 修改代码（自动热重载）

# 3. 测试生产构建
./scripts/build.sh build
./scripts/build.sh run

# 4. 清理资源
./scripts/build.sh clean
```

### 生产部署
```bash
# 1. 拉取最新镜像
docker pull ghcr.io/your-username/mysql-8.0-ocp-1z0-908:latest

# 2. 停止旧容器
docker stop mysql-exam
docker rm mysql-exam

# 3. 启动新容器
docker run -d -p 8080:80 \
  --name mysql-exam \
  --restart unless-stopped \
  ghcr.io/your-username/mysql-8.0-ocp-1z0-908:latest

# 4. 健康检查
curl http://localhost:8080/health
```

## 🔍 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 查看端口占用
   netstat -tulpn | grep :8080
   
   # 使用不同端口
   docker run -d -p 9090:80 mysql-practice-exam:latest
   ```

2. **构建失败**
   ```bash
   # 清理 Docker 缓存
   docker system prune -a
   
   # 重新构建
   docker build --no-cache -t mysql-practice-exam:latest .
   ```

3. **容器无法启动**
   ```bash
   # 查看容器日志
   docker logs mysql-exam
   
   # 进入容器调试
   docker exec -it mysql-exam sh
   ```

### 性能优化

1. **启用 BuildKit**
   ```bash
   export DOCKER_BUILDKIT=1
   docker build -t mysql-practice-exam:latest .
   ```

2. **使用多阶段构建缓存**
   ```bash
   docker build --target builder -t mysql-practice-exam:builder .
   docker build --cache-from mysql-practice-exam:builder -t mysql-practice-exam:latest .
   ```

## 📈 监控和日志

### 健康检查
```bash
# 检查应用健康状态
curl http://localhost:8080/health

# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' mysql-exam
```

### 日志管理
```bash
# 查看实时日志
docker logs -f mysql-exam

# 查看最近 100 行日志
docker logs --tail 100 mysql-exam

# 配置日志轮转
docker run -d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  mysql-practice-exam:latest
```

## 🔐 安全最佳实践

1. **使用非 root 用户**（已在 Dockerfile 中配置）
2. **最小化镜像大小**（使用 Alpine 基础镜像）
3. **定期更新依赖**（通过 CI/CD 自动检查）
4. **扫描安全漏洞**（集成在 GitHub Actions 中）
5. **使用多阶段构建**（避免在最终镜像中包含构建工具）

## 📚 相关资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Nginx 配置指南](https://nginx.org/en/docs/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)