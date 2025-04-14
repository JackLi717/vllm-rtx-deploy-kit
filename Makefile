# Makefile - 启动 DeepSeek 14B Chat 4bit AWQ 模型推理服务

# 自动加载 .env 文件
ifneq (,$(wildcard .env))
	include .env
	export
endif

#############################
# PHONY 定义（防止命令名与文件名冲突）
#############################

.PHONY: help start stop restart status logs clean-logs \
		init=conda-env check-conda-env check-deps \
		curl-test test run-infer build-vllm build-flashinfer \
		clean-all

#############################
# 🆘 帮助命令
#############################
help:  ## Show all available make targets
	@echo "🎯 可用命令："
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'


#############################
# 🔧 Conda 环境相关
#############################

init-conda-env: ## Initialize Conda environment $(ENV_NAME)
	@PYTHON_VERSION="3.10"; \
	if conda info --envs | grep -q "^$(ENV_NAME) "; then \
		echo "✅ 环境 '$(ENV_NAME)' 已存在。请使用：conda activate $(ENV_NAME)"; \
	else \
		echo "📦 正在创建 Conda 环境 '$(ENV_NAME)' (Python $$PYTHON_VERSION)..."; \
		conda create -n $(ENV_NAME) python=$$PYTHON_VERSION -y; \
		echo "✅ 创建完成，请使用：conda activate $(ENV_NAME)"; \
	fi

check-conda-env: ## Check if vllm-env is activated
	@CURRENT_ENV=$$(basename "$$CONDA_PREFIX" 2>/dev/null || echo ""); \
	if [ "$$CURRENT_ENV" != "$(ENV_NAME)" ]; then \
		echo "❌ 当前环境为 '$$CURRENT_ENV'，请先激活 Conda 环境 "$(ENV_NAME)" 后再执行此命令。"; \
		echo "👉 使用命令：conda activate "$(ENV_NAME)""; \
		exit 1; \
	fi

#############################
# 🚀 启动 & 停止服务
#############################

# ===== 启动服务 =====
start: check-conda-env ## Start vLLM inference service
	@mkdir -p $(LOG_DIR)
	@echo "🚀 启动 vLLM 推理服务 $(MODEL_PATH) at $$(date '+%Y-%m-%d %H:%M:%S')" | tee -a $(LOG_FILE)
	@python3 -m vllm.entrypoints.openai.api_server \
		--model $(MODEL_PATH) \
		--tokenizer $(MODEL_PATH) \
		--max-model-len $(MAX_LEN) \
		--gpu-memory-utilization $(MEM_UTIL) \
		--port $(PORT) \
		>> $(LOG_FILE) 2>&1 &
	@echo "✅ 服务已启动，监听端口: $(PORT)，日志输出: $(LOG_FILE)"


stop: check-conda-env ## Stop the vLLM service
	@echo "🛑 停止 vLLM 服务..."
	@PID=$$(ps aux | grep -E "openai.api_server|vllm serve" | grep -v grep | awk '{print $$2}'); \
	if [ -z "$$PID" ]; then \
		echo "⚠️ 未找到运行中的 vLLM 服务。"; \
	else \
		kill -9 $$PID; \
		echo "✅ vLLM 服务进程 PID $$PID 已被终止。"; \
	fi

restart: check-conda-env stop start  ## Restart the vLLM service

status: check-conda-env
	@PID=$$(ps aux | grep -E "openai.api_server|vllm serve" | grep -v grep | awk '{print $$2}'); \
	if [ -z "$$PID" ]; then \
		echo "🔴 vLLM 服务未在运行中。"; \
	else \
		echo "🟢 vLLM 正在运行中，PID: $$PID"; \
	fi

logs: ## Show latest log
	@echo "📄 最近 20 行日志：$(LOG_FILE)"
	@tail -n 20 $(LOG_FILE)

# 删除日志文件或目录
clean-logs: ## Clean log file
	@echo "🧹 正在清理日志文件..."
	@if [ -f "$(LOG_FILE)" ]; then rm -f "$(LOG_FILE)" && echo "✅ 日志文件已删除: $(LOG_FILE)"; else echo "ℹ️ 无日志文件可删"; fi

#############################
# 🧪 依赖检查
#############################

check-deps:  ## Check Python dependencies and CUDA availability
	@echo "🔍 正在检查环境依赖版本...\n"
	@echo "📦 vLLM 版本:"
	@python -c "import vllm; print('vLLM:', vllm.__version__)" || echo "❌ vLLM 未安装"
	@echo "\n📦 PyTorch 版本:"
	@python -c "import torch; print('torch:', torch.__version__)" || echo "❌ PyTorch 未安装"
	@echo "\n📦 Transformers 版本:"
	@python -c "import transformers; print('transformers:', transformers.__version__)" || echo "❌ Transformers 未安装"
	@echo "\n🎯 CUDA 是否可用:"
	@python -c "import torch; print('CUDA Available:', torch.cuda.is_available())" || echo "❌ CUDA 不可用"


#############################
# 🧪 服务测试 & 调试
#############################

curl-test: check-conda-env ## Use curl to test inference API
	@echo "📡 正在向 vLLM 发送测试请求..."
	curl -s http://localhost:$(PORT)/v1/completions \
		-H "Content-Type: application/json" \
		-d '{ "prompt": "介绍一下鲁迅。", "max_tokens": 100, "model": "$(MODEL_PATH)" }' | jq .

test: curl-test ## Alias for test

#############################
# 🧱 测试不启动 API Server 的本地推理
#############################
run-infer: check-conda-env ## Run local inference using vLLM CLI
	@python -m vllm.scripts.run_cli --model $(MODEL_PATH) --tokenizer $(MODEL_PATH)

#############################
# 🧱 构建 vLLM 
#############################

build-vllm: check-conda-env
	@echo "🛠️ 检查 vLLM 源码..."
	@if [ ! -d "./vllm" ]; then \
		echo "📦 未检测到 vllm 目录，正在 clone 仓库..."; \
		git clone https://github.com/vllm-project/vllm.git; \
	else \
		echo "✅ 已检测到 vllm 目录，跳过 clone"; \
	fi

	
	@echo "🚀 安装 PyTorch 2.8.0 Nightly + CUDA 12.8..."
	@pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128

	@echo "🔧 安装 requirements.txt 通用依赖..."
	@pip install -r requirements.txt
	@echo "🔧 安装 vLLM 构建依赖..."
	@pip install -r vllm/requirements/build.txt --no-deps
	@pip uninstall -y flash-attn || true
	@pip install flash-attn --no-build-isolation --no-binary=flash-attn
	@cd vllm && python use_existing_torch.py
	@cd vllm && python setup.py develop
	@echo "✅ vLLM 构建完成"


.PHONY: install-flashinfer

#############################
# 🧱 构建 FlashInfer
#############################

build-flashinfer: check-conda-env ## Build FlashInfer v0.2.2 (compatible with vLLM)
	@REPO="flashinfer"; \
	VERSION="v0.2.2"; \
	if [ ! -d "$$REPO" ]; then \
		echo "📥 正在 clone FlashInfer ($$VERSION)..."; \
		git clone --branch $$VERSION --depth=1 https://github.com/flashinfer-ai/flashinfer.git $$REPO; \
	else \
		echo "✅ FlashInfer 已存在，跳过 clone"; \
	fi
	@echo "🔧 正在构建 FlashInfer..."
	@cd flashinfer && \
	if [ -f setup.py ]; then \
		pip install packaging ninja && \
		python setup.py bdist_wheel && \
		pip install dist/*.whl; \
		echo "✅ FlashInfer v0.2.2 构建并安装完成"; \
	else \
		echo "❌ 构建失败：找不到 flashinfer/setup.py"; \
		exit 1; \
	fi

#############################
# 🧹 清理所有构建与临时文件
#############################

clean-all: ## Delete logs/, flashinfer/, and vllm/ directories
	@echo "🧹 正在清理以下目录：logs/, flashinfer/, vllm/"
	@rm -rf logs flashinfer vllm
	@echo "✅ 清理完成"
	@mkdir -p logs

