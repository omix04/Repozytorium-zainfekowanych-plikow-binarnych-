#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage

QUEUE_FILE = Path(__file__).parent / "queue.json"
SERVICE_ACCOUNT_FILE = Path(__file__).parent / "serviceAccountKey.json"
STORAGE_BUCKET = "repozytorium-binarne.firebasestorage.app"
DATABASE_ID = "sala"
COLLECTION_NAME = "binary_items"


def init_firebase():
    if not SERVICE_ACCOUNT_FILE.exists():
        print(f"Brak pliku {SERVICE_ACCOUNT_FILE}")
        print("Pobierz klucz konta serwisowego z Firebase Console:")
        print("Project Settings -> Service Accounts -> Generate New Private Key")
        sys.exit(1)

    if not firebase_admin._apps:
        cred = credentials.Certificate(str(SERVICE_ACCOUNT_FILE))
        firebase_admin.initialize_app(cred, {"storageBucket": STORAGE_BUCKET})


def calculate_md5(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def upload_file(file_path, metadata):
    init_firebase()

    file_path = Path(file_path)
    if not file_path.exists():
        print(f"Plik nie istnieje: {file_path}")
        return False

    file_name = file_path.name
    storage_path = f"binaries/{file_name}"
    file_format = file_path.suffix.lower().lstrip(".")
    md5_hash = calculate_md5(file_path)

    print(f"Wysylanie: {file_name}")
    print(f"MD5: {md5_hash}")

    try:
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)
        blob.upload_from_filename(str(file_path))
        print(f"Plik wyslany do Storage: {storage_path}")
    except Exception as e:
        print(f"Blad wysylania do Storage: {e}")
        return False

    doc_data = {
        "fileName": file_name,
        "fileNameDescription": metadata.get("fileNameDescription", ""),
        "platform": metadata.get("platform", "Unknown"),
        "platformDescription": metadata.get("platformDescription", ""),
        "format": file_format,
        "formatDescription": metadata.get("formatDescription", ""),
        "source": metadata.get("source", "Unknown"),
        "sourceDescription": metadata.get("sourceDescription", ""),
        "status": "to analysis",
        "statusDescription": metadata.get("statusDescription", ""),
        "storagePath": storage_path,
        "storagePathDescription": metadata.get("storagePathDescription", ""),
        "md5": md5_hash,
        "lastVerified": datetime.now().isoformat(),
    }

    try:
        db = firestore.client(database_id=DATABASE_ID)
        db.collection(COLLECTION_NAME).add(doc_data)
        print(f"Metadane zapisane w Firestore")
        return True
    except Exception as e:
        print(f"Blad zapisu do Firestore: {e}")
        return False


def load_queue():
    if QUEUE_FILE.exists():
        with open(QUEUE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []


def save_queue(queue):
    with open(QUEUE_FILE, "w", encoding="utf-8") as f:
        json.dump(queue, f, indent=2, ensure_ascii=False)


def add_to_queue(file_path, metadata):
    file_path = Path(file_path)
    if not file_path.exists():
        print(f"Plik nie istnieje: {file_path}")
        return False

    queue = load_queue()

    entry = {
        "file_path": str(file_path.absolute()),
        "metadata": metadata,
        "added_at": datetime.now().isoformat(),
    }

    queue.append(entry)
    save_queue(queue)

    print(f"Dodano do kolejki: {file_path.name}")
    print(f"Liczba elementow w kolejce: {len(queue)}")
    return True


def list_queue():
    queue = load_queue()

    if not queue:
        print("Kolejka jest pusta")
        return

    print(f"Elementy w kolejce ({len(queue)}):")
    print("-" * 50)

    for i, entry in enumerate(queue, 1):
        file_path = Path(entry["file_path"])
        added_at = entry.get("added_at", "brak daty")
        exists = "OK" if file_path.exists() else "BRAK PLIKU"
        print(f"{i}. {file_path.name}")
        print(f"   Sciezka: {file_path}")
        print(f"   Dodano: {added_at}")
        print(f"   Status: {exists}")
        print()


def send_queue():
    queue = load_queue()

    if not queue:
        print("Kolejka jest pusta")
        return

    print(f"Wysylanie {len(queue)} elementow...")
    print("=" * 50)

    success_count = 0
    failed_entries = []

    for entry in queue:
        file_path = entry["file_path"]
        metadata = entry["metadata"]

        if upload_file(file_path, metadata):
            success_count += 1
        else:
            failed_entries.append(entry)

        print("-" * 30)

    save_queue(failed_entries)

    print("=" * 50)
    print(f"Wyslano: {success_count}/{len(queue)}")

    if failed_entries:
        print(f"Nieudane proby pozostaly w kolejce: {len(failed_entries)}")


def clear_queue():
    save_queue([])
    print("Kolejka wyczyszczona")


def main():
    parser = argparse.ArgumentParser(
        description="CLI do wysylania zainfekowanych plikow binarnych do repozytorium"
    )

    subparsers = parser.add_subparsers(dest="command", help="Dostepne komendy")

    upload_parser = subparsers.add_parser("upload", help="Wyslij plik natychmiast")
    upload_parser.add_argument("file", help="Sciezka do pliku")
    upload_parser.add_argument("--platform", default="Windows", help="Platforma docelowa")
    upload_parser.add_argument("--platform-desc", default="", help="Opis platformy")
    upload_parser.add_argument("--source", default="Unknown", help="Zrodlo pliku")
    upload_parser.add_argument("--source-desc", default="", help="Opis zrodla")
    upload_parser.add_argument("--file-desc", default="", help="Opis nazwy pliku")
    upload_parser.add_argument("--format-desc", default="", help="Opis formatu")
    upload_parser.add_argument("--status-desc", default="", help="Opis statusu")
    upload_parser.add_argument("--storage-desc", default="", help="Opis sciezki storage")

    queue_parser = subparsers.add_parser("queue", help="Dodaj plik do kolejki")
    queue_parser.add_argument("file", help="Sciezka do pliku")
    queue_parser.add_argument("--platform", default="Windows", help="Platforma docelowa")
    queue_parser.add_argument("--platform-desc", default="", help="Opis platformy")
    queue_parser.add_argument("--source", default="Unknown", help="Zrodlo pliku")
    queue_parser.add_argument("--source-desc", default="", help="Opis zrodla")
    queue_parser.add_argument("--file-desc", default="", help="Opis nazwy pliku")
    queue_parser.add_argument("--format-desc", default="", help="Opis formatu")
    queue_parser.add_argument("--status-desc", default="", help="Opis statusu")
    queue_parser.add_argument("--storage-desc", default="", help="Opis sciezki storage")

    subparsers.add_parser("list", help="Pokaz zawartosc kolejki")
    subparsers.add_parser("send", help="Wyslij wszystkie elementy z kolejki")
    subparsers.add_parser("clear", help="Wyczysc kolejke")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return

    if args.command in ["upload", "queue"]:
        metadata = {
            "platform": args.platform,
            "platformDescription": args.platform_desc,
            "source": args.source,
            "sourceDescription": args.source_desc,
            "fileNameDescription": args.file_desc,
            "formatDescription": args.format_desc,
            "statusDescription": args.status_desc,
            "storagePathDescription": args.storage_desc,
        }

        if args.command == "upload":
            upload_file(args.file, metadata)
        else:
            add_to_queue(args.file, metadata)

    elif args.command == "list":
        list_queue()

    elif args.command == "send":
        send_queue()

    elif args.command == "clear":
        clear_queue()


if __name__ == "__main__":
    main()
