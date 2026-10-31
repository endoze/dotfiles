{ pkgs, lib, ... }:

# Tooling for fine-tuning and serving open-weights models on the local GPU.
# Everything heavy runs in pinned containers (GPU access comes from the CDI
# spec nvidia.nix's nvidia-container-toolkit generates), so no Python or CUDA
# userspace lands on the host. Containers run as the invoking user so model
# downloads and training outputs stay user-owned, and they share one Hugging
# Face cache so each model is only downloaded once.
let
  images = {
    vllm = "docker.io/vllm/vllm-openai:v0.32.0";
    axolotl = "docker.io/axolotlai/axolotl:0.21.0";
    # 89- is the Ada (sm_89) build, matching the 4090
    tei = "ghcr.io/huggingface/text-embeddings-inference:89-1.9.4";
  };

  # Shared `docker run` prefix. The current directory is mounted at /work, so
  # configs, datasets, and outputs are addressed as /work/... inside the
  # container. HOME is a persistent dir so Triton/torch compile caches
  # survive between runs instead of recompiling on every start.
  mkGpuWrapper = name: text: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ pkgs.docker pkgs.coreutils ];
    text = ''
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}"
      hf="$cache/huggingface"
      home="$cache/llm-lab/home"
      mkdir -p "$hf" "$home"

      # Ollama keeps models resident in VRAM until OLLAMA_KEEP_ALIVE expires,
      # which starves vLLM's up-front allocation and training runs alike.
      if systemctl --user is-active --quiet ollama; then
        echo "warning: ollama is running and may be holding VRAM (systemctl --user stop ollama)" >&2
      fi

      tty=()
      if [ -t 0 ] && [ -t 1 ]; then tty=(-t); fi

      gpu_run=(
        docker run --rm -i "''${tty[@]}"
        --device nvidia.com/gpu=all
        --ipc=host
        --user "$(id -u):$(id -g)"
        -e HOME=/home/llm -v "$home:/home/llm"
        -e HF_HOME=/hf -e HF_TOKEN -v "$hf:/hf"
        -v "$PWD:/work" -w /work
      )

      ${text}
    '';
  };

  # OpenAI-compatible server on localhost:8000. The image's entrypoint is
  # `vllm serve`, so arguments pass straight through:
  #   vllm-serve Qwen/Qwen3-8B --enable-lora --lora-modules doc=/work/out/stage2
  vllm-serve = mkGpuWrapper "vllm-serve" ''
    exec "''${gpu_run[@]}" --name vllm -p 127.0.0.1:8000:8000 ${images.vllm} "$@"
  '';

  # The upstream image's venv interpreter lives under /root (mode 0700), so it
  # can't start as a non-root user. A one-layer local image opens /root up;
  # it's built on first use and keyed to the pinned tag.
  axolotlLocal = "llm-lab/axolotl:${lib.last (lib.splitString ":" images.axolotl)}";

  # Axolotl CLI, run from the project directory:
  #   axolotl train /work/configs/stage1.yml
  axolotl = mkGpuWrapper "axolotl" ''
    if ! docker image inspect ${axolotlLocal} >/dev/null 2>&1; then
      printf 'FROM %s\nRUN chmod 0755 /root\n' ${images.axolotl} \
        | docker build -q -t ${axolotlLocal} - >/dev/null
    fi
    exec "''${gpu_run[@]}" ${axolotlLocal} axolotl "$@"
  '';

  # Embedding and reranker server on localhost:8081:
  #   tei-serve --model-id BAAI/bge-m3
  # Skips the image's entrypoint.sh: it sniffs the driver's CUDA version via
  # nvidia-smi, but the CDI-mounted nvidia-smi is a NixOS binary that can't
  # exec inside the image, so the script misreads the driver as old and
  # prepends the CUDA 12.9 compat libs, which break on a CUDA 13 driver.
  tei-serve = mkGpuWrapper "tei-serve" ''
    exec "''${gpu_run[@]}" --name tei -p 127.0.0.1:8081:8080 \
      -e PORT=8080 -e HUGGINGFACE_HUB_CACHE=/hf/hub \
      --entrypoint text-embeddings-router \
      ${images.tei} "$@"
  '';
in
{
  home.packages = [
    vllm-serve
    axolotl
    tei-serve
  ];
}
