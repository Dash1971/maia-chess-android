# Maia-3 model provenance

Mobile Maia bundles an ONNX conversion of the released Maia-3 79M model so
that all play and analysis can run offline.

## Upstream source

- Project: <https://github.com/CSSLab/maia3>
- Source revision: `1e13597c42d4858b7cfd7cfdae01e297263364b2`
- Checkpoint repository: <https://huggingface.co/UofTCSSLab/Maia3-79M>
- Checkpoint repository revision: `a107d6ceb7b298cb04ae1da4edffe2939858b894`
- Checkpoint file: `maia3-79m.pt`
- Checkpoint size: `315651851` bytes
- Checkpoint SHA-256:
  `3fc6181d5db789b45a15305732148757ae74efa3e0028e81ba335b462dac45c2`
- Licence: GNU Affero General Public License v3.0

The model card identifies the file as the released Maia3-79M checkpoint and
applies the AGPL-3.0 licence to the model repository. The Maia-3 source
repository is licensed under the same licence.

## Bundled conversion

- File: `assets/models/maia3-79m.onnx`
- Size: `316034244` bytes
- SHA-256:
  `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`
- ONNX producer: PyTorch `2.2.2`
- ONNX IR version: `8`
- ONNX opset: `17`

The ONNX file is a converted form of the upstream checkpoint. It does not add
training data or change the learned weights. It remains covered by Maia-3's
AGPL-3.0 licence.

## Reproduction

Create an isolated Python 3.12 environment, install the pinned packages in
`tool/requirements-maia3-onnx.txt`, and install the pinned Maia-3 source:

```sh
python3.12 -m venv .venv-maia-export
. .venv-maia-export/bin/activate
python -m pip install -r tool/requirements-maia3-onnx.txt
python -m pip install \
  "git+https://github.com/CSSLab/maia3.git@1e13597c42d4858b7cfd7cfdae01e297263364b2"
```

Download `maia3-79m.pt` from the pinned checkpoint revision and verify its
SHA-256 digest before placing it in the Hugging Face cache used by Maia-3. Then
run:

```sh
python tool/export_maia3_onnx.py \
  --model maia3-79m \
  --output assets/models/maia3-79m.onnx
shasum -a 256 assets/models/maia3-79m.onnx
```

The exporter loads the checkpoint locally, exports with opset 17, validates
the ONNX graph, and compares ONNX Runtime outputs with the PyTorch outputs. A
clean re-export from the revisions and package versions above produced a file
that was byte-for-byte identical to the bundled ONNX file.
