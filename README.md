# 🧠 vLLM Inference Deployment Kit for DeepSeek 14B + RTX 5090/4090 GPUs

This project provides a local inference deployment solution for running [vLLM](https://github.com/vllm-project/vllm) with the DeepSeek 14B Chat AWQ model (4-bit) on NVIDIA RTX 5090 GPUs using PyTorch Nightly + CUDA 12.8.

---

## 🚀 Features

- ✅ Run DeepSeek 14B Chat (4-bit AWQ) with vLLM
- ✅ Supports local OpenAI-compatible API and CLI inference
- ✅ Optimized for RTX 5000 series GPUs
- ✅ One-line Makefile-based build and deployment
- ✅ PyTorch 2.8.0 Nightly + FlashInfer 0.2.2 integration
- ✅ Environment isolation with Conda + `.env` configuration

---

## 🧱 Prerequisites

- 🧠 Model: [DeepSeek LLM 14B Chat AWQ]
- 💻 GPU: NVIDIA RTX 5090
- 🐍 Python 3.10 (via Miniconda)
- 🐧 Linux or WSL2 recommended

---

## ⚙️ Getting Started

### 1. Clone and configure

```bash
git clone https://github.com/yourname/vllm-rtx-deploy-kit.git
cd vllm-rtx-deploy-kit
cp .env.example .env
```

Edit `.env` to configure:

- `MODEL_PATH`: Path to your DeepSeek model (e.g. `/mnt/c/llm/models/deepseek-14b-awq`)
- `PORT`: API service port

---

### 2. Create and activate Conda environment

```bash
make init-conda-env
conda activate vllm-env  # or ENV_NAME from your .env
```

---

### 3. Build vLLM + FlashInfer

```bash
make build-vllm
make build-flashinfer
```

---

### 4. Start the inference server

```bash
make start
```

This will launch an OpenAI-compatible server at `http://localhost:8000`.

---

### 5. Run CLI or curl test

```bash
make run-infer     # Local CLI test
make curl-test     # HTTP request to /v1/completions
```

---

## 🧹 Cleanup

```bash
make clean-all  # Removes logs/, vllm/, flashinfer/
```

---

## 📁 Recommended Structure

```
.
├── .env
├── .env.example
├── Makefile
├── requirements.txt
├── logs/
├── flashinfer/     ← Cloned and built automatically
├── vllm/           ← Cloned and built automatically
```

---

## 🔍 Keywords (GitHub Topics)

`vllm`, `nvidia`, `rtx5090`, `deepseek`, `gpu-inference`, `flashinfer`, `cuda12`, `pytorch-nightly`

---

## 📄 References

- https://github.com/vllm-project/vllm
- https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
- https://github.com/flashinfer-ai/flashinfer