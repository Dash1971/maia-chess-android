#!/usr/bin/env python3
"""Export Maia-3 5M to ONNX and verify it against PyTorch."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import onnx
import onnxruntime as ort
import torch
from torch import nn


if not hasattr(nn, "RMSNorm"):
    class RMSNorm(nn.Module):
        """Compatibility implementation for Intel macOS PyTorch 2.2."""

        def __init__(self, normalized_shape: int, eps: float | None = None) -> None:
            super().__init__()
            self.eps = eps if eps is not None else torch.finfo(torch.float32).eps
            self.weight = nn.Parameter(torch.ones(normalized_shape))

        def forward(self, value: torch.Tensor) -> torch.Tensor:
            scale = value.pow(2).mean(dim=-1, keepdim=True)
            return value * torch.rsqrt(scale + self.eps) * self.weight

    nn.RMSNorm = RMSNorm

from maia3.model_registry import resolve_checkpoint_path
from maia3.uci import load_model, parse_args


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    cfg = parse_args(["--model", "maia3-5m", "--device", "cpu", "--local-files-only"])
    cfg.checkpoint_path = resolve_checkpoint_path(
        cfg.model_spec,
        checkpoint_filename=cfg.checkpoint_filename,
        cache_dir=cfg.cache_dir,
        revision=cfg.revision,
        local_files_only=True,
    )
    model = load_model(cfg)

    torch.manual_seed(7)
    tokens = torch.zeros((1, 64, 12 * cfg.history + 1), dtype=torch.float32)
    self_elo = torch.tensor([1500], dtype=torch.int64)
    opponent_elo = torch.tensor([1500], dtype=torch.int64)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with torch.inference_mode():
        expected = model(tokens, self_elo, opponent_elo)
        torch.onnx.export(
            model,
            (tokens, self_elo, opponent_elo),
            str(args.output),
            input_names=["tokens", "self_elo", "opponent_elo"],
            output_names=["move_logits", "value_logits", "ponder"],
            dynamic_axes={
                "tokens": {0: "batch"},
                "self_elo": {0: "batch"},
                "opponent_elo": {0: "batch"},
                "move_logits": {0: "batch"},
                "value_logits": {0: "batch"},
                "ponder": {0: "batch"},
            },
            opset_version=17,
            do_constant_folding=True,
        )

    onnx.checker.check_model(onnx.load(args.output))
    session = ort.InferenceSession(str(args.output), providers=["CPUExecutionProvider"])
    actual = session.run(
        None,
        {
            "tokens": tokens.numpy(),
            "self_elo": self_elo.numpy(),
            "opponent_elo": opponent_elo.numpy(),
        },
    )
    errors = [
        float(np.max(np.abs(reference.detach().numpy() - exported)))
        for reference, exported in zip(expected, actual, strict=True)
    ]
    if max(errors) > 1e-4:
        raise RuntimeError(f"ONNX verification failed: max errors {errors}")
    print(f"Exported {args.output} ({args.output.stat().st_size} bytes); max errors {errors}")


if __name__ == "__main__":
    main()
