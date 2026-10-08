"""Train the Lumina crop-disease classifier and export it for the Flutter app.

Model: MobileNetV2 (ImageNet weights) + a small softmax head, 38 PlantVillage classes.
The exported TFLite model matches what lib/features/diagnosis/data/tflite_service_mobile.dart
feeds it: float32 [1, 224, 224, 3] RGB with pixel values in 0..1. The model rescales to
MobileNetV2's -1..1 range itself, so the app needs no preprocessing changes.

Stages (run in order; each one reuses the previous stage's files):
  features  run every image once through the frozen MobileNetV2 and cache the 1280-d vectors
  head      train the classifier head on the cached vectors (fast)
  finetune  optional: unfreeze the top of MobileNetV2 and train on images (slow on CPU)
  export    build the full model (fine-tuned if present), convert to TFLite, write labels.txt
            and evaluation reports

Usage:
  python ml/train_mobilenetv2.py --data "<dataset root containing train/ and valid/>" --stage features
  python ml/train_mobilenetv2.py --data ... --stage head
  python ml/train_mobilenetv2.py --data ... --stage finetune
  python ml/train_mobilenetv2.py --data ... --stage export
"""
import argparse
import json
import os
import re
import time
from pathlib import Path

import numpy as np

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
import tensorflow as tf  # noqa: E402

IMG_SIZE = 224
BATCH = 64
SEED = 42
REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO / "assets" / "models"


# Display names where the dataset's folder name is long or awkward for farmers.
NAME_OVERRIDES = {
    "Apple___Cedar_apple_rust": "Apple Cedar Rust",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": "Corn Gray Leaf Spot",
    "Grape___Esca_(Black_Measles)": "Grape Black Measles",
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": "Grape Leaf Blight",
    "Orange___Haunglongbing_(Citrus_greening)": "Citrus Greening",
    "Tomato___Spider_mites Two-spotted_spider_mite": "Tomato Spider Mites",
}


def friendly_name(folder: str) -> str:
    """'Corn_(maize)___Common_rust_' -> 'Corn Common Rust'; '*___healthy' -> 'Healthy Corn'."""
    if folder in NAME_OVERRIDES:
        return NAME_OVERRIDES[folder]
    crop, _, disease = folder.partition("___")
    crop = re.sub(r"_?\(.*?\)", "", crop).replace(",_bell", "").replace("_", " ").strip()
    disease = disease.replace("_", " ").strip()
    if disease.lower() == "healthy":
        return f"Healthy {crop}"
    # Drop a repeated crop word ("Tomato Tomato mosaic virus") and the alternative name
    # after a space-separated duplicate ("Cercospora leaf spot Gray leaf spot").
    if disease.lower().startswith(crop.lower() + " "):
        disease = disease[len(crop) + 1:]
    words = [w if w.isupper() else w.capitalize() for w in disease.split()]
    return f"{crop} {' '.join(words)}".strip()


def load_split(root: Path, split: str, class_names=None, shuffle=False):
    return tf.keras.utils.image_dataset_from_directory(
        root / split,
        labels="inferred",
        label_mode="int",
        class_names=class_names,
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH,
        shuffle=shuffle,
        seed=SEED,
    )


def backbone():
    base = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3), include_top=False, weights="imagenet", pooling="avg"
    )
    base.trainable = False
    return base


def build_full_model(base, head):
    """Input: RGB 0..1 (what the app sends). Output: class probabilities."""
    inp = tf.keras.Input((IMG_SIZE, IMG_SIZE, 3), name="image")
    x = tf.keras.layers.Rescaling(2.0, offset=-1.0, name="to_mobilenet_range")(inp)
    x = base(x, training=False)
    out = head(x)
    return tf.keras.Model(inp, out, name="lumina_crop_disease")


def build_head(num_classes):
    return tf.keras.Sequential(
        [
            tf.keras.Input((1280,)),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(num_classes, activation="softmax"),
        ],
        name="head",
    )


def stage_features(data: Path, work: Path):
    work.mkdir(parents=True, exist_ok=True)
    train_ds = load_split(data, "train")
    class_names = train_ds.class_names
    valid_ds = load_split(data, "valid", class_names=class_names)
    (work / "class_names.json").write_text(json.dumps(class_names, indent=1))

    base = backbone()
    # Image datasets give 0..255; mirror the app's 0..1 input and the model's own rescale.
    extractor = tf.keras.Sequential([tf.keras.layers.Rescaling(2.0 / 255.0, offset=-1.0), base])

    for name, ds in (("train", train_ds), ("valid", valid_ds)):
        t0 = time.time()
        feats, labels = [], []
        for i, (x, y) in enumerate(ds):
            feats.append(extractor(x, training=False).numpy())
            labels.append(y.numpy())
            if i % 50 == 0:
                done = sum(len(l) for l in labels)
                print(f"[features] {name}: {done} images, {time.time() - t0:.0f}s", flush=True)
        np.save(work / f"{name}_x.npy", np.concatenate(feats).astype(np.float32))
        np.save(work / f"{name}_y.npy", np.concatenate(labels).astype(np.int32))
        print(f"[features] {name} done in {time.time() - t0:.0f}s", flush=True)


def split_valid(work: Path):
    """Half of 'valid' tunes training (early stopping); the other half is a held-out test set."""
    x, y = np.load(work / "valid_x.npy"), np.load(work / "valid_y.npy")
    idx = np.random.default_rng(SEED).permutation(len(y))
    half = len(y) // 2
    return (x[idx[:half]], y[idx[:half]]), (x[idx[half:]], y[idx[half:]])


def stage_head(work: Path):
    class_names = json.loads((work / "class_names.json").read_text())
    xtr, ytr = np.load(work / "train_x.npy"), np.load(work / "train_y.npy")
    (xva, yva), (xte, yte) = split_valid(work)

    tf.keras.utils.set_random_seed(SEED)
    head = build_head(len(class_names))
    head.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    hist = head.fit(
        xtr, ytr,
        validation_data=(xva, yva),
        epochs=30,
        batch_size=256,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=4, restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.3, patience=2),
        ],
        verbose=2,
    )
    test_loss, test_acc = head.evaluate(xte, yte, verbose=0)
    print(f"[head] held-out test accuracy: {test_acc:.4f}", flush=True)
    head.save(work / "head.keras")
    (work / "head_history.json").write_text(json.dumps({k: [float(v) for v in vs] for k, vs in hist.history.items()}))


def valid_paths_split(data: Path, work: Path):
    """Same val/test halves as split_valid(), but as image file paths."""
    class_names = json.loads((work / "class_names.json").read_text())
    ds = load_split(data, "valid", class_names=class_names)
    paths = np.array(ds.file_paths)
    labels = np.load(work / "valid_y.npy")
    idx = np.random.default_rng(SEED).permutation(len(labels))
    half = len(labels) // 2
    return (paths[idx[:half]], labels[idx[:half]]), (paths[idx[half:]], labels[idx[half:]])


def image_dataset(paths, labels, shuffle=False, repeat=False):
    """RGB images resized to 224 and scaled to 0..1, exactly what the app sends."""
    def load(p, y):
        img = tf.io.decode_jpeg(tf.io.read_file(p), channels=3)
        img = tf.image.resize(img, (IMG_SIZE, IMG_SIZE)) / 255.0
        return img, y

    ds = tf.data.Dataset.from_tensor_slices((paths, labels))
    if shuffle:
        ds = ds.shuffle(len(paths), seed=SEED, reshuffle_each_iteration=True)
    if repeat:
        ds = ds.repeat()
    return ds.map(load, num_parallel_calls=tf.data.AUTOTUNE).batch(BATCH).prefetch(tf.data.AUTOTUNE)


def stage_finetune(data: Path, work: Path, steps_per_epoch: int, epochs: int, unfreeze_from: int,
                   resume: bool = False):
    class_names = json.loads((work / "class_names.json").read_text())
    train = load_split(data, "train", class_names=class_names)
    tr_paths = np.array(train.file_paths)
    tr_labels = np.load(work / "train_y.npy")
    (va_paths, va_labels), _ = valid_paths_split(data, work)

    tf.keras.utils.set_random_seed(SEED)
    ckpt = work / "finetuned.keras"
    history_file = work / "finetune_history.json"
    best_so_far = None
    if resume and ckpt.exists():
        # Continue from the best fine-tuned model; only save if it gets better still.
        model = tf.keras.models.load_model(ckpt)
        base = next(l for l in model.layers if l.name.startswith("mobilenetv2"))
        if history_file.exists():
            best_so_far = max(json.loads(history_file.read_text())["val_accuracy"])
        print(f"[finetune] resuming from {ckpt.name}, best val_accuracy so far {best_so_far}", flush=True)
    else:
        base = backbone()
        model = build_full_model(base, tf.keras.models.load_model(work / "head.keras"))
    # Unfreeze the top blocks only. The backbone is called with training=False, so its
    # BatchNorm statistics stay fixed while the weights adapt.
    base.trainable = True
    for layer in base.layers[:unfreeze_from]:
        layer.trainable = False
    print(f"[finetune] trainable backbone layers: {sum(l.trainable for l in base.layers)}/{len(base.layers)}", flush=True)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(2e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    hist = model.fit(
        image_dataset(tr_paths, tr_labels, shuffle=True, repeat=True),
        steps_per_epoch=steps_per_epoch,
        epochs=epochs,
        validation_data=image_dataset(va_paths, va_labels),
        callbacks=[
            tf.keras.callbacks.ModelCheckpoint(ckpt, monitor="val_accuracy", save_best_only=True,
                                               initial_value_threshold=best_so_far),
            tf.keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=2, restore_best_weights=True),
        ],
        verbose=2,
    )
    previous = json.loads(history_file.read_text()) if (resume and history_file.exists()) else {}
    merged = {k: previous.get(k, []) + [float(v) for v in vs] for k, vs in hist.history.items()}
    history_file.write_text(json.dumps(merged))


def stage_export(data: Path, work: Path):
    class_names = json.loads((work / "class_names.json").read_text())
    finetuned = work / "finetuned.keras"
    if finetuned.exists():
        # Fine-tuned model: evaluate on the held-out test images directly.
        model = tf.keras.models.load_model(finetuned)
        _, (te_paths, yte) = valid_paths_split(data, work)
        probs = model.predict(image_dataset(te_paths, yte), verbose=0)
    else:
        head = tf.keras.models.load_model(work / "head.keras")
        model = build_full_model(backbone(), head)
        # Evaluate the exact float model on the held-out test half (from cached features).
        (_, _), (xte, yte) = split_valid(work)
        probs = head.predict(xte, batch_size=512, verbose=0)
    pred = probs.argmax(1)
    acc = float((pred == yte).mean())
    top3 = float(np.mean([yte[i] in np.argsort(probs[i])[-3:] for i in range(len(yte))]))

    from sklearn.metrics import classification_report, confusion_matrix

    labels = [friendly_name(c) for c in class_names]
    report = classification_report(yte, pred, target_names=labels, output_dict=True, zero_division=0)
    cm = confusion_matrix(yte, pred)

    # TFLite: float16 weights halve the file size while keeping float32 input/output (app
    # unchanged). Int8 dynamic-range quantisation was smaller (2.5 MB) but changed ~2% of
    # predictions, so it was not used.
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_bytes = converter.convert()

    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "crop_disease_v1.tflite").write_bytes(tflite_bytes)
    (ASSETS / "labels.txt").write_text("\n".join(labels) + "\n", encoding="utf-8")

    # Check the quantised TFLite model agrees with the float model on sample test images.
    interp = tf.lite.Interpreter(model_content=tflite_bytes)
    interp.allocate_tensors()
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    valid_ds = load_split(data, "valid", class_names=class_names, shuffle=True)
    agree = total = correct = 0
    for x, y in valid_ds.take(16):
        x01 = (x.numpy() / 255.0).astype(np.float32)
        fl = model.predict(x01, verbose=0).argmax(1)
        for i in range(len(x01)):
            interp.set_tensor(inp["index"], x01[i : i + 1])
            interp.invoke()
            q = interp.get_tensor(out["index"])[0].argmax()
            agree += int(q == fl[i])
            correct += int(q == y.numpy()[i])
            total += 1

    ml_out = REPO / "ml" / "results"
    ml_out.mkdir(parents=True, exist_ok=True)
    summary = {
        "classes": len(labels),
        "test_images": int(len(yte)),
        "test_accuracy": acc,
        "test_top3_accuracy": top3,
        "tflite_size_mb": round(len(tflite_bytes) / 1e6, 2),
        "tflite_vs_float_agreement": agree / total,
        "tflite_sample_accuracy": correct / total,
        "tflite_sample_size": total,
        "input": "float32 [1,224,224,3] RGB 0..1",
        "per_class_f1": {k: round(v["f1-score"], 4) for k, v in report.items() if k in labels},
    }
    (ml_out / "summary.json").write_text(json.dumps(summary, indent=2))
    np.savetxt(ml_out / "confusion_matrix.csv", cm, fmt="%d", delimiter=",", header=",".join(labels), comments="")
    print(json.dumps({k: v for k, v in summary.items() if k != "per_class_f1"}, indent=2), flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=Path, help="folder that contains train/ and valid/")
    ap.add_argument("--work", type=Path, default=Path(__file__).resolve().parents[2] / "ml_work",
                    help="cache folder for features and the trained head (kept outside the repo)")
    ap.add_argument("--stage", required=True, choices=["features", "head", "finetune", "export"])
    ap.add_argument("--steps-per-epoch", type=int, default=400, help="finetune: batches of 64 per epoch")
    ap.add_argument("--epochs", type=int, default=4, help="finetune: maximum epochs")
    ap.add_argument("--resume", action="store_true", help="finetune: continue from finetuned.keras")
    ap.add_argument("--unfreeze-from", type=int, default=107, help="finetune: first backbone layer to train")
    a = ap.parse_args()
    {"features": lambda: stage_features(a.data, a.work),
     "head": lambda: stage_head(a.work),
     "finetune": lambda: stage_finetune(a.data, a.work, a.steps_per_epoch, a.epochs, a.unfreeze_from, a.resume),
     "export": lambda: stage_export(a.data, a.work)}[a.stage]()


if __name__ == "__main__":
    main()
