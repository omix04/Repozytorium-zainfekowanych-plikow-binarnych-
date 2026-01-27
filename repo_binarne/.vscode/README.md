# Infected File Tagger

A VS Code system to tag and highlight files with "infected" status in red.

## Features

- **Red highlighting** for infected files in the editor
- **Easy tagging** via command palette
- **Metadata persistence** in `.vscode/infected_files.json`
- **Quick navigation** to infected files

## Usage

### Method 1: Using Commands

1. Open command palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Run one of these commands:
   - **Tag as Infected**: Tags the current file as infected
   - **Remove Infection Tag**: Removes the infected tag from current file
   - **Show All Infected Files**: Lists all infected files for quick access

### Method 2: Manual Editing

1. Edit `.vscode/infected_files.json`
2. Add file paths to the `infected_files` array:

```json
{
  "infected_files": [
    "lib/screens/suspicious_file.dart",
    "lib/data/compromised_repo.dart"
  ]
}
```

3. Save the file - infected files will be automatically highlighted in red

## Visual Indicators

- **Red border and background** on infected files
- **Error icon** in the gutter
- Files remain highlighted when opened

## Example

```json
{
  "infected_files": [
    "lib/screens/edit_item_screen.dart",
    "functions/index.js"
  ],
  "description": "Add file paths here to mark them as infected"
}
```

## Syncing with Firebase Metadata

To automatically sync infected statuses from Firebase:

1. Export your `binary_items` collection from Firestore
2. Filter items where `status` = "infected"
3. Add their `storagePath` values to `infected_files.json`

Example Firebase sync (Node.js):
```javascript
const admin = require('firebase-admin');

async function syncInfectedFiles() {
  const db = admin.firestore();
  const snapshot = await db.collection('binary_items')
    .where('status', '==', 'infected')
    .get();
  
  const infectedPaths = snapshot.docs.map(doc => doc.data().storagePath);
  console.log(JSON.stringify({ infected_files: infectedPaths }, null, 2));
}
```
